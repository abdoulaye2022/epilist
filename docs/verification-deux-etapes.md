# Vérification en deux étapes (2FA) par email — optionnelle

Livré le 2026-09-30. Migration : `api/migrations/add_two_factor_optin.sql`
(idempotente).

## Ce qui change

Avant, le 2FA était **imposé** aux comptes administrateur et
**indisponible** pour tous les autres. Désormais :

- c'est un **réglage par utilisateur**, désactivé par défaut ;
- chacun l'active s'il le souhaite, depuis son profil ;
- la méthode est **l'email** (code à 6 chiffres, 10 minutes, usage
  unique). Pas d'application d'authentification.

Les administrateurs existants **gardent** leur protection : la migration
met `two_factor_enabled = 1` sur les comptes `role = 'admin'` déjà en
place. Ils peuvent la désactiver eux-mêmes ensuite.

## API

| Route | Rôle |
|---|---|
| `GET /auth/2fa` | état du réglage du compte connecté |
| `POST /auth/2fa` `{enabled, password}` | activer / désactiver |
| `POST /auth/2fa/verify` `{email, code}` | 2ᵉ étape de connexion → jetons |
| `POST /auth/login` | renvoie `TWO_FACTOR_REQUIRED` **sans jeton** si activé |
| `POST /auth/admin/otp` | identique : jetons directs si le 2FA est inactif |

Le **mot de passe courant est exigé** pour activer OU désactiver : un
appareil laissé déverrouillé ne suffit pas à retirer la protection.

Le code vit dans `users.admin_otp_code` / `admin_otp_expires_at`
(colonnes existantes, réutilisées : elles ne sont plus réservées aux
administrateurs). Il est stocké **haché**, jamais exposé par l'API
(`$hidden`), consommé à la première vérification réussie.

## Application mobile

- Connexion : si le 2FA est actif, l'app ouvre l'écran « Vérification en
  deux étapes » (saisie à 6 chiffres, validation automatique à la
  6ᵉ touche, renvoi de code possible).
- Profil → Sécurité : tuile « Vérification en deux étapes » indiquant
  Activée/Désactivée ; le changement demande le mot de passe.
- 16 clés i18n fr/en.

## Web admin

La page de connexion passe directement au tableau de bord quand le
compte n'a pas le 2FA, et n'affiche l'étape du code que si le serveur
l'exige (`requestOtp` retourne désormais un booléen).

## En développement

Tous les emails (dont les codes) sont redirigés vers la boîte de test
par `MailSender` — voir le sujet `[DEV → vraie@adresse]`.

## Vérifié (E2E 195/195, 15 vérifications dédiées)

Réglage désactivé par défaut ; activation refusée sans mot de passe et
avec un mauvais mot de passe ; login challengé sans jeton ; mauvais code,
code rejoué et code expiré refusés ; bon code délivrant les deux jetons ;
désactivation ramenant la connexion à une étape ; admin avec et sans
2FA ; non-admin toujours refusé sur la route administrateur.

## Note de sécurité

Désactiver le 2FA d'un compte administrateur réduit sa protection à un
simple mot de passe. Le réglage est volontairement laissé au choix de
l'utilisateur, mais il reste recommandé de le garder actif sur les
comptes d'administration.
