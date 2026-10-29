# API EpiList

PHP 8.4 · Slim 4 · Eloquent · MySQL 8.

## Stockage des images

Les images vivent dans un bucket Google Cloud Storage, et **pas toutes au
même régime** :

| Dossier     | Visibilité | Ce qui est gardé en base |
|-------------|-----------|---------------------------|
| `avatars/`  | publique  | l'URL (`users.avatar_url`) |
| `items/`    | publique  | l'URL (`list_items.image_url`) |
| `receipts/` | **privée** | la **clé** de l'objet (`list_receipts.image_path`) |

Un reçu porte le magasin, la date et les montants. Il était téléversé en
lecture publique : l'URL suffisait à le lire, sans compte et sans jeton.
Une URL non devinable n'est pas une URL privée — elle fuit par un partage
d'écran, un presse-papier, un journal de serveur mandataire. Depuis la
migration `015_recus_prives.sql`, l'objet reste privé et ne s'ouvre que
par une URL signée de quinze minutes, délivrée par
`GET /shopping-lists/{listId}/receipts/{receiptId}/image-url` à qui a le
droit de voir la liste.

### Variables d'environnement

| Variable | Défaut | Rôle |
|---|---|---|
| `GCS_BUCKET` | `epilist-storage` | nom du bucket |
| `GCS_BUCKET_LOCATION` | `northamerica-northeast1` | région **attendue** du bucket |
| `GCS_KEY_BASE64` | — | clé du compte de service, JSON encodé en base64 |

### La région doit être canadienne

Le site annonce que les données restent au Canada. Cette phrase n'est
vraie que si le bucket est dans l'une des deux régions canadiennes de
Google Cloud Storage :

- `northamerica-northeast1` — Montréal
- `northamerica-northeast2` — Toronto

**Le code ne peut pas déplacer un bucket existant.** `GCS_BUCKET_LOCATION`
déclare donc où le bucket *doit* être, et sert à vérifier :

```bash
php scripts/make_receipts_private.php     # dit la région réelle et la compare
```

Si la région réelle n'est pas canadienne, la seule façon d'y remédier est
de créer un nouveau bucket dans la bonne région et d'y recopier les
objets — Google ne déplace pas un bucket. Tant que ce n'est pas fait, la
phrase du site doit rester masquée.

Lire la région réelle demande la permission `storage.buckets.get`. Sans
elle le script le dit, et renvoie à la console Google Cloud.

## Suppression de compte

Trois portes, **un seul service** : `App\Services\AccountDeletionService`.

| Porte | Chemin |
|---|---|
| Dans l'application | `POST /auth/request-account-deletion` puis `POST /auth/confirm-account-deletion` (code à six chiffres, 2 h) |
| Depuis le site | `POST /account-deletion/request` puis `GET /account-deletion/confirm/{token}` (lien à usage unique, 1 h) |
| Rattrapage | `scripts/backfill_deleted_accounts.php` |

Ce que fait la suppression, immédiatement :

1. les listes et espaces **partagés** changent de main — le membre actif
   le plus ancien qui peut les administrer. Une liste dont les seuls
   autres membres sont en lecture seule est détruite : personne ne peut
   l'entretenir ;
2. tout le reste de ce qui lui appartient est détruit (listes, articles,
   reçus, budgets, inventaire, historique, habitudes, préférences,
   appareils, jetons de rafraîchissement, liens SSO) ;
3. les **messages de clavardage** restent, signés « Utilisateur
   supprimé » — les retirer trouerait la conversation des autres ;
4. ses images partent du stockage (reçus, photos d'articles, avatar) ;
5. la ligne `users` est vidée : courriel remplacé par
   `deleted_user_{id}@deleted.local`, empreinte du mot de passe, avatar,
   codes, jetons et deuxième étape effacés, `anonymized_at` posée.
   **L'ancienne adresse redevient disponible** et peut se réinscrire.

La ligne vide quitte la base à la **purge des trente jours** (`cron.php`,
tâche 12). Comme tous les scripts destructeurs, la purge est en mode
constat par défaut : il faut `PURGE_APPLY=true` dans `.env`, ou
`--apply` en ligne de commande.

Un jeton d'accès déjà émis vit une heure : `JwtMiddleware` vérifie à
chaque appel que le compte existe encore, sinon un compte supprimé
continuerait de travailler jusqu'à soixante minutes après son départ.

### L'utilisateur réservé

La migration `016_suppression_compte.sql` crée une ligne
`deleted@deleted.local`, qui porte les messages des comptes supprimés.
Elle est nécessaire : `list_messages.user_id` est en `ON DELETE
CASCADE`, donc purger l'auteur emporterait ses messages. Elle ne peut
pas servir à se connecter (`password_hash` NULL, `is_active = 0`) et
**ne doit jamais être supprimée**.

### Révocation Sign in with Apple : pas en place

Apple demande, à la suppression d'un compte créé avec Sign in with
Apple, d'appeler `POST https://appleid.apple.com/auth/revoke`. Ce n'est
**pas faisable avec la configuration actuelle**, et voici exactement ce
qui manque :

1. **La clé privée Apple** (`.p8`) — Apple Developer → Certificates,
   Identifiers & Profiles → Keys → une clé avec « Sign in with Apple »
   activé. Il faut aussi le **Key ID** (10 caractères, affiché à la
   création) et le **Team ID** (en haut à droite du compte développeur).
   Le `client_secret` d'Apple est un JWT ES256 signé avec cette clé.
2. **Un jeton de rafraîchissement Apple**, et c'est le vrai blocage :
   `/auth/revoke` révoque un jeton, pas un identifiant. Ce jeton
   s'obtient en échangeant l'`authorizationCode` de la connexion contre
   `/auth/token`, dans l'heure. Or l'application envoie cet
   `authorizationCode` à Firebase
   (`app/lib/services/sso_service.dart:566`), jamais à cette API :
   aucun jeton de rafraîchissement n'existe de notre côté.

Il faudrait donc : transmettre l'`authorizationCode` à l'API à la
connexion Apple, l'échanger, chiffrer et stocker le jeton de
rafraîchissement obtenu, puis l'appeler à la suppression. Tant que ce
n'est pas fait, le rapport de suppression porte
`apple => non_configure`, et la suppression se fait quand même : le
compte EpiList part entièrement, c'est le lien côté Apple qui subsiste.

## Scripts

Tous les scripts qui touchent à des données existantes sont en
**`--dry-run` par défaut** : ils listent et comptent, sans rien écrire.
Il faut `--apply` pour qu'ils agissent.

| Script | Rôle |
|---|---|
| `scripts/make_receipts_private.php` | retire l'accès public des photos de reçus déjà téléversées |
| `scripts/check_routes.php` | vérifie que chaque route pointe sur un contrôleur existant |
| `scripts/backfill_deleted_accounts.php` | anonymise les comptes « supprimés » d'avant, restés entiers en base |
| `scripts/test_recus_prives.php` | la photo d'un reçu n'est lisible que par qui a accès à la liste |
| `scripts/test_suppression_compte.php` | « supprimer mon compte » supprime le compte, et n'emporte pas le travail des autres |

## Migrations

Dans `migrations/`, numérotées, idempotentes, à jouer dans l'ordre. Une
migration se colle **en entier** dans phpMyAdmin : les blocs
`SET @c := … ; PREPARE … EXECUTE` utilisent des variables de session, et
une exécution ligne par ligne les perd.
