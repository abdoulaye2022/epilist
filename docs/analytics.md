# Ce que nous mesurons, et ce que nous ne mesurons pas

Ce document est la référence. Si un événement n'y figure pas, il ne
doit pas exister ; s'il y figure, son contenu est exactement celui
décrit ici. Deux tests le vérifient automatiquement :
`app/test/analytics_test.dart` (application) refuse tout paramètre hors
liste, et `app/test/textes_verifiables_test.dart` garde les textes.

---

## 1. La règle, avant la liste

**Aucun contenu ne sort de l'application.** Jamais un nom d'article, un
nom de liste, un montant, un magasin, une adresse courriel, un
identifiant de compte, une recherche. Les propriétés d'un événement sont
des mots d'une liste fermée (`google`, `email`, `done`, `skip`) ou des
nombres.

Ce n'est pas une intention, c'est une barrière : `AnalyticsTracker`
**refuse l'événement entier** si une propriété inconnue apparaît. Pas
nettoyée, pas tronquée — refusée. Le jour où quelqu'un ajoutera
`parametres: {'product_name': ...}` « juste pour voir », rien ne partira
et le test échouera.

**Pas d'identifiant publicitaire.** `firebase_analytics` n'en collecte
aucun par défaut, le SDK AdSupport n'est pas lié au projet iOS, et rien
dans le code ne le demande. **Conséquence : pas de fenêtre ATT sur
iOS**, et aucun `NSUserTrackingUsageDescription` à ajouter. Si un jour
une campagne payante exige l'IDFA, ce document et le formulaire App
Privacy devront changer ensemble.

---

## 2. Les événements de l'application

Source : `app/lib/services/analytics_tracker.dart`.

| Événement | Quand il part | Propriétés | Base |
|---|---|---|---|
| `app_first_open` | Tout premier lancement après installation. Une seule fois par installation (drapeau local). | — | intérêt légitime, opt-out |
| `account_created` | Un compte vient d'être créé et les jetons sont enregistrés. | `method` : `google` \| `apple` \| `email`<br>`source` : `organic` \| `invite` | intérêt légitime, opt-out |
| `onboarding_step` | Fin ou abandon d'une étape du parcours de départ. | `step` : `first_list` \| `invite` \| `budget`<br>`action` : `done` \| `skip` | intérêt légitime, opt-out |
| `list_created` | Une liste a été créée côté serveur (`ShoppingListService`). | — | intérêt légitime, opt-out |
| `item_added` | **Seulement** le 1er et le 5e article de la vie du compte sur ce téléphone. | `rank` : `first` \| `fifth` | intérêt légitime, opt-out |
| `list_shared` | Un lien de partage part par la feuille de partage du système. | `channel` : `native_sheet` \| `link` \| `code` | intérêt légitime, opt-out |
| `invite_code_entered` | Un code à six caractères vient d'être saisi (avant même de savoir s'il est bon). | — | intérêt légitime, opt-out |
| `invite_accepted` | Une invitation de liste a été acceptée. | — | intérêt légitime, opt-out |
| `budget_created` | Un budget a été créé côté serveur. | — | intérêt légitime, opt-out |
| `receipt_scan_started` | La photo du reçu est prise — pas à l'ouverture du menu. | — | intérêt légitime, opt-out |
| `receipt_confirmed` | Un reçu a été enregistré après validation. | — | intérêt légitime, opt-out |
| `feedback_submitted` | Un message a été envoyé par le formulaire d'aide. **Le contenu ne part pas.** | — | intérêt légitime, opt-out |

### Pourquoi seulement le 1er et le 5e article

Mesurer chaque article dirait surtout à quelle vitesse les gens tapent,
et noierait le reste. Ces deux-là disent autre chose : le premier, que
la liste a servi au moins une fois ; le cinquième, qu'elle est devenue
une vraie liste de courses et pas un essai.

### Le refus

**Profil → Mesure d'usage.** Le réglage coupe la mesure *et* appelle
`setAnalyticsCollectionEnabled(false)` : le SDK lui-même cesse de
collecter, pas seulement notre code de cesser d'appeler. Effet immédiat,
rien à redémarrer. Le choix survit à la fermeture de l'application.

---

## 3. Le jour d'activité (serveur)

Table `user_activity_days`, migration 019.

| Ce qu'elle contient | Ce qu'elle ne contient pas |
|---|---|
| `user_id`, `activity_date` (une date, sans heure) | route appelée, adresse IP, appareil, agent utilisateur, action |

Écrite par `ActivityMiddleware`, **au plus une fois par personne et par
jour**. Elle existe parce que la rétention ne se calculait avec rien de
fiable : `user_devices.last_active_at` ne s'écrit qu'à l'enregistrement
d'un appareil et au rafraîchissement du jeton push — il rate tous ceux
qui refusent les notifications et tout usage hors ligne.

