# Audit des notifications (push et email)

Réalisé le 2026-10-01. Méthode : inventaire des envois côté serveur,
des déclencheurs (cron et événements), des préférences en base, et de
ce que l'application expose à l'utilisateur.

## Inventaire

### Push (FCM) — 12 types

| Type | Déclencheur |
|---|---|
| `new_message` | message dans une liste partagée |
| `list_updated`, `list_shared` | activité sur une liste partagée |
| `list_completed` | liste terminée sans facture (cron, heures paires 8h-22h) |
| `budget_alert`, `budget_warning`, `budget_exceeded` | cron horaire 9h-21h |
| `daily_summary` | cron quotidien |
| `user_inactive`, `weekly_list_reminder`, `daily_list_reminder` | cron d'engagement |
| `purchase_reminder` | déclaré, non utilisé |
| `price_alert` | baisse de prix (Phase 4) |

### Email — 10 envois réels

**Obligatoires** : code de vérification, renvoi de code, code de
changement de mot de passe, confirmation de changement, code 2FA, code
d'administration, confirmation de suppression de compte, formulaire de
contact (vers l'équipe), confirmation de désabonnement.

**Non obligatoires** : email de bienvenue (4 points d'envoi),
**alertes de budget par email** (`BudgetAlertService`), campagne
(consentement explicite, légitime).

## Constats

### C1 — CRITIQUE · Les emails de sécurité sont désactivables

L'écran « Préférences email » expose des interrupteurs pour
`email_verification`, `password_change_request` et `password_changed`,
et `MailSender::canSendEmail()` les respecte sans exception.

Conséquence : un utilisateur qui les désactive **ne reçoit plus son
code de vérification ni son code de réinitialisation** — il ne peut
plus activer son compte ni récupérer son mot de passe. Verrouillage
définitif, sans message d'erreur : le serveur répond « envoyé ».

### C2 — MAJEUR · Aucun contrôle propre des notifications push

`NotificationService::canSendNotification()` filtre le push sur la
table `email_preferences`. Les deux canaux sont donc **confondus** :

- couper les emails de budget coupe aussi les **push** de budget ;
- impossible de garder le push en supprimant l'email — précisément ce
  qui est demandé ;
- l'application n'a **aucun écran de réglage des notifications push**
  (seulement « Préférences email »).

Un mécanisme par appareil existe pourtant côté serveur
(`/devices/notifications`, `setNotificationPreferences`) : il n'est
appelé par personne. `shouldReceiveBudgetAlerts()` : 0 appel.

### C3 — MAJEUR · La déconnexion ne coupe pas le push

La route `/devices/deactivate` existe mais **l'application ne l'appelle
jamais**. Après une déconnexion, l'appareil reste enregistré : il
continue de recevoir les notifications du compte précédent. Problème de
confidentialité sur un téléphone partagé.

### C4 — MOYEN · Alertes de budget envoyées deux fois

`BudgetAlertService` envoie l'alerte **par email**, pendant que le cron
envoie la même alerte **par push**. Même événement, deux canaux, aucune
coordination.

### C5 — MOYEN · Le type `price_alert` échappe aux préférences

Il n'est pas dans la table de correspondance : la valeur par défaut
`return true` le rend **non désactivable**.

### C6 — MINEUR · Modèles d'email morts

`listSharedEmail` et `listCompletedEmail` sont définis et traduits mais
**jamais appelés** (ces événements partent en push). Code mort.

### C7 — INFO · Anti-spam existant, à conserver

Les garde-fous en place sont corrects : cooldown de 3 min par liste
pour `list_updated`, 24 h par budget pour les alertes, fichiers de
cache pour les rappels d'inactivité. Le cron respecte des plages
horaires.

## Priorisation

1. **C1** — risque de verrouillage de compte, à corriger en premier.
2. **C2** — demande explicite : séparer push et email.
3. **C3** — confidentialité.
4. **C4**, **C5**, **C6** — cohérence.

---

## Résolutions (appliquées le 2026-10-01)

Migration : `api/migrations/add_push_preferences.sql` (idempotente).

- **C1 corrigé** — `MailSender::MANDATORY_EMAILS` : vérification du
  compte, récupération du mot de passe et alerte de changement passent
  **avant toute préférence**. Les interrupteurs correspondants ont été
  retirés de l'application, et la migration réactive ces emails chez les
  comptes qui les avaient coupés. Vérifié : préférence à 0 en base →
  l'email part quand même ; une préférence facultative à 0 bloque bien.
- **C2 corrigé** — quatre interrupteurs **push** indépendants
  (`push_list_activity`, `push_budget`, `push_price_alert`,
  `push_reminders`). `canSendNotification()` ne lit plus les
  préférences email. L'écran « Préférences email » devient
  « **Notifications** » : les réglages push, et une explication de la
  politique courrier. Vérifié de bout en bout (lecture et écriture via
  l'API).
- **C3 corrigé** — `AuthService.clearUserData()` appelle
  `/devices/deactivate` **avant** d'effacer la session (le jeton est
  encore nécessaire). L'appareil ne reçoit plus les notifications du
  compte précédent.
- **C4 corrigé** — `BudgetAlertService` n'envoie plus d'email : il
  passe par le push, qui respecte `push_budget`. La construction du
  gabarit HTML inutilisé et les gardes sur les préférences email ont
  été retirées.
- **C5 corrigé** — `price_alert` est désormais classé
  (`push_price_alert`), donc désactivable.
- **Email de bienvenue supprimé** — constante
  `AuthController::SEND_WELCOME_EMAIL = false`, décision réversible en
  une ligne. Vérifié : une inscription n'envoie plus que le code de
  vérification.
- **C6 non traité** — `listSharedEmail` / `listCompletedEmail` et
  `BudgetAlertService::getEmailTemplate()` restent en place, inutilisés.
  Code mort sans effet ; suppression à faire au prochain nettoyage.

## Politique courrier retenue

EpiList n'écrit QUE pour : activation du compte, renvoi de ce code,
récupération du mot de passe, confirmation de changement de mot de
passe, code à deux étapes, code d'administration, suppression de
compte, formulaire de contact, confirmation de désabonnement. La
campagne marketing reste soumise au consentement explicite.

Tout le reste passe par les notifications push, réglables par
l'utilisateur.
