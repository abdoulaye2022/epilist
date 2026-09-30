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
