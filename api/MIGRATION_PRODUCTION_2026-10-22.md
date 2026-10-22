# Mise en production — 22 octobre 2026

Migration **012 (planche Version B)** : six manques de données comblés,
plus la refonte complète du thème côté application.

> **L'ordre n'est pas négociable.** Le code de l'application lit des
> colonnes et des tables que la base de production n'a pas encore. Si le
> code part avant le SQL, les écrans **Mes magasins**, **Planifier mes
> repas**, **Alertes de prix** et **Membres d'un espace** répondront 500.

---

## Ce que la migration ajoute

| Table | Ajout | Pour quoi |
|---|---|---|
| `stores` | `address`, `city`, `postal_code`, `latitude`, `longitude`, `opening_hours` | L'adresse et les horaires sur la carte d'un magasin |
| `store_favorites` *(nouvelle)* | — | L'étoile Favori, portée par le **membre** |
| `recipe_favorites` *(nouvelle)* | — | La grille de recettes favorites |
| `meal_plan_recipes` | `weekday`, `meal_slot` | « Lundi vert, Mardi jaune, Mercredi bleu » |
| `product_images` *(nouvelle)* | — | Le visuel d'un produit, partagé entre les écrans |
| `space_invitations` | `invitee_name`, `invitee_phone` | « Bonjour Sara » dans le courriel d'invitation |

**Aucune donnée existante n'est réécrite.** Les colonnes sont ajoutées
nulles, les tables sont vides à la création. Le seul `DROP` porte sur
`recipes.is_favorite`, une colonne que **seule la base de développement
a jamais eue** — une fausse route corrigée avant d'être poussée.

**Durée** : moins d'une minute. **Risque** : faible.

---

## Étape 0 — Sauvegarder

La sauvegarde `PRODUCTION_2026-10-01.sql` **ne contient pas de données**.
En prendre une vraie avant de commencer, avec les données :

- phpMyAdmin → onglet **Exporter** → méthode **personnalisée** →
  structure **et** données → compression gzip.

Sans cette sauvegarde, il n'y a pas de retour en arrière.

---

## Étape 1 — Vérifier les prérequis (ne modifie rien)

phpMyAdmin → base de production → onglet **SQL** → coller
`migrations/012_prerequis.sql` → **Exécuter**.

Le résultat se lit en quatre blocs :

- **A. PRÉREQUIS** — tant qu'une ligne porte `MANQUE`, **s'arrêter** :
  la migration nommée dans la colonne `detail` doit passer d'abord.
- **B. ÉTAT** — `déjà fait` partout veut dire que 012 est déjà passée ;
  il n'y a alors rien à faire à l'étape 2.
- **C. VOLUME** — combien de lignes sont concernées.
- **D. LIGATURES** — si une ligne porte `ATTENTION`, **me le dire avant
  de continuer** : des produits écrits avec « œ » ou « æ » changeraient
  de clé, et leur historique devrait être réindexé. (Zéro en
  développement.)

---

## Étape 2 — Jouer la migration

phpMyAdmin → onglet **SQL** → coller `migrations/012_planche_version_b.sql`
→ **Exécuter**.

Elle est **idempotente** : la rejouer ne casse rien et ne duplique rien.
Elle se termine par une ligne de vérification qui doit afficher :

```
magasin_6_colonnes = 6
table_favoris = 1
table_recettes_favorites = 1
colonne_fausse_route_restante = 0
repas_2_colonnes = 2
table_images = 1
invitation_2_colonnes = 2
```

Si un de ces chiffres diffère, **ne pas continuer**.

*Avec un accès SSH, au choix :*
`php scripts/run_migration.php migrations/012_planche_version_b.sql`

---

## Étape 2 bis — Vérifier que tout est là

phpMyAdmin → onglet **SQL** → coller `migrations/012_verification.sql`
→ **Exécuter**. Lecture seule, rejouable.

