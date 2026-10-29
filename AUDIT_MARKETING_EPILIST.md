# Audit marketing EpiList — état des lieux factuel

**Date :** 29 octobre 2026
**Méthode :** lecture seule du dépôt. Aucune modification, aucun accès à la production.
**Commit audité :** `3de47fd` (branche `master`)
**Convention :** chaque affirmation porte sa preuve `fichier:ligne` et un verdict
**CONFIRMÉ (code)** / **PARTIEL** / **ABSENT**. Quand le code ne permet pas de
trancher, c'est écrit — rien n'est deviné.

> **Avertissement de portée.** Je peux prouver ce qui est *écrit* dans le code.
> Je ne peux pas prouver ce qui est *vrai en production* : le contenu des tables,
> la région d'un bucket, ou le comportement d'un appareil réel. Ces points sont
> marqués « non vérifiable depuis le code ».

---

## 1. Affirmations du site (`web/`)

### 1.1 Tous les chiffres affichés

Aucun chiffre marketing du site n'est calculé : **ils sont tous en dur** dans
`web/lib/translations.ts`. Le site ne fait aucun appel à l'API pour des
statistiques — les seuls `fetch` sont le formulaire de contact
(`web/components/ContactContent.tsx:83`) et l'espace admin
(`web/lib/admin-api.ts:91`).

| Chiffre | FR | EN | Rendu par | En dur / API | Verdict |
|---|---|---|---|---|---|
| « plus de 50 000 familles » | `translations.ts:183` | `:873` | `BenefitsSection.tsx:30` | **en dur** | **ABSENT** du code produit |
| « plus de 50 000 familles » (CTA) | `:250` | `:940` | `CTASection.tsx:30` | **en dur** | **ABSENT** |
| « 70 % de temps économisé » | `:186`, `:188` | `:876`, `:878` | `BenefitsSection.tsx:45` | **en dur** | **ABSENT** |
| « 100 % de synchronisation » | `:193` | `:883` | `BenefitsSection.tsx:45` | **en dur** | slogan, non mesurable |
| « 30 % d'économies moyennes » | `:198` | `:888` | `BenefitsSection.tsx:45` | **en dur** | **ABSENT** |
| « ∞ insights précieux » | `:203` | — | `BenefitsSection.tsx:45` | **en dur** | slogan |
| « 100 % sécurisé » | `:208` | `:898` | `BenefitsSection.tsx:45` | **en dur** | slogan |
| « 24/7 disponible » | `:213` | — | `BenefitsSection.tsx:45` | **en dur** | slogan |
| Note **4.9** (JSON-LD) | `lib/schema.ts:41` | idem | `app/layout.tsx:167-169` | **en dur** | **ABSENT** |
| **1247** avis (JSON-LD) | `lib/schema.ts:42` | idem | `app/layout.tsx:167-169` | **en dur** | **ABSENT** |
| « 150+ devises » | `:61`, `:632` | `:751` | `FeaturesContent.tsx:230` | **en dur** | **PARTIEL** (voir 1.3) |
| « 20+ fonctionnalités » | — | — | `FeaturesContent.tsx:217` | **en dur** | **PARTIEL** : 20 clés `featureNTitle` existent (`:36`→`:94`) |
| « 2 langues » | — | — | `FeaturesContent.tsx:224` | **en dur** | **CONFIRMÉ** : `app_fr.arb` / `app_en.arb`, 3101 clés chacun |
| « 2024, année de création » | `:625` | `:1314` | `AboutContent.tsx:90` | **en dur** | non vérifiable depuis le code |
| « 100 % gratuite, sans publicité » | `:626` | `:1315` | `AboutContent.tsx:90` | **en dur** | **CONFIRMÉ** (voir §6) |

**Chiffres définis mais jamais rendus** (clés mortes — ils n'apparaissent sur
aucune page, donc rien à retirer publiquement, mais rien ne les justifie non plus) :

- « Plus de 2000 avis positifs » — `:224` (FR), `:914` (EN) — aucun composant ne l'appelle
- « 200+ utilisateurs actifs » — `:225` (FR) — aucun composant ne l'appelle
- « 70 % de temps économisé » (variante courte) — `:21` (FR), `:711` (EN) — non rendue

### 1.2 Témoignages

Cinq témoignages sont écrits dans `translations.ts` ; **trois seulement sont
affichés** (`TestimonialsSection.tsx:11` → `const testimonials = [1, 2, 3]`).

| # | Nom | Rôle | FR | EN | Verdict |
|---|---|---|---|---|---|
| 1 | Marie Dubois | Mère de famille, Moncton | `:228-230` | `:918-920` | **placeholder** |
| 2 | Pierre Martin | Père de 3 enfants, Fredericton | `:232-234` | `:922-924` | **placeholder** |
| 3 | Sophie Laurent | Étudiante, Saint John | `:236-238` | `:926-928` | **placeholder** |
| 4 | Jean-Marc Petit | Retraité, Bathurst | `:240-242` | `:930-932` | non affiché |
| 5 | Amélie Chen | Professeure, Dieppe | `:244-246` | `:934-936` | non affiché |

**Pourquoi « placeholder » et non « réel » :** les cinq noms sont des noms
français génériques répartis sur cinq villes du Nouveau-Brunswick, un par
segment démographique (mère, père, étudiante, retraité, professeure). Aucun n'a
de photo, de lien, de date, d'identifiant de source, ni de trace en base. Le
témoignage 1 affirme « économiser 200 $ par mois », chiffre qu'aucune donnée du
dépôt ne soutient. **Verdict : ABSENT (aucune preuve de personnes réelles).**

