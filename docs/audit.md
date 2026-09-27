# Audit complet — EpiList

Date : 27 septembre 2026. Périmètre : `api/` (PHP 8.4 / Slim 4), `app/` (Flutter 3.47), `web/` (Next.js 13), base MySQL locale, dépôt git et déploiement.
Méthode : trois audits parallèles (sécurité API, qualité Flutter, web + infra) + audit BD direct ; les 4 constats **critiques** ont été re-vérifiés ligne à ligne avant publication. Les références `fichier:ligne` sont cliquables depuis l'éditeur.
Complète l'étude `docs/faisabilite-rayon-foyer.md` (contrôle d'accès, pile hors ligne, schéma), dont les constats restent valables et ne sont pas répétés en détail ici.

---

## Verdict

L'application est fonctionnelle et bien fournie, mais elle a **4 failles critiques de sécurité côté API** (dont un contournement complet de l'authentification SSO), une **hygiène de production dangereuse** (scripts d'admin appelables par URL sans mot de passe), et **zéro test automatisé** sur les trois composants. Rien n'est irrécupérable : le socle (Slim + Eloquent, BLoC, validation Valitron, JWT bien configuré, aucune injection SQL trouvée) est sain. La priorité absolue est la sécurité, pas les fonctionnalités.

---

## 1. CRITIQUE — à corriger avant toute autre chose

| # | Faille | Preuve | Conséquence |
|---|---|---|---|
| C1 | **SSO Apple : signature du token jamais vérifiée** | `api/src/Services/SSOService.php:90` — « Décoder le payload sans vérification de signature » ; seuls iss/aud/exp/sub du payload (forgeables) sont contrôlés | N'importe qui connaissant l'email d'un compte peut fabriquer un token et **se connecter à ce compte** via `/auth/sso/apple/login` (route publique) |
| C2 | **SSO Google : fallback local sans signature** | `SSOService.php:309-390` ; atteint dès que `tokeninfo` renvoie une erreur (`ClientException` ⊂ `RequestException`, `:290-297`) — donc un token **rejeté par Google** est ensuite accepté localement | Même prise de compte que C1, côté Google |
| C3 | **Brute force du code de changement de mot de passe** | `AuthController.php:2534-2596` (`verifyPasswordChangeCode`) : **aucun** rate limiting ni compteur d'échecs (vérifié : 0 appel au RateLimiter), code à 6 chiffres généré par `mt_rand()` | Réinitialisation du mot de passe d'autrui = prise de compte |
| C4 | **`public/campaign.php` sans aucune authentification** | Vérifié : aucune garde auth/secret/CLI dans le fichier ; en prod un GET anonyme déclenche l'envoi de la campagne à toute la base et la réponse **liste les emails des destinataires** | Spam massif de tes utilisateurs + fuite de données personnelles |

Dans la même famille, juste derrière :

- **C5** — Le déploiement FTP envoie **tout `api/`** vers `/www/api.epilist/`, et `setBasePath('/api.epilist/public')` (`public/index.php:88-90`) indique que le docroot est **au-dessus** de `public/`. Si c'est confirmé, sont téléchargeables/exécutables par URL : `api/.env` (secrets JWT, DB, Brevo), `service-account.json` (Firebase Admin), `migrations/*.sql`, `generate_test_data.php`, `run_migration_language.php`, tous les `test_*.php`. **À vérifier sur le serveur immédiatement ; si exposés, faire tourner tous les secrets.**
- **C6** — `public/cron.php` et `public/ debug_completion_notifications.php` : appelables par URL sans secret → un anonyme déclenche des vagues de notifications push.
- **C7** — Les routes `/campaigns/*` sont dans le groupe JWT mais **aucune notion d'admin n'existe** (pas de colonne `role`, aucun middleware) : n'importe quel compte inscrit peut envoyer la campagne à toute la base (`CampaignController.php`).

### Correctifs C1-C7 (ordre d'exécution conseillé)

1. Supprimer `public/campaign.php`, ` debug_completion_notifications.php`, `test_budget_direct.php` ; protéger `cron.php` par un secret (`CRON_KEY` en query, comparé à l'env) ou une garde `php_sapi_name() === 'cli'`.
2. Exclure du workflow FTP (`.github/workflows/deploy-api.yaml`) tout sauf `public/`, `src/`, `vendor/` ; vérifier le docroot ; si `.env`/`service-account.json` étaient exposés → rotation des secrets.
3. Rate limiting + compteur d'échecs + invalidation du code sur `verifyPasswordChangeCode` ; `random_int()` et `hash_equals()` pour tous les codes.
4. Vérification JWKS des tokens Apple (la lib `firebase/php-jwt` déjà installée sait le faire avec les clés publiques d'Apple) ; **supprimer** le fallback Google local.
5. Colonne `users.role` + middleware admin sur `/campaigns/*`, `/devices/debug`, `/devices/test-*`.

---

## 2. Sécurité API — élevée et moyenne

- **Pas de rate limiting sur `/auth/login`** (`RateLimiter.php:13-31` ne couvre que l'inscription et 2 autres cas) → brute force illimité. Élevée.
- **Tokens irrévocables** : pas de table de refresh tokens, pas de `jti` ; `logout()` n'invalide rien ; la rotation glissante rend la session éternelle ; `refresh_token()` ne vérifie pas `is_active` (`AuthController.php:1867-1920`). Élevée.
- **Fuites d'erreurs** : `addErrorMiddleware(true, true, true)` en prod (`public/index.php:105`) + de nombreux contrôleurs renvoient `$e->getMessage()` au client. Élevée.
- Route publique `GET /test-auth-header` renvoie tous les headers reçus, body et query (`AuthController.php:1968-1991`). À supprimer.
- CORS : `Allow-Origin: *` combiné à `Allow-Credentials: true` (`CorsMiddleware.php:28-31`) ; aucun header de sécurité (HSTS, nosniff, X-Frame-Options, CSP). Moyenne.
- `$fillable` trop larges : `User` expose `password_hash`, `email_verified`, `is_active`… (`User.php:21-45`) ; `SharedList` expose `owner_id`, `share_token`, `permission`. Défense en profondeur. Moyenne.
- Mot de passe : `lengthMin 6` seul ; pas de max (bcrypt tronque à 72 octets). Moyenne.
- Logs : préfixes de tokens et emails en clair (`AuthController.php:64-65`, `SSOService.php:164,194,269`) ; `DebugMiddleware` (dump complet des échanges Apple) présent mais non branché — à supprimer. Moyenne.
- 7 routes déclarées → méthodes inexistantes = 500 : `/auth/reset-link`, `/auth/validate-reset-token`, `/auth/reset-password`, `/devices/debug`, `/devices/analyze`, `/devices/test-advanced`, `PUT /devices/real-token`. S'ajoutent aux **7 handlers de partage manquants** déjà documentés dans `docs/faisabilite-rayon-foyer.md` §2.3 (`revokeShare`, `updateSharePermission`, `getSharedLists`…) que l'app appelle réellement.
- Points sains vérifiés : aucun secret dans l'historique git, aucune injection SQL (tous les `raw` sont statiques), bcrypt via `PASSWORD_DEFAULT`, JWT à algorithme forcé et expiration vérifiée, dépendances Composer à jour, tokens de partage/désabonnement en `random_bytes`.

---

## 3. Application Flutter

### Élevée
- **861 `print()` actifs en release** (contre 295 `debugPrint`), dont des fuites directes : `auth_service.dart:729` imprime **la réponse login complète avec access et refresh tokens**, `auth_service.dart:218` la réponse SSO Google, `user.dart:132` l'email. → règle `avoid_print` en erreur + logger neutralisé en release.
- **3 services contournent le Dio partagé** (donc pas de refresh automatique du token) : `category_service.dart`, `email_preference_service.dart`, `offline_sync_service.dart`. Quand le token expire : exception générique pour l'un, échec silencieux de la synchro pour l'autre — alors que le même appel via Dio serait rejoué de façon transparente.
- **Perte de données hors ligne** : `offline_sync_service.dart:273` — l'action `update_profile` est retirée de la file **sans être envoyée** (`return true` sur un TODO). S'ajoute aux actions catégories jamais rejouées et aux ids temporaires négatifs jamais remappés (détail dans `docs/faisabilite-rayon-foyer.md` §2.5).
- **Zéro test** : `test/widget_test.dart` est le template du compteur avec le `pumpWidget` commenté — il ne teste rien. Cibles prioritaires : AuthBloc, TokenRefreshInterceptor, OfflineSyncService.
- Son de notification manquant : `budget_notification_service.dart:66` référence `res/raw/budget_alert` qui n'existe pas.

### Moyenne
- 47 × `use_build_context_synchronously` (usage de `context` après `await` sans check `mounted`) — risque de crash réel (`main.dart:540`, `email_verification_screen.dart`, `login_screen.dart:578-586`…).
- Fichiers `.arb` avec **clés dupliquées** (16 en EN, 21 en FR — dont `days`, `offlineMode`, `cancel`) : la dernière définition écrase silencieusement la première. ~40 chaînes en dur hors l10n, dont l'écran `share_invitation_screen.dart` quasi entièrement en anglais non traduit.
- Dépendances : Firebase (core 3→4, messaging 15→16), `flutter_local_notifications` 19→22 (3 majeures), `google_sign_in` 6→7, `sign_in_with_apple` 6→8 — migrations cassantes à planifier ensemble.
- Performance : avatars via `Image.network` sans cache (`home_app_bar.dart:506`), une seule `key` sur 22 `ListView.builder`, 4 `BlocBuilder` sans `buildWhen` sur `budget_screen`, polling chat 5 s jamais suspendu en arrière-plan.
- ~40 `catch` silencieux (les pires : SSO `auth_service.dart:554,594`, synchro `offline_sync_service.dart:328-331`, les 10 catch de `budget_notification_service.dart`).
- `flutter analyze` : 1245 issues (0 erreur) ; `analysis_options.yaml` est le modèle par défaut sans règle renforcée.
- Structure : `auth_bloc.dart` 1601 lignes (login email + Google + Apple + refresh + cache + langue) à découper ; widgets de test livrés dans `lib/` ; 127 `withOpacity` dépréciés.

---

## 4. Site web (Next.js)

- **Analytics sans consentement** : GA4 + Meta Pixel + Hotjar chargés inconditionnellement (`web/app/layout.tsx:219-223`), aucune bannière cookies dans tout `web/` ; Hotjar fait en plus un `identify` par visiteur (`Hotjar.tsx:26-38`). Non conforme RGPD et Loi 25 (Québec). Élevée (juridique).
- **Formulaire de contact factice** : `ContactContent.tsx:44-58` — un `setTimeout(2000)` simule l'envoi, rien ne part nulle part, alors que la page promet une réponse sous 24 h. À brancher sur `/contact/feedback-anonymous` de l'API (qui existe) + honeypot. Élevée (confiance utilisateur).
- **Next.js 13.5.1** : CVE connues sur la branche (dont contournement de middleware CVE-2025-29927, corrigé en 13.5.9). Minimum sans migration : 13.5.11 ; idéalement 14/15. `axios` ≥ 1.12. Élevée.
- Désabonnement déclenché automatiquement par **GET** au chargement (`unsubscribe/[token]/page.js:18-22`) : un antivirus/préchargeur de liens d'email désabonne l'utilisateur à son insu → passer à une confirmation par clic (POST). URL API de secours en dur `m2atodev.com` dans la page. Moyenne.
- SEO : placeholder `VOTRE_CODE_GOOGLE_SEARCH_CONSOLE` en prod (`layout.tsx:130`) ; hreflang `en-CA` vers `/en` qui n'existe pas (`layout.tsx:143`) ; `aggregateRating: 4.9` invérifiable dans les données structurées (`lib/schema.ts:39-41`) — risque de pénalité ; redirections dupliquées middleware/next.config ; `/share` et `/unsubscribe` sans `noindex`. Moyenne.
- Page `/share/[token]` : redirige les desktops non-Apple vers l'App Store iOS et rend `null` sans contenu. Faible.

---

## 5. Infrastructure et dépôt

- **Déploiement : chaque push sur `master` part en FTP prod sans aucun test, lint ni staging** (`.github/workflows/deploy-api.yaml`, seul workflow). Ajouter au minimum : `php -l`/phpstan + exclusions de fichiers avant le deploy, et passer le transfert en FTPS (paramètre `protocol` de l'action).
- **`api/composer.lock` est gitignoré** → chaque déploiement résout des versions fraîches, non reproductibles. Même problème avec `app/pubspec.lock` (pour une application, il doit être versionné). Élevée.
- Migrations SQL appliquées à la main (`mysql <` documenté dans `CHECKLIST_DEPLOIEMENT.md`) sans outil ni suivi → dérive schéma/code garantie à terme. Moyenne.
- **~24 fichiers `.md` à la racine**, quasi tous des journaux de fin de tâche redondants figés sur v1.1.4-1.1.6, pendant que `README.md` fait 2 lignes → déplacer les utiles dans `docs/`, supprimer le reste, écrire un vrai README. `docs/`, `launch.sh`, `stop.sh` ne sont pas encore commités.
- `.gitignore` : 21 fichiers `.dart_tool/` racine encore trackés (suppression en attente de commit), pas d'entrée `/.dart_tool/` ; `*.jar`/`*.zip` globaux (piège si `android/` est re-versionné : `gradle-wrapper.jar`).
- Cron : `public/cron.php` conçu pour un appel horaire, aucune crontab versionnée, aucune authentification (voir C6).

---

## 6. Base de données

- **4 tables cœur en latin1** (`users`, `shopping_lists`, `list_items`, `shared_list`) contre utf8mb4 partout ailleurs — les accents y sont fragiles (« Métro » stocké différemment selon la table). Conversion à planifier avec sauvegarde.
- **`shared_list` sans index** sur `list_id` ni `shared_with_user_id` (seulement PRIMARY et `share_token`), alors que c'est la table interrogée par **toutes** les vérifications d'accès (~38 sites). Deux `ADD INDEX`, gain immédiat.
- `email_marketing_consent` par défaut à `1` : consentement marketing présumé à l'inscription — à passer en opt-in explicite (LCAP canadienne / RGPD).
- `budgets.list_id` sans contrainte FK dans la base locale ; `shopping_lists.user_id` nullable ; ids en `INT` signés (voir faisabilité §2.1 pour l'impact sur les évolutions).
- Rappel du bug métier majeur documenté dans la faisabilité : `PATCH /items/{id}/toggle` **inverse** l'état côté serveur en ignorant la valeur envoyée (`ListItemController.php:560`) → deux cocheurs hors ligne se neutralisent.

---

## 7. Plan d'action priorisé

### Semaine 1 — sécurité (bloquant)
1. C4/C6 : supprimer/protéger `campaign.php`, `cron.php`, scripts de debug de `public/` ; exclusions dans le workflow FTP.
2. C5 : vérifier le docroot prod ; rotation des secrets si `.env` exposé.
3. C1/C2 : vérification JWKS Apple, suppression du fallback Google.
4. C3 : rate limiting + `random_int` + `hash_equals` sur les codes ; rate limiting login dans la foulée.
5. Flutter : purger les `print()` de tokens (`auth_service.dart:218,729` en premier) et publier une mise à jour.

### Semaines 2-3 — fiabilité
6. Corriger `toggle` (valeur absolue), la synchro profil hors ligne, migrer les 3 services vers Dio.
7. Écrire les 7 handlers de partage manquants + les 7 routes mortes ; premiers tests PHPUnit (auth, accès aux listes) et tests Flutter (AuthBloc, interceptor).
8. Versionner `composer.lock`/`pubspec.lock` ; CI minimale (lint + tests) avant le deploy FTP ; FTPS.
9. Admin : colonne `role` + middleware sur `/campaigns/*` ; table de refresh tokens révocables.

### Mois suivant — conformité et qualité
10. Bannière de consentement web + opt-in marketing en BD ; formulaire de contact réel ; Next 13.5.11 puis migration 14/15.
11. Index `shared_list`, conversion utf8mb4, dédoublonnage des `.arb`, correction des 47 `use_build_context_synchronously`, `res/raw/budget_alert`.
12. Ménage : `.md` racine → `docs/`, README digne de ce nom, découpage `auth_bloc.dart`, mises à jour Firebase/google_sign_in groupées.

---

## Ce qui n'a pas pu être vérifié

- **Le serveur de production** : docroot réel (C5), version de `SharedListController.php` déployée, présence effective des scripts de test en ligne, config du cron OVH. Tests à faire : `curl -I https://m2atodev.com/api.epilist/.env`, `.../api.epilist/public/campaign.php` (avec précaution — un GET déclenche l'envoi !), `GET /shared-lists` avec un token valide.
- Les chiffres `npm audit` (non lancé) ; les CVE Next.js citées de mémoire par l'agent — la recommandation 13.5.11 reste valable dans tous les cas.
- La base de production (audit fait sur la locale).
