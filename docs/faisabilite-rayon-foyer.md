# Étude de faisabilité — Tri par rayon et Foyer

Date : 22 août 2026. Mode analyse uniquement : aucun fichier de code n'a été modifié.
Toutes les références `fichier:ligne` sont relatives à la racine du monorepo et ont été
lues dans le code de la branche `claude` (HEAD `22e6496`). Les requêtes SQL ont été
exécutées sur la **base locale** (`epilist`, 9 utilisateurs, 46 articles), qui n'est pas
la production — voir §8.

---

## 1. Verdict en 5 lignes

- **Fonctionnalité 1 — Tri par rayon : faisable avec réserves.** Le modèle de données est sain (vraie FK `category_id`), le tri client se greffe sans refonte. Les réserves : les catégories sont **privées par utilisateur** (pas d'identité commune), ce qui rend `store_category_orders` inutilisable tel quel sur une liste partagée ; et 43 articles sur 46 n'ont pas de catégorie localement — sans auto-catégorisation, la fonctionnalité ne trie rien.
- **Fonctionnalité 2 — Foyer : risquée sur cette base, Phase A seule faisable.** Le contrôle d'accès est **dispersé** (4 helpers dupliqués + ~38 sites de vérification inline dans 5 contrôleurs), il n'existe **aucun test automatisé**, et **7 routes de partage déclarées n'ont pas de handler** (`revokeShare`, `updateSharePermission`, `getSharedLists`…). Il faut réparer le partage avant de construire dessus.
- **Point bloquant transversal :** `PATCH /items/{id}/toggle` **inverse** l'état côté serveur en ignorant la valeur envoyée (`ListItemController.php:560`). Deux personnes qui cochent le même article hors ligne le **décochent** à la resynchronisation. Ce bug existe déjà avec le partage actuel ; le foyer le rend quotidien. À corriger avant tout.
- **Décision `stores` :** concevoir avec `household_id NULL` dès la F1 (pas de polymorphisme) — coût marginal ~0,5 j, migration ultérieure ~3-4 j et risquée.
- **Effort total pessimiste :** F1 ≈ 14-24 j ; F2 Phase A ≈ 19-31 j (dont 5-8 j de remise à niveau préalable du partage) ; F2 Phase B ≈ 12-20 j.

---

## 2. Inventaire de l'existant

### 2.1 Schéma réel (base locale, `SHOW CREATE TABLE`)

| Table | Colonnes pertinentes | Contraintes |
|---|---|---|
| `shopping_lists` | `id INT`, `user_id INT NULL`, `name TEXT`, timestamps, `deleted_at` | FK `user_id → users`. **Charset latin1.** |
| `list_items` | `id INT`, `list_id`, `product_name TEXT`, `category_id INT NULL`, `barcode VARCHAR(50)`, `quantity`, `price DOUBLE`, `store_name TEXT`, `is_purchased`, `purchased_at`, timestamps, `deleted_at` | FK `fk_list_items_category (category_id → categories) ON DELETE SET NULL` ; FK `list_id → shopping_lists`. **Charset latin1.** |
| `categories` | `id INT`, `user_id INT NOT NULL`, `name VARCHAR(100)`, `icon_code`, `color_hex`, `order_index`, timestamps, `deleted_at` | FK `user_id → users ON DELETE CASCADE`. utf8mb4. |
| `shared_list` | `id`, `list_id`, `owner_id`, `shared_with_user_id NULL`, `permission ENUM('readOnly','edit','admin')`, `share_token VARCHAR(64) UNIQUE`, `status VARCHAR(20)`, `expires_at`, `accepted_at`, `declined_at`, `revoked_at`, `is_active` | latin1 |
| `budgets` | `id`, `user_id NOT NULL`, `list_id NULL`, `budget_amount`, `period_type`, `start_date`, `end_date`, `alert_threshold` | |
| `list_receipts` | `id`, `list_id`, `store_name VARCHAR(255) NOT NULL`, `total_amount`, `purchase_date` | FK `list_id CASCADE` |

Points structurants :
- Tous les ids sont `INT` signés. Le schéma proposé en `BIGINT UNSIGNED` **ne peut pas** référencer ces tables en FK (types incompatibles).
- `categories.user_id NOT NULL` : **chaque utilisateur possède ses propres lignes**. Les « 12 catégories par défaut » sont dupliquées avec des ids différents à chaque `POST /categories/initialize-defaults` (`api/src/Controllers/CategoryController.php`). Aucune colonne ne relie « Boulangerie » de l'utilisateur A à « Boulangerie » de l'utilisateur B.
- Local : 43/46 articles ont `category_id IS NULL` ; 3 articles pointent vers des catégories **soft-deleted** (ids 14, 15).
- Source des migrations : `api/migrations/bd_prod.sql` (dump du 7 nov. 2025) + fichiers incrémentaux (`create_categories_table.sql`, `add_barcode_to_list_items.sql`, `008_fix_orphaned_data_production.sql`). Pas de système de migration versionné (pas de `api/database/`, pas de Phinx/Doctrine).

### 2.2 Contrôle d'accès API

- `api/src/Middleware/JwtMiddleware.php:57-59` pose seulement `auth_id` sur la requête. **Aucun middleware d'autorisation, aucune Policy, aucun Repository.**
- Quatre copies privées de `checkListAccess` :
  - `api/src/Controllers/ListItemController.php:189-243` (niveaux read/edit/delete)
  - `api/src/Controllers/ListReceiptsController.php:32-86` (copie identique)
  - `api/src/Controllers/AnalyticsController.php:225-250` (sans niveau, **jamais appelée**)
  - `api/src/Controllers/BudgetController.php:90-112` (sans niveau)
- Deux méthodes modèle : `ShoppingList::canBeAccessedBy()` `api/src/Models/ShoppingList.php:115-127` (lecture seule, ignore `permission`) et `scopeAccessibleBy` `:307-317`.
- Logique inline non factorisée dans `ShoppingListController.php` : `index` l.82-96, `show` l.180-214, `update` l.288-316, `destroy` l.356-381, `restore` l.419 (owner seulement), `duplicate` l.451-465.
- Lecture de la permission : `api/src/Models/SharedList.php:156-166`
  ```php
  public function canEdit(): bool { return $this->isAccepted() && in_array($this->permission, [self::PERMISSION_EDIT, self::PERMISSION_ADMIN]); }
  public function canDelete(): bool { return $this->isAccepted() && $this->permission === self::PERMISSION_ADMIN; }
  ```
- **Total : ~38 sites de vérification**, répartis sur 5 contrôleurs et 1 modèle.

### 2.3 Partage — état réel

- Table unique `shared_list` ; un enregistrement = un lien d'invitation à usage unique, `shared_with_user_id` rempli à l'acceptation (`SharedListController.php:53-63`, `:205-257`).
- Token : `bin2hex(random_bytes(16))` `SharedListController.php:332-338`.
- **Routes déclarées sans handler** (`api/public/index.php:126, 209-212, 214-215`) : `showSharePage`, `getSharedLists`, `getListShares`, `updateSharePermission`, `revokeShare`, `revokeAllShareLinks`, `getShareStats`. `SharedListController.php` ne contient que 5 méthodes publiques (l.24, 102, 199, 285, 370) et porte à la ligne 329 le commentaire `// ... (autres méthodes restent identiques)`. L'historique git (`db5b174`, `3a7c0f0`) montre que ces méthodes **n'ont jamais existé dans le dépôt**. L'application les appelle pourtant : `app/lib/services/shared_list_service.dart:305, 326, 349, 362, 392`.
- `GET /share/invitation/{token}` (l.102-194) et `POST /share/decline/{token}` (l.285-327) ne lisent jamais `auth_id`.
- `expires_at` n'est pas vérifié lors des accès à un partage déjà accepté (seul le hook `retrieved` `SharedList.php:250-254` agit, sur `pending`).

### 2.4 Tests

`api/composer.json` : pas de `require-dev`, pas de `scripts`, pas de `phpunit.xml`, pas de `api/tests/`. Les fichiers `api/test_*.php` sont des scripts manuels ; aucun ne mentionne le partage. Côté Flutter : `app/test/` non inspecté en détail (voir §8). **Conclusion : zéro test automatisé sur le partage.**

### 2.5 Pile hors ligne Flutter — ce qui tourne vraiment

Deux piles coexistent ; une seule est branchée :

| Service | Fichier | État |
|---|---|---|
| `OfflineStorageService` (SharedPreferences) | `app/lib/services/offline_storage_service.dart` | **utilisé** — cache de lecture, TTL 7 j (`:49-61`) |
| `OfflineQueueService` | `app/lib/services/offline_queue_service.dart` | **utilisé** — file d'actions JSON sous une clé unique (`:15`, `:94`) |
| `OfflineSyncService` | `app/lib/services/offline_sync_service.dart` | **utilisé** — rejeu séquentiel trié par timestamp (`:100-138`) |
| `ConnectivityService` | `app/lib/services/connectivity_service.dart` | utilisé |
| `OfflineCacheService` (Hive) | `app/lib/services/offline_cache_service.dart` | **code mort** — aucun appelant dans `lib/` |
| `ConflictResolutionService` | `app/lib/services/conflict_resolution_service.dart` | **code mort** — `detectConflict`/`resolveConflict` jamais appelés |

Conséquence directe pour le prompt : la « décision d'architecture » de cacher l'ordre des rayons « dans Hive comme les listes » repose sur une prémisse fausse — les listes ne sont pas dans Hive, elles sont dans SharedPreferences.

Autres constats sur la file :
- Pas d'enum : types en constantes `String` (`offline_queue_service.dart:22-47`).
- `isDuplicateAction()` (`:354-381`) existe mais n'est **jamais appelé**.
- Créations hors ligne : id temporaire négatif (`app/lib/blocs/list_item/list_item_bloc.dart:212-214`), **aucun mapping id temporaire → id serveur** après rejeu. Un `toggle_item` sur un article créé hors ligne est rejoué avec l'id négatif.
- Les actions catégories (`create/update/delete/reorder_categories`) sont enfilées (`category_bloc.dart:240, 344, 444`) mais **n'ont pas de `case` dans `_syncAction`** (`offline_sync_service.dart:324-326`) → abandon après 5 essais.
- `create_budget`/`update_budget` retournent toujours `false` (`:254-264`).
- Aucun service n'envoie `updated_at`, `version` ou `If-Match` (grep sur `app/lib/services/*.dart` : seul `shared_list_service.dart:123-125` **lit** `updated_at`).

### 2.6 Tri et filtres des articles

- `app/lib/widgets/list_detail/item_filters_bar.dart:6-11` : `enum ItemSortBy { name, price, store, dateAdded }`.
- `ItemFilterCriteria` `:13-32` : `storeName`, `minPrice`, `maxPrice`, `categoryId`, `sortBy`, `ascending`, `showOnlyPurchased`, `showOnlyUnpurchased`.
- `apply()` `:51-119`, tri :
  ```dart
  switch (sortBy) {
    case ItemSortBy.name:      comparison = a.productName.compareTo(b.productName);
    case ItemSortBy.price:     comparison = (a.price ?? 0).compareTo(b.price ?? 0);
    case ItemSortBy.store:     comparison = (a.storeName ?? '').compareTo(b.storeName ?? '');
    case ItemSortBy.dateAdded: comparison = a.createdAt.compareTo(b.createdAt);
  }
  return ascending ? comparison : -comparison;
  ```
- Appel : `app/lib/screens/list_detail_screen.dart:71` et `:240` (`filteredItems = _filterCriteria.apply(items)`). Les catégories disponibles viennent de `CategoryBloc` (`:264-286`), les magasins du set des `storeName` des articles (`:244-249`).
- `ListItem` (`app/lib/models/list_item.dart:5-16`) porte `categoryId (int?)` et `storeName (String?)` ; pas d'objet `Category`.

### 2.7 Code-barres et ajout d'article

- `app/lib/services/product_api_service.dart:6` → `https://world.openfoodfacts.org/api/v2`. Champs lus par `ProductInfo.fromOpenFoodFacts` (`app/lib/models/product_info.dart:24-62`) : `product_name*`, `generic_name`, `brands`, `quantity`, `image_*`, `code`, `nutriments`. **`categories` / `categories_tags` : non lus** (grep : 0 résultat dans `app/lib` et `api/src`).
- Flux scan : `add_item_dialog.dart:859-939` → le scan remplit uniquement `productController.text` (`:910-912`) ; la catégorie reste `_selectedCategory` choisie à la main (`:41`, `:725`, lue en `:987`).
- `store_name` : `TextField` texte libre `add_item_dialog.dart:510-534`, pas d'`Autocomplete`.
- Ajout vocal : `list_detail_screen.dart:770-793` envoie `categoryId: null`.

### 2.8 Sémantique de `toggle`

`api/src/Controllers/ListItemController.php:560-561` :
```php
$newStatus = !$item->is_purchased;
$item->update(['is_purchased' => $newStatus]);
```
Le corps `{"is_purchased": bool}` envoyé par `app/lib/services/list_item_service.dart:166-177` est **ignoré**. À l'inverse, `markAll` (`:928`) applique bien une valeur absolue.

### 2.9 Budgets, analytiques, notifications

- Budgets filtrés **uniquement** par `user_id` (`Budget::scopeForUser` `api/src/Models/Budget.php:536-539`, utilisé 9 fois dans `BudgetController`). Le « dépensé » (`Budget::getSpentAmount()` `:168-177`) = somme des `list_receipts` sur la période, et **seulement si elle vaut 0**, somme `price*quantity` des articles achetés (`:194-218`, `:238-265`). Le budget général inclut les listes partagées via `ShoppingList::accessibleBy` (`:228`).
- Les 11 endpoints analytiques passent tous par `AnalyticsController::getUserAccessibleListIds` (`:205-220`, own + partagées acceptées) puis `whereIn('list_id', …)` ; paramètre `include_shared` (défaut `true`), sauf `data-quality` qui ne le lit pas.
- Notifications : modèle « un utilisateur → ses devices » (`NotificationService::sendToUser` `api/src/Services/NotificationService.php:395-420`). Un seul envoi multi-destinataires existe : `MessageController::sendMessage` `:142-150` via `ShoppingList::getAllAccessUsers()` (`ShoppingList.php:101-111`). La notification « liste terminée » ne va qu'au propriétaire (`ListCompletionNotificationService.php:95-130`). `sendSharedListUpdateNotification` (`:396-425`) appelle une relation `sharedWith()` qui **n'existe pas** sur `ShoppingList`.

---

## 3. Fonctionnalité 1 — Tri par rayon

### Q1. Migration de `store_name`

Requête de diagnostic (à exécuter sur la prod) :
```sql
SELECT COUNT(*) total, COUNT(store_name) renseignes,
       COUNT(DISTINCT store_name) distincts_bruts,
       COUNT(DISTINCT LOWER(TRIM(store_name))) distincts_normalises
FROM list_items WHERE deleted_at IS NULL;

SELECT LOWER(TRIM(store_name)) norm, GROUP_CONCAT(DISTINCT store_name) variantes, COUNT(*) n
FROM list_items WHERE store_name IS NOT NULL AND store_name <> ''
GROUP BY norm ORDER BY n DESC;

-- même chose sur list_receipts.store_name, qui est une 2e source indépendante
SELECT LOWER(TRIM(store_name)) norm, GROUP_CONCAT(DISTINCT store_name), COUNT(*) n
FROM list_receipts GROUP BY norm ORDER BY n DESC;
```

Résultat **local** (non représentatif, 46 articles) : 26 renseignés, 5 valeurs distinctes brutes = 5 normalisées (`IGA`, `Walmart`, `Rio Mar`, `Sobeys`, `Métro`). Sur `list_receipts` : `IGA`, `Walmart`, `Métro`, `One Store`, `Wjjjj` — ce dernier montre que la saisie libre produit du bruit.

Constats qui conditionnent la migration :
- `list_items.store_name` est un `TEXT` en **latin1** ; `list_receipts.store_name` un `VARCHAR(255)` **utf8mb4**. « Métro » est stocké dans deux encodages différents. Un slug par `LOWER(TRIM())` en SQL donnera des résultats différents selon la table ; il faut slugifier en PHP après conversion UTF-8, en retirant les accents (`Métro` → `metro`, `Super C` → `super-c`).
- Le champ est `textCapitalization: TextCapitalization.words` côté app (`add_item_dialog.dart`), donc la casse est déjà relativement homogène, mais rien n'empêche « iga », « IGA Extra », « Iga Ste-Foy ».

**Réponse :** le slug minuscules sans accents suffit pour la **première passe automatique**, mais il faut prévoir la **fusion manuelle dès le départ** (`POST /stores/{id}/merge` du schéma proposé est justifié), car le slug ne rapprochera jamais « IGA » et « IGA Extra ». Sur 200 utilisateurs, l'ordre de grandeur est probablement 100-300 magasins distincts après slug, dont une minorité de doublons sémantiques.

### Q2. Modèle de catégories

- `list_items.category_id` est une **vraie FK entière** vers `categories(id) ON DELETE SET NULL` (base locale ; déclarée dans `api/migrations/create_categories_table.sql:78-81`). Pas une chaîne.
- **Mais `categories.user_id NOT NULL`** : les catégories sont privées. `store_category_orders(store_id, category_id)` ne tient donc debout **que pour un magasin et des catégories du même utilisateur**. Sur une liste partagée, l'article porte le `category_id` de l'utilisateur qui l'a saisi (`ListItemController.php:179-180` caste en `(int)` sans vérifier la propriété) ; l'autre utilisateur ne possède pas cette catégorie et son `store_category_orders` ne la contient pas.
- Article **sans catégorie** : c'est le cas majoritaire localement (43/46). Le tri doit définir une position de repli explicite (fin de liste, ou groupe « Non classé » en tête pour inciter à classer). Sans auto-catégorisation (Q6), la fonctionnalité ne triera rien d'utile.
- Article dont la catégorie est **soft-deleted** (3 cas locaux) : `category_id` reste renseigné (le `SET NULL` ne joue que sur un `DELETE` physique). `CategoryBloc` filtre `deletedAt == null`, donc l'UI ne la connaît pas → même traitement que « sans catégorie ».

**Ce qui ne va pas dans le schéma proposé et ce que je propose à la place :**
- Types : `INT` partout, pas `BIGINT UNSIGNED`, sinon pas de FK possible.
- `store_category_orders.category_id` doit être une FK `ON DELETE CASCADE` vers `categories` (sinon suppression de catégorie = ligne orpheline).
- Pour rendre le tri **partageable** (Q3 et foyer), il faut une identité de catégorie indépendante de l'utilisateur. Option minimale : ajouter `categories.kind VARCHAR(40) NULL` (ex. `bakery`, `dairy`), renseigné pour les 12 défauts à l'initialisation et rétro-rempli par nom pour l'existant. L'ordre de rayon se définit alors sur le `kind` (`store_category_orders(store_id, category_kind, position)`), ce qui le rend valable pour n'importe quel utilisateur de la liste. Les catégories personnalisées (`kind NULL`) tombent dans le repli.
- `list_items.store_id` et `shopping_lists.active_store_id` : `active_store_id` sur la liste suffit pour le tri ; `list_items.store_id` double `store_name` et crée un second champ à maintenir. Je le déconseille en v1 — garder `store_name` et le résoudre par slug à la volée.

### Q3. Listes partagées

`stores` par `user_id` + catégories par `user_id` = sur une liste partagée, chaque participant a son propre ordre **et** ses propres ids de catégorie. Sans règle, deux personnes devant la même liste au même Superstore la voient dans deux ordres différents, ou pas triée du tout.

Endroits où l'ambiguïté se matérialise :
1. `ListItemController::store` l.323 et `:179-180` — accepte n'importe quel `category_id` entier sans vérifier `categories.user_id = auth_id`. Un invité peut donc poser une catégorie que le propriétaire ne connaît pas.
2. `list_detail_screen.dart:264-286` — le filtre par catégorie n'affiche que **mes** catégories (`CategoryBloc`) ; les `category_id` des autres participants ne correspondent à rien.
3. `shopping_lists.active_store_id` (proposé) — un seul magasin actif par liste, mais si deux participants le changent, c'est le dernier qui gagne, sans notification.
4. `budget`/`analytics` par catégorie (`AnalyticsController::spendingByCategory` l.1348) — agrège déjà sur des `category_id` hétérogènes pour les listes partagées (bug latent existant).

**Règle proposée :** l'ordre de rayon appartient au **magasin**, le magasin appartient à un **espace** (utilisateur en F1, foyer en F2), et le tri s'applique sur le `kind` de catégorie (Q2), jamais sur `category_id`. Le choix du magasin actif est **local à l'appareil** (pas `shopping_lists.active_store_id`) : chaque participant choisit « je suis au Costco » sur son téléphone, et voit la liste dans l'ordre de son propre Costco. Ça supprime l'ambiguïté, évite un aller-retour serveur, et fonctionne hors ligne. Le magasin actif est mémorisé par liste dans SharedPreferences.

### Q4. Mode hors ligne

Prémisse corrigée : **ne pas toucher à `offline_cache_service` (Hive) ni à `conflict_resolution_service`, qui sont du code mort**. Les brancher reviendrait à introduire une deuxième pile de cache. Travailler dans `OfflineStorageService`, `OfflineQueueService`, `OfflineSyncService`.

À ajouter :

| Fichier | Ajout |
|---|---|
| `offline_storage_service.dart` | clés `cached_stores`, `cached_store_orders` ; `saveStores/getStores`, `saveStoreOrder(storeId)/getStoreOrder` ; ajout dans `keysToRemove` de `clearAll()` (`:546-559`) |
| `offline_queue_service.dart` | constantes `ACTION_CREATE_STORE`, `ACTION_UPDATE_STORE`, `ACTION_DELETE_STORE`, `ACTION_SET_STORE_ORDER` |
| `offline_sync_service.dart` | 4 `case` dans `_syncAction` (`:140-326`) — **sinon abandon silencieux après 5 essais, comme les catégories aujourd'hui** |
| nouveau `store_service.dart` + `StoreBloc` | appels Dio, fallback cache à la lecture |

Risque de conflit sur `position` : **oui, mais facile à éviter**. Si l'ordre est envoyé en bulk (`PUT /stores/{id}/category-order {category_ids:[...]}` comme `PUT /categories/reorder`, `category_service.dart:165-194`) et que le serveur **remplace** toutes les lignes du magasin en une transaction, il n'y a jamais de conflit sur une position individuelle : c'est du last-write-wins sur l'ordre complet, acceptable pour une configuration rare. Il ne faut **pas** exposer un `PUT` par ligne de `store_category_orders`.

Deux pièges hérités :
- Un magasin créé hors ligne a un id temporaire négatif ; un `set_store_order` enfilé juste après portera cet id négatif et échouera (même bug que `toggle_item` sur un article créé hors ligne, §2.5). Soit on interdit de configurer l'ordre d'un magasin non synchronisé, soit on corrige enfin le mapping id temporaire → id serveur (bénéfice général, ~2 j).
- `forceSyncNow()` n'entraîne aucun rechargement des BLoCs ; après synchro, `StoreBloc` devra se réabonner à `syncStatusStream`.

### Q5. Intégration UI

Oui, ça se greffe **sans refonte**. Le point d'insertion est `ItemFilterCriteria.apply()` (`item_filters_bar.dart:51-119`) :
- ajouter `ItemSortBy.aisle` à l'enum (`:6-11`) ;
- `apply()` reçoit en plus une `Map<String,int>? aisleOrder` (kind → position) et un `Map<int,String>` catégorieId → kind ; `case ItemSortBy.aisle` compare les positions avec repli `999` pour null/inconnu, puis sous-tri par nom ;
- `list_detail_screen.dart:240` passe ces deux maps, construites à partir de `StoreBloc` et `CategoryBloc` (déjà disponible `:264-286`).

Une refonte n'est nécessaire que si l'on veut un affichage **groupé par rayon** avec en-têtes de section : `_buildContent` (`:288`) rend aujourd'hui une liste plate de `SwipeableItemCard` ; le regroupement demande un `ListView` à sections (~1-2 j). La barre de filtres gagne un sélecteur de magasin actif (chips), qui peut réutiliser `availableStores` (`:244-249`) en le croisant avec les magasins configurés.

### Q6. Auto-catégorisation sans IA

- Open Food Facts renvoie `categories_tags` (ex. `en:breakfast-cereals`, `en:dairies`) dans `GET /product/{barcode}`. **Aujourd'hui ce champ n'est pas lu** (`product_info.dart`, grep vide). Il est exploitable : la hiérarchie OFF est en anglais, stable, et se mappe sur les 12 défauts avec une table d'une cinquantaine de préfixes (`en:dairies`→`dairy`, `en:beverages`→`drinks`, `en:meats`/`en:seafood`→`meat_fish`, `en:breads`→`bakery`…). Point de branchement : `ProductInfo.fromOpenFoodFacts` (`product_info.dart:24-62`) pour exposer `categoryKind`, puis `add_item_dialog.dart:910-912` où le scan remplit le nom — y positionner aussi `_selectedCategory` si non déjà choisi.
- Limite : OFF couvre l'alimentaire emballé ; pas les fruits et légumes en vrac, ni l'hygiène/entretien de façon fiable. Le mapping se fait sur le **kind** (Q2), puis on cherche la catégorie de l'utilisateur portant ce kind.
- Dictionnaire local mot-clé → catégorie (~500 entrées FR) : à brancher à **un seul endroit**, dans `AddItemDialog._addItem()` (`add_item_dialog.dart:941-990`), juste avant `:987 categoryId: _selectedCategory?.id`, et **aussi** dans le flux vocal `list_detail_screen.dart:770-793` qui envoie `categoryId: null`. Je recommande une classe pure `CategoryGuesser` (asset JSON, normalisation sans accents, match sur préfixe de mot) dans `app/lib/services/`, côté client uniquement : zéro dépendance réseau, fonctionne hors ligne, et ne force rien (la catégorie devinée reste modifiable avant validation).
- Ne pas le faire côté API : l'API ne connaît pas la langue de saisie de façon fiable, et l'app a besoin du résultat avant l'envoi pour l'afficher.

### Q7. i18n

Estimation : **45 à 60 clés** (FR + EN, donc 90-120 entrées) — écran des magasins (liste, créer, renommer, supprimer, fusionner, confirmation : ~15), éditeur d'ordre de rayons (titre, aide, glisser-déposer, réinitialiser, « non classé » : ~10), sélecteur de magasin actif et tri par rayon dans la barre de filtres (~8), auto-catégorisation (« catégorie suggérée », annuler : ~5), erreurs et états vides (~10). Rappel : `app_en.arb` a déjà 1 clé en moins (`days`) et les deux fichiers contiennent des **clés dupliquées** (1481 lignes clé pour 1308 clés uniques en FR) — à nettoyer à l'occasion.

---

## 4. Fonctionnalité 2 — Foyer

### Q1. Point d'insertion des permissions

**Dispersé — signal d'alarme majeur, je le dis clairement.** Détail en §2.2 :
- 4 helpers privés dupliqués (`ListItemController:189-243`, `ListReceiptsController:32-86`, `AnalyticsController:225-250`, `BudgetController:90-112`) ;
- 6 blocs inline dans `ShoppingListController` ;
- 2 méthodes modèle (`canBeAccessedBy`, `scopeAccessibleBy`) qui ignorent le niveau de permission ;
- `AnalyticsController::getUserAccessibleListIds` (l.205-220) qui reconstruit la liste des ids accessibles à sa façon.

Code actuel de la vérification la plus complète (`ListItemController.php:189-243`, abrégé) :
```php
$list = ShoppingList::where('user_id', $user_id)->where('id', $list_id)->first();
if ($list) return ['list' => $list, 'permission' => 'admin'];
$shared = SharedList::where('shared_with_user_id', $user_id)
    ->whereHas('shoppingList', fn($q) => $q->where('id', $list_id))
    ->where('status', SharedList::STATUS_ACCEPTED)->where('is_active', true)->first();
if (!$shared) return null;
$ok = match($requiredPermission) { 'read' => true, 'edit' => $shared->canEdit(), 'delete' => $shared->canDelete() };
```

**Nombre de sites à modifier pour R3 : ~38** (14 dans `ListItemController`, 9 dans `ListReceiptsController`, 3 dans `BudgetController`, 4 dans `MessageController`, 6 dans `ShoppingListController`, 2 dans `SharedListController`, `AnalyticsController::getUserAccessibleListIds`). À cela s'ajoutent les 7 handlers de partage **manquants** (§2.3) qu'il faudra écrire pour que révocation et changement de permission existent réellement.

Le bon chemin n'est pas de modifier 38 sites mais de **centraliser d'abord** : une classe `ListAccessResolver::resolve(userId, listId): ?Access{permission}` dans `api/src/Services/`, que les 4 helpers délèguent, puis remplacement progressif des blocs inline. C'est un préalable de 3-5 j, **sans test pour se protéger**.

### Q2. Non-régression du partage

Implémentation de R3 sans toucher à `SharedList` :
1. `ListAccessResolver` calcule trois valeurs indépendantes — `owner` (`shopping_lists.user_id`), `share` (requête `shared_list` existante, inchangée), `household` (`shopping_lists.household_id` non nul ET `household_members(household_id, user_id)` existe, rôle → `admin` si owner/admin, `edit` sinon) — et renvoie `max()` sur l'ordre `readOnly < edit < admin`.
2. `SharedList::canEdit()/canDelete()`, la génération de token, `accept/decline/leave` ne sont **pas modifiés** : ils restent une des trois sources.
3. `ShoppingList::scopeAccessibleBy` (`:307-317`) et `AnalyticsController::getUserAccessibleListIds` gagnent une troisième clause `orWhereIn('household_id', mesFoyers)`.
4. L'app lit déjà ses droits dans `is_owner / share_permission / can_edit / can_delete` de la réponse (`app/lib/models/shopping_list.dart:359-369`) : si l'API renvoie la permission effective dans ces mêmes champs, **aucun changement Flutter** n'est nécessaire pour que l'UI respecte R3 (`isReadOnly`, `canManageItems` `:152-158`).

Tests existants couvrant le partage : **aucun** (§2.4). Il faut en écrire avant de centraliser : un jeu PHPUnit (owner / invité readOnly / invité edit / invité admin / non-membre × 6 routes clés) est le minimum, ~2-3 j incluant la mise en place de PHPUnit et d'une base de test.

### Q3. Réutilisation des invitations

**Réutilisable partiellement, mais je recommande un système parallèle léger.** Arguments depuis le code :
- `shared_list` mélange dans une seule ligne l'invitation (`share_token`, `status`, `expires_at`) et le partage effectif (`shared_with_user_id`, `permission`, `is_active`) (`SharedListController.php:53-63`). Une invitation au foyer n'a ni `list_id` ni `permission` ; la réutiliser forcerait `list_id NULL` sur une colonne `NOT NULL` et un `permission` sans sens.
- Le code de génération de token (`:332-338`) et le hook d'expiration (`SharedList.php:250-254`) font 15 lignes à eux deux : rien à gagner à les partager.
- Ce qui **doit** être réutilisé : le deep link. `app_links` est déjà configuré pour `epilist://share/{token}` ; ajouter `epilist://household/{token}` + `https://epilist.app/household/{token}` + une page web `web/app/household/[token]` (copie de `share/[token]`) est mécanique (~1 j).

Proposition : `household_invitations(id, household_id, token UNIQUE, invited_by, email NULL, status, expires_at, accepted_by NULL, accepted_at)` avec les mêmes constantes de statut que `SharedList` (`pending/accepted/declined/expired/revoked`).

### Q4. Conflits hors ligne — le point critique

Scénario : 4 membres, A et B au magasin avec réseau instable, même liste.

Chemin du code : `TogglePurchasedStatus(isPurchased: valeurCible)` (`list_detail_screen.dart:504-510`) → hors ligne, enfilé avec `is_purchased` absolu (`list_item_bloc.dart:503-512`) → rejoué par `PATCH /items/{id}/toggle {is_purchased}` (`offline_sync_service.dart:214-220`, `list_item_service.dart:166-177`) → **le serveur ignore le corps et inverse** (`ListItemController.php:560`).

Ce qui casse, dans l'ordre :
1. **Double coche = décoche.** A et B cochent « Lait » hors ligne. A se resynchronise : lait coché. B se resynchronise : lait **décoché**. Avec 4 membres dont 2 actifs, c'est systématique, pas théorique. Ce bug est déjà présent avec le partage actuel ; il est juste rare avec deux utilisateurs dont un seul fait les courses.
2. **Pas de détection de conflit.** `ConflictResolutionService` n'est pas branché ; aucun `updated_at` n'est envoyé ; le serveur n'a pas de colonne `version`. Il n'y a donc aucune résolution : c'est du last-write-wins aveugle sur chaque champ, action par action.
3. **Actions en double.** `isDuplicateAction()` n'est pas appelé : si A coche, décoche, recoche hors ligne, trois `toggle` sont rejoués — avec la sémantique d'inversion, le résultat dépend de l'état serveur au moment du rejeu, pas de l'intention.
4. **Articles créés hors ligne.** A ajoute « Beurre » (id `-17xxxx`), le coche ; le `create_item` passe, le `toggle_item` est rejoué avec l'id négatif → 404 → `markAsFailed` → 5 essais → abandonné. B ne verra jamais le beurre coché.
5. **Suppression vs modification.** A supprime « Pain », B le coche : l'ordre de rejeu (par `timestamp` d'appareil, horloges non synchronisées) décide. Le toggle sur un article soft-deleted renvoie 404 et finit abandonné ; pas de message à l'utilisateur.
6. **Aucun rafraîchissement après synchro** : B ne voit pas les coches de A tant qu'il ne tire pas pour rafraîchir ; pas de push « liste modifiée » (la seule notification multi-participants est le chat, `MessageController:142-150`).

