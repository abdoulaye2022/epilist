# 🔍 Diagnostic du problème de timeout

## Problème
Les requêtes API mettent plus de 60 secondes à recevoir une réponse, causant des timeouts dans l'application Flutter.

## Symptômes
```
Error loading shopping lists: DioException [receive timeout]:
The request took longer than 0:01:00.000000 to receive data.
```

## Cause probable
Le serveur PHP répond mais très lentement (>60s). Logs serveur montrent des réponses HTTP 200 mais avec un délai énorme.

## Solutions temporaires appliquées

### 1. Augmentation des timeouts (TEMPORAIRE)
- `lib/main.dart`: `receiveTimeout` passé à 120 secondes
- `lib/services/notification_service.dart`: `receiveTimeout` passé à 120 secondes

### 2. Fix du ConnectivityService
- Ajout de vérification `isClosed` avant d'ajouter au stream
- Évite l'erreur "Cannot add new events after calling close"

## Diagnostic requis côté serveur

### Vérifier ngrok
```bash
# Vérifier si ngrok est lancé
ps aux | grep ngrok

# Relancer ngrok si nécessaire
ngrok http 8080 --host-header="localhost:8080"
```

### Vérifier le serveur PHP
```bash
# Vérifier si le serveur PHP tourne
ps aux | grep php

# Relancer le serveur si nécessaire
cd /Users/mohamedahmedabdoulaye/Documents/mes-projets/epilist/api
php -S localhost:8080 -t public public/index.php
```

### Tester la performance API
```bash
# Test simple (remplacer YOUR_TOKEN par un vrai token)
time curl "https://a0f4e7436d3e.ngrok-free.app/shopping-lists" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Si ça prend plus de 5 secondes, il y a un problème côté serveur
```

## Causes possibles de lenteur serveur

1. **Base de données lente**
   - Requête SQL non optimisée
   - Pas d'index sur les colonnes utilisées
   - Trop de données chargées (eager loading excessif)

2. **ngrok ralenti**
   - Compte gratuit limité
   - Tunnel instable
   - Essayer de relancer ngrok

3. **Serveur PHP surchargé**
   - Mémoire insuffisante
   - Process bloqué
   - Redémarrer le serveur PHP

4. **Problème réseau local**
   - Firewall
   - Antivirus qui scanne les requêtes
   - VPN actif

## Actions recommandées

### Court terme (MAINTENANT)
1. ✅ Redémarrer le serveur PHP
2. ✅ Relancer ngrok avec nouvelle URL
3. ✅ Mettre à jour `app_config.dart` avec nouvelle URL ngrok
4. ✅ Tester avec `curl` pour mesurer le temps de réponse

### Moyen terme
1. Optimiser les requêtes SQL (ajouter des index)
2. Réduire le eager loading (ne charger que ce qui est nécessaire)
3. Ajouter un cache côté serveur (Redis ou fichier)

### Long terme
1. Déployer sur un vrai serveur (pas localhost + ngrok)
2. Utiliser production URLs dans `app_config.dart`
3. Ramener les timeouts à des valeurs normales (30-45 secondes)

## Tests à effectuer

### 1. Test de connectivité ngrok
```bash
curl -I https://a0f4e7436d3e.ngrok-free.app
# Devrait répondre en < 1 seconde
```

### 2. Test de l'endpoint login
```bash
curl -X POST "https://a0f4e7436d3e.ngrok-free.app/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
# Devrait répondre en < 3 secondes
```

### 3. Logs du serveur PHP
Regarder les logs dans le terminal où tourne `php -S`
- Y a-t-il des erreurs?
- Quel est le temps de traitement des requêtes?

## Résolution

Une fois le serveur optimisé et rapide (<5s de réponse):
1. Réduire `receiveTimeout` à 45 secondes dans `main.dart`
2. Réduire `receiveTimeout` à 60 secondes dans `notification_service.dart`
3. Tester l'application

---

**Note**: Les timeouts de 120 secondes sont TEMPORAIRES et doivent être réduits une fois le serveur optimisé.
