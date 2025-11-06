-- Migration pour ajouter le support des codes-barres aux articles
-- Date: 2025-01-04
-- Description: Ajout de la colonne barcode à la table list_items de manière sûre

-- IMPORTANT: Cette migration est NON-DESTRUCTIVE
-- Elle peut être exécutée sur une base de données en production sans temps d'arrêt

-- ============================================
-- MIGRATION VERS L'AVANT (UP)
-- ============================================

-- Étape 1: Vérifier si la colonne existe déjà
SET @column_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'list_items'
    AND COLUMN_NAME = 'barcode'
);

-- Étape 2: Ajouter la colonne barcode si elle n'existe pas
SET @sql = IF(
    @column_exists = 0,
    'ALTER TABLE list_items ADD COLUMN barcode VARCHAR(50) NULL AFTER product_name',
    'SELECT "Column barcode already exists" AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Étape 3: Créer un index sur barcode pour accélérer les recherches
SET @index_exists = (
    SELECT COUNT(*)
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'list_items'
    AND INDEX_NAME = 'idx_barcode'
);

SET @sql = IF(
    @index_exists = 0,
    'CREATE INDEX idx_barcode ON list_items(barcode)',
    'SELECT "Index idx_barcode already exists" AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Étape 4: Créer une table de cache pour les produits scannés
CREATE TABLE IF NOT EXISTS scanned_products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    barcode VARCHAR(50) NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    brand VARCHAR(100) NULL,
    quantity VARCHAR(50) NULL,
    image_url VARCHAR(500) NULL,
    nutriments JSON NULL,
    source VARCHAR(50) NOT NULL DEFAULT 'openfoodfacts',
    last_scanned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_barcode (barcode),
    INDEX idx_last_scanned (last_scanned_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- VERIFICATION
-- ============================================

-- Vérifier que la colonne a été ajoutée
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
AND TABLE_NAME = 'list_items'
AND COLUMN_NAME = 'barcode';

-- Vérifier que l'index a été créé
SELECT
    INDEX_NAME,
    COLUMN_NAME,
    SEQ_IN_INDEX
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = DATABASE()
AND TABLE_NAME = 'list_items'
AND INDEX_NAME = 'idx_barcode';

-- Vérifier que la table de cache a été créée
SELECT
    TABLE_NAME,
    ENGINE,
    TABLE_ROWS
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = DATABASE()
AND TABLE_NAME = 'scanned_products';

-- ============================================
-- ROLLBACK (si nécessaire)
-- ============================================

-- Pour annuler cette migration, exécutez les commandes suivantes:
/*

-- Supprimer l'index
DROP INDEX idx_barcode ON list_items;

-- Supprimer la colonne barcode
ALTER TABLE list_items DROP COLUMN barcode;

-- Supprimer la table de cache
DROP TABLE IF EXISTS scanned_products;

*/

-- ============================================
-- NOTES IMPORTANTES
-- ============================================

/*
1. Cette migration est SAFE pour la production:
   - Utilise ALTER TABLE ADD COLUMN (non-bloquant sur MySQL 5.6+)
   - La colonne est NULLABLE donc pas de valeur par défaut requise
   - Pas de modification des données existantes
   - Index créé après l'ajout de la colonne

2. Performance:
   - Sur une table de 1M lignes: ~10-30 secondes
   - Sur une table de 10M lignes: ~2-5 minutes
   - Aucun lock de table pendant l'opération (MySQL 5.6+)

3. Compatibilité:
   - MySQL 5.6+
   - MariaDB 10.0+

4. Utilisation:
   - Le champ barcode stockera le code EAN/UPC du produit
   - Le cache scanned_products évite les appels répétés à l'API
   - Le cache est automatiquement mis à jour avec last_scanned_at

5. Après la migration:
   - Mettre à jour le modèle ListItem.php pour inclure le champ barcode
   - Mettre à jour l'API pour accepter le barcode lors de la création d'un article
   - Implémenter le service de cache des produits scannés
*/