**La stratégie actuelle ne tient pas avec 4 acteurs — elle ne tient déjà pas avec 2.** Minimum viable avant le foyer :
- `PATCH /toggle` doit appliquer la valeur reçue si présente (`is_purchased` absolu), et ne rester une inversion que si le corps est vide. Une ligne côté serveur, rétro-compatible. C'est **le** correctif à faire cette semaine, foyer ou pas.
- Ajouter `If-Unmodified-Since`/`updated_at` au `PUT /items/{id}` complet (pas au toggle) et renvoyer 409 → côté app, recharger et réappliquer ; `ConflictResolutionService` existant peut servir de base (`MERGE` privilégie `is_purchased`/`quantity`/`price` locaux, `:173-180`), mais le brancher demande ~3 j.
- Mapping id temporaire → id serveur dans `OfflineSyncService` (réécrire les actions en attente après un `create_item` réussi) : ~2 j.
- Dédoublonnage à l'enfilement (`isDuplicateAction` existe) : 0,5 j.

### Q5. Budgets et analytiques

- Budgets : `budgets.household_id NULL` + `scopeForUser` devient « mes budgets OU ceux de mon foyer ». `getUserSpentAmount` (`Budget.php:225-270`) construit `$userLists` par `accessibleBy($this->user_id)` ; pour un budget de foyer, la fenêtre doit être « listes publiées au foyer » (`shopping_lists.household_id = X`), pas « listes accessibles au créateur ». Piège existant : le fallback « articles si reçus = 0 » (`:194`) fait qu'un seul reçu saisi par un membre masque tous les articles cochés par les autres. Avec 4 membres, ce fallback produit des montants incohérents d'un jour à l'autre ; il faut choisir une source (reçus **ou** articles) par budget, pas un fallback.
- `BudgetAlertService` (`:27`) et le cron (`cron.php:247-250`, `:337-344`) font `$budget->user` → un seul destinataire ; voir Q6.
- Analytiques : les 11 endpoints passent par `getUserAccessibleListIds` (`AnalyticsController.php:205-220`). Ajouter un paramètre `scope=me|household` et une clause `orWhere('household_id', …)` dans cette seule méthode couvre 10 endpoints ; `dashboard` (`:887-891`) et `data-quality` (`:2674-2689`) ont des requêtes directes à adapter. **Ampleur : 2-3 j API + 1-2 j Flutter** (sélecteur de périmètre sur `analytics_screen.dart`). La répartition « par catégorie » (`:1348`) reste fausse tant que les catégories sont privées (Q2 de la F1) — c'est un argument de plus pour `categories.kind`.

