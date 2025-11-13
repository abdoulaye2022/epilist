# 📋 Explication complète du système de notifications CRON EpiList

## 🕐 Vue d'ensemble du CRON

Le cron s'exécute **TOUTES LES HEURES** et contient 8 types de notifications différentes.

---

## 📨 1. RÉSUMÉ QUOTIDIEN (Daily Budget Summary)

**Quand ?** Tous les jours à 9h UTC
**Ligne cron :** 39-42
**Fonction :** `sendDailySummaries()`

### Comment ça marche ?
- Trouve tous les budgets actifs qui ont des alertes (`shouldShowAlert()` = true)
- Envoie UN SEUL résumé par jour à chaque utilisateur
- **Anti-spam :** Fichier verrou `daily_summary_YYYY-MM-DD.lock` empêche l'envoi multiple le même jour

### Type de notification :
- Type: `TYPE_DAILY_SUMMARY`
- Préférence vérifiée: `budget_summary`

---

## ⚠️ 2. ALERTES BUDGETS DÉPASSÉS (Budget Exceeded/Warning)

**Quand ?** Toutes les heures de 9h à 21h UTC
**Ligne cron :** 44-49
**Fonction :** `checkBudgetAlerts()`

### Comment ça marche ?
- Vérifie TOUS les budgets actifs qui dépassent (`shouldShowAlert()` = true)
- Détermine le type d'alerte :
  - `exceeded` : Budget complètement dépassé
  - `warning` : Budget proche de la limite (ex: 80-100%)

### 🚨 SYSTÈME ANTI-SPAM (lignes 207-225) :
```
- Alerte "exceeded" : Maximum 1 par HEURE par budget
- Alerte "warning" : Maximum 1 par 4 HEURES par budget
```

**Stockage :** Fichiers cache `storage/alerts_{budget_id}_{alertType}.txt`

### Type de notification :
- Type: `TYPE_BUDGET_ALERT`
- Préférence vérifiée: `budget_alert`

### ⚠️ PROBLÈME IDENTIFIÉ :
Si un budget reste dépassé, il reçoit une alerte **CHAQUE HEURE** pendant 13 heures (9h-21h) !
- Exceeded : 13 notifications max par jour (1 par heure)
- Warning : 3-4 notifications max par jour (1 toutes les 4h)

---

## ⏰ 3. BUDGETS EXPIRANT BIENTÔT (Budget Expiring Soon)

**Quand ?** Tous les jours à 18h UTC
**Ligne cron :** 51-55
**Fonction :** `checkExpiringBudgets()`

### Comment ça marche ?
- Trouve les budgets qui expirent dans **EXACTEMENT 3 jours** (`end_date = aujourd'hui + 3 jours`)
- Envoie UNE notification par budget
- **Anti-spam :** Fichier verrou `expiring_budgets_YYYY-MM-DD.lock` empêche l'envoi multiple le même jour

### Type de notification :
- Type: `TYPE_BUDGET_EXPIRING`
- Préférence vérifiée: `budget_alert`

### ⚠️ COMPORTEMENT ACTUEL :
- Si un budget expire le 15 novembre, vous recevez UNE notification le 12 novembre à 18h
- **AUCUNE notification multiple**

---

## 😴 4. RAPPEL UTILISATEURS INACTIFS (Inactivity Reminder)

**Quand ?** Chaque mardi à 10h UTC
**Ligne cron :** 57-61
**Fonction :** `checkInactiveUsers()`

### Comment ça marche ?
- Trouve les utilisateurs qui n'ont pas créé de liste depuis **2 semaines**
- **Anti-spam :** Maximum 1 notification par MOIS par utilisateur
- **Anti-spam hebdomadaire :** Fichier verrou `inactive_users_week_{YYYY-WW}.lock`

### Type de notification :
- Type: `TYPE_USER_INACTIVE`
- Préférence vérifiée: `tips_and_tricks`

---

## 📝 5. LISTES COMPLÉTÉES SANS FACTURE (Completed Lists Reminder)

**Quand ?** Heures paires (8h, 10h, 12h, 14h, 16h, 18h, 20h, 22h) UTC
**Ligne cron :** 63-67
**Fonction :** `checkCompletedLists()`

### Comment ça marche ?
- Trouve les listes complétées sans photo de facture
- Envoie un rappel pour ajouter la facture

### Type de notification :
- Type: `TYPE_LIST_COMPLETED`
- Préférence vérifiée: `list_completed`

---

## 🧹 6. NETTOYAGE (Cleanup)

**Quand ?** Chaque dimanche à 2h UTC
**Ligne cron :** 69-76
**Fonction :** `cleanupInactiveDevices()` + `cleanupNotificationCacheFiles()`

