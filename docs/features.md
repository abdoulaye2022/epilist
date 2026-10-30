# Fonctionnalités d'EpiList

Inventaire complet des fonctionnalités de l'application, établi à partir du code source.
Dernière mise à jour : 2026-10-29 (version mobile 2.2.2+29).

EpiList est une application de gestion de listes de courses collaborative, composée de trois éléments :

| Composant | Technologie | Rôle |
|---|---|---|
| `app/` | Flutter 3.47 (BLoC + Dio) | Application mobile Android / iOS |
| `api/` | PHP 8.3 (prod) / 8.4 (dev), Slim 4, Eloquent | API REST — 231 routes |
| `web/` | Next.js 15 (App Router), React 19 | Site vitrine bilingue, pages publiques et espace administrateur |

---

## 1. Comptes et authentification

### Inscription et connexion
- Création de compte par email / mot de passe, avec acceptation des conditions d'utilisation.
  Le **nom de famille est facultatif**.
- **L'inscription délivre les jetons tout de suite** : on entre dans l'application sans
  passer par sa boîte de courriel. Un bandeau rappelle la vérification en attente, et deux
  gestes restent réservés aux adresses vérifiées — activer le 2FA et inviter par courriel
  dans un espace.
- Connexion par email / mot de passe, jetons **JWT** (access token + refresh token). Le
  message d'erreur est le même pour « compte inconnu » et « mauvais mot de passe ».
- Jetons stockés dans le **stockage sécurisé** de l'appareil (Keychain iOS,
  Keystore Android via `TokenStore`), avec migration douce depuis l'ancien stockage.
- Refresh tokens **enregistrés côté serveur** (table `refresh_tokens`, hash SHA-256) :
  **rotation** à chaque refresh, **révocation** à la déconnexion et à la désactivation
  du compte.
- Rafraîchissement automatique et transparent du token expiré côté application
  (`app/lib/config/token_refresh_interceptor.dart`) : mutex anti-refresh concurrents
  (compatible rotation), requête rejouée sans que l'utilisateur s'en aperçoive ;
  seul un refus explicite du serveur déconnecte (jamais un simple échec réseau).
- Un jeton d'un compte supprimé ou anonymisé est refusé **à la requête suivante**
  (`JwtMiddleware`), pas à son expiration.

### Authentification tierce (SSO)
- **Connexion avec Google** et **Connexion avec Apple**, en inscription comme en connexion,
  proposées **en premier** sur l'écran d'accueil.
- Jeton Apple vérifié contre les clés publiques d'Apple (JWKS), jeton Google contre
  `tokeninfo` ; audience strictement limitée aux identifiants déclarés.
- Gestion des emails privés Apple (`@privaterelay.appleid.com`).
- Liaison de plusieurs fournisseurs SSO à un même compte (table `user_sso_links`).

### Vérification en deux étapes (2FA)
- **Optionnelle et activable par l'utilisateur** (`/auth/2fa`), obligatoire pour les
  administrateurs : à la connexion, un code à six chiffres part par courriel
  (haché, usage unique, dix minutes).
- Les essais de code sont plafonnés **par compte** et par adresse IP.

### Vérification d'adresse email
- Envoi d'un code de vérification à l'inscription, avec possibilité de renvoi
  (renvois plafonnés : 3 par heure et par adresse).
- Les essais de code sont plafonnés par compte (5 / 30 min) — un code à six chiffres ne
  se force pas.

### Mot de passe
- Réinitialisation par lien envoyé par email (mot de passe oublié).
- Changement de mot de passe en deux temps : demande d'un code à 6 chiffres,
  puis validation du code avec le nouveau mot de passe. Le code a une durée de validité
  limitée. Minimum huit caractères.

### Suppression de compte
Procédure conforme aux exigences des stores et de la Loi 25, qui **supprime vraiment** :
- Demande depuis l'application (code par courriel, annulable) **ou depuis le site**
  (`/suppression-compte`, `/en/delete-account`) sans être connecté : un lien à jeton
  part par courriel, la page répond toujours la même chose, qu'on connaisse l'adresse ou non.
