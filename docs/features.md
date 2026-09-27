# Fonctionnalités d'EpiList

Inventaire complet des fonctionnalités de l'application, établi à partir du code source.

EpiList est une application de gestion de listes de courses collaborative, composée de trois éléments :

| Composant | Technologie | Rôle |
|---|---|---|
| `app/` | Flutter 3.x (BLoC + Dio) | Application mobile Android / iOS |
| `api/` | PHP 8.4, Slim 4, Eloquent | API REST — 139 routes |
| `web/` | Next.js 13 (App Router) | Site vitrine et pages publiques |

---

## 1. Comptes et authentification

### Inscription et connexion
- Création de compte par email / mot de passe, avec acceptation des conditions d'utilisation.
- Connexion par email / mot de passe, jetons **JWT** (access token + refresh token).
- Rafraîchissement automatique et transparent du token expiré côté application
  (`app/lib/config/token_refresh_interceptor.dart`) : la requête est rejouée sans que
  l'utilisateur s'en aperçoive, et l'échec du refresh déclenche une déconnexion propre.

### Authentification tierce (SSO)
- **Connexion avec Google** et **Connexion avec Apple**, en inscription comme en connexion.
- Gestion des emails privés Apple (`@privaterelay.appleid.com`).
- Liaison de plusieurs fournisseurs SSO à un même compte (table `user_sso_links`).

### Vérification d'adresse email
- Envoi d'un code de vérification à l'inscription, avec possibilité de renvoi.
- Un compte non vérifié reste identifiable via le champ `email_verified`.

### Mot de passe
- Réinitialisation par lien envoyé par email (mot de passe oublié).
- Changement de mot de passe en deux temps : demande d'un code à 6 chiffres,
  puis validation du code avec le nouveau mot de passe. Le code a une durée de validité limitée.

### Suppression de compte
Procédure en plusieurs étapes, conforme aux exigences des stores :
- Demande de suppression avec motif optionnel.
- Confirmation par code envoyé par email.
- **Annulation possible** tant que le délai n'est pas écoulé.
- Consultation à tout moment du statut de la demande depuis l'application.

### Premier lancement et profil
- Écran d'accueil (`welcome_screen.dart`) avec **choix de la langue** avant même la connexion,
  et accès aux pages légales.
- Écran de profil (`profil_screen.dart`) : modification des informations du compte (`PUT /auth/me`),
  choix de la devise, sécurité (changement de mot de passe), gestion des suggestions,
  préférences email, envoi de retour, suivi de la suppression de compte, déconnexion.

### Protection contre les robots
`api/src/Services/RateLimiter.php` applique une limitation à l'inscription :
- Limite par adresse IP.
- Limite par adresse email.
- Limite globale d'inscriptions.
- Détection d'IP suspecte et blocage, avec en-tête `Retry-After`.

---

## 2. Listes de courses

- Création, modification et suppression de listes.
- **Suppression douce** (`deleted_at`) avec **restauration** d'une liste supprimée.
- **Duplication** d'une liste existante.
- Statistiques par liste : nombre d'articles, articles achetés, montant total.
- **Filtres rapides** sur l'écran des listes : toutes, actives, terminées, partagées
  (`widgets/shopping/list_filter_chips.dart`).
- Tirer pour rafraîchir, suppression par glissement.

### Articles d'une liste
- Ajout, modification, suppression et **restauration** d'un article.
- Champs : nom du produit, quantité, prix, catégorie, code-barres, nom du magasin.
- Marquage **acheté / non acheté** par article, avec horodatage (`purchased_at`).
- **Tout marquer comme acheté** en une action.
- **Vider les articles achetés** en une action.
- Détection des doublons à l'ajout : l'API propose les articles similaires existants
  et permet soit de **fusionner** avec l'article existant, soit de **forcer** l'ajout.
- **Filtres et tri** des articles (`widgets/list_detail/item_filters_bar.dart`) :
  par magasin, achetés seulement / non achetés seulement, ordre croissant ou décroissant.

---

## 3. Partage et collaboration

- Génération d'un **lien de partage** pour une liste, envoyé via la feuille de partage
  native du téléphone (`share_plus`) : SMS, WhatsApp, email, etc.
- Invitation avec trois niveaux de permission : **lecture seule**, **modification**, **administration**
  (`SharePermission { readOnly, edit, admin }`).
- Cycle de vie d'une invitation : `pending`, `accepted`, `declined`, `expired`.
- Acceptation ou refus d'une invitation depuis l'application ou via un lien web.
- Consultation des listes partagées avec soi, et des personnes avec qui on partage.
- Modification de la permission d'un participant, **révocation** d'un partage.
- **Quitter** une liste partagée de sa propre initiative.
- Révocation de **tous** les liens de partage d'une liste d'un coup.
- Statistiques de partage par liste.

### Liens profonds (deep links)
Ouverture directe d'une invitation dans l'application :
- Schéma personnalisé : `epilist://share/{token}`
- Universal Links / App Links : `https://epilist.app/share/{token}`

Une page web publique prend le relais si l'application n'est pas installée.

---

## 4. Messagerie par liste

