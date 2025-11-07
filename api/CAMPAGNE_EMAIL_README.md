# 📧 Guide de Campagne Email - EpiList 2.0.0

## 📋 Vue d'ensemble

Ce guide explique comment utiliser le système de campagne email pour informer tous les utilisateurs des nouvelles fonctionnalités d'EpiList 2.0.0.

## ✨ Nouvelles Fonctionnalités Incluses dans l'Email

L'email de campagne présente **11 nouvelles fonctionnalités révolutionnaires** :

1. 🎤 **Ajout vocal intelligent** - Reconnaissance vocale en français et anglais
2. ✓✓ **Détection des doublons** - Évite les articles en double
3. 💡 **Suggestions d'habitudes d'achat** - Recommandations basées sur vos habitudes
4. 📱 **Scanner de code-barres** - Ajout rapide de produits
5. 💬 **Messagerie de listes intégrée** - Communication en temps réel sur les listes
6. 📶 **Mode hors ligne avancé** - Utilisation sans Internet avec sync automatique
7. 💰 **Gestion complète des dépenses** - Suivi et analyse des dépenses
8. 🧾 **Gestion des reçus** - Photos et organisation des reçus
9. 🎯 **Budgets intelligents** - Alertes et objectifs financiers
10. 📊 **Statistiques avancées** - Graphiques et analyses détaillées
11. 🔔 **Notifications temps réel** - Alertes instantanées

## 🎯 Critères d'Éligibilité

Les utilisateurs reçoivent l'email s'ils répondent à **TOUS** ces critères :

- ✅ `email_marketing_consent = 1` (consentement marketing)
- ✅ `email_verified_at IS NOT NULL` (email vérifié)
- ✅ `is_active = 1` (compte actif)
- ✅ `deletion_requested_at IS NULL` (pas de demande de suppression)

## 🔧 Méthodes d'Envoi

### Option 1 : Script PHP Simple (Recommandé pour tester)

```bash
cd /path/to/api
php test_simple_email.php
```

**Avantages :**
- ✅ Test rapide et simple
- ✅ Pas besoin d'authentification
- ✅ Affiche les informations détaillées
- ✅ En mode DEV, envoie **UN SEUL email** à `m2atodev@gmail.com`

### Option 2 : API REST (Pour production)

#### A. Obtenir les statistiques

```bash
curl -X GET 'http://localhost:8080/campaigns/stats' \
  -H 'Authorization: Bearer YOUR_TOKEN'
```

**Réponse :**
```json
{
  "success": true,
  "data": {
    "environment": "dev",
    "user_stats": {
      "total_users": 250,
      "active_users": 230,
      "verified_users": 220,
      "eligible_for_campaign": 200,
      "unsubscribed_from_marketing": 50,
      "marketing_consent_rate": "80.00%"
    }
  }
}
```

#### B. Envoyer la campagne

```bash
curl -X POST 'http://localhost:8080/campaigns/new-version' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  -d '{}'
```

**Réponse en mode DEV :**
```json
{
  "success": true,
  "data": {
    "mode": "production_dev",
    "environment": "development",
    "total_users_in_db": 200,
    "emails_sent": 1,
    "actual_email_sent_to": "m2atodev@gmail.com",
    "note": "En mode DEV, un seul email est envoyé à l'adresse de développement"
  }
}
```

**Réponse en mode PRODUCTION :**
```json
{
  "success": true,
  "data": {
    "mode": "production",
    "campaign_type": "new_version_2_0",
    "total_users": 200,
    "emails_sent": 198,
    "emails_failed": 2,
    "success_rate": "99.00%",
    "batch_size": 50
  }
}
```

### Option 3 : Prévisualisation de l'Email

Pour voir l'email sans l'envoyer :

```bash
# Dans le navigateur
http://localhost:8080/campaign/preview?first_name=Mohamed

# Ou via curl
curl -X GET 'http://localhost:8080/campaign/preview?first_name=Mohamed' > email_preview.html
open email_preview.html
```

## 🛡️ Sécurité en Mode DEV

### Protection Automatique

Lorsque `APP_ENV=dev` dans le fichier `.env` :

1. **UN SEUL EMAIL envoyé** - Jamais aux vrais utilisateurs
2. **Email forcé vers** : `m2atodev@gmail.com`
3. **Données réelles utilisées** - Pour simuler un envoi réel
4. **Note visible** - Le système indique clairement qu'on est en DEV

### Vérification de l'Environnement

```php
// Dans CampaignController.php ligne 84-148
if (Config::get('APP_ENV') == 'dev') {
    // Mode DEV: 1 seul email à m2atodev@gmail.com
    $emailToSend = 'm2atodev@gmail.com';
} else {
    // Mode PROD: Tous les utilisateurs éligibles
    // ...envoi à tous...
}
```