### Q6. Notifications

- Le cron raisonne **par utilisateur** partout (`cron.php:114-181, 247-250, 337-344, 399-417, 773-791, 1063`). `NotificationService::sendToUser` (`:395-420`) est correct comme brique de base : il suffit de boucler sur les membres.
- Il existe déjà un modèle à copier : `MessageController::sendMessage` (`:142-150`) → `getAllAccessUsers()` → `sendNewMessageNotification` (`NotificationService.php:1129-1187`) avec exclusion de l'expéditeur et vérification `canSendNotification`. Ajouter `Household::memberIds()` et réutiliser ce schéma pour : liste publiée au foyer, liste terminée (aujourd'hui propriétaire seul, `ListCompletionNotificationService.php:95-130`), alerte de budget de foyer.
- Point à corriger au passage : `sendSharedListUpdateNotification` (`:396-425`) appelle une relation `sharedWith()` inexistante → collection vide, jamais appelé. Ne pas s'appuyer dessus.
- Canaux FCM : `list_updates` et `budget_alerts` existent déjà (`app/lib/services/notification_service.dart`, 5 canaux) ; pas de nouveau canal nécessaire. Volume : avec 200 utilisateurs et des foyers de 2-4, la charge reste négligeable.

### Q7. Découpage

**Confirmé, à une condition : une Phase 0 avant A.**