- À la confirmation, en une transaction : listes personnelles détruites, listes partagées
  transférées, espaces remis à un successeur ou détruits, photos effacées du stockage,
  données personnelles **anonymisées**, messages de discussion réattribués à un compte
  réservé « Utilisateur supprimé ».
- **Purge définitive** trente jours plus tard par le cron (mode constat par défaut,
  `PURGE_APPLY` pour agir).
- Script de rattrapage des comptes « supprimés » d'avant (`backfill_deleted_accounts.php`,
  `--dry-run` par défaut).

### Premier lancement et profil
- Écran d'accueil (`welcome_screen.dart`) avec **choix de la langue** avant même la connexion,
  accès aux pages légales, boutons SSO et **saisie d'un code d'invitation**.
- **Parcours de départ en trois étapes** après l'inscription, chacune passable : première
  liste, inviter quelqu'un, premier budget. Terminé ou passé, il est mémorisé **côté
  serveur** (`users.onboarding_done_at`) : changer de téléphone ne le remontre pas.
- **Navigation par onglets** (`main_shell.dart`) : Accueil, Listes, bouton central de
  création, Factures, Plus — même en-tête et même barre sur toutes les pages.
- Écran de profil (`profil_screen.dart`) : informations du compte, devise, apparence
  (clair / sombre / système), sécurité (mot de passe, 2FA), espaces, suggestions,
  préférences email, **mesure d'usage** (refus en un geste), envoi de retour, suppression
  de compte, déconnexion.
- **Photo de profil** : téléversement vers le stockage infonuagique, affichage partout
  dans l'application (avatar avec repli sur les initiales).

### Protection contre les robots et les abus
`api/src/Services/RateLimiter.php` plafonne, par adresse IP **et par compte** :
inscription (plus un plafond global horaire), connexion, codes de vérification, 2FA,
OTP administrateur, changement de mot de passe, renvoi de code, demandes de suppression,
codes d'invitation, formulaire de contact (plus un total horaire et un **pot de miel**).

L'adresse IP est lue par `ClientIp` : les en-têtes transmis (`X-Forwarded-For`…) ne sont
crus que derrière un mandataire — déclaré dans `TRUSTED_PROXIES`, ou reconnu par son
adresse privée — et lus de droite à gauche. Un client ne choisit pas son adresse.

---

## 2. Espaces (foyer, restaurant, organisation)

Chaque utilisateur possède un **espace personnel** et peut créer ou rejoindre des espaces
partagés (`docs/architecture-espaces.md`, `docs/permissions-espaces.md`) :

| Type | Usage |
|---|---|
| `personal` | l'expérience individuelle, protégée : ne se partage pas, ne se supprime pas |
| `household` | le foyer : listes, budgets, inventaire et historique **communs** à tous les membres |
| `restaurant` | la cuisine professionnelle : fournisseurs, demandes d'achat, stock critique |
| `organization` | même module que le restaurant, pour toute autre structure |

- **Cinq rôles** (`owner`, `admin`, `manager`, `member`, `viewer`) avec un jeu de
  **douze permissions** par défaut, surchargeables membre par membre
  (`manage_space`, `manage_members`, `view_budgets`, `manage_budgets`, `add_items`,
  `manage_lists`, `approve_purchases`, `scan_receipts`, `view_expenses`,
  `manage_inventory`, `manage_suppliers`, `view_statistics`).
- **Invitations** par courriel avec jeton, acceptation / refus / révocation, liste de ses
  invitations en attente ; retrait d'un membre, départ volontaire.
- **Journal d'activité** de l'espace (`space_activity_screen.dart`) : liste créée, article
  ajouté ou acheté, reçu ajouté, budget créé, membre arrivé ou parti…
- **Accueil adaptatif** (`docs/dashboard-adaptatif.md`) : rien ne change dans l'espace
  personnel ; dans un foyer, une carte « à racheter probablement / ruptures / activité » ;
  dans un restaurant, les **demandes d'achat en attente** d'abord, puis le **stock
  critique** nommé, les fournisseurs et l'activité.
- Isolation stricte entre espaces, vérifiée par `SpaceAccessService::assertPermission()`
  sur chaque action.

