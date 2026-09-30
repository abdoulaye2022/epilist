# Audit — Introduction des espaces (personnel / foyer / restaurant)

Date : 2026-09-30. Établi à partir du code source et du schéma réel de la
base locale (34 tables), avant toute modification.

Objectif : faire évoluer EpiList vers un modèle multi-espaces
(`personal`, `household`, `restaurant`, `organization`) **sans casser**
l'existant : un utilisateur seul, ses données, son mode hors ligne et
ses prédictions doivent fonctionner exactement comme aujourd'hui.

---

## 1. Architecture actuelle

| Couche | Contenu | État |
|---|---|---|
| API (`api/`) | PHP 8.4, Slim 4, Eloquent, 179 routes, JWT + refresh tokens (rotation/révocation), middlewares `JwtMiddleware` puis `AdminMiddleware` | Sain, tout est « single-user » : `auth_id` du JWT ⇒ `user_id` partout |
| App (`app/`) | Flutter, 15 BLoCs globaux (sauf `ListItemBloc`), Dio partagé + `TokenRefreshInterceptor`, mode hors ligne complet (cache + file + sync + remap d'ids) | Sain, audité (`docs/audit-hors-ligne.md`) |
| Web (`web/`) | Site bilingue + espace admin (2FA, refresh) | Sain |

Le modèle d'autorisation actuel tient en une règle : **une ressource
appartient à un `user_id`**, et le partage est une exception gérée table
par table (`shared_list` uniquement, pour les listes).

## 2. Cartographie des tables (34) et de leur propriété

### Propriété directe `user_id` (19 tables)

| Table | Rôle | Destin multi-espaces |
|---|---|---|
| `shopping_lists` | listes | → `space_id` (Phase 2) |
| `budgets` | budgets (+ `list_id` optionnel) | → `space_id` (Phase 2) |
| `home_inventory` | inventaire (statuts maison) | → `space_id` (Phase 2) |
| `purchase_history` | historique d'achat/prix (20 col.) | → `space_id` (Phase 2, volumineuse) |
| `stores` | magasins perso (+ `household_id` **vestige inutilisé**) | → `space_id` (Phase 2, remplace le vestige) |
| `recurring_lists` (+ items) | listes récurrentes | → `space_id` (Phase 2) |
| `meal_plans` / `recipes` (+ liaison, ingrédients) | plan de repas | → `space_id` (Phase 2) |
| `product_aliases` | apprentissage libellés reçus | → `space_id` (Phase 4, avec les prix) |
| `product_suggestions`, `user_purchase_patterns`, `suggestion_feedback`, `product_prediction_prefs` | intelligence par utilisateur | → **espace** pour le modèle, **utilisateur** pour les retours (Phase 5) |
| `categories` | catégories perso | reste **utilisateur** (préférence d'affichage) ; réévaluer en Phase 2 |
| `email_preferences`, `user_devices`, `user_sso_links`, `refresh_tokens`, `message_read_status`, `api_error_logs`, `list_messages.user_id` (auteur) | compte, sessions, lecture | restent **utilisateur** (identité, pas contexte d'achat) |

### Propriété indirecte via `list_id` (4 tables)

`list_items`, `list_receipts`, `receipt_items`, `list_messages` : elles
héritent de l'espace de leur liste — **aucune migration de colonne
nécessaire** tant que `shopping_lists` porte l'espace. C'est un point
fort de l'architecture actuelle.

### Partage actuel

`shared_list` (16 col.) : owner → invité, permission
`readOnly|edit|admin`, cycle `pending/accepted/declined/expired`,
`share_token`, révocation. **Modèle de référence à répliquer** pour les
invitations d'espace (mêmes états, même UX de lien profond).

### Sans propriété (globales)

`currencies`, `app_versions`, `product_associations`, `scanned_products`,
`store_category_orders` (par magasin), `users`.

## 3. Fonctionnalités réutilisables telles quelles

- **Invitations** : cycle de vie, tokens, deep links `epilist://` +
  page web `/share/{token}` → à dupliquer en `space_invitations` avec
  `epilist://space-invite/{token}`.
- **Permissions par rôle** : `AdminMiddleware` (role global) et
  `SharePermission` (par liste) donnent les deux patrons ; l'espace
  utilise un patron intermédiaire (rôle par membre + permissions fines).
- **Moteur de prédiction** (`PurchasePredictionService`) : fenêtres,
  médianes, confiance — il suffit de changer la CLÉ d'agrégation
  (`user_id` → `space_id`) et de **segmenter par `space.type`** (§34 du
  cahier des charges).
- **OCR + parseur + anti-doublon reçus** : inchangés ; seul le
  rattachement (liste → espace) change.
- **Comparateur/optimiseur de prix** : inchangés, mêmes fenêtres de
  fraîcheur 14/30/90 j (réutilisées pour la « qualité des prix », §24).
- **Mode hors ligne** : file versionnée + remap d'ids — il faut ajouter
  `space_id` aux payloads et **invalider le cache au changement
  d'espace** (le versionnage de cache existant sert de mécanisme).
- **Admin** : pages et middleware prêts à accueillir les compteurs
  d'espaces.
- **i18n** : 1667 clés, parité fr/en, pipeline en place.

## 4. Ce qui doit être construit

| Bloc | Contenu |
|---|---|
| Fondation | `spaces`, `space_members`, `space_invitations`, service central d'autorisation, en-tête `X-Space-Id`, sélecteur d'espace, espace personnel auto-créé |
| Foyer | budgets/inventaire/activité au niveau espace, attribution « ajouté par / acheté par » |
| Restaurant | inventaire quantitatif (stock/minimum), demandes d'achat avec approbation, fournisseurs, permissions fines |
| Prix | table d'observations normalisée (vue au-dessus de `purchase_history`), prix cible (`price_alerts`), alertes dédupliquées |
| Journal d'activité | `space_activities` en **événements structurés** (type + payload JSON), rendu traduit côté client |

## 5. Risques de régression identifiés

1. **Requêtes `where('user_id', $authId)`** : ~60 occurrences dans les
   contrôleurs. Toute migration d'une table vers `space_id` doit livrer
   en même temps la réécriture de TOUTES ses requêtes — d'où la
   stratégie table par table, jamais « big bang ».
2. **Mode hors ligne** : payloads de file sans `space_id` → une action
   rejouée après changement d'espace atterrirait dans le mauvais espace.
   Parade : `space_id` capturé À L'ENQUEUE, et version de file
   incrémentée (la file existante se vide proprement à la mise à jour).
3. **Prédictions** : basculer l'agrégation sur l'espace sans backfill de
   `purchase_history.space_id` viderait les suggestions. Parade :
   backfill AVANT bascule, et repli `user_id` si `space_id` nul.
4. **Isolation multi-tenant** : le risque n° 1 du projet. Parade : un
   SEUL point de contrôle (`SpaceAccessService`) + tests d'isolation
   systématiques (un membre de l'espace A ne lit jamais l'espace B).
5. **`stores.household_id`** : colonne vestige jamais lue ; à remplacer
   par `space_id` (pas deux colonnes de contexte).
6. **Cron** : les tâches itèrent par utilisateur ; celles qui passent au
   niveau espace (récurrentes, budgets foyer) doivent dédupliquer les
   notifications (1 par membre, pas 1 par membre × produit).
7. **JWT** : ne PAS mettre l'espace actif dans le jeton (il changerait à
   chaque bascule) ; l'espace est un en-tête par requête, vérifié en
   base à chaque fois.

## 6. Décisions d'architecture

1. **Espace personnel matérialisé** : chaque utilisateur reçoit une
   ligne `spaces(type='personal')`, créée par backfill idempotent + à la
   volée au premier accès. Un seul système de requêtes, pas de branche
   « NULL = personnel ».
2. **Phase 1 sans toucher aux tables métier** : la fondation (tables,
   autorisations, sélecteur) est livrée seule ; les données restent sur
   `user_id`. L'app fonctionne à l'identique — l'espace personnel est
   une coquille tant que la Phase 2 n'a pas déplacé les entités.
3. **Résolution de l'espace par requête** : en-tête `X-Space-Id`
   (défaut : espace personnel). Le serveur vérifie l'appartenance et le
   statut du membre à CHAQUE requête via `SpaceAccessService` —
   jamais de confiance au client (§40).
4. **Rôles + permissions fines** : rôle (`owner/admin/manager/member/
   viewer`) qui donne un jeu de permissions par défaut, surchargées par
   membre dans `space_members.permissions` (JSON). Une seule fonction
   d'évaluation : `can($member, 'permission')`.
5. **`shared_list` conservé** : le partage par liste reste le mécanisme
   de l'espace personnel ; le foyer partage par appartenance à l'espace.
   Convergence éventuelle en Phase 6+, jamais avant.
6. **Localisation sur l'espace, pas sur l'utilisateur** (§6) :
   `country/region/city/postal_code` optionnels sur `spaces`.
7. **Traçabilité** : `created_by_user_id` ajouté avec `space_id` lors de
   chaque migration d'entité (Phase 2+), backfillé depuis `user_id`.

## 7. Stratégie de migration des données

Pour CHAQUE table migrée (patron répété, testé d'abord sur `stores`) :

1. `ALTER TABLE … ADD COLUMN space_id INT NULL` (+ index) — additif.
2. Backfill idempotent : `space_id = espace personnel du user_id`.
3. Code : écrit `space_id` ET `user_id` (double écriture), lit par
   `space_id` avec repli `user_id` si nul.
4. Vérification (compteurs), puis lecture par `space_id` seul.
5. `user_id` conservé (traçabilité) — **aucune suppression de colonne**.

Rollback : chaque étape est additive ; revenir en arrière = redéployer
le code précédent. Sauvegarde SQL avant chaque backfill volumineux
(`purchase_history`).

## 8. Plan d'implémentation par phases

### Phase 1 — Fondation (cette livraison)
- SQL `api/migrations/add_spaces.sql` : `spaces`, `space_members`,
  `space_invitations` + backfill des espaces personnels existants.
- API : modèles `Space`, `SpaceMember`, `SpaceInvitation` ; service
  `SpaceAccessService` (résolution X-Space-Id, appartenance, rôles,
  permissions) ; `SpaceController` (mes espaces, créer, modifier,
  membres, inviter, accepter/refuser/révoquer, quitter, rôle) ;
  routes `/spaces/*`.
- App : `SpaceService` + espace actif persisté (`ActiveSpaceStore`),
  en-tête `X-Space-Id` injecté par l'intercepteur Dio, sélecteur
  d'espace (drawer + accueil), écran « Créer un espace » (type → nom →
  infos optionnelles, §5), écran membres/invitations. i18n fr/en.
- Tests : script E2E d'isolation et de permissions
  (`api/scripts/test_spaces_e2e.php`).
- Docs : `architecture-espaces.md`, `permissions-espaces.md`,
  `migration-espaces.md`.

### Phase 2 — Foyer
Migration patron §7 sur : `shopping_lists` (entraîne items, reçus,
messages), `budgets`, `home_inventory`, `stores` (remplace
`household_id`), `recurring_lists`, `meal_plans`/`recipes`.
Attribution (« ajouté par ») via `created_by_user_id`. Journal
`space_activities`. Dashboard foyer (§13-16, composants réutilisés).

### Phase 3 — Restaurant
`space_inventory_settings` (stock/minimum/unité/réappro/fournisseur
préféré), `purchase_requests` (+ historique de statuts),
`suppliers`, permissions fines actives, dashboard restaurant (§18-22).

### Phase 4 — Intelligence prix
Backfill `purchase_history.space_id`, modèle d'observation normalisé,
`price_alerts` (+ prix cible automatique §26), alertes dédupliquées
(§27), fraîcheur réutilisant 14/30/90 j (§24).

### Phase 5 — Assistant intelligent
Prédictions par espace segmentées par type (§17, §34), « avant les
courses » / « prochaine commande » (§28), « est-ce un bon prix » (§29),
économies estimées documentées (§30), panier optimal avec seuil par
magasin supplémentaire (§31).

### Phase 6 — Communauté de prix
Agrégats anonymisés (produit/magasin/région/prix/date, jamais
d'identité, §33), règles de qualité avant usage.

### Hors ligne et i18n : à CHAQUE phase
`space_id` dans les payloads de file dès la Phase 1 (préparé), cache
par espace dès la Phase 2, parité fr/en vérifiée à chaque livraison.

## 9. Ce que la Phase 1 ne fait volontairement PAS

- Aucune colonne ajoutée aux tables métier (listes, budgets…).
- Aucun changement de comportement pour un utilisateur actuel : son
  espace personnel est actif par défaut, toutes ses données s'affichent
  comme avant.
- Pas de dashboard foyer/restaurant (Phases 2-3) : créer un espace
  donne la coquille (membres, invitations) — le contenu suit.
