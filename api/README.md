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

## Scripts

Tous les scripts qui touchent à des données existantes sont en
**`--dry-run` par défaut** : ils listent et comptent, sans rien écrire.
Il faut `--apply` pour qu'ils agissent.

| Script | Rôle |
|---|---|
| `scripts/make_receipts_private.php` | retire l'accès public des photos de reçus déjà téléversées |
| `scripts/check_routes.php` | vérifie que chaque route pointe sur un contrôleur existant |
| `scripts/test_recus_prives.php` | la photo d'un reçu n'est lisible que par qui a accès à la liste |

## Migrations

Dans `migrations/`, numérotées, idempotentes, à jouer dans l'ordre. Une
migration se colle **en entier** dans phpMyAdmin : les blocs
`SET @c := … ; PREPARE … EXECUTE` utilisent des variables de session, et
une exécution ligne par ligne les perd.