Les requêtes de lecture sont dans `docs/metrics.sql`.

**Suppression** : la clé étrangère est en `ON DELETE CASCADE`. Quand un
compte est purgé (trente jours après sa suppression), ses jours
d'activité partent avec lui, sans que le service de suppression ait à
les connaître.

---

## 4. Le site web

### Rien avant le consentement

`ConsentGate` ne **monte pas** les scripts tiers tant que la personne
n'a pas choisi. Pas « ne les déclenche pas » : ne les charge pas. Un
script tiers qui s'exécute a déjà lu l'adresse IP et posé ce qu'il
voulait. Les `preconnect` vers leurs domaines ont été retirés pour la
même raison — une préconnexion ouvre une vraie connexion.

| Outil | Catégorie | Ce qu'il fait |
|---|---|---|
| Google Analytics 4 | `mesure` | compte les visites, la provenance, les clics vers les magasins |
| Hotjar | `mesure` | rejoue des sessions ; le formulaire de contact porte `data-hj-suppress` |
| Meta Pixel | `marketing` | mesure l'effet des publicités, reconnaît la personne ailleurs |

GA4 fonctionne en **Consent Mode v2** : le mode par défaut (`denied`
partout) est posé **avant** `gtag.js`, puis mis à jour selon le choix.
L'ordre fait la conformité : l'inverse pose les cookies puis les
retire.

### Les événements web

Source : `web/lib/gtag.ts`.

| Événement | Quand | Propriétés |
|---|---|---|
| `page_view` | Changement de page | URL de la page |
| `store_click_ios` | Clic vers l'App Store | `source`, `utm_source`, `utm_medium`, `utm_campaign` |
| `store_click_android` | Clic vers Google Play | idem |
| `app_download_click` | idem (**conservé** : des rapports et des conversions GA existants s'y appuient) | plateforme + emplacement |
| `app_download` | Conversion GA4 historique | plateforme, emplacement |
| `demo_click`, `feature_interaction`, `scroll_depth`, `section_view` | Interactions de page | libellés de section |

### Les UTM

Lus à l'arrivée, gardés **le temps de la session** (`sessionStorage`,
pas `localStorage` : une campagne n'a pas à suivre quelqu'un pendant des
mois), bornés à 100 caractères et nettoyés.

Ils sont recollés dans le paramètre `referrer` du lien Google Play :
c'est le seul canal que Google transmet à l'application au premier
lancement, et donc le seul fil entre « a cliqué sur la publicité » et
« a créé un compte » (`users.signup_source`).

**Côté iOS, rien d'équivalent n'existe** : l'App Store ne transmet aucun
referrer. C'est une limite de la plateforme.

---

## 5. Conservation

| Donnée | Où | Combien de temps |
|---|---|---|
| Événements de l'application | Google Analytics | selon la durée fixée dans la propriété GA4 — **à régler sur 14 mois**, le maximum autorisé pour les données d'utilisateur |
| Événements du site | Google Analytics | idem |
| Pixel Meta | Meta | selon les règles de Meta ; aucune donnée EpiList ne lui est transmise |
| Hotjar | Hotjar | selon le réglage du compte Hotjar — **à vérifier**, et à aligner sur 12 mois |
| `user_activity_days` | notre base | tant que le compte existe ; effacée avec lui |
| Choix de consentement | navigateur du visiteur | 12 mois, puis redemandé |
| UTM | navigateur du visiteur | la session seulement |

---

## 6. Ce qui reste à faire de votre côté

1. **GA4 → Administration → Conservation des données** : passer à
   14 mois. Par défaut, Google conserve 2 mois seulement, ce qui rend
   toute comparaison annuelle impossible.
2. **Hotjar → Settings → Data retention** : aligner sur 12 mois, et
   vérifier que la suppression du contenu des formulaires est bien
   active en plus de `data-hj-suppress`.
3. **Google Play Console → Sécurité des données** : déclarer la collecte
   d'identifiants d'application (Firebase Analytics), sans identifiant
   publicitaire, avec l'option de refus.
4. **App Store Connect → Confidentialité de l'app** : déclarer
   « Données d'utilisation / Données de produit », **non liées à
   l'identité**, et non utilisées pour le suivi. Si cette dernière
   réponse devait changer, l'ATT deviendrait obligatoire.
5. **Déclarer l'URL de suppression de compte** (phase 2) dans Play
   Console → Contenu de l'app → Suppression du compte :
   `https://epilist.app/suppression-compte`.

---

## 7. Si vous ajoutez un événement

1. L'ajouter à `EvenementMesure` et au tableau de la section 2 ;
2. si une nouvelle propriété est nécessaire, l'ajouter à
   `AnalyticsTracker.valeursAutorisees` **avec sa liste fermée de
   valeurs** ;
3. si cette propriété peut contenir du texte venu de la personne :
   ne pas l'ajouter. Chercher autre chose à mesurer.
