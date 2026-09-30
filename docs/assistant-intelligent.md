# Assistant intelligent (Phase 5)

Livré le 2026-09-30. Prérequis : Phases 1-4. Migration :
`api/migrations/add_spaces_phase5.sql` (idempotente — voir plus bas).

## Prédictions par espace (§17, §34)

`PurchasePredictionService` raisonne maintenant **dans un espace** :

- Foyer : les cycles d'achat sont calculés sur les achats de TOUT le
  foyer ; personnel : strictement personnel (aucune fuite, testé E2E).
- Les préférences (« ne plus suggérer », snooze, fréquence
  personnalisée) restent **par utilisateur** : un goût personnel ne
  masque pas une suggestion pour les autres membres.
- « J'en ai encore » écrit l'inventaire estimé dans l'ESPACE courant
  (l'index unique est space+produit) — corrige un upsert resté
  par-utilisateur après la Phase 2.
- **Espaces pro (§17)** : le quantitatif prime. Produit sous le seuil
  (`quantity <= min_quantity`) → au moins « bientôt » ; stock à zéro →
  « en retard », même si le cycle d'achat dit « pas besoin ».
  Chaque prédiction expose `below_min`.
- Même périmètre appliqué à : estimations d'inventaire, aperçu des
  listes récurrentes (`buildPreview` raisonne dans l'espace de la
  liste), rythme quotidien de la projection budgétaire
  (`robustDailyRate` — était resté par-utilisateur).

## Avant les courses (§28)

`GET /assistant/pre-shopping` — UN appel, le brief de l'espace actif :

| Section | Contenu |
|---|---|
| `restock` | 8 prédictions urgentes (statut, confiance, magasin habituel, below_min) |
| `inventory_alerts` | ruptures déclarées + produits sous le seuil (10 max) |
| `budget` | budget mensuel actif : restant, jours, $/jour |
| `price_watch` | alertes de prix déclenchées ces 7 derniers jours |
| `pending_requests` | espaces pro : demandes d'achat en attente (« prochaine commande ») ; `null` sinon |

## Est-ce un bon prix ? (§29)

`GET /prices/check?product=&price=` — verdict PRUDENT contre
l'historique de l'espace actif (90 j) :

- `good` — au niveau du bon prix (25e percentile) ou mieux ;
- `fair` — proche du prix habituel (médiane +5 %) ;
- `high` — au-dessus du prix habituel ;
- `unknown` — moins de 3 observations : on ne devine pas.

Toujours accompagné des chiffres (habituel, bon prix, min, écart %,
fraîcheur) : c'est une aide, pas un oracle.

## Économies estimées documentées (§30)

`GET /assistant/savings?days=30` — pour chaque achat de la fenêtre, le
prix habituel est la **médiane des observations ANTÉRIEURES à l'achat**
(90 j, minimum 2 repères). Une économie n'est comptée que si
payé < habituel (seuil 0,05 $). Chaque ligne est documentée : produit,
payé, habituel d'alors, nombre de repères, magasin, date. Le total
n'existe jamais sans son détail.

## Panier optimal (§31)

Déjà livré : `GET /shopping-lists/{id}/optimization` avec
`min_saving` par magasin supplémentaire (défaut 5 $), périmètre espace
depuis la Phase 4, écran de comparaison existant dans l'app.

## Migration : magasins par espace

L'unicité des magasins était `(user_id, slug)` : le même utilisateur ne
pouvait pas avoir « IGA » dans son foyer ET son restaurant (500 à
l'import de reçu). Elle devient `(space_id, slug)` — même bascule que
`home_inventory` en Phase 2. Aucune donnée modifiée.

## Application

- Écran « Avant les courses » (drawer, tous les espaces) : budget,
  à racheter, ruptures/seuils, prix repérés, demandes en attente (pro),
  économies estimées avec détail ligne par ligne.
- « Est-ce un bon prix ? » : icône dans l'AppBar de l'écran — produit +
  prix → verdict coloré + chiffres.
- 20 clés i18n fr/en (0 untranslated).

## Sécurité vérifiée (E2E 142/142)

Prédictions du foyer visibles par un membre, absentes du personnel ;
feedback écrit dans l'inventaire du bon espace ; verdict `unknown` sans
historique personnel (pas de fuite) ; économies du foyer absentes du
personnel ; brief refusé à un non-membre (403) ; stock à zéro → « en
retard » malgré un cycle lent ; alerte déclenchée par l'import testée
de bout en bout.

## Reporté (assumé)

- Dashboard adaptatif par type d'espace (§45) : le brief §28 en pose
  les sections ; l'intégration à l'accueil suivra la Phase 6.
- Notification « avant les courses » planifiée (opt-in) : à évaluer
  avec les réglages d'intelligence existants.
