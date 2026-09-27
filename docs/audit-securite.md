# Audit de sécurité — EpiList (app mobile + web + API)

> Date : 27 septembre 2026. Second audit de la journée : le premier
> (docs/audit.md) couvrait l'API historique ; celui-ci couvre l'app
> mobile, le site web (marketing + espace admin) et tout ce qui a été
> ajouté depuis (intelligence prix, intelligence du foyer, espace
> admin, versions d'app).
>
> ✅ = corrigé pendant l'audit · ⚠️ = à ta charge (prod) · 📋 = recommandé

---

## 1. Corrigés pendant l'audit

### ✅ CRITIQUE — Jetons d'accès valides 1 AN
`JWT_EXPIRATION=31536000` (le commentaire disait « 1 heure » mais la
valeur était 365 jours), refresh idem. Un jeton volé (téléphone perdu,
log, proxy) restait utilisable un an, sans aucun moyen de le révoquer.
**Corrigé en local** : accès 1 h, refresh 30 jours. Le
TokenRefreshInterceptor de l'app prend le relais silencieusement.
⚠️ **Prod** : reporter ces deux valeurs dans le .env prod via FTP —
mais teste d'abord en local pendant une session > 1 h pour valider le
flux de refresh, qui n'a presque jamais servi avec des jetons d'un an.

### ✅ ÉLEVÉ — Scripts tiers chargés sur /admin
Google Analytics, le pixel Facebook et Hotjar étaient injectés sur
TOUTES les pages, espace admin compris. Conséquences : (1) le jeton
admin vit en localStorage, accessible à tout script de la page — un
script tiers compromis = compte admin compromis ; (2) Hotjar enregistre
les sessions : les écrans admin (emails et données des utilisateurs)
partaient chez Hotjar. **Corrigé** : `TrackingGate` ne rend aucun
script tiers sous `/admin`.

### ✅ ÉLEVÉ — Sauvegardes Android non désactivées
`android:allowBackup` absent = activé par défaut : les
SharedPreferences (jetons d'accès et refresh, profil en cache)
partaient dans les sauvegardes Google/adb, extractibles sur certains
appareils. **Corrigé** : `android:allowBackup="false"`.

### ✅ MOYEN — Mot de passe minimum 6 caractères
Passé à 8 (inscription, changement, réinitialisation). N'affecte que
les nouveaux mots de passe.

### ✅ MOYEN — Redirections incohérentes
`next.config.mjs` redirigeait `/features`, `/help`… vers les pages
FRANÇAISES (et passait avant le middleware qui visait les pages
anglaises). Aligné sur `/en/...`.

### ✅ (audit précédent, rappel) 
Signatures SSO, brute force login (RateLimiter), rôle admin serveur,
secrets cron, uploads d'images re-rasterisés (anti-malware), header
Authorization préservé, garde-fou `minimum_version > current_version`.

---

## 2. Vérifié sain (pas d'action)

| Point | Constat |
|---|---|
| IDOR sur les nouveaux endpoints | PriceController (canEditList/canReadList), inventaire/prédictions/récurrentes/repas (filtrés par auth_id), testés en direct : 403/404 inter-utilisateurs |
| Espace admin API | JwtMiddleware + AdminMiddleware sur les 9 routes, testé (403 pour un non-admin) ; impossible de se rétrograder soi-même |
| Injection SQL | Tout passe par Eloquent/bindings ; les selectRaw n'interpolent que des constantes internes |
| Mass assignment | Listes `fillable` explicites, contrôleurs avec listes de champs |
| version-check public | Voulu (une app bloquée doit l'apprendre avant l'auth) ; ne divulgue que la version publiée |
| Cleartext Android | Non autorisé (défaut API 28+), baseUrl en HTTPS |
| Messages d'erreur | Détails uniquement si APP_ENV=dev ; les 500 vont dans api_error_logs (admin seulement) |
| Deep links de partage | Jetons validés côté serveur |
| Formulaire de contact | Honeypot + validation ; l'email cible est côté serveur |
| Web /admin | noindex + robots disallow ; pas de SSR des données |
| CORS `*` | Acceptable : auth par Bearer, pas de cookies → pas de CSRF |
| CSP | Absente, mais X-Frame-Options DENY + nosniff présents ; une CSP stricte casserait GA/FB/Hotjar — voir §3 |

---

## 3. Recommandé (non appliqué aujourd'hui)

### 📋 ÉLEVÉ — Jetons mobiles en clair (SharedPreferences)
Les jetons sont stockés en clair dans les préférences. `allowBackup=false`
réduit l'exfiltration, mais le standard est `flutter_secure_storage`
(Keychain iOS / Keystore Android). Migration à faire avec soin : lire
l'ancien emplacement une fois puis migrer, sinon tous les utilisateurs
sont déconnectés à la mise à jour. À planifier, pas à improviser.

### 📋 MOYEN — Pas de révocation de jetons côté serveur
Le logout est purement client (suppression locale). Avec l'accès à 1 h
c'est devenu un risque borné, mais une vraie révocation demanderait une
liste de refresh tokens en base (invalidables). À considérer si un
compte admin est un jour compromis.

### 📋 MOYEN — Espace admin : pas de 2FA, session en localStorage
Pour un admin solo c'est tolérable ; si l'équipe grandit : 2FA (TOTP)
et cookie httpOnly + SameSite plutôt que localStorage.

### 📋 FAIBLE — `version-stat` non authentifié
N'importe qui peut gonfler les compteurs updated/dismissed. Sans
conséquence (indicatifs, reset en un clic) — hérité du mécanisme
d'origine, assumé.

### 📋 FAIBLE — `image_url` du reçu importé non vérifiée
`POST /receipts/import` accepte une URL arbitraire (stockée, affichée
dans l'app). Quand l'upload de photo de reçu vers GCS sera branché,
restreindre au domaine `storage.googleapis.com/epilist-storage/`.

### 📋 FAIBLE — baseUrl unique dans AppConfig
L'URL API (ngrok en ce moment) est une constante commitée : penser à la
remettre en prod avant chaque build de release (ou passer par
`--dart-define`). Déjà mordu une fois dans l'historique du fichier.

---

## 4. Checklist prod au prochain déploiement

1. `.env` prod : `JWT_EXPIRATION=3600`, `JWT_REFRESH_EXPIRATION=2592000`
   (après validation du refresh en local).
2. Migrations phpMyAdmin : add_images, add_price_intelligence,
   add_household_intelligence, add_admin_space.
3. `GCS_BUCKET` + `GCS_KEY_BASE64` dans le .env prod.
4. Compte admin prod : `UPDATE users SET role='admin' WHERE email='…'`
   + mot de passe fort (pas Abc1234!).
5. Supprimer via FTP `public/test_budget_direct.php` et
   `public/debug_completion_notifications.php`.
6. `AppConfig.baseUrl` → URL prod avant le build de release.