- **Phase 0 — remise à niveau du partage (5-8 j)** : correctif `toggle` ; écriture des 7 handlers manquants (`getSharedLists`, `getListShares`, `updateSharePermission`, `revokeShare`, `revokeAllShareLinks`, `getShareStats`, `showSharePage`) — l'app les appelle déjà ; `ListAccessResolver` centralisé ; PHPUnit + tests d'accès ; mapping id temporaire. Sans cette phase, A hérite d'un partage qui ne sait pas révoquer et d'une synchro qui décoche.
- **Phase A** (foyer, membres, rôles, invitations, publier/dépublier, quitter) : livrable seule. R1 (un seul foyer) = contrainte `UNIQUE(user_id)` sur `household_members`, simple. R2 = `household_id` posé explicitement par `PUT /lists/{id}/publish`. R4 = `PUT /lists/... household_id = NULL` au départ ; le blocage du propriétaire est une vérification dans `leave`. Rien dans A ne crée de dette pour B **si** `ListAccessResolver` est en place et si `stores` (F1) porte déjà `household_id NULL` (voir §5).
- **Phase B** : budget commun, analytiques agrégées, magasins de foyer. Dépend de A et de la F1.

Dette qui rendrait B plus coûteuse si on l'ignore en A : (1) ne pas centraliser l'accès ; (2) faire le budget de foyer en gardant le fallback reçus/articles ; (3) laisser les catégories sans `kind`.