### Module restaurant
- **Fournisseurs** par espace (`suppliers_screen.dart`) : création, modification, suppression.
- **Demandes d'achat** (`purchase_requests_screen.dart`) : brouillon → soumise → approuvée
  ou rejetée → achetée, ou annulée. Soumettre demande `add_items`, approuver demande
  `approve_purchases`.

---

## 3. Listes de courses

- Création, modification et suppression de listes ; **après « Créer », la liste est sous
  les yeux**.
- **Suppression douce** (`deleted_at`) avec **restauration** d'une liste supprimée.
- **Duplication** d'une liste existante.
- Statistiques par liste : nombre d'articles, articles achetés, montant total.
- **Filtres rapides** sur l'écran des listes : toutes, actives, terminées, partagées.
- Tirer pour rafraîchir, suppression par glissement.
- **Fin des courses** (`shopping_success_screen.dart`) : compteur vivant pendant les
  courses, réussite célébrée quand tout est coché.

### Articles d'une liste
- Ajout, modification, suppression et **restauration** d'un article.
- Champs : nom du produit, quantité, prix (**saisi au magasin**, le budget le voit), catégorie,
  code-barres, nom du magasin, **photo** de l'article.
- Marquage **acheté / non acheté** par article, avec horodatage (`purchased_at`) ; au
  magasin, **l'article coché reste à sa place**.
- **Tout marquer comme acheté** et **vider les articles achetés** en une action.
- Détection des doublons à l'ajout : l'API propose les articles similaires existants
  et permet soit de **fusionner**, soit de **forcer** l'ajout.
- Suggestions **sous le champ de saisie** pendant la frappe.
- **Filtres et tri** des articles : par magasin, achetés / non achetés, ordre croissant ou décroissant.

---

## 4. Partage et collaboration

- Génération d'un **lien de partage** pour une liste, envoyé via la feuille de partage
  native du téléphone (`share_plus`) : SMS, WhatsApp, email, etc.
- **Un code court à six caractères double chaque lien** (alphabet sans `0 O 1 I L`) : il se
  dicte au téléphone et se tape dans l'application, même fraîchement installée.
- **L'invitation survit à l'installation** : sur Android, le jeton passe par le *Play
  Install Referrer* et l'invitation s'ouvre au premier lancement ; sur iOS, le code court
  prend le relais. Le jeton en attente est conservé sur disque jusqu'à la connexion.
- Invitation avec trois niveaux de permission : **lecture seule**, **modification**,
  **administration** ; le panneau d'invitation **dit ce que le rôle permet**.