Chaque liste partagée dispose de sa propre discussion (`app/lib/screens/chat_screen.dart`) :
- Envoi et consultation des messages.
- **Compteur de messages non lus** par liste.
- Marquage d'un message comme lu (table `message_read_status`).
- Suppression d'un message.

---

## 5. Suggestions intelligentes

`api/src/Services/SmartSuggestionService.php` analyse l'historique d'achat de l'utilisateur pour proposer :

| Fonction | Description |
|---|---|
| Suggestions personnalisées | Produits susceptibles d'être rachetés, à partir des habitudes |
| Suggestion de quantité | Quantité habituellement achetée pour un produit donné |
| Suggestion de prix | Prix habituellement payé pour un produit donné |
| Produits tendance | Produits les plus ajoutés sur la période |
| Associations de produits | Produits fréquemment achetés ensemble (`product_associations`) |

- L'utilisateur peut donner un **retour** sur une suggestion (accepté / rejeté), ce qui affine le modèle.
- Recalcul des motifs d'achat à la demande (`user_purchase_patterns`).
- Statistiques sur la pertinence des suggestions.

### Historique de saisie
Indépendamment des suggestions, l'application mémorise les produits déjà saisis
(`product_suggestions`) pour l'auto-complétion : recherche, produits populaires,
statistiques, et purge manuelle de l'historique. Un écran de gestion
(`suggestion_management_widget.dart`, accessible depuis le profil) permet de supprimer
une suggestion précise ou de tout effacer.

---

## 6. Scanner de codes-barres

- Scan via la caméra (`mobile_scanner`), écran dédié `barcode_scanner_screen.dart`.
- Recherche du produit scanné dans la base publique **Open Food Facts**
  (`https://world.openfoodfacts.org/api/v2`).
- Le code-barres est conservé sur l'article (`list_items.barcode`), ce qui permet
  de retrouver le produit lors d'un achat ultérieur.

---

## 7. Saisie vocale

- Ajout d'articles à la voix (`speech_to_text`), avec retour visuel animé pendant l'écoute.
- Français par défaut (`fr_FR`), langue paramétrable.
- Gestion explicite de la permission micro, avec message d'explication traduit.

---

## 8. Budgets

- Création de budgets sur quatre périodicités : **hebdomadaire**, **mensuelle**, **annuelle**, **personnalisée**.
- Création rapide d'un budget (valeurs pré-remplies).
- Tableau de bord des budgets : montant alloué, dépensé, restant, pourcentage consommé.
- Écran de détail par budget.
- **Alertes de dépassement** : notification lorsqu'un seuil est franchi ou le budget dépassé.
- Alerte à l'approche de la **fin d'un budget**.
- Rappels programmés localement sur l'appareil, en plus des notifications serveur.

---

## 9. Factures et reçus

Chaque liste peut recevoir des reçus d'achat (`list_receipts`) :
- Enregistrement d'un reçu : magasin, montant, date, articles.
- Consultation, modification et suppression.
- Regroupement **par magasin**.
- Statistiques de dépenses par liste.
- **Export PDF** et **export CSV** (`api/src/Services/ReceiptExportService.php`).

---

## 10. Analytiques de dépenses

Tableau de bord complet (`app/lib/screens/analytics_screen.dart`) alimenté par 11 endpoints :

| Vue | Description |
|---|---|
| Tableau de bord | Synthèse générale |
| Historique | Dépenses par jour, semaine, mois, année |
| Tendances | Évolution des dépenses dans le temps |
| Comparaison | Comparaison entre deux périodes |
| Par catégorie | Répartition des dépenses par catégorie |
| Par magasin | Répartition des dépenses par enseigne |
| Top produits | Produits les plus achetés |
| Qualité des données | Signale les données incomplètes qui faussent les statistiques |

---

## 11. Catégories

- Catégories personnalisables par utilisateur : création, modification, suppression.
- **Réordonnancement** manuel.
- Initialisation d'un jeu de **12 catégories par défaut** :
  Fruits & Légumes, Viandes & Poissons, Produits laitiers, Boulangerie, Boissons,
  Snacks & Sucreries, Hygiène & Beauté, Entretien ménager, Bébé & Enfants, Animaux,
  Santé & Pharmacie, Autre.

---

## 12. Devises

- **25 devises** disponibles, dont 11 marquées comme populaires
  (CAD, USD, EUR, GBP, JPY, AUD, CHF, CNY, HKD, SGD, ZAR).
- Bonne couverture africaine : XOF, XAF, NGN, MAD, EGP, KES, GHS, ETB…
- Choix de la devise par utilisateur, appliqué à l'ensemble de l'application.
- Formatage des montants côté serveur selon la devise choisie.

---

## 13. Notifications push

Notifications **Firebase Cloud Messaging**, avec 5 canaux Android distincts :
`general`, `budget_alerts`, `list_updates`, `messages`, `reminders`.

### Notifications programmées (`api/public/cron.php`)

