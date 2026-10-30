# Audit de sécurité et de robustesse — EpiList

**Date** : 2026-10-29 · **Révision auditée** : `master` à `ee86ae2` (28 commits des six phases inclus)
**Corrections** : appliquées le 2026-10-29, voir §8 — chaque constat y porte son état.
**Périmètre** : API PHP (`api/`), application Flutter (`app/`), site Next.js (`web/`)
**Méthode** : lecture seule. Outils d'abord (lint, analyse statique, audits de dépendances, suites de tests), puis lecture manuelle des zones sensibles : authentification, limites de débit, contrôle d'accès, téléversements, SQL, secrets, transport, journalisation.
**Règle** : chaque point porte sa preuve `fichier:ligne`. Ce qui n'a pas pu être vérifié est dit tel quel en §6.

---

## 0. Résumé

| Gravité | Nombre | Points |
|---|---|---|
| **Élevée** | 1 | §2.1 — l'IP cliente vient d'en-têtes falsifiables : toutes les limites « par IP » se contournent |
| **Moyenne** | 4 | §2.2 Next.js 13.5.1 (avis critiques) · §2.3 retour anonyme sans limite · §2.4 XSS réfléchi sur `/campaign/preview` · §2.5 messages d'exception renvoyés au client (90 endroits) |
| **Faible** | 7 | §3.1 → §3.7 |
| **Information** | 5 | §4 |

**Rien de cassé** : 0 erreur de syntaxe PHP sur 122 fichiers, **227 routes → 227 gestionnaires existants**, `flutter analyze` 0 problème, **349 tests Flutter verts**, `tsc` 0 erreur, `composer audit` 0 avis. Les fondations (§5) sont saines : JWT, mots de passe, jetons, codes, SSO Apple, téléversements, contrôle d'accès par liste et par espace, stockage des jetons sur l'appareil.

---

## 1. Ce que les outils ont dit

| Contrôle | Résultat |
|---|---|
| `php -l` sur `api/src`, `api/public`, `api/scripts` | 0 erreur / 122 fichiers |
| Réflexion sur les 227 `[Controller::class, 'méthode']` de `api/public/index.php` | 0 classe absente, 0 méthode absente |
| `composer audit --locked` | aucun avis de sécurité |
| `flutter analyze` | « No issues found » |
| `flutter test` | **349 réussis, 0 échec** |
| `npx tsc --noEmit` (web) | 0 erreur |
| `npm audit --omit=dev` (web) | **21 avis : 1 critique, 16 élevés, 4 modérés** — détail en §2.2 |
| `npx next lint` | **ne s'exécute pas** — voir §3.6 |

---

## 2. Constats — à corriger

### 2.1 ÉLEVÉ — L'adresse IP est lue dans des en-têtes que le client écrit lui-même

**Preuve** : `api/src/Controllers/AuthController.php:1498-1529` (`getClientIP`). Ordre de lecture : `X-Forwarded-For` → `X-Real-IP` → `CF-Connecting-IP` → `REMOTE_ADDR`. Aucune liste de mandataires de confiance (`grep TRUSTED_PROXY` : rien).

**Conséquence** : n'importe quel client envoie `X-Forwarded-For: 1.2.3.4` avec une valeur différente à chaque requête, et devient une IP neuve à chaque fois. Tout ce qui se limite **par IP uniquement** devient illimité (`api/src/Services/RateLimiter.php:8-72`) :

| Action | Limite actuelle | Limite par courriel/compte en plus ? | Après falsification de l'IP |
|---|---|---|---|
| `verification_code` (code de confirmation courriel, 6 chiffres) | 5 / 30 min / IP | **non** | **illimité** → le code se force (1 000 000 de combinaisons, expiration à vérifier à `AuthController.php:2920`) |
| `two_factor_verify` (code 2FA admin, 6 chiffres, 10 min) | par IP | **non** (`AuthController.php:1277-1280`) | **illimité pendant les 10 minutes** qui suivent une connexion admin — demande le mot de passe au préalable, mais l'étape 2FA ne protège plus de rien |
| `admin_otp_verify` | par IP | non | idem |
| `invite_code` | 20 / h / IP | non | illimité — 887 millions de codes, donc pas exploitable en pratique |
| `registration` | 3 / h / IP + 50 / h global | courriel 5 / 24 h | le plafond global de 50/h tient ; le reste tombe |
| `login` | 10 / 15 min / IP | **oui**, 10 / compte | tient grâce à la limite par compte |
| `password_change_code` | 5 / IP | **oui**, 5 / courriel | tient |