### 1.3 Le cas « 150+ devises »

Les devises viennent d'une table `currencies` lue par `Currency::getActiveOrdered()`
(`api/src/Controllers/CurrencyController.php:26`). La table est **créée** dans
`api/migrations/bd_prod.sql:70` mais **le dépôt ne contient aucun `INSERT`** qui
la peuple : le nombre réel est en production. Le code ne cite en dur que 8
devises « populaires » (`api/src/Models/Currency.php:304`).
**Verdict : PARTIEL — non vérifiable depuis le code.** Requête de contrôle en §7.

---

## 2. Fonctionnalités annoncées vs réelles

### 2.1 Tableau de correspondance

| Fonction annoncée | App Flutter | API | FR/EN | Verdict |
|---|---|---|---|---|
| Partage de liste | `screens/share_invitation_screen.dart` | `index.php:287-297` | oui | **CONFIRMÉ** |
| « Synchro temps réel » | — | — | — | **PARTIEL** (§2.2) |
| **Scanner de reçus (OCR)** | `services/receipt_ocr_service.dart:7`, `utils/receipt_scan_flow.dart:83-91` | `index.php:331` | oui | **CONFIRMÉ** |
| Scanner de code-barres | `screens/barcode_scanner_screen.dart`, appelé `widgets/list_detail/add_item_dialog.dart:757` | — | oui | **CONFIRMÉ** (distinct du reçu) |
| Comparaison de prix | `screens/store_comparison_screen.dart` | `index.php:334` | oui | **CONFIRMÉ** |
| Historique des prix payés | `services/price_service.dart` | `index.php:333` | oui | **CONFIRMÉ** |
| Budgets | `screens/budget_screen.dart` | `index.php:355-363` | oui | **CONFIRMÉ** |
| Alertes de budget | `services/budget_notification_service.dart` | `index.php:358`, `Services/BudgetAlertService.php` | oui | **CONFIRMÉ** |
| Alertes de prix | `screens/price_alerts_screen.dart` | `index.php:248-252` | oui | **CONFIRMÉ** |
| Inventaire domestique | `screens/inventory_screen.dart:89` | `index.php:439-442` | oui | **CONFIRMÉ** |
| Mode en magasin | `screens/shopping_mode_screen.dart` | — (local) | oui | **CONFIRMÉ** |
| Tri par rayon | `screens/store_aisle_order_screen.dart` | `index.php:473-474` | oui | **CONFIRMÉ** |
| Planification des repas | `screens/meal_planner_screen.dart` | `index.php:454-461` | oui | **CONFIRMÉ** |
| Foyer (household) | `screens/create_space_screen.dart:88` | `index.php:212-224` | oui | **CONFIRMÉ** |
| Saisie vocale → article | `services/voice_recognition_service.dart:71`, `voice_list_parser.dart` | — (local) | oui | **CONFIRMÉ** |
| Mode hors ligne | `services/offline_queue_service.dart:125`, `offline_sync_service.dart` | — | oui | **CONFIRMÉ** |
| Listes récurrentes / modèles | `screens/recurring_lists_screen.dart` | `index.php:446-451` | oui | **CONFIRMÉ** |

### 2.2 « Synchronisation en temps réel » — le point le plus fragile

Annoncé en `translations.ts:40` (FR) / `:730` (EN) et `:70` (« Notifications
temps réel »), rendu sur la page d'accueil (`FeaturesSection.tsx:26`).

**Aucun websocket, aucun Pusher, aucun canal persistant** — recherche
`websocket|socket.io|pusher|ably|centrifugo` dans `app/lib`, `api/src`,
`api/composer.json`, `app/pubspec.yaml` : **aucun résultat**.

Ce qui existe réellement :

1. **Push FCM** (`app/pubspec.yaml:61`, `api/src/Services/NotificationService.php:1150`)
   déclenché à l'ajout d'un article (`api/src/Controllers/ListItemController.php:567`),
   à l'achat (`:799`) et à la complétion (`:1202`).
2. **Un verrou de 3 minutes par liste** : `NotificationService.php:1156-1159` —
   si une seconde modification survient dans les 180 secondes, **aucune
   notification n'est envoyée**. Deux personnes qui font les courses ensemble ne
   reçoivent donc qu'une alerte sur trois.
3. **Le chat est en *polling***, pas en temps réel : `app/lib/blocs/chat/chat_bloc.dart:262`
   (`Timer.periodic`).

**Verdict : PARTIEL.** « Temps réel » est inexact : c'est une notification
poussée, plafonnée à une toutes les 3 minutes par liste, plus un rafraîchissement.

**Défaut bilingue confirmé :** le corps du push est écrit **en français en dur**
dans le contrôleur (`ListItemController.php:567` : `"\"{$item->product_name}\" a été
ajouté à la liste"`, `:799`, `:1202`) et traverse `sendListUpdateNotification`
**sans traduction** (`NotificationService.php:1183` passe `$body` tel quel). Un
membre anglophone reçoit un push en français. *(Les e-mails, eux, sont bien
bilingues : `api/src/Services/EmailTemplates.php:14-19`.)*

### 2.3 Annoncé sur le site, inexact dans le code

