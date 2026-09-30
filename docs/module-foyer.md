# Module foyer (Phase 2)

Livré le 2026-09-30. Prérequis : Phase 1 (`docs/architecture-espaces.md`).
Migration : `api/migrations/add_spaces_phase2.sql` (idempotente).

## Ce qu'un foyer partage désormais

| Donnée | Comportement |
|---|---|
| Listes | Créées dans l'espace ACTIF (`X-Space-Id`) ; tous les membres les voient ; items/reçus/messages suivent la liste |
| Articles | Attribution : `created_by_user_id` (« ajouté par ») et `purchased_by_user_id` (« acheté par ») remplis automatiquement |
| Budgets | Par espace ; création/modification/suppression exigent `manage_budgets` ; lecture pour tous les membres |
| Inventaire | Par espace (unicité produit PAR ESPACE) ; écriture = `manage_inventory` |
| Magasins, listes récurrentes, plans de repas, recettes | Par espace ; une liste générée (récurrente ou plan de repas) naît dans l'espace de son parent — cron compris |
| Journal d'activité | `space_activities` : événements structurés, rendus traduits dans l'app (écran Activité, accessible depuis le sélecteur d'espace) |

Événements journalisés : `list_created`, `item_added`, `item_purchased`,
`receipt_added`, `budget_created`, `member_joined`, `member_left`,
`inventory_out`. Les espaces personnels ne journalisent rien.

## Règles d'accès (rappel)

- **Listing / création** : l'espace vient de l'en-tête `X-Space-Id`
  (défaut : personnel), appartenance revérifiée en base à chaque requête.
- **Accès à un objet** (liste, item, reçu, message) : le critère est
  l'appartenance à l'espace DE L'OBJET, pas l'espace actif — le rejeu
  hors ligne et les liens profonds fonctionnent sans dépendre de
  l'en-tête. Un non-membre reçoit 403/404, jamais les données.
- Le personnel garde le partage par liste historique (`shared_list`).
- `SpaceAccessException` est traduite en JSON propre par
  l'ErrorMiddleware (jamais un 500).

## Hors ligne (Phase 2)

- File d'actions **v2.0.0** : chaque action capture `space_id` à
  l'enqueue ; le rejeu force cet espace via
  `SpaceHeaderInterceptor.syncOverride` (changer d'espace entre-temps
  ne détourne aucune action).
- Cache **v2.0.0** : listes, budgets et magasins sont cloisonnés par
  espace (`clé@s{id}`, personnel = clé historique) — aucune donnée d'un
  foyer ne s'affiche hors ligne dans le personnel, et inversement.
- Les bumps de version vident proprement l'ancien cache/file à la mise
  à jour.

## Application

- Changement d'espace : listes + budgets rechargés immédiatement
  (sélecteur) ; l'accueil écoute `ActiveSpaceStore` (carte budget).
- Écran **Activité** (`space_activity_screen.dart`), textes fr/en.

## Reporté (assumé)

- Affichage « Ajouté par X » sur chaque ligne d'article (les données
  sont prêtes côté API) et dashboard foyer dédié (§13) → avec le
  dashboard adaptatif (§45, Phase 3+).
- `purchase_history.space_id` → Phase 4 (voir audit §2).
- Notifications par espace (§37) → avec les phases 3-5.

## Tests

`php api/scripts/test_spaces_e2e.php` — **56 vérifications** dont
Phase 2 : liste créée dans le foyer (space_id vérifié en base),
visibilité croisée A/B, non-fuite vers le personnel, attribution
created_by/purchased_by, viewer bloqué, budgets (visibilité + refus
sans `manage_budgets`), inventaire partagé et cloisonné, journal
d'activité complet et refusé aux non-membres.