### Pas de notification envoyée, juste du nettoyage :
- Supprime les appareils inactifs depuis 30+ jours
- Nettoie les fichiers cache de notifications anciens

---

## 📅 7. RAPPEL LISTE HEBDOMADAIRE (Weekly List Reminder)

**Quand ?** Chaque vendredi à 19h UTC
**Ligne cron :** 78-82
**Fonction :** `checkUsersWithoutWeeklyLists()`

### Comment ça marche ?
- Trouve les utilisateurs qui n'ont PAS créé de liste cette semaine
- **Anti-spam :** Fichier verrou `weekly_lists_check_week_{YYYY-WW}.lock`

### Type de notification :
- Type: `TYPE_WEEKLY_LIST_REMINDER`
- Préférence vérifiée: `tips_and_tricks`

---

## 🤖 8. RAPPELS INTELLIGENTS BASÉS SUR LES HABITUDES (Habit-Based Reminders)

**Quand ?** Tous les jours à 10h UTC
**Ligne cron :** 84-88
**Fonction :** `analyzeUserHabitsAndSendReminders()`

### Comment ça marche ?
- Analyse les habitudes de création de listes de chaque utilisateur
- Détecte si l'utilisateur crée des listes de façon régulière (hebdomadaire, mensuelle)
- Envoie un rappel si l'utilisateur "devrait" créer une liste selon ses habitudes
- **Anti-spam :** Fichier verrou `habit_analysis_YYYY-MM-DD.lock`

### Type de notification :
- Type: `TYPE_WEEKLY_LIST_REMINDER`
- Préférence vérifiée: `tips_and_tricks`

---

## 🔍 DIAGNOSTIC : Pourquoi plusieurs notifications pour un budget expirant ?

### Scénario possible :

Si votre budget expire et qu'il est AUSSI dépassé, vous pouvez recevoir :

1. **Budget Exceeded Alerts** (type 2) : 1 par heure de 9h à 21h
   - "⚠️ Budget Exceeded! You exceeded the budget..."

2. **Budget Expiring Alert** (type 3) : 1 fois à 18h, 3 jours avant expiration
   - "Budget se termine bientôt"

### Exemple concret :
Budget : "Monthly General Budget"
- Budget: $10.00
- Dépensé: $18.00 (DÉPASSÉ de $8)
- Date de fin: 15 novembre 2025

**12 novembre à 18h** : Notification "Budget se termine dans 3 jours"
**13 novembre à 9h** : Notification "Budget Exceeded" ($18/$10)
**13 novembre à 10h** : Notification "Budget Exceeded" ($18/$10)
**13 novembre à 11h** : Notification "Budget Exceeded" ($18/$10)
... (et ainsi de suite jusqu'à 21h)

---

## 🎯 SOLUTION AU PROBLÈME

### Option 1 : Désactiver les alertes budget
Dans les préférences, décochez "Budget Exceeded" → Plus aucune notification de budget

### Option 2 : Augmenter le cooldown pour les budgets dépassés
Modifier le cooldown de 1 heure à 24 heures pour les alertes "exceeded"

**Fichier :** `public/cron.php` ligne 213
```php
// AVANT :
$cooldownHours = $alertType === 'exceeded' ? 1 : 4;

// APRÈS (1 alerte par jour max) :
$cooldownHours = $alertType === 'exceeded' ? 24 : 24;
```

### Option 3 : Ne pas envoyer d'alertes "exceeded" pour les budgets qui expirent bientôt
Ajouter une vérification dans `checkBudgetAlerts()` pour ignorer les budgets qui expirent dans moins de 7 jours

---

## 📊 Résumé des fréquences d'envoi

| Type de notification | Fréquence maximum | Anti-spam |
|---------------------|-------------------|-----------|
| Daily Summary | 1 par jour | Verrou quotidien |
| Budget Exceeded | 1 par heure | Cache 1h |
| Budget Warning | 1 par 4h | Cache 4h |
| Budget Expiring | 1 fois (3 jours avant) | Verrou quotidien |
| Inactivity Reminder | 1 par mois | Cache 30 jours |
| Completed Lists | Multiple (heures paires) | Cache par liste |
| Weekly List Reminder | 1 par semaine | Verrou hebdomadaire |
| Habit-Based Reminder | 1 par jour | Verrou quotidien |

---

## ✅ Recommandations

1. **Augmenter le cooldown des alertes "exceeded"** de 1h à 6h ou 24h
2. **Ne pas envoyer d'alertes exceeded** pour les budgets qui expirent dans < 7 jours
3. **Grouper les alertes** : Envoyer une seule notification avec tous les budgets dépassés au lieu d'une par budget