Le blocage d'IP « suspecte » (`RateLimiter.php:301-360`) repose sur la même valeur et se contourne de la même façon.

**Attention en corrigeant** : OVH mutualisé place très probablement un mandataire devant PHP, donc `REMOTE_ADDR` peut être l'adresse de ce mandataire pour tout le monde. Ignorer purement `X-Forwarded-For` mettrait tous les utilisateurs dans le même seau. La bonne forme : ne lire `X-Forwarded-For` **que si `REMOTE_ADDR` appartient à la liste des mandataires connus**, et prendre alors le **dernier** saut ajouté par ce mandataire, pas le premier élément (que le client contrôle).

**Et surtout** : ajouter une limite **par compte** sur `verification_code` et `two_factor_verify`, comme `password_change_code` le fait déjà (`AuthController.php:3211`). Un compteur d'essais sur le code lui-même (invalidé après 5 échecs) ne dépend d'aucune IP.

### 2.2 MOYEN — Next.js 13.5.1 : trois avis critiques sur le paquet lui-même

**Preuve** : `web/node_modules/next/package.json` → `13.5.1` ; `npm audit` → `next 0.9.9 – 15.5.27 : critical` (SSRF dans les Server Actions GHSA-fr5h-rqp8-mj6g, empoisonnement de cache GHSA-gp8f-8m3g-qvj9, déni de service dans l'optimisation d'images GHSA-g77x-44xx-532m). La version est aussi dans la plage de CVE-2025-29927 (contournement du `middleware` par l'en-tête `x-middleware-subrequest`).

**Exposition réelle sur ce site, vérifiée** :
- Server Actions : **aucune** (`grep '"use server"'` : 0 fichier) → SSRF non applicable.
- `middleware.ts` ne fait que des redirections 301, aucune autorisation → le contournement ne donne rien.
- `next/image` est utilisé dans 6 composants ; sur Vercel l'optimisation passe par leur infrastructure.

Donc : **pas d'attaque immédiate identifiée**, mais la version a deux ans de retard, chaque futur avis s'y ajoutera, et le badge « critical » est là. Mise à jour vers la dernière 13.5.x (sans changement d'API) ou 14.2.x. Les 16 avis « élevés » restants sont des dépendances transitives (`axios`, `lodash`, `minimatch`, `postcss`…) qui suivront en grande partie.

### 2.3 MOYEN — Le formulaire de contact anonyme n'a aucune limite

**Preuve** : route publique `api/public/index.php:199` → `ContactController::sendFeedback` (`api/src/Controllers/ContactController.php:211`). Le fichier ne contient **aucune** référence à `RateLimiter`. Chaque appel valide envoie un courriel (`ContactController.php:306`, `MailSender::sendMail` ligne 398).

**Conséquence** : une boucle `curl` remplit `contact@m2atech.com` et **consomme le quota Brevo** — précisément ce que vous avez demandé de protéger pour les envois de test. Le site vitrine expose ce formulaire à tout le monde.

**Correction** : `checkIPLimit('contact_feedback')` **et** `checkEmailLimit` (3 / h / adresse), un champ pot-de-miel côté site, et un plafond quotidien global comme `registration` en a un.

### 2.4 MOYEN — XSS réfléchi et fuite d'exception sur `/campaign/preview`

**Preuve** : route publique `api/public/index.php:187`. `CampaignController::previewCampaignEmail` lit `first_name` dans la requête et le passe à `MailSender::newVersionCampaignEmail($prenom)` (`api/src/Services/MailSender.php:1092`), qui l'insère **sans échappement** : `Bonjour <strong>{$prenom}</strong>` (ligne 1122). La réponse est servie en `text/html`. En cas d'erreur, `details => $e->getMessage()` part au client.

`https://…/campaign/preview?first_name=<script>…</script>` exécute du script sur l'origine de l'API. Cette origine ne porte ni cookie ni session, ce qui limite l'exploitation — mais c'est une page HTML publique, exécutable, dont le contenu date (« EpiList 2.0.0 »).

**Correction** : la mettre derrière `AdminMiddleware` comme les trois autres routes de campagne (`index.php:407-409`), ou la retirer. Et `htmlspecialchars` dans le gabarit, quoi qu'il arrive : le même gabarit sert aux vrais envois.

### 2.5 MOYEN — 90 réponses HTTP renvoient `$e->getMessage()` au client

**Preuve** : `grep "'message' => … \$e->getMessage()" api/src/Controllers` → **90 occurrences** dans 13 contrôleurs (`ListItemController` 13, `AnalyticsController` 12, `ListReceiptsController` 9, `BudgetController` 8, `ShoppingListController` 7, `CategoryController` 7, …). Exemple : `SuggestionController.php` → `'Failed to get trending products: ' . $e->getMessage()`.

**Conséquence** : le `ErrorMiddleware` masque bien les exceptions non attrapées en production (`api/src/Middleware/ErrorMiddleware.php:72-79`), mais ces `catch` locaux passent à côté de lui. Une erreur SQL renvoie alors le texte de MySQL — noms de tables, de colonnes, fragments de requête — à qui a provoqué l'erreur.

**Correction** : un message générique dans la réponse, `error_log()` pour le détail. C'est mécanique, mais c'est 90 endroits.

---

## 3. Constats — faible gravité

### 3.1 Routes de test publiques
`api/public/index.php:165-181` : `/test` et `/test-json` ; la seconde renvoie `PHP_VERSION`. À retirer : elles n'ont plus de raison d'être et donnent une information gratuite.

### 3.2 Repli d'audience permissif sur le SSO Google
`api/src/Services/SSOService.php:240-245` : si l'audience du jeton n'est dans aucun identifiant client connu, elle est **acceptée quand même** si elle commence par `695717834998-` — c'est-à-dire tout client OAuth du même projet Google Cloud. Le jeton reste vérifié par Google (`tokeninfo`, `iss`, `exp`), donc seul un client créé dans *votre* projet passerait. Le risque est faible ; la liste blanche n'en est plus une. À retirer une fois les identifiants Android bien listés dans `GOOGLE_CLIENT_IDS`.

### 3.3 Paramètre `limit` non borné
`SuggestionController.php:28,222`, `ProductSuggestionController.php:39,71`, `MessageController.php:26` : `(int) $params['limit']` sans `min()`. `?limit=1000000` sur `/suggestions/trending` lance une agrégation sur toute la base. Un `min($limit, 100)` suffit.

### 3.4 Jetons dans les journaux de l'application
`app/lib/services/auth_service.dart:77-78,103` : les 20 premiers caractères des jetons (soit l'en-tête JWT, sans valeur) ; `app/lib/services/shared_list_service.dart:22,253` : **le jeton de partage complet**. `debugPrint` écrit aussi en version publiée (logcat / Console). Les entourer de `if (kDebugMode)`.

### 3.5 `RateLimiter::cleanup()` n'est jamais appelé
`api/src/Services/RateLimiter.php:364` définit le ménage ; `api/public/cron.php` ne l'appelle pas. `storage/rate_limits/` accumule un fichier par couple action×identifiant, pour toujours. Petits fichiers, mais sans fin.

### 3.6 Le lint du site ne tourne pas
`web/.eslintrc.json` étend `next/typescript`, configuration qui n'existe pas dans `eslint-config-next` 13 → `next lint` échoue au chargement (« Failed to load config "next/typescript" »). Rien n'a donc été linté depuis que cette ligne existe. Retirer l'entrée, ou passer à Next 15 où elle est valide.

### 3.7 Dépréciation PHP 8.4
`api/src/Controllers/EmailPreferenceController.php:191` : paramètre implicitement nullable. Simple avertissement, et la prod est en 8.3 (`.github/workflows/deploy-api.yaml:24`) — mais ce sera une erreur un jour. `?array $errors = null`.

---

## 4. Informations (pas de correction exigée)

- **Clés Firebase dans `app/lib/firebase_options.dart:53,61`** : ce sont des identifiants publics par conception, présents dans tout binaire. Vérifier seulement que les restrictions par application sont posées dans la console Google Cloud.
- **CORS `*`** (`api/src/Middleware/CorsMiddleware.php:28`) : acceptable parce que l'authentification est par en-tête `Bearer`, jamais par cookie. Si un cookie de session apparaissait un jour, ce `*` deviendrait une faille.
- **Pas de Content-Security-Policy** sur le site (`web/next.config.mjs:22-37` pose `X-Frame-Options`, `nosniff`, `Referrer-Policy`). HSTS est ajouté par Vercel. Une CSP serait un plus, pas une urgence — les seuls `dangerouslySetInnerHTML` injectent du JSON-LD construit côté serveur et les scripts de mesure sous consentement.
- **`AdminController.php:161-164`** : `$dateColumn` interpolé dans `selectRaw`/`groupByRaw`. Sûr aujourd'hui (la valeur vient d'une fermeture interne avec des constantes), mais c'est le seul endroit du code où une variable entre dans du SQL brut. À garder tel quel, et à ne jamais ouvrir à une entrée externe.
- **Dérive de configuration en production** : votre mémoire de projet note que `api/.htaccess` a été écrasé en prod le 2026-09-27. Vérifié côté dépôt : `api/.htaccess` (« Require all denied ») et `api/public/.htaccess` sont suivis, et `deploy-api.yaml` **les déploie** (l'exclusion `**/.git*` ne couvre pas `.htaccess`). Chaque déploiement remet donc la protection en place — c'est elle qui empêche de lire `api/.env` par HTTP, puisque le docroot est au-dessus de `api.epilist/`.

---

## 5. Ce qui est solide — vérifié, pas supposé

| Domaine | Preuve |
|---|---|
| JWT : algorithme épinglé HS256, clé obligatoire, `jti` aléatoire | `JwtService.php:27,43,104,126` |
| Compte supprimé → jeton refusé à la requête suivante | `JwtMiddleware.php:58-66` |
| Jetons de rafraîchissement hachés SHA-256 et révocables | `Models/RefreshToken.php:17-19`, `AuthController.php:2360,2385` |
| Mots de passe : `password_hash` / `password_verify`, minimum 8 | `AuthController.php:1230,2530,1730,3180` |
| Codes 2FA/OTP hachés avec `password_hash`, usage unique, 10 min | `AuthController.php:1348-1350,1288-1290` |
| Codes de confirmation comparés en temps constant, expirés, limités | `AuthController.php:2909,2920,2874` ; `3227,3237` |
| Aléatoire : uniquement `random_int` / `random_bytes` | 14 occurrences ; `rand`/`mt_rand` : 0 ; `uniqid` : 1, pour un identifiant de journal |
| Connexion : même message pour « inconnu » et « mauvais mot de passe » | `AuthController.php:1605,1618` |
| SSO Apple : JWKS d'Apple, `iss`, `aud`, `sub` vérifiés | `SSOService.php:94-121` |
| SSO Google : `tokeninfo`, `iss`, `exp` vérifiés | `SSOService.php:204,250-265` (réserve §3.2) |
| Admin : rôle lu en base, pas dans le jeton | `AdminMiddleware.php:19-22` |
| Téléversements : taille 8 Mo, type par les octets (`finfo`), **ré-encodage GD complet** | `ImageStorageService.php:47,149-161` |
| Reçus : objets privés, URL signées V4 de 15 min, droit vérifié | `ImageController.php:219-229,254-270` |
| Scripts cron/campagne : `hash_equals`, refus si secret vide | `cron.php:26`, `campaign.php:24`, `community_refresh.php:26`, `seed_product_images.php:34` |
| Erreurs : détail masqué hors `dev`, journal sans corps ni en-têtes | `index.php:124-125`, `ErrorMiddleware.php:72-96` |
| SQL : aucune entrée utilisateur dans du SQL brut ; pas d'`eval`/`exec` dans `src/` | greps §1 |
| Secrets : aucun `.env`, clé privée ou compte de service suivi par git | `git ls-files` |
| Contrôle d'accès : espaces (`SpaceAccessService::assertPermission`), listes (`ListAccessService::check`), messages (403/404), demandes d'achat (filtrées par `space_id`) | `PurchaseRequestController.php:176-230`, `MessageController.php:18-60`, `ImageController.php:44-54` |
| Application : jetons dans `flutter_secure_storage` (`encryptedSharedPreferences`), `allowBackup="false"`, ATS TLS 1.2 sans exception HTTP, hôte des liens profonds vérifié, aucun `badCertificateCallback`, aucune WebView | `token_store.dart:14`, `AndroidManifest.xml:45`, `Info.plist` (ATS), `deep_link_handler.dart:329` |
| Site : rien ne se charge avant consentement, UTM en `sessionStorage` bornés à 100 caractères | `ConsentGate.tsx`, `utm.ts:48` |

---

## 6. Ce qui n'a pas été vérifié, et pourquoi

- **La configuration réelle du serveur de production** (`.htaccess` en place, `APP_ENV`, `CRON_SECRET` défini, droits du dossier `storage/`) : aucune connexion à la prod, par votre règle. Le §4 dit ce que le déploiement *devrait* y mettre.
- **Les suites de bout en bout de l'API** (`api/scripts/test_*.php`, 280 contrôles) : elles exigent un serveur local lancé ; leur dernier passage, à la fin de la phase 6, était à 0 échec. Non relancées ici.
- **`npm run build`** : vert à la fin de la phase 6, non relancé ; `tsc` l'a été.
- **Le comportement sur appareil** (iOS/Android réels) : hors de portée d'une lecture de code.

---

## 7. Ordre de traitement suggéré

1. **§2.1** — limites par compte sur `verification_code` et `two_factor_verify` (une heure de travail, ferme les deux attaques concrètes), puis mandataires de confiance pour `getClientIP`.
2. **§2.3** — limiter le retour anonyme (protège le quota Brevo dès aujourd'hui).
3. **§2.4 + §3.1** — retirer `/test`, `/test-json`, et passer `/campaign/preview` en admin.
4. **§2.5** — remplacer les 90 `$e->getMessage()` par un message générique (mécanique, à faire en une passe).
5. **§2.2** — mettre à jour Next.js, puis réparer le lint (§3.6).
6. Le reste de §3, au fil de l'eau.

---

## 8. Corrections appliquées — état par constat

Tout ce qui est marqué **corrigé** l'a été dans le code, puis vérifié par les outils : `php -l` 0 erreur, 227 routes → 227 gestionnaires, `flutter analyze` 0 problème, **349 tests Flutter**, **11 suites E2E API** (dont celles qui touchent l'authentification) toutes vertes, `tsc` 0 erreur, **`next lint` 0 erreur**, `next build` réussi, **`npm audit` : 0 vulnérabilité** (production et développement).

| Constat | État | Ce qui a été fait |
|---|---|---|
| §2.1 IP falsifiable | **corrigé** | Nouveau `api/src/Services/ClientIp.php` : `X-Forwarded-For` n'est cru que si la requête vient d'un mandataire — déclaré dans `TRUSTED_PROXIES`, ou, à défaut, reconnu par son adresse privée — et lu de **droite à gauche**. Les quatre lecteurs d'IP (`AuthController`, `ContactController`, `AccountDeletionController`, `SharedListController`) passent par lui. **Et surtout** : plafonds **par compte** sur `verification_code`, `two_factor_verify`, `admin_otp_verify` (ces deux derniers n'étaient même pas déclarés dans `LIMITS` — `checkIPLimit` répondait « autorisé » sans compter) et `resend_verification`. Tests : `scripts/test_client_ip.php` (20), `scripts/test_plafonds.php` (39). Doc : `api/README.md`. |
| §2.2 Next.js 13.5.1 | **corrigé** | `next` 15.5.28 (ligne corrigée), React 19.1, `eslint-config-next` 15.5.28. Trois pages à `params` passées en asynchrone, `JSX` importé explicitement. Outillage déplacé en `devDependencies`, `react-day-picker`/`zod`/`calendar.tsx` (jamais importés, et le premier bloquait toute résolution) retirés, `axios`/`recharts`/`vaul` à jour, `overrides` sur `lodash` et `postcss`. Résultat : **0 vulnérabilité**. |
| §2.3 Retour anonyme sans limite | **corrigé** | `contact_feedback` : 5 / h / IP, 3 / h / adresse, 30 / h au total ; pot de miel `website` vérifié côté serveur (réponse de succès silencieuse). |
| §2.4 XSS `/campaign/preview` | **corrigé** | Route déplacée dans le groupe admin (`/campaigns/preview`, `AdminMiddleware`), `htmlspecialchars` sur le prénom dans le gabarit — qui sert aussi aux vrais envois. |
| §2.5 90 `$e->getMessage()` | **corrigé** | 87 réponses réécrites : message générique au client, `error_log(__METHOD__ …)` côté serveur (60 ajoutés là où il n'y en avait pas). Les 3 `InvalidArgumentException` d'`ImageController` sont conservées : leur message est écrit pour la personne (« image trop lourde »). |
| §3.1 Routes de test | **corrigé** | `/test` et `/test-json` supprimées. |
| §3.2 Repli d'audience Google | **corrigé** | Branche retirée ; seuls les identifiants de `GOOGLE_CLIENT_IDS` passent. |
| §3.3 `limit` non borné | **corrigé** | `min(max(…, 1), 100)` sur les 5 lectures. |
| §3.4 Jetons dans les journaux | **corrigé** | Quatre lignes réécrites : la longueur est journalisée, jamais la valeur. |
| §3.5 `cleanup()` jamais appelé | **corrigé** | Tâche 14 de `cron.php`, à chaque passage. |
| §3.6 Lint du site | **corrigé** | Avec Next 15 la configuration est valide ; **27 erreurs** trouvées et corrigées en typant (`Parameters<typeof t>[0]`, fenêtre `gtag` typée, `Record<string, unknown>`, alias de type) plutôt qu'en désactivant les règles. |
| §3.7 Dépréciation PHP 8.4 | **corrigé** | `?array $errors = null`. |
| §4 Informations | inchangé | Rien à corriger ; `AdminController.php:161` reste tel quel, sciemment. |

**Au passage** : `scripts/test_suppression_compte.php` calculait une date avec `NOW()` de MySQL et la comparait à `date()` de PHP — deux fuseaux différents, et un échec garanti autour de minuit. La date est désormais calculée en PHP.

**Non rejoué** : `scripts/test_spaces_e2e.php` exige les comptes locaux `ali@gmail.com` / `admin@gmail.com` avec leurs mots de passe par défaut (`E2E_PWD_A` / `E2E_PWD_B` sinon) ; les mots de passe locaux ont changé, la suite s'arrête à la connexion. Ce n'est pas une régression — aucun fichier qu'elle couvre n'a été modifié.

**De votre côté** : si l'hébergeur documente l'adresse de son répartiteur, la mettre dans `TRUSTED_PROXIES` ; sinon la détection par adresse privée fait le travail. Déployer l'API et le site ensemble : le formulaire de contact du site parle à la nouvelle route limitée, et `/campaign/preview` n'existe plus en public.