---

## 5. Décision `stores` / foyer

**Recommandation : ni polymorphe, ni `user_id` seul. Deux colonnes nullables dès la F1 : `stores.user_id INT NULL` et `stores.household_id INT NULL`, avec `CHECK ((user_id IS NULL) <> (household_id IS NULL))`.**

Pourquoi pas `owner_type + owner_id` :
- Eloquent gère le polymorphisme (`morphTo`), mais MySQL **ne peut pas poser de FK** sur une paire polymorphe : plus de `ON DELETE CASCADE` quand un utilisateur supprime son compte (flux existant, `POST /auth/confirm-account-deletion`) → magasins orphelins à nettoyer à la main, comme le fait déjà `008_fix_orphaned_data_production.sql` pour d'autres tables.
- Les requêtes « mes magasins + ceux de mon foyer » deviennent `where (owner_type='user' and owner_id=?) or (owner_type='household' and owner_id in (...))` : pas d'index composite propre, et un piège classique d'id qui coïncide entre les deux types.
- Il n'y aura jamais un troisième type de propriétaire dans ce produit.

Pourquoi pas `user_id` seul puis migrer :
- Migration ultérieure = `ALTER` + script de bascule des magasins vers le foyer + fusion des doublons entre conjoints (les deux ont créé « Superstore » chacun de leur côté, avec deux ordres différents) + règle de priorité à inventer + cache Flutter à invalider (`OfflineStorageService` versionne en `'1.0.0'`, `:35-47` — un bump vide tout le cache de tous les utilisateurs). Estimation : **3-4 j** et un risque de régression sur une fonctionnalité que les utilisateurs auront déjà configurée.