| Déclencheur | Moment |
|---|---|
| Résumé quotidien des budgets | tous les jours à 9 h |
| Alertes de budget dépassé | toutes les heures, de 9 h à 21 h |
| Budgets arrivant à expiration | tous les jours à 18 h |
| Rappel aux utilisateurs inactifs | mardi à 10 h |
| Rappel hebdomadaire (aucune liste créée) | hebdomadaire |
| Liste terminée | à la complétion |
| Rappels basés sur l'analyse d'habitudes | selon le profil de l'utilisateur |

Le cron gère aussi la maintenance : nettoyage des appareils inactifs, des fichiers
de cache d'alertes et des fichiers de verrouillage (pour éviter les doubles envois).

### Gestion des appareils
- Enregistrement de l'appareil et de son jeton push.
- Liste des appareils d'un utilisateur, désactivation d'un appareil.
- Préférences de notification par appareil.
- Outils de diagnostic : analyse des jetons, envoi de notification de test.

### Analyse d'habitudes
`api/src/Services/UserHabitAnalysisService.php` calcule le rythme d'utilisation de chaque
utilisateur pour envoyer des rappels au bon moment plutôt qu'à heure fixe.

---

## 14. Emails transactionnels

Envoi via **Brevo**, modèles dans `api/src/Services/EmailTemplates.php` :

| Email | Déclencheur |
|---|---|
| Vérification d'adresse | inscription |
| Bienvenue | après vérification |
| Demande de changement de mot de passe | envoi du code |
| Mot de passe modifié | confirmation |
| Liste partagée avec vous | réception d'une invitation |
| Liste terminée | complétion d'une liste partagée |

- **Emails bilingues** : le contenu est envoyé dans la langue de l'utilisateur (fr / en).

### Préférences email
L'utilisateur contrôle finement ce qu'il reçoit, par type :
`email_verification`, `password_change_request`, `password_changed`,
`list_shared_with_me`, `list_completed`, `budget_alert`, `budget_summary`, `tips_and_tricks`.

- Réinitialisation des préférences aux valeurs par défaut.
- **Désabonnement marketing** en un clic, via un lien signé par jeton
  (`/unsubscribe/{token}`), sans nécessiter de connexion — page dédiée sur le site web.

### Campagnes
- Envoi d'une campagne d'annonce de nouvelle version.
- Email de test avant envoi réel, prévisualisation dans le navigateur.
- Statistiques de campagne.

---

## 15. Mode hors ligne

Six services dédiés (`app/lib/services/`) :

| Service | Rôle |
|---|---|
| `connectivity_service` | Détection de l'état du réseau |
| `offline_storage_service` | Stockage local persistant (SharedPreferences) |
| `offline_cache_service` | Cache des listes, budgets et reçus (Hive) |
| `offline_queue_service` | File d'attente des actions faites hors ligne |
| `offline_sync_service` | Synchronisation à la reconnexion |
| `conflict_resolution_service` | Résolution des conflits d'édition concurrente |

L'utilisateur peut consulter et modifier ses listes sans réseau ; les modifications
sont rejouées automatiquement au retour de la connexion. Un bandeau signale l'état
hors ligne (`widgets/connectivity/`).

---

## 16. Internationalisation

- **Français** et **anglais**, 1308 clés de traduction (`app/lib/l10n/app_fr.arb`).
- Sélecteur de langue dans l'application, préférence enregistrée sur le compte
  (`users.language`) et donc appliquée aussi aux emails et notifications serveur.

---

## 17. Contact et support

- Formulaire de retour depuis l'application, avec types de retour prédéfinis.
- Envoi possible **sans être connecté** (retour anonyme).

---

## 18. Pages légales et conformité

Dans l'application comme sur le site web :
- Politique de confidentialité.
- Conditions d'utilisation.
- Écran « À propos » avec la version de l'application (`package_info_plus`) et liens externes.

---

## 19. Site web (`web/`)

Site vitrine Next.js, en français, optimisé pour le référencement :

| Page | Contenu |
|---|---|
| `/` | Accueil |
| `/fonctionnalites` | Présentation des fonctionnalités |
| `/telecharger` | Liens App Store et Google Play |
| `/comparaison-applications-courses` | Comparatif avec les applications concurrentes |
| `/aide` | Aide et questions fréquentes |
| `/contact` | Formulaire de contact |
| `/a-propos` | À propos |
| `/politique-confidentialite` | Politique de confidentialité |
| `/conditions-utilisation` | Conditions d'utilisation |
| `/share/...` | Page publique d'invitation au partage |
| `/unsubscribe/...` | Désabonnement des emails marketing |

- `sitemap.ts` et `robots.ts` générés automatiquement, données structurées Schema.org.
- Redirections 301 des anciens slugs anglais vers les slugs français (`middleware.ts`).
- Suivi analytique : Google Analytics, Meta Pixel, Hotjar.
- Thème clair / sombre.

---

## Récapitulatif technique

| Élément | Valeur |
|---|---|
| Routes API | 139 |
| Écrans Flutter | 23 |
| Services Flutter | 28 |
| BLoCs | 15 |
| Modèles de données | 16 côté API |
| Langues | 2 (fr, en) |
| Devises | 25 |
| Catégories par défaut | 12 |
| Canaux de notification | 5 |
| Types d'emails | 6 transactionnels + campagnes |
