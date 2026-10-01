-- ============================================================================
-- EPILIST — MISE À JOUR DE PRODUCTION
-- ============================================================================
-- Généré le 2026-10-01. À exécuter UNE FOIS, dans cet ordre, sur la base
-- de production (phpMyAdmin : onglet SQL, coller tout le fichier).
--
-- AVANT TOUTE CHOSE : faire un EXPORT SQL COMPLET de la base.
-- L'étape « Phase 4 » touche purchase_history, la table la plus
-- volumineuse : rien n'est supprimé, mais une sauvegarde reste la seule
-- marche arrière possible.
--
-- Ce fichier est IDEMPOTENT : chaque instruction vérifie l'existant
-- avant d'agir. Le relancer ne casse rien et ne duplique rien.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ÉTAPE 0 — PRÉREQUIS : ces migrations plus anciennes doivent déjà être
-- passées. Si une valeur vaut 0 ci-dessous, ARRÊTEZ-VOUS et exécutez
-- d'abord la migration correspondante, sinon la suite échouera.
-- ----------------------------------------------------------------------------
SELECT
    (SELECT COUNT(*) FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'purchase_history')   AS prerequis_price_intelligence,
    (SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'purchase_history'
          AND COLUMN_NAME = 'source')                                          AS prerequis_source,
    (SELECT COUNT(*) FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'home_inventory')     AS prerequis_household_intelligence,
    (SELECT COUNT(*) FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'refresh_tokens')     AS prerequis_refresh_tokens,
    (SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users'
          AND COLUMN_NAME = 'admin_otp_code')                                  AS prerequis_admin_otp,
    (SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'list_receipts'
          AND COLUMN_NAME = 'image_url')                                       AS prerequis_images;


-- ############################################################################
-- ÉTAPE 1/8 — Phase 1 — fondation des espaces
-- source : migrations/add_spaces.sql
-- ############################################################################

-- ============================================================
-- ESPACES (personnel / foyer / restaurant / organisation)
-- Date : 2026-09-30. Idempotente (rejouable sans erreur).
--
-- Phase 1 (fondation) : trois tables + backfill de l'espace
-- personnel de chaque utilisateur existant. AUCUNE table métier
-- n'est modifiée dans cette phase (voir docs/audit-espaces-epilist.md).
-- ============================================================