## 📨 Structure de l'Email

### Sujet
```
🎉 EpiList 2.0.0 - 11 nouvelles fonctionnalités révolutionnaires !
```

### Contenu Principal
1. **En-tête** : Logo EpiList + titre accrocheur
2. **Introduction** : Message personnalisé avec prénom
3. **11 Cartes de fonctionnalités** : Design coloré avec icônes
4. **Section Apps mobiles** : Liens App Store + Google Play
5. **Screenshots** : Aperçus de l'interface
6. **CTA principal** : Invitation à mettre à jour
7. **Section bénéfices** : Pourquoi cette mise à jour
8. **Footer** : Liens de désabonnement + coordonnées

### Design
- ✨ Gradients modernes
- 🎨 Couleurs thématiques par fonctionnalité
- 📱 Responsive (mobile-friendly)
- 🔗 Lien de désabonnement inclus (RGPD)

## 🔄 Gestion du Désabonnement

### URL de Désabonnement

Chaque email contient un lien unique :
```
https://m2atodev.com/api.epilist/public/unsubscribe/{token}
```

### Processus

1. L'utilisateur clique sur "Se désabonner"
2. Le système met à jour :
   - `email_marketing_consent = 0`
   - `email_marketing_unsubscribed_at = NOW()`
3. Email de confirmation envoyé
4. L'utilisateur ne reçoit plus d'emails marketing

## 📊 Suivi et Analytics

### Fichiers de Log

Les envois sont enregistrés dans :
```
/var/log/epilist_emails.log
```

### Informations Trackées

- ✅ Nombre d'emails envoyés
- ✅ Nombre d'échecs
- ✅ Taux de succès
- ✅ Durée totale d'envoi
- ✅ Erreurs par utilisateur

## 🚀 Déploiement en Production

### Checklist Avant Envoi

- [ ] Vérifier que `APP_ENV=production` dans `.env`
- [ ] Tester l'email en DEV d'abord
- [ ] Vérifier le nombre d'utilisateurs éligibles
- [ ] Confirmer la configuration SMTP/Brevo
- [ ] Planifier l'envoi aux heures optimales (10h-16h)

### Commande Production

```bash
# 1. Vérifier les stats
curl -X GET 'https://api.epilist.app/campaigns/stats' \
  -H 'Authorization: Bearer PROD_TOKEN'

# 2. Lancer la campagne
curl -X POST 'https://api.epilist.app/campaigns/new-version' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer PROD_TOKEN' \
  -d '{
    "batch_size": 50
  }'
```

### Monitoring

```bash
# Surveiller les logs en temps réel
tail -f /var/log/epilist_emails.log
```

## 📁 Fichiers Modifiés

### Email Template
- `/api/src/Services/MailSender.php` : Lignes 983-1333
  - `newVersionCampaignEmail()` : Template HTML complet
  - `sendNewVersionCampaign()` : Fonction d'envoi

### Controller
- `/api/src/Controllers/CampaignController.php`
  - `sendNewVersionCampaign()` : Gestion des envois massifs
  - `getCampaignStats()` : Statistiques
  - `handleUnsubscribe()` : Désabonnement

### Routes
- `/api/public/index.php` : Lignes 155-156, 289-291
  - `POST /campaigns/new-version` (protégé)
  - `GET /campaigns/stats` (protégé)
  - `GET /campaign/preview` (public)
  - `GET /unsubscribe/{token}` (public)

## ❓ FAQ

### Q: Combien de temps prend l'envoi ?
**R:** Environ 1 minute par 60 utilisateurs (pause de 0.1s entre chaque email + 1s entre chaque lot)

### Q: Que se passe-t-il si un email échoue ?
**R:** Le système continue avec les autres utilisateurs et log l'erreur

### Q: Puis-je annuler un envoi en cours ?
**R:** Non, une fois lancé, l'envoi continue. Testez toujours en DEV d'abord !

### Q: Comment vérifier qu'un utilisateur a reçu l'email ?
**R:** Consultez les logs de Brevo ou utilisez leur dashboard

### Q: L'email est-il multilingue ?
**R:** Actuellement en français uniquement. Version anglaise à venir.

## 🔐 Sécurité

- ✅ Tokens de désabonnement uniques par utilisateur
- ✅ Validation des consentements marketing
- ✅ Protection contre les envois en DEV
- ✅ Rate limiting sur l'API
- ✅ Authentification requise pour les endpoints sensibles

## 📞 Support

En cas de problème :

1. Vérifiez les logs : `/var/log/epilist_emails.log`
2. Testez avec `test_simple_email.php`
3. Vérifiez la configuration SMTP dans `.env`
4. Contactez l'équipe technique

---

**Développé avec ❤️ par M2atech Solutions Inc.**
*EpiList - Simplifiez vos courses. Maîtrisez votre budget.*