Il ne se contente pas de vérifier que les colonnes **existent** : une
table peut naître sans ses clés étrangères, une colonne avec le mauvais
type, un JSON en VARCHAR si le serveur MySQL est antérieur à 5.7. Tout
cela passe une vérification naïve et casse au premier enregistrement.

Lire la colonne `verdict`. La dernière ligne tranche :

```
colonnes et tables de la migration 012   13   13 sur 13   TOUT EST LA — le code peut partir
```

Tant qu'une ligne porte `ECHEC`, **ne pas pousser** : l'API lirait
quelque chose qui n'est pas là.

Le bloc **F** donne les comptes de lignes : ils doivent être identiques
à ceux du bloc **C** de `012_prerequis.sql`. La migration n'écrit
aucune donnée — un écart voudrait dire que quelque chose d'autre s'est
passé entre-temps.

---

## Étape 3 — Remonter les photos déjà prises

Rattache les photos des articles de liste au **produit**, pour que les
alertes de prix puissent les afficher.

**Sans accès SSH** — par URL, protégée par `CRON_SECRET` :

```
https://m2atodev.com/api.epilist/public/seed_product_images.php?key=LE_CRON_SECRET&dry=1
```

`dry=1` montre sans rien écrire. Retirer `&dry=1` pour l'exécuter.
La réponse donne `articles`, `posees`, `perimees`, `total`.

**Avec SSH** : `php scripts/seed_product_images.php`

Idempotent, rejouable. Facultatif : s'il n'y a aucune photo en
production, il ne fait rien, et rien ne casse.

---

## Étape 4 — Remettre l'application sur la production

```bash
cd app && bash scripts/check_release_config.sh --fix
```

`baseUrl` est une **constante compilée** : elle est figée dans le
binaire. Une build partie avec l'URL de développement ne joindra rien
chez les gens qui l'installent, et l'application ne le dira pas — elle
affichera des erreurs réseau, c'est tout.

Le dépôt, lui, porte déjà la production : cette étape ne concerne que la
**copie de travail**, donc les builds faites depuis cette machine.

À lancer **après** les étapes 1 à 3 : avant, l'application parlerait à
une base qui n'a pas encore les nouvelles colonnes.

---

## Étape 5 — Pousser (votre geste)

```bash
git push origin master      # = déploiement FTP de l'API
```

Puis vérifier, dans l'ordre :

1. `GET /stores` renvoie `address`, `opening_hours`, `is_favorite`
2. `GET /recipes` renvoie `image_url` et `is_favorite`
3. `GET /price-alerts` renvoie `image_url`
4. L'écran **Mes magasins** s'ouvre, l'étoile tient après rechargement
5. Le courriel d'invitation dit « Bonjour » suivi du prénom

---

## Si ça tourne mal

La migration n'écrit aucune donnée : la défaire revient à retirer ce
qu'elle a ajouté. Dans phpMyAdmin :

```sql
DROP TABLE IF EXISTS store_favorites;
DROP TABLE IF EXISTS recipe_favorites;
DROP TABLE IF EXISTS product_images;
ALTER TABLE stores
    DROP COLUMN address, DROP COLUMN city, DROP COLUMN postal_code,
    DROP COLUMN latitude, DROP COLUMN longitude, DROP COLUMN opening_hours;
ALTER TABLE meal_plan_recipes DROP COLUMN weekday, DROP COLUMN meal_slot;
ALTER TABLE space_invitations DROP COLUMN invitee_name, DROP COLUMN invitee_phone;
```

**Mais** l'API déployée les attend : ne défaire la base que si le code
revient aussi en arrière (`git revert`, puis redéploiement).

---

## Ce qui N'EST PAS dans cette mise en production

- **La distance aux magasins.** Les coordonnées sont stockées, la
  distance se calcule depuis la position du téléphone : il faut une
  permission de géolocalisation, donc une décision de produit.
- **L'invitation par SMS.** Le téléphone est enregistré, et le champ le
  dit en toutes lettres sous lui. Aucun fournisseur SMS n'est branché —
  c'est une dépense récurrente, pas une colonne.
