# Protection contre les Bots - EpiList API

## Vue d'ensemble

Le système de protection contre les bots a été implémenté pour sécuriser l'API EpiList contre :
- Les inscriptions automatisées massives
- Les tentatives de brute force sur les mots de passe
- Les abus sur les codes de vérification email
- Les attaques par déni de service (DoS)

## Architecture

### Service RateLimiter

**Fichier**: `src/Services/RateLimiter.php`

Ce service gère toutes les limitations de taux et la détection de comportements suspects.

#### Stockage
- Fichiers JSON dans `/storage/rate_limits/`
- Nettoyage automatique des fichiers de plus de 7 jours
- Pas de dépendance à Redis ou base de données

## Protections Implémentées

### 1. Protection de l'Inscription (register)

**Endpoint**: `POST /api/register`

#### Limites par IP
- **3 inscriptions maximum** par IP en 60 minutes
- Code d'erreur: `RATE_LIMIT_EXCEEDED` (HTTP 429)

#### Limites par Email
- **5 tentatives maximum** par email en 24 heures
- Code d'erreur: `EMAIL_RATE_LIMIT` (HTTP 429)

#### Limite Globale
- **50 inscriptions maximum** par heure (tous IPs confondus)
- Protection contre le spam massif
- Code d'erreur: `GLOBAL_LIMIT_REACHED` (HTTP 429)

#### Détection d'IP Suspecte
- Analyse des patterns d'activité sur plusieurs actions
- Blocage automatique de 60 minutes si détecté
- Code d'erreur: `SUSPICIOUS_ACTIVITY` (HTTP 429)

### 2. Protection Reset Mot de Passe

**Endpoint**: `POST /api/request-password-change`

#### Limites
- **5 tentatives maximum** par IP en 60 minutes
- Code d'erreur: `RATE_LIMIT_EXCEEDED` (HTTP 429)

#### Sécurité Additionnelle
- Réponse identique que l'email existe ou non (évite l'énumération)
- Enregistrement de toutes les tentatives

### 3. Protection Codes de Vérification

**Endpoint**: `POST /api/confirm-email`

#### Limites
- **5 tentatives maximum** par IP en 30 minutes
- Code d'erreur: `RATE_LIMIT_EXCEEDED` (HTTP 429)

#### Réinitialisation
- Les tentatives sont réinitialisées après une vérification réussie

### 4. Blocage d'IP

#### Détection Automatique
Une IP est bloquée automatiquement si :
- Elle dépasse les limites sur une action
- Elle montre des patterns suspects (tentatives sur multiples actions)

#### Durée du Blocage
- **60 minutes** par défaut
- Code d'erreur: `IP_BLOCKED` (HTTP 429)

#### Déblocage
- Automatique après expiration
- Les fichiers de blocage sont supprimés automatiquement

## Intégration dans AuthController

### Méthode `getClientIP()`

Détecte l'IP réelle du client même derrière un proxy/load balancer :
1. Vérifie `X-Forwarded-For` (proxy standard)
2. Vérifie `X-Real-IP` (nginx)
3. Vérifie `CF-Connecting-IP` (Cloudflare)
4. Fallback sur `REMOTE_ADDR`

### Exemple d'Utilisation

```php
// Dans la méthode register()
$ipAddress = $this->getClientIP($request);

// Vérifier si IP bloquée
if ($this->rateLimiter->isIPBlocked($ipAddress)) {
    return $this->createErrorResponse(
        'Trop de tentatives. Votre IP a été temporairement bloquée.',
        429,
        'IP_BLOCKED'
    );
}

// Vérifier limite
if (!$this->rateLimiter->checkIPLimit('registration', $ipAddress)) {
    $retryAfter = $this->rateLimiter->getRetryAfter('registration', $ipAddress);
    return $this->createErrorResponse(
        'Trop de tentatives d\'inscription. Veuillez réessayer dans ' . ceil($retryAfter / 60) . ' minutes.',
        429,
        'RATE_LIMIT_EXCEEDED',
        ['retry_after' => $retryAfter]
    );
}

// Enregistrer la tentative
$this->rateLimiter->recordAttempt('registration', $ipAddress);
```

## Réponses d'Erreur

### HTTP 429 - Too Many Requests