| Affirmation | Où | Réalité |
|---|---|---|
| « synchronisation temps réel » | `translations.ts:40`, `:55`, `:70` | §2.2 — push plafonné, pas de temps réel |
| « Inventaire maison — **trois états simples** : à la maison, bientôt terminé, terminé » | `translations.ts:602` (FR), `:1291` (EN), rendu `FeaturesSection.tsx:31` | L'app range désormais par **zone** (garde-manger / frigo / congélateur / entretien) : `screens/inventory_screen.dart:89`, colonne `zone` ajoutée par `api/migrations/014_zones_de_rangement.sql:35`. **Texte périmé.** |
| « Chiffrement de niveau bancaire (AES-256) » | `translations.ts:371` | **non vérifiable depuis le code** — aucun chiffrement applicatif trouvé ; il s'agit vraisemblablement de TLS + chiffrement au repos de l'hébergeur |
| « Serveurs sécurisés au Canada » / « Vos données restent au Canada » | `:373`, `:341` | **non vérifiable depuis le code.** Les images (avatars, **photos de reçus**) partent sur **Google Cloud Storage** (`api/src/Services/ImageStorageService.php:25`, `:141`), bucket `epilist-storage` par défaut (`:46`) — **la région du bucket n'est pas fixée dans le code** |
| « Audits de sécurité réguliers » | `:374` | **ABSENT** — aucune trace dans le dépôt |
| « avec conversion automatique » (devises) | `:61` | **PARTIEL** — aucun service de taux de change trouvé ; `CurrencyController` formate, il ne convertit pas |

### 2.4 Dans le code, absent du site

Fonctions réelles et atteignables que le site ne met pas en avant :

| Fonction | Preuve app | Preuve API |
|---|---|---|
| **Demandes d'achat** (workflow soumission → approbation → achat) | `screens/purchase_requests_screen.dart`, atteignable `screens/more_screen.dart:295` | `index.php:231-238` |
| **Fournisseurs** | `screens/suppliers_screen.dart`, `more_screen.dart:301` | `index.php:227-230` |
| **Espaces restaurant / organisation** | `screens/create_space_screen.dart:95`, `:102` | `migrations/add_spaces.sql:14` (enum `personal,household,restaurant,organization`) |
| Prix communautaires | `services/price_service.dart` | `index.php:240-242` |
| Assistant avant-courses / économies | `screens/pre_shopping_screen.dart` | `index.php:244-245` |
| Prédictions d'achat | `screens/predictions_screen.dart` | `index.php:437-438` |
| Double authentification | `screens/two_factor_screen.dart` | `index.php:206-207` |
| Export PDF / CSV des reçus | `screens/all_receipts_screen.dart` | `index.php:327-328` |
| Messagerie de liste | `screens/chat_screen.dart` | `index.php:492-500` |