Coût de l'option recommandée en F1 : **~0,5 j** (colonne nullable, contrainte, `scopeVisibleTo(userId)` = `where user_id = ? or household_id in (...)`, qui renvoie juste les magasins perso tant que les foyers n'existent pas). En Phase B : `POST /stores/{id}/move-to-household` + l'UI, ~1,5 j, et la fusion manuelle déjà prévue (`/stores/{id}/merge`) règle les doublons entre conjoints.

Règle de résolution quand un utilisateur a un « Superstore » perso et que le foyer en a un aussi : le magasin du **foyer** gagne pour les listes publiées au foyer, le magasin **perso** pour les listes personnelles. Implémentable en Flutter dans le sélecteur de magasin actif, puisque la liste porte `household_id`.

---

## 6. Estimation d'effort

Jours de développement, **une personne**, fourchette pessimiste. Hors recette et publication store.

### Fonctionnalité 1 — Tri par rayon

| Lot | Contenu | Bas | Haut |
|---|---|---|---|
| Schéma | `stores`, `store_category_orders`, `categories.kind`, rétro-remplissage des kinds, script de slug `store_name` → `stores` | 1,5 | 3 |
| API | CRUD stores, merge, ordre en bulk (transaction), `scopeVisibleTo`, exposition du kind | 2 | 4 |
| Flutter | `StoreBloc` + service, écran magasins, éditeur d'ordre (réutiliser le glisser-déposer de `category_management_screen.dart`), sélecteur de magasin actif, `ItemSortBy.aisle`, affichage groupé | 5 | 8 |
| Auto-catégorisation | `CategoryGuesser` + asset 500 entrées, lecture `categories_tags` OFF, branchement dialog + vocal | 2 | 3 |
| Hors ligne | cache, 4 actions, 4 `case` de sync, rechargement post-sync | 1,5 | 3 |
| i18n | 45-60 clés × 2 | 0,5 | 1 |
| Tests | tests Flutter de `apply()` et du guesser ; tests API stores | 1,5 | 2 |
| **Total** | | **14** | **24** |

