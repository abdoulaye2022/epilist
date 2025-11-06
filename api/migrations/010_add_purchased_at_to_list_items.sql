-- ================================================================
-- MIGRATION: Ajout de purchased_at aux list_items
-- ================================================================
-- Description: Ajoute une colonne purchased_at pour tracer
--              la date exacte d'achat des items
-- Date: 2025-11-06
-- Version: 1.0
-- ================================================================

-- Désactiver les vérifications de clés étrangères temporairement
SET FOREIGN_KEY_CHECKS = 0;

-- ================================================================
-- 1. Ajouter la colonne purchased_at
-- ================================================================

-- Vérifier si la colonne existe déjà
SET @column_exists = (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'list_items'
    AND COLUMN_NAME = 'purchased_at'
);

SET @sql = IF(@column_exists = 0,
    'ALTER TABLE `list_items` ADD COLUMN `purchased_at` TIMESTAMP NULL AFTER `is_purchased`',
    'SELECT "Colonne purchased_at existe déjà" as message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ================================================================
-- 2. Mettre à jour les items déjà achetés avec updated_at
-- ================================================================

-- Pour les items déjà achetés, initialiser purchased_at avec updated_at
-- (meilleure estimation disponible)
UPDATE `list_items`
SET `purchased_at` = `updated_at`
WHERE `is_purchased` = 1
AND `purchased_at` IS NULL;

-- ================================================================
-- 3. Créer un index pour améliorer les performances
-- ================================================================

SET @index_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'list_items'
    AND INDEX_NAME = 'idx_purchased_at'
);

SET @sql = IF(@index_exists = 0,
    'CREATE INDEX `idx_purchased_at` ON `list_items` (`purchased_at`)',
    'SELECT "Index idx_purchased_at existe déjà" as message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ================================================================
-- 4. Créer un index composite pour les requêtes budget
-- ================================================================

SET @index_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'list_items'
    AND INDEX_NAME = 'idx_list_purchased'
);

SET @sql = IF(@index_exists = 0,
    'CREATE INDEX `idx_list_purchased` ON `list_items` (`list_id`, `is_purchased`, `purchased_at`)',
    'SELECT "Index idx_list_purchased existe déjà" as message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ================================================================
-- 5. RÉACTIVER LES VÉRIFICATIONS DE CLÉS ÉTRANGÈRES
-- ================================================================

SET FOREIGN_KEY_CHECKS = 1;

-- ================================================================
-- 6. VÉRIFICATION FINALE
-- ================================================================

SELECT
    'Migration complétée' as status,
    (SELECT COUNT(*) FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'list_items'
     AND COLUMN_NAME = 'purchased_at') as column_exists,
    (SELECT COUNT(*) FROM `list_items`
     WHERE `is_purchased` = 1
     AND `purchased_at` IS NOT NULL) as items_with_purchase_date,
    (SELECT COUNT(*) FROM information_schema.STATISTICS
     WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'list_items'
     AND INDEX_NAME = 'idx_purchased_at') as index_purchased_at_exists,
    (SELECT COUNT(*) FROM information_schema.STATISTICS
     WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'list_items'
     AND INDEX_NAME = 'idx_list_purchased') as index_list_purchased_exists;

-- ================================================================
-- FIN DE LA MIGRATION
-- ================================================================
--
-- NOTES D'UTILISATION:
-- 1. Cette migration ajoute la colonne purchased_at
-- 2. Initialise avec updated_at pour les items déjà achetés
-- 3. Crée des index pour optimiser les requêtes budget
-- 4. Est idempotente (peut être exécutée plusieurs fois)
--
-- UTILISATION FUTURE:
-- Mettre à jour purchased_at automatiquement quand is_purchased
-- passe de false à true (dans le code PHP)
--
-- ROLLBACK (si nécessaire):
-- DROP INDEX IF EXISTS `idx_purchased_at` ON `list_items`;
-- DROP INDEX IF EXISTS `idx_list_purchased` ON `list_items`;
-- ALTER TABLE `list_items` DROP COLUMN `purchased_at`;
--
-- ================================================================