#### IP_BLOCKED
```json
{
  "success": false,
  "message": "Trop de tentatives. Votre IP a été temporairement bloquée.",
  "code": "IP_BLOCKED"
}
```

#### RATE_LIMIT_EXCEEDED
```json
{
  "success": false,
  "message": "Trop de tentatives d'inscription. Veuillez réessayer dans 45 minutes.",
  "code": "RATE_LIMIT_EXCEEDED",
  "errors": {
    "retry_after": 2700
  }
}
```

#### SUSPICIOUS_ACTIVITY
```json
{
  "success": false,
  "message": "Activité suspecte détectée. Veuillez réessayer plus tard.",
  "code": "SUSPICIOUS_ACTIVITY"
}
```

#### GLOBAL_LIMIT_REACHED
```json
{
  "success": false,
  "message": "Trop d'inscriptions en cours. Veuillez réessayer dans quelques minutes.",
  "code": "GLOBAL_LIMIT_REACHED"
}
```

## Tests

### Script de Test
**Fichier**: `test_bot_protection.php`

```bash
php test_bot_protection.php
```

### Tests Effectués
1. ✅ Limite d'inscription par IP (3/60min)
2. ✅ Limite par email (5/24h)
3. ✅ Limite globale (50/h)
4. ✅ Détection d'IP suspecte
5. ✅ Blocage/déblocage d'IP
6. ✅ Réinitialisation des tentatives
7. ✅ Nettoyage automatique

## Maintenance

### Nettoyage Automatique

Le service nettoie automatiquement les fichiers de plus de 7 jours.

Vous pouvez aussi nettoyer manuellement :

```php
$rateLimiter = new RateLimiter();
$rateLimiter->cleanup();
```

### Débloquer Manuellement une IP

```php
// Supprimer le fichier de blocage
unlink('/path/to/storage/rate_limits/blocked_[hash].txt');
```

### Réinitialiser les Tentatives

```php
$rateLimiter->resetAttempts('registration', '192.168.1.100');
```

## Logs

Tous les événements sont loggés avec des emojis pour faciliter la lecture :

- ✅ Tentative autorisée
- 🚫 Tentative bloquée
- 📝 Tentative enregistrée
- ⚠️  IP suspecte détectée
- 🔒 IP bloquée
- 🔓 IP débloquée
- 🔄 Tentatives réinitialisées
- 🧹 Nettoyage effectué

## Configuration

Les limites sont configurées dans `RateLimiter::LIMITS` :

```php
private const LIMITS = [
    'registration' => [
        'max_attempts_per_ip' => 3,
        'window_minutes' => 60,
        'global_max_per_hour' => 50,
    ],
    'registration_email' => [
        'max_attempts' => 5,
        'window_minutes' => 1440, // 24h
    ],
    'verification_code' => [
        'max_attempts' => 5,
        'window_minutes' => 30,
    ],
    'password_reset' => [
        'max_attempts_per_ip' => 5,
        'window_minutes' => 60,
    ]
];
```

## Endpoints Protégés

| Endpoint | Limite | Fenêtre | Type |
|----------|--------|---------|------|
| `/api/register` | 3 | 60 min | Par IP |
| `/api/register` | 5 | 24h | Par Email |
| `/api/register` | 50 | 60 min | Global |
| `/api/confirm-email` | 5 | 30 min | Par IP |
| `/api/request-password-change` | 5 | 60 min | Par IP |

## Améliorations Futures

- [ ] Intégrer reCAPTCHA pour les IPs suspectes
- [ ] Dashboard admin pour visualiser les tentatives
- [ ] Whitelist d'IPs de confiance
- [ ] Notifications admin en cas d'attaque détectée
- [ ] Intégration avec fail2ban pour blocage au niveau firewall

## Sécurité

- Les adresses IP sont hashées (MD5) pour les fichiers de cache
- Les emails sont hashés pour la confidentialité
- Aucune donnée sensible stockée en clair
- Nettoyage automatique pour limiter l'espace disque
- Support des proxies/load balancers

## Support

Pour toute question ou problème :
1. Vérifier les logs dans les erreurs PHP
2. Exécuter `test_bot_protection.php` pour diagnostiquer
3. Vérifier les permissions du dossier `/storage/rate_limits/`