> **Signal marketing.** Les trois premières lignes forment un produit **B2B**
> (restaurant, organisation, fournisseurs, demandes d'achat) entièrement
> construit et invisible sur un site qui ne parle que de familles.

---

## 3. Onboarding

### 3.1 Le parcours exact après installation

1. **`WelcomeScreen`** — `app/lib/screens/welcome_screen.dart`. Logo, trois
   arguments (`:72` partage, `:77` tri par rayon, `:82` budget), **un seul
   bouton** « Commencer » (`:86-89`) et trois liens de bas de page (à propos,
   confidentialité, conditions — `:233-237`).
2. Ce bouton mène à **`LoginScreen`** (`_navigateToLogin`, `:87`) — pas à
   l'inscription.
3. **`SignupScreen`** — atteint depuis l'écran de connexion. **Cinq champs** :
   prénom, nom, courriel, mot de passe, confirmation
   (`screens/signup_screen.dart:366`, `:381`, `:400`, `:419`, `:441`).
4. **Vérification du courriel obligatoire** : `main.dart:702-710` renvoie
   `EmailVerificationScreen` tant que l'état est `EmailConfirmationRequired`.
5. **`MainShell`** (`main.dart:713-723`) — le tableau de bord.
6. La première liste se crée depuis « + Créer une liste »
   (`screens/home_screen.dart:610`).

**Nombre de gestes avant la première liste** (chemin le plus court, courriel
reçu immédiatement) : **environ 14** — 1 (Commencer) + 1 (lien inscription) + 5
(champs) + 1 (valider) + 1 (ouvrir le courriel) + 1 (saisir le code) + 1
(valider) + 1 (+ Créer une liste) + 1 (nommer) + 1 (valider).

### 3.2 Réponses directes

- **Un écran d'onboarding / tutoriel ?** **ABSENT.** Aucun fichier
  `onboard*`, `tutorial*` ou `intro*` dans `app/lib/screens/`.
- **L'onboarding pousse-t-il à inviter quelqu'un ?** **ABSENT.** Aucune
  invitation n'est proposée avant, pendant ou juste après l'inscription.
  `welcome_screen.dart` mentionne le partage comme argument (`:72`) mais
  n'offre aucune action.
- **Un compte est-il obligatoire avant de créer une liste ?** **OUI,
  CONFIRMÉ.** `main.dart:727-733` : tout état `Unauthenticated` renvoie
  `WelcomeScreen`. Recherche `guest|anonymous|skip login|continuer sans compte`
  dans `welcome_screen.dart`, `login_screen.dart`, `main.dart` : **aucun
  résultat.** Il n'existe aucun mode invité. Le courriel doit en plus être
  vérifié.

---

## 4. Partage et invitation (boucle virale)

### 4.1 Le parcours de bout en bout

1. Le partageur crée un lien : `index.php:287` → `SharedListController::createShareLink`.
2. L'invité ouvre `https://epilist.app/share/{token}`.
3. La page `web/app/share/[token]/page.tsx` :
   - **sur ordinateur** → redirige vers l'**App Store iOS** (`:18-20`), quelle
     que soit la plateforme — un visiteur Windows reçoit un lien iOS ;
   - **sur mobile** → tente `epilist://share/{token}` (`:23-24`), puis après
     **3 secondes** bascule vers le store (`:26-31`).
4. L'invité installe l'application.
5. **Il arrive sur `WelcomeScreen`. Pas dans la liste.**

### 4.2 Deferred deep link : ABSENT

**Le jeton n'est transmis nulle part au store.** Les URL de `page.tsx:29-30`
sont les URL nues des stores, sans paramètre.

Côté application, `_pendingShareToken` (`app/lib/services/deep_link_handler.dart:22`)
est une **variable statique en mémoire** : elle ne survit qu'au sein d'un
processus déjà lancé (cas « lien cliqué, app installée, utilisateur non
connecté » → `processPendingTokenAfterLogin`, `main.dart:715`). Elle ne survit
**pas** à une installation.

Aucun outil d'attribution : recherche `branch|firebase_dynamic_links|adjust|appsflyer|install_referrer`
dans `app/pubspec.yaml` et `web/package.json` → **aucun résultat**.

**Verdict : ABSENT.** Un invité qui n'a pas l'app installée est perdu : il
télécharge, ouvre, et doit se créer un compte sans savoir pourquoi — puis
redemander le lien.

### 4.3 Fichiers de vérification des liens

| Fichier | Dans le dépôt | En production |
|---|---|---|
| `apple-app-site-association` | `web/public/.well-known/apple-app-site-association` | **200 OK** |
| `assetlinks.json` | **ABSENT** | **404** |

L'AASA est correct : `appIDs: ["79F8TZGAPL.com.m2atech.epilist"]`, composant
`/share/*`.

**Le trou :** `app/android/app/src/main/AndroidManifest.xml:105` déclare
`android:autoVerify="true"` pour `https://epilist.app` (`:109`). **Sans
`assetlinks.json`, la vérification Android échoue toujours** : un lien
`https://epilist.app/share/{token}` **n'ouvre jamais l'application sur Android**,
il ouvre le navigateur. Seul le schéma `epilist://` (`:101`) fonctionne — et il
est **bloqué par les navigateurs intégrés** de Messenger, Instagram, Gmail et
WhatsApp, c'est-à-dire l'essentiel des canaux de partage.

> `app/android/` est exclu du dépôt (`.gitignore:49`) : ces lignes ont été lues
> sur la machine, pas dans git.

---

## 5. Analytics et tracking

### 5.1 Ce qui est intégré

**Dans l'application mobile : RIEN.**

- `app/pubspec.yaml` ne contient que `firebase_core:^3.10.0` (`:60`) et
  `firebase_messaging:^15.1.5` (`:61`). **Pas de `firebase_analytics`.**
- Recherche `firebase_analytics|FirebaseAnalytics|logEvent` dans tout
  `app/lib` : **aucun résultat**.
- Recherche `track(|trackEvent|sendEvent|analytics.log` : **aucun résultat**.
- **Attention au faux ami :** `app/lib/services/analytics_service.dart` n'est
  **pas** un outil de mesure produit — c'est le client des points d'entrée
  `/analytics/*` de l'API, qui renvoient les **dépenses** de l'utilisateur
  (`:31` `getDashboard`). Aucun événement n'en sort.

**Sur le site :** trois outils, chargés en production seulement et jamais sous
`/admin` (`components/TrackingGate.tsx:14`).

| Outil | Composant | Identifiant |
|---|---|---|
| Google Analytics 4 | `components/GoogleAnalytics.tsx:91` | `NEXT_PUBLIC_GA_ID` (`lib/gtag.ts:1`) |
| Meta Pixel | `components/FacebookPixel.tsx:47` | `FACEBOOK_PIXEL_ID` |
| Hotjar | `components/Hotjar.tsx:59` | `HOTJAR_ID` |

### 5.2 Événements réellement envoyés

**Application mobile : aucun.** (liste vide, voir 5.1)

**Site — cinq événements**, tous dans `web/lib/gtag.ts` :

| Nom exact | Ligne |
|---|---|
| `page_view` | `:11` (via `pageview`) |
| `app_download_click` | `:65` |
| `demo_click` | `:88` |
| `feature_interaction` | `:104` |
| `scroll_depth` | `:117` |
| `section_view` | `:127` |

### 5.3 Comparaison avec la liste demandée

| Événement demandé | État | Note |
|---|---|---|
| `landing_view` | **PARTIEL** | couvert par `page_view` (`gtag.ts:11`), nom différent |
| `store_click_ios` | **PARTIEL** | `app_download_click` porte `platform` en paramètre (`gtag.ts:63-65`) — pas d'événement distinct |
| `store_click_android` | **PARTIEL** | idem |
| `app_first_open` | **ABSENT** | |
| `account_created` | **ABSENT** | |
| `list_created` | **ABSENT** | |
| `item_added` | **ABSENT** | |
| `list_shared` | **ABSENT** | |
| `invite_sent` | **ABSENT** | |
| `invite_accepted` | **ABSENT** | |
| `budget_created` | **ABSENT** | |
| `receipt_scan_started` | **ABSENT** | |
| `receipt_confirmed` | **ABSENT** | |
| `app_opened_d7` | **ABSENT** | |
| `app_opened_d30` | **ABSENT** | |
| `feedback_submitted` | **ABSENT** | |

**13 des 16 événements sont absents, et les 3 autres ne portent pas le bon nom.
Aucun événement in-app n'existe : l'entonnoir s'arrête net au clic sur le store.**

### 5.4 UTM, attribution, consentement

| Point | Verdict | Preuve |
|---|---|---|
| Lecture/propagation d'UTM | **ABSENT** | recherche `utm_source|utm_campaign|utm_medium` dans `web/` : aucun résultat |
| Attribution d'installation | **ABSENT** | voir §4.2 |
| Bannière de consentement cookies | **ABSENT** | aucun `CookieBanner`, `cookie-consent`, ni `gtag('consent'...)` dans `web/` |
| `TrackingGate` | ce n'est **pas** un consentement | `components/TrackingGate.tsx:14` — ne fait que masquer les traceurs sous `/admin` |
| ATT iOS | **ABSENT** | pas de `NSUserTrackingUsageDescription` dans `app/ios/Runner/Info.plist` |

> **Risque juridique.** GA, Meta Pixel et Hotjar se chargent **sans
> consentement préalable**, pour un public canadien (Loi 25 au Québec, LPRPDE).
> Hotjar enregistre les sessions. Aucune bannière n'existe. À traiter avant
> toute campagne payante, car une campagne amplifie l'exposition.

### 5.5 Des données sensibles partent-elles vers un tiers ?

- **Depuis l'application : NON.** Aucun SDK tiers de mesure ; les seuls
  destinataires sont l'API EpiList et Firebase Cloud Messaging (jeton push).
- **Depuis le site : pas de contenu de liste** — le site ne lit jamais les
  données d'un utilisateur connecté (aucun appel API hors contact/admin).
- **Nuance Hotjar :** il enregistre les sessions du site vitrine. Le seul
  formulaire exposé est celui de contact (`ContactContent.tsx:83`) — un message
  libre pouvant contenir des données personnelles est donc susceptible d'être
  rejoué dans Hotjar. **À vérifier dans la configuration Hotjar (hors code).**
- **Photos de reçus : vers Google Cloud Storage**, en **lecture publique** —
  `ImageStorageService.php:141` (`'predefinedAcl' => 'publicRead'`). Le fichier
  est donc accessible à quiconque connaît l'URL. Ce n'est pas un outil tiers
  d'analyse, mais c'est un stockage externe non mentionné dans la politique (§8).

---

## 6. Monétisation

**Verdict global : ABSENT. Aucune ligne de code liée à un paiement.**

Recherche de `in_app_purchase|revenuecat|purchases_flutter|stripe|paypal|subscription|premium|admob|google_mobile_ads|is_pro|plan_type|paywall`
dans `app/pubspec.yaml`, `app/lib`, `api/src`, `api/composer.json`,
`web/package.json` : **aucun résultat** (seuls des faux positifs
`StreamSubscription`). Pas de table `plans`, pas de colonne premium dans `users`
(`api/migrations/bd_prod.sql:317-343`), pas de quota.

L'affirmation « 100 % gratuite, sans publicité » (`translations.ts:626`) est donc
**CONFIRMÉE (code)** — c'est l'une des rares du site qui le soit.

### 6.1 Ce qui serait techniquement simple à placer derrière un mur premium

Classé par facilité d'implémentation, d'après la structure existante :

1. **Nombre de membres par espace** — `space_members` a déjà `role` et `status`
   (`migrations/add_spaces.sql:40-42`) ; un comptage à l'invitation
   (`index.php:221`) suffit.
2. **Historique des prix au-delà de N mois** — un seul point d'entrée
   (`index.php:333`), filtrage par date trivial.
3. **Export PDF / CSV des reçus** — deux routes isolées (`index.php:327-328`),
   aucune dépendance.
4. **Le module B2B entier** (fournisseurs + demandes d'achat, `index.php:227-238`) —
   déjà cloisonné par type d'espace ; c'est le candidat le plus naturel à une
   offre payante, et le seul qui ne retire rien aux familles.
5. **Nombre de budgets ou de listes actives** — `BudgetController::store`
   (`index.php:356`), `ShoppingListController::store` (`:279`) : un comptage.
6. **Analytics avancés** (tendances, comparaison de périodes, qualité des
   données) — `index.php:344-352`, déjà séparés du tableau de bord de base.

---

## 7. Mesure des utilisateurs — requêtes SQL

> Requêtes écrites pour le schéma réel (MySQL 8). **Aucune n'a été exécutée** —
> je n'ai pas touché à la production.
>
> **Pièges du schéma, à lire avant :**
> - La table de partage s'appelle **`shared_list`** au singulier
>   (`api/src/Models/SharedList.php:15`), pas `shared_lists`.
> - `users` n'a **aucune colonne d'activité** (`migrations/bd_prod.sql:317-343`).
>   Le seul indicateur est **`user_devices.last_active_at`**
>   (`bd_prod.sql:361`, indexée `:578`).
> - Toutes les tables principales sont en **suppression douce** (`deleted_at`) :
>   chaque requête doit le filtrer.

### a) Utilisateurs totaux et actifs 7 / 30 jours

```sql
SELECT
  (SELECT COUNT(*) FROM users WHERE deleted_at IS NULL)                        AS total_comptes,
  (SELECT COUNT(*) FROM users WHERE deleted_at IS NULL AND email_verified = 1) AS comptes_verifies,
  (SELECT COUNT(DISTINCT d.user_id)
     FROM user_devices d JOIN users u ON u.id = d.user_id
    WHERE u.deleted_at IS NULL AND d.deleted_at IS NULL
      AND d.last_active_at >= NOW() - INTERVAL 7 DAY)                          AS actifs_7j,
  (SELECT COUNT(DISTINCT d.user_id)
     FROM user_devices d JOIN users u ON u.id = d.user_id
    WHERE u.deleted_at IS NULL AND d.deleted_at IS NULL
      AND d.last_active_at >= NOW() - INTERVAL 30 DAY)                         AS actifs_30j;
```

**Limite importante.** `last_active_at` n'est écrit qu'à l'enregistrement de
l'appareil et au rafraîchissement du jeton push
(`api/src/Models/UserDevice.php:106`, `:115`, `:126`, `:145`). Côté application,
cela part après une connexion réussie — y compris une session restaurée au
démarrage (`app/lib/main.dart:650-659` sur l'état `AuthSuccess`). C'est donc une
bonne approximation de « dernière ouverture de l'app », **mais** elle rate :
l'utilisateur qui refuse les notifications, celui dont l'init FCM échoue, et
tout usage hors ligne. **Le chiffre sous-estime l'activité réelle.** Contrôle
croisé recommandé :

```sql
-- Activité déduite des écritures : plus fiable, mais ne voit que ceux qui AGISSENT
SELECT COUNT(DISTINCT user_id) AS auteurs_30j FROM (
  SELECT user_id             FROM shopping_lists WHERE deleted_at IS NULL AND updated_at >= NOW() - INTERVAL 30 DAY
  UNION SELECT l.user_id     FROM list_items i JOIN shopping_lists l ON l.id = i.list_id
                             WHERE i.deleted_at IS NULL AND i.updated_at >= NOW() - INTERVAL 30 DAY
  UNION SELECT l.user_id     FROM list_receipts r JOIN shopping_lists l ON l.id = r.list_id
                             WHERE r.deleted_at IS NULL AND r.created_at  >= NOW() - INTERVAL 30 DAY
) AS actifs;
```

### b) Inscriptions par mois depuis le lancement

```sql
SELECT DATE_FORMAT(created_at, '%Y-%m') AS mois,
       COUNT(*)                          AS inscriptions,
       SUM(email_verified = 1)           AS verifies,
       ROUND(100 * SUM(email_verified = 1) / COUNT(*), 1) AS pct_verifies
  FROM users
 WHERE deleted_at IS NULL
 GROUP BY mois
 ORDER BY mois;
```

### c) Répartition iOS / Android / web

```sql
SELECT d.platform, COUNT(DISTINCT d.user_id) AS utilisateurs
  FROM user_devices d JOIN users u ON u.id = d.user_id
 WHERE u.deleted_at IS NULL AND d.deleted_at IS NULL
 GROUP BY d.platform;
```

**`platform` est un `ENUM('android','ios')`** (`bd_prod.sql:355`) : **« web »
n'existe pas** et ne peut pas apparaître. Un utilisateur n'ayant jamais
enregistré d'appareil (notifications refusées) est absent du total — à mesurer :

```sql
SELECT COUNT(*) AS sans_appareil_connu
  FROM users u
 WHERE u.deleted_at IS NULL
   AND NOT EXISTS (SELECT 1 FROM user_devices d WHERE d.user_id = u.id AND d.deleted_at IS NULL);
```

### d) Activation : 1 liste, 5 articles, 1 partage

```sql
WITH base AS (SELECT id FROM users WHERE deleted_at IS NULL)
SELECT
  (SELECT COUNT(*) FROM base) AS total,
  ROUND(100 * (SELECT COUNT(DISTINCT l.user_id) FROM shopping_lists l
                WHERE l.deleted_at IS NULL AND l.user_id IN (SELECT id FROM base))
            / (SELECT COUNT(*) FROM base), 1) AS pct_1_liste,
  ROUND(100 * (SELECT COUNT(*) FROM (
                 SELECT l.user_id FROM list_items i
                   JOIN shopping_lists l ON l.id = i.list_id
                  WHERE i.deleted_at IS NULL AND l.deleted_at IS NULL
                    AND l.user_id IN (SELECT id FROM base)
                  GROUP BY l.user_id HAVING COUNT(*) >= 5) AS t)
            / (SELECT COUNT(*) FROM base), 1) AS pct_5_articles,
  ROUND(100 * (SELECT COUNT(DISTINCT s.owner_id) FROM shared_list s
                WHERE s.deleted_at IS NULL AND s.owner_id IN (SELECT id FROM base))
            / (SELECT COUNT(*) FROM base), 1) AS pct_a_partage,
  ROUND(100 * (SELECT COUNT(DISTINCT s.owner_id) FROM shared_list s
                WHERE s.deleted_at IS NULL AND s.status = 'accepted'
                  AND s.owner_id IN (SELECT id FROM base))
            / (SELECT COUNT(*) FROM base), 1) AS pct_partage_accepte;
```

La dernière colonne est **le vrai taux viral** : un partage créé n'est pas un
partage accepté (statuts : `api/src/Models/SharedList.php:21-26`).

### e) Budgets et reçus

```sql
WITH base AS (SELECT id FROM users WHERE deleted_at IS NULL)
SELECT
  ROUND(100 * (SELECT COUNT(DISTINCT b.user_id) FROM budgets b
                WHERE b.deleted_at IS NULL AND b.user_id IN (SELECT id FROM base))
            / (SELECT COUNT(*) FROM base), 1) AS pct_budget,
  ROUND(100 * (SELECT COUNT(DISTINCT l.user_id)
                 FROM list_receipts r JOIN shopping_lists l ON l.id = r.list_id
                WHERE r.deleted_at IS NULL AND l.deleted_at IS NULL
                  AND l.user_id IN (SELECT id FROM base))
            / (SELECT COUNT(*) FROM base), 1) AS pct_recu,
  (SELECT COUNT(*) FROM currencies) AS nb_devises_reelles;   -- contrôle du « 150+ » du site
```

### f) Rétention par cohorte mensuelle

```sql
SELECT DATE_FORMAT(u.created_at, '%Y-%m') AS cohorte,
       COUNT(*) AS inscrits,
       SUM(EXISTS (SELECT 1 FROM user_devices d
                    WHERE d.user_id = u.id AND d.deleted_at IS NULL
                      AND d.last_active_at >= u.created_at + INTERVAL 7 DAY))  AS actifs_j7,
       SUM(EXISTS (SELECT 1 FROM user_devices d
                    WHERE d.user_id = u.id AND d.deleted_at IS NULL
                      AND d.last_active_at >= u.created_at + INTERVAL 30 DAY)) AS actifs_j30
  FROM users u
 WHERE u.deleted_at IS NULL
 GROUP BY cohorte
 ORDER BY cohorte;
```

**Lisez ce résultat avec prudence.** `last_active_at` est **écrasé** à chaque
enregistrement : la colonne ne garde que la **dernière** activité, pas
l'historique. « Encore actif à J+7 » signifie en réalité « sa dernière activité
connue est postérieure à J+7 » — c'est une rétention *jusqu'à aujourd'hui*, pas
une rétention *à J+7*. **Une vraie courbe de rétention est impossible** (§7.1).

### g) Foyers et listes réellement partagées

```sql
-- Espaces à au moins 2 membres actifs
SELECT s.type, COUNT(*) AS nb_espaces FROM (
  SELECT m.space_id, COUNT(*) AS membres
    FROM space_members m JOIN spaces sp ON sp.id = m.space_id
   WHERE m.status = 'active' AND sp.deleted_at IS NULL
   GROUP BY m.space_id HAVING COUNT(*) >= 2) AS t
  JOIN spaces s ON s.id = t.space_id
 GROUP BY s.type;

-- Listes partagées ACCEPTÉES, avec au moins 2 personnes
SELECT COUNT(*) AS listes_a_2_ou_plus FROM (
  SELECT s.list_id
    FROM shared_list s JOIN shopping_lists l ON l.id = s.list_id
   WHERE s.deleted_at IS NULL AND l.deleted_at IS NULL
     AND s.status = 'accepted' AND s.is_active = 1
   GROUP BY s.list_id
  HAVING COUNT(DISTINCT s.shared_with_user_id) >= 1) AS t;
```

### 7.1 Métriques IMPOSSIBLES avec le schéma actuel

| Métrique | Pourquoi |
|---|---|
| **Vraie rétention J+1 / J+7 / J+30** | `user_devices.last_active_at` est écrasé à chaque écriture ; aucune table de sessions ni d'événements. Il n'existe aucun historique de connexion. |
| **DAU / WAU / MAU au sens usuel** | même cause : pas de journal d'ouvertures. |
| **Durée de session, écrans vus, entonnoirs in-app** | aucun SDK d'analytics dans l'app (§5.1). |
| **Source d'acquisition d'un utilisateur** | aucun UTM, aucune attribution, aucune colonne `source` sur `users` (`bd_prod.sql:317-343`). |
| **Taux de conversion visite du site → installation** | aucun identifiant ne relie une session web à un compte. |
| **Boucle virale (invité devenu utilisateur)** | `shared_list.shared_with_user_id` ne se remplit qu'**après** la création du compte, et rien ne relie ce compte au jeton d'invitation d'origine : impossible de distinguer un invité converti d'un inscrit spontané. |
| **Utilisateurs « web »** | `user_devices.platform` est `ENUM('android','ios')` (`bd_prod.sql:355`). |
| **Usage hors ligne** | la file locale (`offline_queue_service.dart:125`) est rejouée sans horodatage d'origine conservé côté serveur. |
| **Temps réellement économisé / économies réalisées** | rien n'est mesuré : les « 70 % » et « 30 % » du site (§1.1) ne reposent sur aucune donnée. |

---

## 8. Confidentialité

### 8.1 La politique est-elle liée ?

- **Dans l'application : OUI.** `app/lib/screens/privacy_policy_screen.dart`,
  atteignable depuis l'écran d'accueil (`welcome_screen.dart:11`, lien `:235`)
  et le profil (`profil_screen.dart:18`).
- **Sur le site : OUI.** `web/app/politique-confidentialite/`, contenu
  `web/components/PrivacyContent.tsx`, textes `translations.ts:332-392` (FR) et
  `:1022-…` (EN).

### 8.2 Ce qu'elle dit des reçus : RIEN

Recherche de `reçu`, `receipt`, `OCR`, `photo` dans les clés de la politique
(`translations.ts:332-392`) : **aucune occurrence.**

Or l'application :

1. photographie un reçu et en extrait le texte **localement**, via ML Kit
   (`app/lib/services/receipt_ocr_service.dart:7` — *« 100 % local, gratuit et
   hors ligne »*). **C'est un bon point, et il n'est pas dit.**
2. **téléverse l'image du reçu** vers **Google Cloud Storage**
   (`api/src/Services/ImageStorageService.php:25`, route
   `api/public/index.php:481`) ;
3. **en lecture publique** — `ImageStorageService.php:141` :
   `'predefinedAcl' => 'publicRead'` ;
4. conserve les montants dans `list_receipts` (`bd_prod.sql`, colonnes
   `store_name`, `total_amount`, `purchase_date`).

**Verdict : PARTIEL et risqué.** La politique affirme « Vos données restent au
Canada » (`translations.ts:341`) et « Serveurs sécurisés au Canada » (`:373`),
alors que les images partent sur GCS, bucket `epilist-storage`
(`ImageStorageService.php:46`), **dont la région n'est fixée nulle part dans le
code**. Si ce bucket n'est pas en région canadienne, l'affirmation est fausse.
**À vérifier dans la console Google Cloud — impossible depuis le code.**

### 8.3 La suppression de compte efface-t-elle les données ? NON

`api/src/Controllers/AuthController.php:2002-2008` — « Marquer le compte pour
suppression (soft delete) » :

```php
$user->update([
    'is_active' => false,
    'deleted_at' => Carbon::now(),
    'deletion_confirmed_at' => Carbon::now(),
]);
```

Puis l'API répond **« Compte supprimé avec succès »** (`:2017`).

Ce qui subsiste : la ligne `users` complète (**courriel, prénom, nom, empreinte
du mot de passe**), toutes les listes, articles, reçus, budgets, et **les images
de reçus sur GCS en accès public**.

Une méthode d'anonymisation existe — `api/src/Models/User.php:275` `anonymizeData()`,
qui remplacerait le courriel par `deleted_user_{id}@deleted.local` et viderait
l'empreinte — mais **elle n'est appelée nulle part** (recherche `anonymizeData`
dans `api/` : seules sa définition et son propre corps). **Code mort.**

Aucune tâche de purge différée : recherche `purge` dans `api/public/cron.php` →
aucun résultat (le seul `purge` du dépôt concerne les journaux d'erreurs admin,
`AdminController.php:253`).

**Verdict : ABSENT.** La suppression de compte n'efface rien. C'est un écart
avec les exigences de Google Play et de l'App Store sur la suppression de
compte, et avec la Loi 25 / la LPRPDE.

---

## 9. Résumé en 10 lignes

1. **Affirmable sans risque :** l'application est gratuite, sans publicité et
   sans achat intégré — vérifié, aucune ligne de paiement n'existe (§6) ; elle
   est entièrement bilingue FR/EN (3101 clés de chaque côté) ; elle fonctionne
   hors ligne avec file d'attente ; le scanner de reçus fait un **vrai OCR, et
   100 % sur l'appareil** (§8.2) — c'est le meilleur argument de confidentialité
   du produit, et il n'est écrit nulle part.
2. **Affirmable aussi :** budgets et alertes, inventaire par zone, mode magasin,
   tri par rayon, planification de repas, listes récurrentes, comparateur de
   prix, alertes de prix, foyers multi-membres — les 17 fonctions du tableau
   §2.1 existent côté app **et** côté API.
3. **À retirer du site immédiatement :** « plus de 50 000 familles » (deux
   endroits), la note **4.9** et les **1247 avis** du JSON-LD — ces deux
   derniers sont envoyés à Google et exposent à une sanction pour avis fictifs.
4. **À retirer aussi :** « 70 % de temps économisé », « 30 % d'économies
   moyennes », « Audits de sécurité réguliers » — aucune donnée, aucune trace.
5. **À remplacer :** les cinq témoignages sont des placeholders (§1.2) ; et
   « synchronisation temps réel » doit devenir « notifications instantanées »,
   car le push est plafonné à une toutes les 3 minutes par liste (§2.2).
6. **À corriger :** le texte « inventaire : trois états simples » décrit une
   version antérieure — l'app range par zone depuis la migration 014 ; et
   « vos données restent au Canada » est à vérifier avant d'être maintenu, les
   images de reçus partant sur GCS en accès public.
7. **Trou bloquant n° 1 — l'invitation ne boucle pas.** `assetlinks.json` est
   **absent (404)** alors que le manifeste Android demande `autoVerify` : un
   lien de partage **n'ouvre jamais l'app sur Android**. Et aucun *deferred deep
   link* : l'invité qui installe arrive sur l'écran de bienvenue, pas dans la
   liste. La boucle virale est cassée aux deux bouts.
8. **Trou bloquant n° 2 — vous ne mesurerez rien.** Zéro événement dans
   l'application (pas même `firebase_analytics`), 13 des 16 événements demandés
   absents, aucun UTM, aucune attribution. Une campagne lancée demain ne pourra
   pas dire combien d'installations elle a produites, ni ce que ces gens ont
   fait ensuite.
9. **Trou bloquant n° 3 — l'onboarding perd tout le monde.** Compte
   obligatoire, courriel à vérifier, aucun mode invité, aucun tutoriel,
   **~14 gestes** avant la première liste — et **aucune invitation proposée**,
   alors que le partage est l'argument principal du produit.
10. **Deux dettes à régler avant de dépenser en publicité :** la suppression de
    compte n'efface rien (§8.3, exigence des deux stores), et les traceurs se
    chargent sans consentement (§5.4, Loi 25). Un marché opportun attend par
    ailleurs : le module **B2B complet** — fournisseurs, demandes d'achat,
    espaces restaurant et organisation — est construit, atteignable, et
    totalement absent d'un site qui ne parle que de familles.
