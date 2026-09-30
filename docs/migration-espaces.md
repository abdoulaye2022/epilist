# Migration des données vers les espaces

Règle : **aucune perte, aucune suppression, chaque étape additive et
rejouable**. Détail des tables : `docs/audit-espaces-epilist.md` §2 et §7.

## Phase 1 (faite)

`api/migrations/add_spaces.sql` :
- crée `spaces`, `space_members`, `space_invitations` ;
- backfill : un espace personnel par utilisateur existant + ligne
  membre `owner` — idempotent (revérifiable en le rejouant) ;
- les nouveaux comptes sont couverts par `Space::personalFor()`
  (création paresseuse au premier `GET /spaces`).

Aucune table métier modifiée : rollback = ne plus servir les routes
`/spaces` ; les données n'ont pas bougé.

## Patron pour chaque table métier (Phase 2+)

Ordre d'application prévu : `stores` (pilote, remplace le vestige
`household_id`), puis `shopping_lists`, `budgets`, `home_inventory`,
`recurring_lists`, `meal_plans`/`recipes`, enfin `purchase_history`
(volumineuse, sauvegarde SQL préalable obligatoire).

1. **Colonne** : `ALTER TABLE t ADD COLUMN space_id INT NULL` +
   `ADD COLUMN created_by_user_id INT NULL` (traçabilité §11) + index —
   gardés par `information_schema` comme les migrations existantes.
2. **Backfill** : `space_id = espace personnel de user_id`,
   `created_by_user_id = user_id`. Idempotent (`WHERE space_id IS NULL`).
3. **Double écriture** : le code écrit `space_id` ET `user_id`.
4. **Lecture** : `WHERE space_id = ?` avec repli `user_id` tant que des
   lignes `space_id NULL` existent (mesuré par compteur).
5. **Bascule** : lecture par `space_id` seul quand le compteur est à 0.
6. `user_id` **n'est jamais supprimé**.

`list_items`, `list_receipts`, `receipt_items`, `list_messages`
héritent de l'espace via `list_id` : pas de colonne à leur ajouter.

## Hors ligne

- La version de la file (`offline_queue_version`) est incrémentée à
  chaque phase qui change la forme des payloads : la file se vide
  proprement à la mise à jour.
- Dès la Phase 2 : `space_id` capturé À L'ENQUEUE dans chaque payload,
  et cache local cloisonné par espace (invalidé au changement d'espace).

## Vérifications après chaque backfill

```sql
SELECT COUNT(*) FROM t WHERE space_id IS NULL;          -- doit tendre vers 0
SELECT COUNT(*) FROM t x LEFT JOIN spaces s ON s.id = x.space_id
 WHERE x.space_id IS NOT NULL AND s.id IS NULL;         -- toujours 0 (orphelins)
```

Et rejouer `php api/scripts/test_spaces_e2e.php` + les scénarios hors
ligne de `docs/audit-hors-ligne.md`.