- Cycle de vie d'une invitation : `pending`, `accepted`, `declined`, `expired`.
  Un code expiré ou inconnu reçoit la même réponse (pas d'énumération).
- Consultation des listes partagées avec soi, et des personnes avec qui on partage.
- Modification de la permission d'un participant, **révocation** d'un partage, **quitter**
  une liste, révocation de **tous** les liens d'une liste, statistiques de partage.
- **Courriel d'invitation** envoyé à chaque partage nominatif, invité déjà inscrit ou non.

### Liens profonds (deep links)
- Schéma personnalisé : `epilist://share/{token}`
- **App Links Android** (`/.well-known/assetlinks.json`) et **Universal Links iOS**
  (`apple-app-site-association`) : `https://epilist.app/share/{token}` ouvre
  directement l'application (`web/docs/liens-applicatifs.md`).
- Sans l'application, la page `/share/{token}` détecte la plateforme : un bouton vers le
  bon magasin sur téléphone, les deux magasins, un **code QR** et le code court sur ordinateur.

---

## 5. Messagerie par liste

Chaque liste partagée dispose de sa propre discussion (`app/lib/screens/chat_screen.dart`) :
- Envoi et consultation des messages.
- **Compteur de messages non lus** par liste.
- Marquage d'un message comme lu (table `message_read_status`).
- Suppression d'un message.
- Les messages d'un compte supprimé restent lisibles, signés « Utilisateur supprimé ».

---

## 6. Suggestions intelligentes

`api/src/Services/SmartSuggestionService.php` analyse l'historique d'achat pour proposer :

| Fonction | Description |
|---|---|
| Suggestions personnalisées | Produits susceptibles d'être rachetés, à partir des habitudes |
| Suggestion de quantité | Quantité habituellement achetée pour un produit donné |
| Suggestion de prix | Prix habituellement payé pour un produit donné |
| Produits tendance | Produits les plus ajoutés sur la période |
| Associations de produits | Produits fréquemment achetés ensemble (`product_associations`) |

- Retour sur une suggestion (accepté / rejeté), recalcul des motifs à la demande,
  statistiques de pertinence.

### Historique de saisie
Les produits déjà saisis (`product_suggestions`) servent à l'auto-complétion : recherche,
produits populaires, statistiques, purge manuelle (écran de gestion depuis le profil).

### Intelligence du foyer
Moteur 100 % statistique (`PurchasePredictionService`, aucun LLM), débrayable par
réglage (`intelligence_settings_screen.dart`), et qui **raisonne dans un espace** : dans un
foyer, les cycles d'achat se calculent sur les achats de tous les membres
(`docs/assistant-intelligent.md`).

| Fonction | Description |
|---|---|
| Prédictions de rachat | « Il vous manque probablement du lait » : fréquence médiane par produit (fenêtre 12 mois, valeurs aberrantes écartées), niveau de confiance, carte sur l'accueil |
| Retour utilisateur | Ajouté / pas maintenant / j'en ai encore / ne plus proposer — chaque réponse affine ou éteint la prédiction |
| Brief avant les courses | `pre_shopping_screen.dart` : ce qu'il faut racheter, ce qui manque, où aller |
| Économies | `/assistant/savings` : ce que les prix observés permettent d'économiser |
| Listes récurrentes | Hebdomadaires, aux deux semaines ou mensuelles, préremplies selon les habitudes, **modifiables** (on sait ce qu'on modifie), générées par le cron avec notification |
| Plan de repas | Recettes et ingrédients, **recettes personnelles** et favoris, repas planifiés **par jour**, consolidation des quantités (g→kg, ml→L) vers la liste ; **un repas cuisiné vide la maison** comme les courses la remplissent |
| Mode magasin | Liste triée rayon par rayon selon l'ordre du magasin, grandes cases, progression en temps réel |
| Projection budget | Rythme de dépense robuste (médiane 7 j / 14 j / mois), projection de fin de mois et budget conseillé par jour |

### À la maison (inventaire)
`inventory_screen.dart`, `docs/inventaire-reapprovisionnement.md` :
- Trois états par produit — **à la maison, bientôt terminé, terminé** — et trois niveaux
  (plein, moitié, bas). **La quantité décide de l'état** quand un seuil est défini.
- **Zones de rangement** : garde-manger, réfrigérateur, congélateur, entretien
  (`NULL` = « ailleurs »), chacune sur son fond de couleur.
- Quantité, unité, **seuil d'alerte** (« Suggérer un seuil » répond toujours), date de
  péremption facultative.
- L'inventaire se met à jour **tout seul** : cocher un article ou importer une facture
  remet le produit « à la maison » ; cuisiner un repas le consomme.

### Magasins et rayons
- Référentiel de magasins par espace : création, renommage, suppression, **favoris**.
- **Position** (adresse, latitude / longitude) et **heures d'ouverture** ; les magasins sont
  **triés du plus proche au plus loin** quand la position est autorisée — la permission
  n'est demandée qu'après l'explication, jamais avant. La position n'est ni enregistrée ni envoyée.
- **Combien il reste à y prendre** : chaque devanture affiche les articles qu'on y achète.
- **Ordre des rayons** personnalisé par magasin (`store_aisle_order_screen.dart`),
  utilisé par le mode magasin et le tri des articles.

---

## 7. Scanner de codes-barres

- Scan via la caméra (`mobile_scanner`), écran dédié `barcode_scanner_screen.dart`.
- Recherche du produit scanné dans la base publique **Open Food Facts**.
- Le code-barres est conservé sur l'article (`list_items.barcode`).

---

## 8. Saisie vocale

- Ajout d'articles à la voix (`speech_to_text`), avec retour visuel animé pendant l'écoute.
- **La phrase est découpée** (`voice_list_parser.dart`) : « 3 pommes, 2 litres de lait,
  5 kilos de tomates » donne trois articles avec leurs quantités et unités, **vérifiables
  avant l'ajout**.
- Français par défaut (`fr_FR`), langue paramétrable ; permission micro expliquée.

---

## 9. Budgets

- Création de budgets sur cinq périodicités : **hebdomadaire**, **aux deux semaines**,
  **mensuelle**, **annuelle**, **personnalisée**. Chaque budget a une **période**, et deux
  phrases ne se contredisent plus.
- **Renouvellement automatique** à la fin de la période (cron), avec date de renouvellement.
- Création rapide d'un budget (valeurs pré-remplies).
- Tableau de bord des budgets : alloué, dépensé, restant, pourcentage consommé — **la jauge
  se remplit et porte sa phrase** ; prix estimés signalés (`price_is_estimate`).
- Écran de détail par budget ; **alertes de dépassement** et à l'approche de la **fin**.
- Rappels programmés localement sur l'appareil, en plus des notifications serveur.

---

## 10. Factures et reçus

Chaque liste peut recevoir des reçus d'achat (`list_receipts`) ; un **onglet Factures**
les rassemble tous (`all_receipts_screen.dart`, `GET /receipts`) :
- Enregistrement d'un reçu : magasin, montant, date, articles.
- Consultation, modification et suppression ; regroupement **par magasin** ; statistiques.
- **Export PDF** et **export CSV** (`ReceiptExportService.php`).
- **Photo du reçu papier**, **privée** : l'objet est stocké sans accès public et ne se
  regarde qu'à travers une **URL signée de quinze minutes**, délivrée à qui a le droit de
  voir la liste. Les anciennes photos se privatisent par script (`make_receipts_private.php`).

### Scanner de reçus (OCR)
- Photographiez la facture (caméra ou galerie) : la lecture se fait **sur l'appareil**
  puis un parseur dédié (`receipt_parser_service.dart`, couvert par des tests) reconstitue
  magasin, date, numéro, lignes, sous-total, taxes et total — **montants québécois
  « 4,99 $ » compris**.
- Écran de validation avant enregistrement : tout est corrigeable, l'échec OCR bascule
  en saisie manuelle.
- **Anti-doublon** : signature du reçu côté serveur (409 en cas de reçu déjà importé).
- **Apprentissage des libellés** (`product_aliases`) : un libellé corrigé une fois est
  reconnu les fois suivantes.

### Intelligence prix
- **Historique de prix réel** par produit, alimenté par les reçus et les achats, **par
  espace** (`docs/intelligence-prix.md`).
- **Courbe de prix** par produit, doublée de sa phrase.
- **Comparateur de magasins** (`store_comparison_screen.dart`) : coût de la liste chez
  chaque enseigne à partir des prix réellement payés, pondéré par la fraîcheur (14/30/90 j).
- **Optimisation** : répartition sur un ou deux magasins quand l'économie le justifie.
- **Alertes de prix** (`price_alerts_screen.dart`) : un prix cible par produit, globalement
  ou pour un magasin ; vérification à la saisie d'un prix (`/prices/check`), suggestion de
  cible, notification immédiate ou **résumé hebdomadaire** des baisses (lundi 9 h).
- **Communauté de prix anonymisée** (`docs/communaute-prix.md`) : avec le consentement de
  l'utilisateur, les prix observés nourrissent des **médianes par produit × magasin ×
  région**, rafraîchies par `community_refresh.php` ; consultation et réglage du
  consentement depuis l'application.

---

## 11. Analytiques de dépenses

Tableau de bord complet (`analytics_screen.dart`) alimenté par 11 endpoints :

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

## 12. Catégories

- Catégories personnalisables par utilisateur : création, modification, suppression,
  **réordonnancement** manuel.
- Initialisation d'un jeu de **12 catégories par défaut**.

---

## 13. Devises

- **25 devises** disponibles, dont 11 populaires (CAD, USD, EUR, GBP, JPY, AUD, CHF, CNY,
  HKD, SGD, ZAR), bonne couverture africaine (XOF, XAF, NGN, MAD, EGP, KES, GHS, ETB…).
- Choix de la devise par utilisateur, formatage côté serveur.

---

## 14. Notifications push

Notifications **Firebase Cloud Messaging**, avec 5 canaux Android distincts :
`general`, `budget_alerts`, `list_updates`, `messages`, `reminders`.

- **Le clic ouvre le bon écran** (`docs/notifications-cliquables.md`).
- **Dans la langue de chaque destinataire** (`NotificationTexts.php`), pas dans celle de
  l'auteur de l'action.
- **Regroupées** : les changements d'une liste faits dans une fenêtre de trois minutes
  partent en un seul message — « Marie a ajouté 4 articles » — au lieu d'un par article.
- Réglables par l'utilisateur, courrier réduit à l'essentiel (`docs/audit-notifications.md`).

### Tâches planifiées (`api/public/cron.php`)

| Déclencheur | Moment |
|---|---|
| Résumé quotidien des budgets | tous les jours à 9 h |
| Alertes de budget dépassé | toutes les heures, de 9 h à 21 h |
| Budgets arrivant à expiration | tous les jours à 18 h |
| Rappel aux utilisateurs inactifs | mardi à 10 h |
| Listes terminées sans facture | heures paires, 8 h – 22 h |
| Rappel hebdomadaire (aucune liste créée) | vendredi à 19 h |
| Rappels basés sur l'analyse d'habitudes | tous les jours à 10 h |
| Listes récurrentes dues | à chaque passage |
| Budgets à renouveler | à chaque passage |
| Résumé hebdomadaire des baisses de prix | lundi à 9 h |
| Résumés groupés des listes | à chaque passage |
| Purge définitive des comptes supprimés | dimanche à 3 h (constat par défaut) |
| Ménage : appareils inactifs, caches d'alertes, verrous, plafonds de cadence | dimanche 2 h / chaque passage |

### Gestion des appareils
- Enregistrement de l'appareil et de son jeton push ; liste, désactivation.
- Préférences de notification par appareil ; outils de diagnostic.

### Analyse d'habitudes
`UserHabitAnalysisService.php` calcule le rythme d'utilisation pour envoyer les rappels au
bon moment plutôt qu'à heure fixe.

---

## 15. Emails transactionnels

Envoi via le fournisseur de courriel, modèles dans `MailSender.php` / `EmailTemplates.php`,
**bilingues** (langue de l'utilisateur) :

| Email | Déclencheur |
|---|---|
| Vérification d'adresse | inscription, renvoi |
| Bienvenue | après vérification |
| Code de changement de mot de passe / mot de passe modifié | sécurité |
| Code 2FA / OTP administrateur | connexion en deux étapes |
| Liste partagée avec vous / invitation à un espace | partage |
| Liste terminée | complétion d'une liste partagée |
| Code, confirmation et annulation de suppression de compte | suppression |
| Lien de suppression depuis le site | demande hors application |
| Confirmation de désabonnement | lien de désabonnement |

- **En développement, aucun courriel ne part** : ils sont écrits dans `api/storage/mails/`
  (`MAIL_DEV_SEND=true` pour forcer l'envoi vers la boîte de dev).

### Préférences email
Contrôle par type : `email_verification`, `password_change_request`, `password_changed`,
`list_shared_with_me`, `list_completed`, `budget_alert`, `budget_summary`, `tips_and_tricks`.
Réinitialisation aux valeurs par défaut ; **désabonnement marketing** en un clic par lien
signé (`/unsubscribe/{token}`), sans connexion.

### Campagnes
- Campagne « nouveautés » **bilingue** (`campaign.php`), désabonnés / non vérifiés / inactifs /
  en suppression exclus ; email de test avant envoi ; aperçu réservé aux administrateurs ;
  accès HTTP protégé par `CRON_SECRET`.

---

## 16. Mode hors ligne

Six services dédiés (`app/lib/services/`) : connectivité, stockage local, cache (Hive),
file d'actions (versionnée, anti-doublons, **repart au lancement** sans attendre une
coupure), synchronisation, résolution de conflits.

Couverture vérifiée (`docs/audit-hors-ligne.md`) : consultation hors ligne des listes,
articles, budgets, profil, devise, analytiques ; actions rejouées au retour du réseau avec
**remappage des identifiants locaux** ; 5 tentatives par action puis abandon tracé ;
un 401 ne laisse plus de requête suspendue.

---

## 17. Interface et accessibilité

- **Thème « Version B »** (`app/lib/theme/`) : palette de rôles (succès, avertissement,
  erreur, information, violet, indigo, sarcelle, chacune avec sa teinte et sa bordure),
  **police Sora** pour les titres, quatre rayons, boutons de 60 dp, textes relevés au-dessus
  du plancher de lisibilité.
- **Mode sombre** complet, clair / sombre / système (`appearance_screen.dart`) ; aucune
  couleur écrite en dur (garde-fou dans les tests).
- **Chaque jauge est doublée de sa phrase**, les états s'écrivent, les icônes disent leur section.
- Affichage **sans clignotement** : les données en cache s'affichent d'abord, le
  rafraîchissement se fait en silence (`docs/affichage-sans-clignotement.md`).
- Tests de mise en page sur **petits écrans (320 points)**, clair et sombre.

---

## 18. Internationalisation

- **Français** et **anglais**, **2 186 clés** de traduction (`app_fr.arb` / `app_en.arb`),
  parité complète.
- Sélecteur de langue dans l'application, préférence enregistrée sur le compte
  (`users.language`) et appliquée aux emails, notifications serveur et campagnes.
- Fenêtres système iOS (caméra, micro, dictée, position, photos) traduites par
  `InfoPlist.strings` (`fr.lproj` / `en.lproj`).

---

## 19. Mesure d'usage et consentement

`docs/analytics.md` est la référence.

- **Application** : douze événements, sans aucun contenu (jamais un nom d'article, de
  liste, un montant, un courriel) — le traqueur **refuse l'événement entier** si une
  propriété inconnue apparaît (`analytics_tracker.dart`, testé). Pas d'identifiant
  publicitaire, donc pas de fenêtre ATT. **Refus en un geste** dans le profil : le SDK
  lui-même cesse de collecter.
- **Serveur** : un jour d'activité par personne et par jour (`user_activity_days`), sans
  route, IP ni appareil — effacé avec le compte. Requêtes de lecture dans `docs/metrics.sql`.
- **Site** : **rien ne se charge avant le consentement** (`ConsentGate`), deux catégories
  (mesure, marketing), Consent Mode v2 posé avant le script de mesure, choix conservé
  douze mois, « Gérer les témoins » dans le pied de page.
- **Provenance** : `users.signup_source` (`direct`, `share_link`, `invite_code`,
  `install_referrer`) ; les UTM du site sont gardés le temps de la session et recollés
  dans le lien Google Play.

---

## 20. Contact et support

- Formulaire de retour depuis l'application, avec types prédéfinis.
- Envoi possible **sans être connecté** (retour anonyme), plafonné et protégé par un pot de miel.

---

## 21. Pages légales et conformité

Dans l'application comme sur le site : politique de confidentialité (**douze sections**,
termes génériques pour les fournisseurs), conditions d'utilisation, écran « À propos » avec
la version. Le site **ne dit que ce qu'il peut prouver** : plus de chiffres invérifiables,
témoignages désactivés tant qu'aucun n'a de consentement daté, mention de résidence des
données conditionnée à un drapeau (`NEXT_PUBLIC_DATA_RESIDENCY_CANADA_CONFIRMED`) — un
test interdit le retour des phrases invendables.

---

## 22. Site web (`web/`)

Site vitrine Next.js 15 **entièrement bilingue** (URLs comprises), le français à la
racine, l'anglais sous `/en/*` (`lib/routes.ts`, hreflang, sitemap généré) :

| Page (fr) | Équivalent (en) | Contenu |
|---|---|---|
| `/` | `/en` | Accueil, avec les **captures de l'application d'aujourd'hui** (accueil, au magasin, à la maison) |
| `/fonctionnalites` | `/en/features` | Présentation des fonctionnalités |
| `/telecharger` | `/en/download` | Liens App Store et Google Play |
| `/comparaison-applications-courses` | `/en/grocery-app-comparison` | Comparatif |
| `/aide` | `/en/help` | Aide et questions fréquentes |
| `/contact` | `/en/contact` | Formulaire de contact (pot de miel, plafonds côté API) |
| `/a-propos` | `/en/about` | À propos |
| `/politique-confidentialite` | `/en/privacy-policy` | Politique de confidentialité |
| `/conditions-utilisation` | `/en/terms-of-use` | Conditions d'utilisation |
| `/suppression-compte` (+ `/confirmer/{token}`) | `/en/delete-account` (+ `/confirm/{token}`) | Suppression de compte sans l'application |
| `/share/{token}` | — | Page d'invitation : magasins, code QR, code court |
| `/unsubscribe/{token}` | — | Désabonnement des emails marketing |
| `/.well-known/…` | — | `assetlinks.json`, `apple-app-site-association` (servis en JSON, jamais redirigés) |

- Données structurées Schema.org (éditeur : M2atech Solutions Inc.), redirections 301 des
  anciens slugs (`middleware.ts`), thème clair / sombre.
- 1 028 clés de traduction fr / en ; aucun fournisseur technique nommé dans les textes.
- Suivi : mesure et marketing **sous consentement** ; désactivés sous `/admin`.
- Dépendances : **0 vulnérabilité** (`npm audit`), `tsc` et `next lint` sans erreur.

---

## 23. Espace administrateur (`/admin`)

Console web réservée aux comptes `role = 'admin'` (middleware dédié côté API) :

| Page | Contenu |
|---|---|
| Tableau de bord | Utilisateurs (total, actifs 7 j, nouveaux 30 j), listes, articles, reçus, achats 30 j, erreurs API |
| Utilisateurs | Recherche, pagination, activation / désactivation (révocation des sessions), promotion / rétrogradation |
| Statistiques | Activité 12 mois, top produits, communautés par pays et par langue |
| Monitoring | Journal des erreurs 500 (`api_error_logs`) : consultation, suppression, purge |
| Versions de l'app | Version publiée, mise à jour conseillée ou **forcée**, version minimale, notes par langue, statistiques |
| Campagnes | Envoi, statistiques, email de test, aperçu |

- **Connexion en deux étapes** (mot de passe puis code OTP par email, haché, usage unique,
  plafonné par compte et par IP), **session longue** par refresh token.

### Contrôle de version de l'app mobile
Une vérification par lancement (`/app/version-check`), fenêtre de mise à jour avec trois
verrous quand elle est **obligatoire**, statistiques `updated` / `dismissed`.

---

## Récapitulatif technique

| Élément | Valeur |
|---|---|
| Routes API | 231 (227 nommées + 4 fonctions) |
| Contrôleurs / services / modèles API | 31 / 23 / 40 |
| Écrans Flutter | 48 |
| Services Flutter | 44 |
| BLoCs | 15 |
| Tests Flutter | 38 fichiers, 349 tests |
| Suites E2E API | 11 scripts (`api/scripts/test_*.php`) + 2 tests unitaires sans serveur |
| Clés de traduction | 2 186 (app, parité fr/en) · 1 028 (site) |
| Migrations numérotées | 006 → 019 (idempotentes, à coller entières) |
| Devises | 25 |
| Catégories par défaut | 12 |
| Canaux de notification | 5 |
| Types d'espaces / rôles / permissions | 4 / 5 / 12 |

Documents de référence : `docs/architecture-espaces.md`, `docs/permissions-espaces.md`,
`docs/module-foyer.md`, `docs/module-restaurant.md`, `docs/intelligence-prix.md`,
`docs/assistant-intelligent.md`, `docs/communaute-prix.md`, `docs/dashboard-adaptatif.md`,
`docs/inventaire-reapprovisionnement.md`, `docs/verification-deux-etapes.md`,
`docs/notifications-cliquables.md`, `docs/analytics.md`, `web/docs/liens-applicatifs.md`.

Audits : sécurité (`docs/audit-securite.md`, puis `AUDIT_SECURITE_EPILIST.md` du
2026-10-29 — 12 constats, tous corrigés), marketing (`AUDIT_MARKETING_EPILIST.md`, six
phases livrées, `CHANGEMENTS_EPILIST.md`), espaces (`docs/audit-espaces-final.md`),
notifications (`docs/audit-notifications.md`), hors ligne (`docs/audit-hors-ligne.md`).
