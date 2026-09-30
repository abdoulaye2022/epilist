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