-- 1. Espaces ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS spaces (
    id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(120) NOT NULL,
    type ENUM('personal','household','restaurant','organization') NOT NULL DEFAULT 'personal',
    owner_user_id INT NOT NULL,
    -- Localisation de l'ESPACE (jamais l'adresse personnelle de
    -- l'utilisateur) : tout est optionnel (voir cahier des charges §6).
    country VARCHAR(2) NULL,
    region VARCHAR(120) NULL,
    city VARCHAR(120) NULL,
    postal_code VARCHAR(20) NULL,
    currency VARCHAR(3) NULL,
    settings JSON NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    PRIMARY KEY (id),
    KEY idx_spaces_owner (owner_user_id),
    KEY idx_spaces_type (type),
    CONSTRAINT fk_spaces_owner FOREIGN KEY (owner_user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Membres ---------------------------------------------------------
-- role : jeu de permissions par défaut ; permissions : surcharges
-- fines par membre (JSON, ex. {"manage_budgets": false}).
CREATE TABLE IF NOT EXISTS space_members (
    id INT NOT NULL AUTO_INCREMENT,
    space_id INT NOT NULL,
    user_id INT NOT NULL,
    role ENUM('owner','admin','manager','member','viewer') NOT NULL DEFAULT 'member',
    permissions JSON NULL,
    status ENUM('active','removed','left') NOT NULL DEFAULT 'active',
    invited_by INT NULL,
    joined_at DATETIME NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_space_user (space_id, user_id),
    KEY idx_members_user (user_id, status),
    CONSTRAINT fk_members_space FOREIGN KEY (space_id) REFERENCES spaces(id) ON DELETE CASCADE,
    CONSTRAINT fk_members_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Invitations -----------------------------------------------------
-- Même cycle de vie que shared_list (pending/accepted/declined/
-- expired/revoked) + lien par jeton, réutilisé par les deep links.
CREATE TABLE IF NOT EXISTS space_invitations (
    id INT NOT NULL AUTO_INCREMENT,
    space_id INT NOT NULL,
    email VARCHAR(150) NOT NULL,
    role ENUM('admin','manager','member','viewer') NOT NULL DEFAULT 'member',
    token CHAR(64) NOT NULL,
    status ENUM('pending','accepted','declined','expired','revoked') NOT NULL DEFAULT 'pending',
    invited_by INT NOT NULL,
    expires_at DATETIME NOT NULL,
    accepted_at DATETIME NULL,
    declined_at DATETIME NULL,
    revoked_at DATETIME NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_space_invite_token (token),
    KEY idx_invites_space (space_id, status),
    KEY idx_invites_email (email, status),
    CONSTRAINT fk_invites_space FOREIGN KEY (space_id) REFERENCES spaces(id) ON DELETE CASCADE,
    CONSTRAINT fk_invites_user FOREIGN KEY (invited_by) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Backfill : un espace personnel par utilisateur existant ---------
-- Idempotent : ne crée rien pour un utilisateur qui possède déjà un
-- espace personnel. Le nom sera affiché traduit côté client (le type
-- 'personal' fait foi) ; « Personnel » n'est qu'une valeur de repli.
INSERT INTO spaces (name, type, owner_user_id, currency, created_at)
SELECT 'Personnel', 'personal', u.id,
       (SELECT c.code FROM currencies c WHERE c.id = u.currency_id),
       NOW()
FROM users u
WHERE NOT EXISTS (
    SELECT 1 FROM spaces s
    WHERE s.owner_user_id = u.id AND s.type = 'personal' AND s.deleted_at IS NULL
);

-- Chaque propriétaire est membre 'owner' de son espace personnel.
INSERT INTO space_members (space_id, user_id, role, status, joined_at)
SELECT s.id, s.owner_user_id, 'owner', 'active', NOW()
FROM spaces s
WHERE s.type = 'personal' AND s.deleted_at IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM space_members m
    WHERE m.space_id = s.id AND m.user_id = s.owner_user_id
  );

SELECT 'verification' AS v,
 (SELECT COUNT(*) FROM spaces) AS spaces_total,
 (SELECT COUNT(*) FROM spaces WHERE type='personal') AS personal_spaces,
 (SELECT COUNT(*) FROM space_members) AS members_total,
 (SELECT COUNT(*) FROM users) AS users_total;

-- ############################################################################
-- ÉTAPE 2/8 — Phase 2 — données du foyer
-- source : migrations/add_spaces_phase2.sql
-- ############################################################################

-- ============================================================
-- ESPACES — PHASE 2 (foyer) : rattachement des tables métier.
-- Date : 2026-09-30. Idempotente (rejouable sans erreur).
-- Prérequis : add_spaces.sql (Phase 1).
--
-- Patron (docs/migration-espaces.md) : colonnes ADDITIVES space_id +
-- created_by_user_id, backfill vers l'espace PERSONNEL du user_id.
-- user_id n'est JAMAIS supprimé. list_items/list_receipts/
-- list_messages héritent de l'espace via list_id (pas de colonne),
-- mais list_items reçoit l'attribution (« ajouté par / acheté par »).
-- ============================================================

-- Utilitaire répété : ajout de colonne si absente.
-- 1. shopping_lists ---------------------------------------------------
SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='shopping_lists' AND column_name='space_id');
SET @sql=IF(@c=0,'ALTER TABLE shopping_lists ADD COLUMN space_id INT NULL AFTER user_id, ADD COLUMN created_by_user_id INT NULL AFTER space_id, ADD KEY idx_sl_space (space_id)','SELECT "sl ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 2. budgets ----------------------------------------------------------
SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='budgets' AND column_name='space_id');
SET @sql=IF(@c=0,'ALTER TABLE budgets ADD COLUMN space_id INT NULL AFTER user_id, ADD COLUMN created_by_user_id INT NULL AFTER space_id, ADD KEY idx_budget_space (space_id)','SELECT "budgets ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 3. home_inventory ---------------------------------------------------
SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='home_inventory' AND column_name='space_id');
SET @sql=IF(@c=0,'ALTER TABLE home_inventory ADD COLUMN space_id INT NULL AFTER user_id, ADD COLUMN created_by_user_id INT NULL AFTER space_id, ADD KEY idx_inv_space (space_id)','SELECT "inventory ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 4. stores (remplace le vestige household_id, jamais lu) -------------
SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='stores' AND column_name='space_id');
SET @sql=IF(@c=0,'ALTER TABLE stores ADD COLUMN space_id INT NULL AFTER user_id, ADD COLUMN created_by_user_id INT NULL AFTER space_id, ADD KEY idx_store_space (space_id)','SELECT "stores ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 5. recurring_lists --------------------------------------------------
SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='recurring_lists' AND column_name='space_id');
SET @sql=IF(@c=0,'ALTER TABLE recurring_lists ADD COLUMN space_id INT NULL AFTER user_id, ADD COLUMN created_by_user_id INT NULL AFTER space_id, ADD KEY idx_rec_space (space_id)','SELECT "recurring ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 6. meal_plans -------------------------------------------------------
SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='meal_plans' AND column_name='space_id');
SET @sql=IF(@c=0,'ALTER TABLE meal_plans ADD COLUMN space_id INT NULL AFTER user_id, ADD COLUMN created_by_user_id INT NULL AFTER space_id, ADD KEY idx_mp_space (space_id)','SELECT "meal_plans ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 7. recipes ----------------------------------------------------------
SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='recipes' AND column_name='space_id');
SET @sql=IF(@c=0,'ALTER TABLE recipes ADD COLUMN space_id INT NULL AFTER user_id, ADD COLUMN created_by_user_id INT NULL AFTER space_id, ADD KEY idx_recipe_space (space_id)','SELECT "recipes ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 8. list_items : attribution (« ajouté par », « acheté par ») --------
SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='list_items' AND column_name='created_by_user_id');
SET @sql=IF(@c=0,'ALTER TABLE list_items ADD COLUMN created_by_user_id INT NULL AFTER store_name, ADD COLUMN purchased_by_user_id INT NULL AFTER created_by_user_id','SELECT "items ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 8b. home_inventory : l'unicité produit devient PAR ESPACE (le même
--     produit peut exister dans le personnel ET dans le foyer).
SET @c=(SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='home_inventory' AND index_name='uq_inventory_user_product');
SET @sql=IF(@c>0,'ALTER TABLE home_inventory DROP INDEX uq_inventory_user_product','SELECT "old idx gone"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
SET @c=(SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='home_inventory' AND index_name='uq_inventory_space_product');
SET @sql=IF(@c=0,'ALTER TABLE home_inventory ADD UNIQUE KEY uq_inventory_space_product (space_id, normalized_name)','SELECT "new idx ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 9. Journal d'activité (événements STRUCTURÉS : type + payload JSON,
--    le rendu traduit fr/en se fait côté client) ----------------------
CREATE TABLE IF NOT EXISTS space_activities (
    id INT NOT NULL AUTO_INCREMENT,
    space_id INT NOT NULL,
    user_id INT NULL,
    type VARCHAR(40) NOT NULL,
    payload JSON NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_act_space (space_id, created_at),
    CONSTRAINT fk_act_space FOREIGN KEY (space_id) REFERENCES spaces(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. Backfills idempotents : espace personnel du propriétaire --------
UPDATE shopping_lists t JOIN spaces s ON s.owner_user_id = t.user_id AND s.type='personal' AND s.deleted_at IS NULL
   SET t.space_id = s.id, t.created_by_user_id = t.user_id WHERE t.space_id IS NULL;
UPDATE budgets t JOIN spaces s ON s.owner_user_id = t.user_id AND s.type='personal' AND s.deleted_at IS NULL
   SET t.space_id = s.id, t.created_by_user_id = t.user_id WHERE t.space_id IS NULL;
UPDATE home_inventory t JOIN spaces s ON s.owner_user_id = t.user_id AND s.type='personal' AND s.deleted_at IS NULL
   SET t.space_id = s.id, t.created_by_user_id = t.user_id WHERE t.space_id IS NULL;
UPDATE stores t JOIN spaces s ON s.owner_user_id = t.user_id AND s.type='personal' AND s.deleted_at IS NULL
   SET t.space_id = s.id, t.created_by_user_id = t.user_id WHERE t.space_id IS NULL;
UPDATE recurring_lists t JOIN spaces s ON s.owner_user_id = t.user_id AND s.type='personal' AND s.deleted_at IS NULL
   SET t.space_id = s.id, t.created_by_user_id = t.user_id WHERE t.space_id IS NULL;
UPDATE meal_plans t JOIN spaces s ON s.owner_user_id = t.user_id AND s.type='personal' AND s.deleted_at IS NULL
   SET t.space_id = s.id, t.created_by_user_id = t.user_id WHERE t.space_id IS NULL;
UPDATE recipes t JOIN spaces s ON s.owner_user_id = t.user_id AND s.type='personal' AND s.deleted_at IS NULL
   SET t.space_id = s.id, t.created_by_user_id = t.user_id WHERE t.space_id IS NULL;
-- Attribution héritée : le propriétaire de la liste a ajouté l'article.
UPDATE list_items li JOIN shopping_lists sl ON sl.id = li.list_id
   SET li.created_by_user_id = sl.user_id
 WHERE li.created_by_user_id IS NULL;
UPDATE list_items li JOIN shopping_lists sl ON sl.id = li.list_id
   SET li.purchased_by_user_id = sl.user_id
 WHERE li.purchased_by_user_id IS NULL AND li.is_purchased = 1;

SELECT 'verification' AS v,
 (SELECT COUNT(*) FROM shopping_lists WHERE space_id IS NULL) AS sl_null,
 (SELECT COUNT(*) FROM budgets WHERE space_id IS NULL) AS budgets_null,
 (SELECT COUNT(*) FROM home_inventory WHERE space_id IS NULL) AS inv_null,
 (SELECT COUNT(*) FROM stores WHERE space_id IS NULL) AS stores_null,
 (SELECT COUNT(*) FROM recurring_lists WHERE space_id IS NULL) AS rec_null,
 (SELECT COUNT(*) FROM meal_plans WHERE space_id IS NULL) AS mp_null,
 (SELECT COUNT(*) FROM recipes WHERE space_id IS NULL) AS recipes_null,
 (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='space_activities') AS activities_table;

-- ############################################################################
-- ÉTAPE 3/8 — Phase 3 — module restaurant
-- source : migrations/add_spaces_phase3.sql
-- ############################################################################

-- ============================================================
-- ESPACES — PHASE 3 (restaurant) : fournisseurs, demandes d'achat,
-- inventaire quantitatif. Date : 2026-09-30. Idempotente.
-- Prérequis : add_spaces.sql, add_spaces_phase2.sql.
-- ============================================================

-- 1. Fournisseurs (espaces professionnels, §22) -----------------------
CREATE TABLE IF NOT EXISTS suppliers (
    id INT NOT NULL AUTO_INCREMENT,
    space_id INT NOT NULL,
    name VARCHAR(150) NOT NULL,
    contact_name VARCHAR(150) NULL,
    phone VARCHAR(40) NULL,
    email VARCHAR(150) NULL,
    notes TEXT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_by_user_id INT NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    PRIMARY KEY (id),
    KEY idx_suppliers_space (space_id, is_active),
    CONSTRAINT fk_suppliers_space FOREIGN KEY (space_id) REFERENCES spaces(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Inventaire quantitatif (§21) : seuils sur home_inventory ---------
SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='home_inventory' AND column_name='min_quantity');
SET @sql=IF(@c=0,'ALTER TABLE home_inventory ADD COLUMN min_quantity DECIMAL(10,3) NULL AFTER quantity, ADD COLUMN reorder_quantity DECIMAL(10,3) NULL AFTER min_quantity, ADD COLUMN preferred_supplier_id INT NULL AFTER reorder_quantity','SELECT "inv qty ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 3. Demandes d'achat (§20) ------------------------------------------
CREATE TABLE IF NOT EXISTS purchase_requests (
    id INT NOT NULL AUTO_INCREMENT,
    space_id INT NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    normalized_name VARCHAR(255) NOT NULL,
    quantity DECIMAL(10,3) NULL,
    unit VARCHAR(10) NULL,
    note VARCHAR(500) NULL,
    status ENUM('draft','pending','approved','rejected','purchased','cancelled') NOT NULL DEFAULT 'pending',
    requested_by INT NOT NULL,
    approved_by INT NULL,
    decided_at DATETIME NULL,
    decision_comment VARCHAR(500) NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_pr_space (space_id, status),
    KEY idx_pr_requester (requested_by),
    CONSTRAINT fk_pr_space FOREIGN KEY (space_id) REFERENCES spaces(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Historique des changements de statut (§20) -----------------------
CREATE TABLE IF NOT EXISTS purchase_request_events (
    id INT NOT NULL AUTO_INCREMENT,
    request_id INT NOT NULL,
    user_id INT NULL,
    from_status VARCHAR(20) NULL,
    to_status VARCHAR(20) NOT NULL,
    comment VARCHAR(500) NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_pre_request (request_id),
    CONSTRAINT fk_pre_request FOREIGN KEY (request_id) REFERENCES purchase_requests(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SELECT 'verification' AS v,
 (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='suppliers') AS suppliers_table,
 (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='purchase_requests') AS requests_table,
 (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='home_inventory' AND column_name='min_quantity') AS inv_min_col;

-- ############################################################################
-- ÉTAPE 4/8 — Phase 4 — intelligence prix  ⚠ SAUVEGARDE OBLIGATOIRE AVANT
-- source : migrations/add_spaces_phase4.sql
-- ############################################################################

-- ============================================================================
-- ESPACES — PHASE 4 : intelligence prix par espace (§23-§27)
-- ============================================================================
-- Idempotente : chaque ALTER est gardé par information_schema, les
-- backfills par un WHERE, la table par CREATE IF NOT EXISTS.
--
-- ⚠️ PRODUCTION : purchase_history est la table la plus volumineuse de
-- la base. Faire une SAUVEGARDE (export SQL) avant d'exécuter ce fichier,
-- puis l'exécuter hors heure de pointe. Le backfill est un UPDATE+JOIN
-- unique, sans suppression : aucune donnée n'est perdue ni modifiée en
-- dehors de la nouvelle colonne space_id.
--
-- Prérequis : add_spaces.sql, add_spaces_phase2.sql, add_spaces_phase3.sql.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1) purchase_history.space_id : chaque observation de prix appartient à
--    un espace (§34 : les prix d'un foyer ne fuient jamais vers un autre
--    espace). user_id est CONSERVÉ (qui a acheté = traçabilité).
-- ----------------------------------------------------------------------------
SET @has_col := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'purchase_history' AND COLUMN_NAME = 'space_id');
SET @sql := IF(@has_col = 0,
    'ALTER TABLE purchase_history ADD COLUMN space_id INT NULL AFTER user_id',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_idx := (SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'purchase_history' AND INDEX_NAME = 'idx_ph_space_norm_date');
SET @sql := IF(@has_idx = 0,
    'ALTER TABLE purchase_history ADD INDEX idx_ph_space_norm_date (space_id, normalized_name, purchased_at)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Backfill : l'historique existant est personnel -> espace personnel de
-- l'utilisateur. Les lignes d'utilisateurs sans espace personnel restent
-- NULL (le repli de lecture space_id IS NULL AND user_id = ? les couvre).
UPDATE purchase_history ph
JOIN spaces s ON s.type = 'personal' AND s.owner_user_id = ph.user_id AND s.deleted_at IS NULL
SET ph.space_id = s.id
WHERE ph.space_id IS NULL;

-- ----------------------------------------------------------------------------
-- 2) product_aliases.space_id : l'apprentissage libellé->produit profite
--    à tout l'espace (un membre du foyer valide « LAIT 2% NAT » une fois).
-- ----------------------------------------------------------------------------
SET @has_col := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'product_aliases' AND COLUMN_NAME = 'space_id');
SET @sql := IF(@has_col = 0,
    'ALTER TABLE product_aliases ADD COLUMN space_id INT NULL AFTER user_id',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_idx := (SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'product_aliases' AND INDEX_NAME = 'idx_pa_space');
SET @sql := IF(@has_idx = 0,
    'ALTER TABLE product_aliases ADD INDEX idx_pa_space (space_id, normalized_alias)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

UPDATE product_aliases pa
JOIN spaces s ON s.type = 'personal' AND s.owner_user_id = pa.user_id AND s.deleted_at IS NULL
SET pa.space_id = s.id
WHERE pa.space_id IS NULL;

-- ----------------------------------------------------------------------------
-- 3) price_alerts : prix cible par espace (§25-§27).
--    store_id NULL = « n'importe quel magasin ». La déduplication
--    anti-spam vit dans last_triggered_at + last_notified_price.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS price_alerts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    space_id INT NOT NULL,
    created_by_user_id INT NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    normalized_name VARCHAR(255) NOT NULL,
    store_id INT NULL,
    target_price DECIMAL(10,2) NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    last_triggered_at DATETIME NULL,
    last_notified_price DECIMAL(10,2) NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_alerts_space_product (space_id, normalized_name, is_active),
    INDEX idx_alerts_creator (created_by_user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- Vérification
-- ----------------------------------------------------------------------------
SELECT
    (SELECT COUNT(*) FROM purchase_history WHERE space_id IS NULL) AS ph_sans_espace,
    (SELECT COUNT(*) FROM product_aliases WHERE space_id IS NULL) AS aliases_sans_espace,
    (SELECT COUNT(*) FROM price_alerts) AS alertes;

-- ############################################################################
-- ÉTAPE 5/8 — Phase 5 — assistant (unicité des magasins par espace)
-- source : migrations/add_spaces_phase5.sql
-- ############################################################################

-- ============================================================================
-- ESPACES — PHASE 5 : assistant intelligent (§17, §28-§31)
-- ============================================================================
-- Idempotente. La Phase 5 est surtout applicative ; ce fichier corrige
-- une contrainte héritée : l'unicité des magasins était PAR UTILISATEUR
-- (user_id, slug), ce qui empêchait le même utilisateur d'avoir « IGA »
-- dans son foyer ET dans son restaurant (erreur 500 à l'import de reçu).
-- L'unicité devient PAR ESPACE (space_id, slug) — même bascule que
-- home_inventory en Phase 2.
--
-- Prérequis : add_spaces.sql ... add_spaces_phase4.sql.
-- ============================================================================

-- 1) Nouvel index unique par espace (avant de retirer l'ancien)
SET @has_idx := (SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'stores' AND INDEX_NAME = 'uq_store_space_slug');
SET @sql := IF(@has_idx = 0,
    'ALTER TABLE stores ADD UNIQUE INDEX uq_store_space_slug (space_id, slug)',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2) Retrait de l'ancienne unicité par utilisateur
SET @has_idx := (SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'stores' AND INDEX_NAME = 'uq_store_user_slug');
SET @sql := IF(@has_idx > 0,
    'ALTER TABLE stores DROP INDEX uq_store_user_slug',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- Vérification
-- ----------------------------------------------------------------------------
SELECT
    (SELECT COUNT(*) FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'stores' AND INDEX_NAME = 'uq_store_space_slug') AS index_espace,
    (SELECT COUNT(*) FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'stores' AND INDEX_NAME = 'uq_store_user_slug') AS ancien_index,
    (SELECT COUNT(*) FROM stores WHERE space_id IS NULL AND deleted_at IS NULL) AS stores_sans_espace;

-- ############################################################################
-- ÉTAPE 6/8 — Phase 6 — communauté de prix anonymisée
-- source : migrations/add_spaces_phase6.sql
-- ############################################################################

-- ============================================================================
-- ESPACES — PHASE 6 : communauté de prix anonymisée (§33)
-- ============================================================================
-- Idempotente.
--
-- Principe §33 : les prix observés peuvent nourrir des AGRÉGATS
-- communautaires (produit / magasin / région / prix / date) — JAMAIS
-- d'identité. La table community_prices ne contient aucun user_id :
-- seulement des statistiques par groupe, publiées uniquement si les
-- règles de qualité sont réunies (assez de contributeurs distincts,
-- assez d'observations, valeurs aberrantes écartées).
--
-- Chaque utilisateur peut se retirer (community_prices_enabled = 0) :
-- ses observations sont exclues du prochain recalcul.
--
-- Prérequis : add_spaces.sql ... add_spaces_phase5.sql.
-- ============================================================================

-- 1) Consentement de partage (retrait possible à tout moment)
SET @has_col := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'community_prices_enabled');
SET @sql := IF(@has_col = 0,
    'ALTER TABLE users ADD COLUMN community_prices_enabled TINYINT(1) NOT NULL DEFAULT 1 AFTER email_marketing_consent',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2) Agrégats matérialisés — reconstruits par public/community_refresh.php
CREATE TABLE IF NOT EXISTS community_prices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    normalized_name VARCHAR(255) NOT NULL,
    product_label VARCHAR(255) NOT NULL,
    store_key VARCHAR(255) NOT NULL,
    store_label VARCHAR(255) NOT NULL,
    region VARCHAR(120) NOT NULL DEFAULT '',
    country VARCHAR(2) NOT NULL DEFAULT '',
    observations INT NOT NULL,
    contributors INT NOT NULL,
    min_price DECIMAL(10,2) NOT NULL,
    median_price DECIMAL(10,2) NOT NULL,
    avg_price DECIMAL(10,2) NOT NULL,
    last_observed_at DATE NOT NULL,
    computed_at DATETIME NOT NULL,
    UNIQUE KEY uq_community (normalized_name, store_key, region, country),
    INDEX idx_comm_product (normalized_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- Vérification
-- ----------------------------------------------------------------------------
SELECT
    (SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'community_prices_enabled') AS consentement,
    (SELECT COUNT(*) FROM community_prices) AS agregats;

-- ############################################################################
-- ÉTAPE 7/8 — Vérification en deux étapes, optionnelle
-- source : migrations/add_two_factor_optin.sql
-- ############################################################################

-- ============================================================================
-- VÉRIFICATION EN DEUX ÉTAPES (2FA) PAR EMAIL — OPTIONNELLE
-- ============================================================================
-- Idempotente.
--
-- Avant : le 2FA était IMPOSÉ aux comptes administrateur (et indisponible
-- pour les autres). Désormais c'est un réglage par utilisateur, désactivé
-- par défaut, que chacun active s'il le souhaite.
--
-- Les colonnes admin_otp_code / admin_otp_expires_at sont CONSERVÉES et
-- réutilisées : elles portent maintenant le code à usage unique de
-- n'importe quel utilisateur, pas seulement d'un admin.
-- ============================================================================

SET @has_col := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'two_factor_enabled');
SET @sql := IF(@has_col = 0,
    'ALTER TABLE users ADD COLUMN two_factor_enabled TINYINT(1) NOT NULL DEFAULT 0 AFTER admin_otp_expires_at',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Les administrateurs subissaient déjà le 2FA : on NE LEUR RETIRE PAS leur
-- protection au passage. Ils peuvent la désactiver eux-mêmes ensuite.
-- (Ne s'applique qu'au premier passage : WHERE two_factor_enabled = 0 et
--  colonne fraîchement créée -> pas de réactivation d'un choix ultérieur.)
SET @sql := IF(@has_col = 0,
    'UPDATE users SET two_factor_enabled = 1 WHERE role = ''admin''',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- Vérification
-- ----------------------------------------------------------------------------
SELECT
    (SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users'
          AND COLUMN_NAME = 'two_factor_enabled') AS colonne_ok,
    (SELECT COUNT(*) FROM users WHERE two_factor_enabled = 1) AS comptes_2fa_actif,
    (SELECT COUNT(*) FROM users WHERE two_factor_enabled = 0) AS comptes_sans_2fa;

-- ############################################################################
-- ÉTAPE 8/8 — Notifications push séparées des emails
-- source : migrations/add_push_preferences.sql
-- ############################################################################

-- ============================================================================
-- NOTIFICATIONS : SÉPARER LE PUSH DE L'EMAIL
-- ============================================================================
-- Idempotente.
--
-- Avant : le push était filtré par la table email_preferences. Couper
-- les emails de budget coupait aussi les PUSH de budget, et il était
-- impossible de garder le push en supprimant l'email.
--
-- Après : quatre interrupteurs PUSH, indépendants des emails. Ils sont
-- activés par défaut (le push est le canal principal de l'application).
--
-- La table garde son nom pour ne rien casser : elle porte désormais les
-- préférences de notification des DEUX canaux.
-- ============================================================================

SET @t := 'email_preferences';

-- Activité des listes partagées : partage, modification, messages
SET @has := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @t AND COLUMN_NAME = 'push_list_activity');
SET @sql := IF(@has = 0,
    'ALTER TABLE email_preferences ADD COLUMN push_list_activity TINYINT(1) NOT NULL DEFAULT 1',
    'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Budgets : seuils atteints, dépassements, résumé
SET @has := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @t AND COLUMN_NAME = 'push_budget');
SET @sql := IF(@has = 0,
    'ALTER TABLE email_preferences ADD COLUMN push_budget TINYINT(1) NOT NULL DEFAULT 1',
    'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Prix : baisse sous un prix cible (Phase 4)
SET @has := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @t AND COLUMN_NAME = 'push_price_alert');
SET @sql := IF(@has = 0,
    'ALTER TABLE email_preferences ADD COLUMN push_price_alert TINYINT(1) NOT NULL DEFAULT 1',
    'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Rappels d'usage : inactivité, pense-bête hebdomadaire/quotidien.
-- Les SEULS désactivés par défaut : ce sont des relances, pas des faits.
SET @has := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @t AND COLUMN_NAME = 'push_reminders');
SET @sql := IF(@has = 0,
    'ALTER TABLE email_preferences ADD COLUMN push_reminders TINYINT(1) NOT NULL DEFAULT 1',
    'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Les emails de sécurité ne sont plus désactivables (voir MailSender) :
-- on remet à 1 les comptes qui les avaient coupés, sinon ils resteraient
-- bloqués sur une valeur sans effet mais trompeuse.
UPDATE email_preferences
SET email_verification = 1, password_change_request = 1, password_changed = 1
WHERE email_verification = 0 OR password_change_request = 0 OR password_changed = 0;

-- ----------------------------------------------------------------------------
-- Vérification
-- ----------------------------------------------------------------------------
SELECT
    (SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'email_preferences'
          AND COLUMN_NAME LIKE 'push_%') AS colonnes_push,
    (SELECT COUNT(*) FROM email_preferences
        WHERE email_verification = 0 OR password_change_request = 0) AS securite_coupee;

-- ----------------------------------------------------------------------------
-- VÉRIFICATION FINALE — tout doit être > 0 (sauf les deux « restants »,
-- qui doivent valoir 0).
-- ----------------------------------------------------------------------------
SELECT
    (SELECT COUNT(*) FROM spaces)                                              AS espaces_crees,
    (SELECT COUNT(*) FROM spaces WHERE type = 'personal')                      AS espaces_personnels,
    (SELECT COUNT(*) FROM purchase_history WHERE space_id IS NULL)             AS restant_historique_sans_espace,
    (SELECT COUNT(*) FROM shopping_lists WHERE space_id IS NULL
        AND deleted_at IS NULL)                                                AS restant_listes_sans_espace,
    (SELECT COUNT(*) FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'price_alerts')       AS table_prix_cible,
    (SELECT COUNT(*) FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'community_prices')   AS table_communaute,
    (SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users'
          AND COLUMN_NAME = 'two_factor_enabled')                              AS colonne_2fa,
    (SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'email_preferences'
          AND COLUMN_NAME LIKE 'push_%')                                       AS colonnes_push;
