# Permissions des espaces

Source de vérité : `api/src/Models/SpaceMember.php`
(`PERMISSIONS`, `ROLE_DEFAULTS`, `can()`).

## Principe

1. Le **rôle** donne un jeu de permissions par défaut.
2. La colonne JSON `space_members.permissions` **surcharge** au cas par
   cas (`{"view_budgets": false}` retire, `{"manage_inventory": true}`
   accorde) — validée côté serveur (clé inconnue = 422).
3. Une seule fonction d'évaluation : `SpaceMember::can($permission)`.
   Les contrôleurs passent par
   `SpaceAccessService::assertPermission()` — jamais de test de rôle
   en dur ailleurs.

## Matrice des défauts

| Permission | owner | admin | manager | member | viewer |
|---|---|---|---|---|---|
| manage_space | ✓ | ✓ | — | — | — |
| manage_members | ✓ | ✓ | — | — | — |
| view_budgets | ✓ | ✓ | ✓ | ✓ | ✓ |
| manage_budgets | ✓ | ✓ | ✓ | — | — |
| add_items | ✓ | ✓ | ✓ | ✓ | — |
| manage_lists | ✓ | ✓ | ✓ | ✓ | — |
| approve_purchases | ✓ | ✓ | ✓ | — | — |
| scan_receipts | ✓ | ✓ | ✓ | ✓ | — |
| view_expenses | ✓ | ✓ | ✓ | ✓ | ✓ |
| manage_inventory | ✓ | ✓ | ✓ | ✓ | — |
| manage_suppliers | ✓ | ✓ | ✓ | — | — |
| view_statistics | ✓ | ✓ | ✓ | ✓ | ✓ |

Exemple type restaurant : un employé (`member`) ajoute des articles et
scanne des reçus, mais on lui retire la vue financière avec
`{"view_budgets": false, "view_expenses": false}`.

## Règles structurelles (non contournables)

- L'**owner** est intouchable : ni changement de rôle, ni retrait, ni
  départ volontaire. Personne ne peut être promu `owner` via l'API.
- Seul l'owner peut promouvoir un membre `admin` (un admin ne fabrique
  pas d'égal).
- L'espace **personnel** : jamais d'invitation, jamais de suppression,
  jamais de départ, nom non modifiable (affiché traduit).
- Accès refusé = **403 identique** que l'espace existe ou non.
- `approve_purchases`, `manage_suppliers` : réservées à la Phase 3
  (restaurant) — déjà déclarées pour figer la matrice.