### Fonctionnalité 2 — Foyer

| Lot | Contenu | Bas | Haut |
|---|---|---|---|
| **Phase 0** — partage | correctif `toggle`, 7 handlers manquants, `ListAccessResolver`, PHPUnit + tests d'accès, mapping id temporaire, dédoublonnage file | 5 | 8 |
| Phase A — schéma | `households`, `household_members`, `household_invitations`, `shopping_lists.household_id` | 0,5 | 1 |
| Phase A — API | CRUD foyer, membres/rôles, invitations + token, publier/dépublier, quitter/transférer/dissoudre, R3 dans le resolver, `scopeAccessibleBy` | 4 | 7 |
| Phase A — Flutter | `HouseholdBloc`, écrans foyer/membres/invitation, deep link `household/{token}`, action « publier au foyer », badges | 5 | 8 |
| Phase A — web | page `household/[token]` | 0,5 | 1 |
| Phase A — notifications | publication, liste terminée aux membres | 1 | 2 |
| Phase A — hors ligne | cache foyer (lecture seule), pas d'actions hors ligne en v1 | 1 | 1,5 |
| Phase A — i18n | ~40 clés × 2 | 0,5 | 1 |
| Phase A — tests | accès R3, invitations, quitter | 1,5 | 2 |
| **Total Phase A (avec Phase 0)** | | **19** | **31** |
| Phase B — budget commun | `household_id`, périmètre des listes, source unique reçus/articles, alertes aux membres | 3 | 5 |
| Phase B — analytiques | `scope=household` dans `getUserAccessibleListIds` + `dashboard` + `data-quality`, sélecteur Flutter | 3 | 5 |
| Phase B — magasins de foyer | move-to-household, règle de priorité, fusion | 2 | 3 |
| Phase B — conflits 409 | `updated_at` sur `PUT`, branchement `ConflictResolutionService` | 3 | 5 |
| Phase B — tests / i18n | | 1 | 2 |
| **Total Phase B** | | **12** | **20** |

