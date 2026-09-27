-- ============================================================
-- TRI PAR RAYON — Tranche A : magasins et ordre des rayons
-- Date : 2026-09-28. Idempotente (rejouable sans erreur).
--
-- 1. categories.kind : identite commune des 12 categories par defaut,
--    independante de l'utilisateur (l'ordre des rayons se definit sur le
--    kind, jamais sur category_id — indispensable pour les listes partagees).
-- 2. stores : magasins de l'utilisateur (household_id NULL des maintenant,
--    pret pour le foyer sans migration future).
-- 3. store_category_orders : position de chaque rayon (kind) par magasin.
-- 4. Seed : cree les magasins depuis les store_name deja saisis.
-- ============================================================

-- 1. categories.kind -------------------------------------------------
SET @c = (SELECT COUNT(*) FROM information_schema.columns
          WHERE table_schema = DATABASE() AND table_name = 'categories' AND column_name = 'kind');
SET @sql = IF(@c = 0,
    "ALTER TABLE categories ADD COLUMN kind VARCHAR(40) NULL COMMENT 'Identite commune des categories par defaut (dairy, bakery...)' AFTER name",
    'SELECT "categories.kind deja presente"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c = (SELECT COUNT(*) FROM information_schema.statistics
          WHERE table_schema = DATABASE() AND table_name = 'categories' AND index_name = 'idx_categories_kind');
SET @sql = IF(@c = 0, 'CREATE INDEX idx_categories_kind ON categories(kind)', 'SELECT "index kind deja present"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Retro-remplissage par nom pour les categories par defaut existantes
UPDATE categories SET kind = 'fruits_vegetables' WHERE kind IS NULL AND name = 'Fruits & Légumes';
UPDATE categories SET kind = 'meat_fish'         WHERE kind IS NULL AND name = 'Viandes & Poissons';
UPDATE categories SET kind = 'dairy'             WHERE kind IS NULL AND name = 'Produits laitiers';
UPDATE categories SET kind = 'bakery'            WHERE kind IS NULL AND name = 'Boulangerie';
UPDATE categories SET kind = 'drinks'            WHERE kind IS NULL AND name = 'Boissons';
UPDATE categories SET kind = 'snacks'            WHERE kind IS NULL AND name = 'Snacks & Sucreries';
UPDATE categories SET kind = 'hygiene'           WHERE kind IS NULL AND name = 'Hygiène & Beauté';
UPDATE categories SET kind = 'household'         WHERE kind IS NULL AND name = 'Entretien ménager';
UPDATE categories SET kind = 'baby'              WHERE kind IS NULL AND name = 'Bébé & Enfants';
UPDATE categories SET kind = 'pets'              WHERE kind IS NULL AND name = 'Animaux';
UPDATE categories SET kind = 'health'            WHERE kind IS NULL AND name = 'Santé & Pharmacie';
UPDATE categories SET kind = 'other'             WHERE kind IS NULL AND name = 'Autre';

-- 2. stores -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS stores (
    id INT NOT NULL AUTO_INCREMENT,
    user_id INT NULL,
    household_id INT NULL COMMENT 'Reserve pour le futur mode foyer',
    name VARCHAR(120) NOT NULL,
    slug VARCHAR(140) NOT NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_store_user_slug (user_id, slug),
    KEY idx_stores_user (user_id),
    CONSTRAINT fk_stores_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. store_category_orders ---------------------------------------------
CREATE TABLE IF NOT EXISTS store_category_orders (
    id INT NOT NULL AUTO_INCREMENT,
    store_id INT NOT NULL,
    category_kind VARCHAR(40) NOT NULL,
    position SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_store_kind (store_id, category_kind),
    CONSTRAINT fk_sco_store FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Seed des magasins depuis les noms deja saisis ----------------------
-- Un magasin par (proprietaire de liste, nom normalise). INSERT IGNORE :
-- rejouable, ne touche pas les magasins deja crees.
INSERT IGNORE INTO stores (user_id, name, slug)
SELECT sl.user_id,
       MIN(TRIM(CONVERT(li.store_name USING utf8mb4))),
       LOWER(TRIM(CONVERT(li.store_name USING utf8mb4)))
FROM list_items li
JOIN shopping_lists sl ON sl.id = li.list_id
WHERE li.store_name IS NOT NULL
  AND TRIM(li.store_name) <> ''
  AND sl.user_id IS NOT NULL
GROUP BY sl.user_id, LOWER(TRIM(CONVERT(li.store_name USING utf8mb4)));

-- Verification finale ----------------------------------------------------
SELECT 'categories avec kind' AS verif, COUNT(*) AS n FROM categories WHERE kind IS NOT NULL
UNION ALL
SELECT 'magasins seedes', COUNT(*) FROM stores;