---

## 7. Risques classés

| # | Risque | Prob. | Impact | Mitigation |
|---|---|---|---|---|
| 1 | `toggle` inverse au lieu d'appliquer → décoches fantômes dès que deux personnes cochent hors ligne | **Certaine** (code lu) | Élevé — perte de confiance, rétention | Correctif d'une ligne dans `ListItemController.php:560` (valeur absolue si présente). À livrer indépendamment de tout le reste. |
| 2 | Les 7 routes de partage sans handler : révoquer, changer une permission, lister les partages échouent en 500 | Élevée (vérifier la prod, §8) | Élevé — le foyer s'appuie sur un partage incomplet | Phase 0 ; tester manuellement `DELETE /shared-lists/{id}` sur la prod avant de planifier |
| 3 | Catégories privées par utilisateur → tri par rayon incohérent sur listes partagées, analytiques par catégorie déjà fausses | Certaine | Moyen (F1), Élevé (F2-B) | `categories.kind` + tri sur le kind, jamais sur l'id |
| 4 | Contrôle d'accès dispersé : oubli d'un des 38 sites lors de R3 → fuite d'accès entre foyers | Élevée | Élevé (données d'un autre foyer visibles) | `ListAccessResolver` + tests PHPUnit par route **avant** d'ajouter la clause foyer |
| 5 | Aucun test automatisé → régressions silencieuses du partage existant | Certaine | Élevé | PHPUnit + base de test en Phase 0 ; refuser de démarrer A sans |
| 6 | Articles sans catégorie (43/46 en local) → tri par rayon sans effet visible | Élevée | Moyen — fonctionnalité perçue comme cassée | Livrer l'auto-catégorisation **avec** F1, pas après ; repli « non classé » explicite |
| 7 | Id temporaires négatifs non remappés → actions perdues après création hors ligne | Certaine | Moyen, devient élevé avec 4 membres | Mapping dans `OfflineSyncService` (Phase 0) |
| 8 | Encodage latin1 sur `list_items`/`shopping_lists` → slugs de magasins faux sur les accents, fusion ratée | Élevée | Moyen | Slugifier en PHP après `mb_convert_encoding` ; prévoir la conversion des tables en utf8mb4 (hors périmètre, mais à planifier) |
| 9 | Conflit Phase A / F1 sur l'ordre des livraisons : F1 livrée avec `user_id` seul, puis migration | Moyenne | Moyen (3-4 j + régression) | Colonnes `user_id`/`household_id` nullables dès F1 (§5) |
| 10 | Bump de version du cache (`OfflineStorageService` `'1.0.0'`) qui vide tout pour tout le monde à la livraison | Moyenne | Faible-moyen | Ajouter les nouvelles clés sans changer la version ; ne bumper que si un format existant change |
| 11 | Horloges d'appareils non synchronisées → ordre de rejeu incohérent entre membres | Moyenne | Moyen | Le serveur fait foi : `updated_at` serveur comparé, 409 + rechargement (Phase B) |
| 12 | Pas de mécanisme de migration versionné côté API → `ALTER` appliqués à la main en prod | Certaine | Moyen | Scripts SQL idempotents (`IF NOT EXISTS`, comme `create_categories_table.sql`) + note de déploiement |

---

## 8. Ce que je n'ai pas pu vérifier

- **La base de production.** Toutes les requêtes ont tourné sur la base locale (9 utilisateurs, 46 articles, 15 listes). La saleté réelle de `store_name`, la proportion d'articles sans catégorie et l'existence de la FK `fk_list_items_category` en prod (absente du dump `bd_prod.sql` du 7 nov. 2025, ajoutée par une migration conditionnelle) sont à confirmer avec les requêtes de §3-Q1.
- **Le code réellement déployé de `SharedListController.php`.** Le dépôt n'a jamais contenu les 7 handlers manquants, mais le déploiement se fait par FTP ; la prod pourrait avoir une version différente. Test : appeler `GET /shared-lists` avec un token valide sur `m2atodev.com`.
- **Le comportement de Slim** sur une route dont la méthode n'existe pas : je suppose une erreur 500 à l'exécution (résolution du callable), pas au démarrage.
- **Le format exact de `categories_tags`** dans la réponse Open Food Facts v2 pour les produits québécois courants (couverture, langue des tags). Supposé `en:*` d'après la documentation publique ; non testé en live.
- **`app/test/`** : non inspecté ligne par ligne ; j'ai supposé qu'il n'y a pas de test du partage côté Flutter, par cohérence avec l'absence totale côté API.
- **Les horloges et l'ordre de rejeu réel** sur plusieurs appareils : raisonnement à partir du tri par `timestamp` (`offline_sync_service.dart:101-105`), non reproduit.
- **Le nombre d'utilisateurs actifs (~200)** et la taille des foyers : pris du brief, non mesurés.
- **Le volume de clés i18n dupliquées** (1481 lignes pour 1308 clés uniques) : constaté par comptage, mais je n'ai pas listé quelles clés sont en double.
- **Le comportement de `PUT /categories/reorder`** côté serveur (remplacement transactionnel ou mise à jour ligne à ligne) : non lu ; j'ai recommandé le remplacement transactionnel pour `store_category_orders` sans vérifier que l'existant le fait.
