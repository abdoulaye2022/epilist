-- ================================================================
-- MIGRATION DE PRODUCTION : Nettoyage des données orphelines
-- ================================================================
-- Description: Nettoie toutes les données orphelines qui empêchent
--              l'ajout des contraintes de clés étrangères
-- Date: 2025-11-06
-- Version: 1.0
-- ================================================================

-- Désactiver les vérifications de clés étrangères temporairement
SET FOREIGN_KEY_CHECKS = 0;

-- ================================================================
-- 1. ANALYSE DES DONNÉES ORPHELINES
-- ================================================================

-- Afficher les données orphelines dans product_suggestions
SELECT
    'product_suggestions' as table_name,
    COUNT(*) as orphaned_rows
FROM `product_suggestions` ps
LEFT JOIN `users` u ON ps.user_id = u.id
WHERE u.id IS NULL;

-- Afficher les données orphelines dans shared_list
SELECT
    'shared_list (owner)' as table_name,
    COUNT(*) as orphaned_rows
FROM `shared_list` sl
LEFT JOIN `users` u ON sl.owner_id = u.id
WHERE u.id IS NULL;

SELECT
    'shared_list (shared_with)' as table_name,
    COUNT(*) as orphaned_rows
FROM `shared_list` sl
LEFT JOIN `users` u ON sl.shared_with_user_id = u.id
WHERE u.id IS NULL;

SELECT
    'shared_list (list_id)' as table_name,
    COUNT(*) as orphaned_rows
FROM `shared_list` sl
LEFT JOIN `shopping_lists` lst ON sl.list_id = lst.id
WHERE lst.id IS NULL;

-- Afficher les données orphelines dans budgets
SELECT
    'budgets (user_id)' as table_name,
    COUNT(*) as orphaned_rows
FROM `budgets` b
LEFT JOIN `users` u ON b.user_id = u.id
WHERE u.id IS NULL;

SELECT
    'budgets (list_id)' as table_name,
    COUNT(*) as orphaned_rows
FROM `budgets` b
LEFT JOIN `shopping_lists` sl ON b.list_id = sl.id
WHERE b.list_id IS NOT NULL AND sl.id IS NULL;

-- Afficher les données orphelines dans shopping_lists
SELECT
    'shopping_lists' as table_name,
    COUNT(*) as orphaned_rows
FROM `shopping_lists` sl
LEFT JOIN `users` u ON sl.user_id = u.id
WHERE u.id IS NULL;

-- Afficher les données orphelines dans list_items
SELECT
    'list_items' as table_name,
    COUNT(*) as orphaned_rows
FROM `list_items` li
LEFT JOIN `shopping_lists` sl ON li.list_id = sl.id
WHERE sl.id IS NULL;

-- Afficher les données orphelines dans list_receipts
SELECT
    'list_receipts' as table_name,
    COUNT(*) as orphaned_rows
FROM `list_receipts` lr
LEFT JOIN `shopping_lists` sl ON lr.list_id = sl.id
WHERE sl.id IS NULL;

-- Afficher les données orphelines dans user_devices
SELECT
    'user_devices' as table_name,
    COUNT(*) as orphaned_rows
FROM `user_devices` ud
LEFT JOIN `users` u ON ud.user_id = u.id
WHERE u.id IS NULL;

-- ================================================================
-- 2. NETTOYAGE DES DONNÉES ORPHELINES
-- ================================================================

-- Supprimer les suggestions de produits orphelines
DELETE FROM `product_suggestions`
WHERE user_id NOT IN (SELECT id FROM `users`);

-- Supprimer les partages de liste orphelins (owner_id invalide)
DELETE FROM `shared_list`
WHERE owner_id NOT IN (SELECT id FROM `users`);

-- Supprimer les partages de liste orphelins (shared_with_user_id invalide)
DELETE FROM `shared_list`
WHERE shared_with_user_id NOT IN (SELECT id FROM `users`);

-- Supprimer les partages de liste orphelins (list_id invalide)
DELETE FROM `shared_list`
WHERE list_id NOT IN (SELECT id FROM `shopping_lists`);

-- Supprimer les reçus orphelins (avant de supprimer les listes)
DELETE FROM `list_receipts`
WHERE list_id NOT IN (SELECT id FROM `shopping_lists`);

-- Supprimer les articles de liste orphelins (avant de supprimer les listes)
DELETE FROM `list_items`
WHERE list_id NOT IN (SELECT id FROM `shopping_lists`);

-- Supprimer les listes de courses orphelines
DELETE FROM `shopping_lists`
WHERE user_id NOT IN (SELECT id FROM `users`);

-- Nettoyer les budgets avec list_id orphelin (mettre à NULL au lieu de supprimer)
UPDATE `budgets`
SET list_id = NULL
WHERE list_id IS NOT NULL
AND list_id NOT IN (SELECT id FROM `shopping_lists`);

-- Supprimer les budgets avec user_id orphelin
DELETE FROM `budgets`
WHERE user_id NOT IN (SELECT id FROM `users`);

-- Supprimer les appareils orphelins
DELETE FROM `user_devices`
WHERE user_id NOT IN (SELECT id FROM `users`);

-- ================================================================
-- 3. VÉRIFICATION POST-NETTOYAGE
-- ================================================================

-- Vérifier qu'il n'y a plus de données orphelines
SELECT
    'Vérification finale' as status,
    (
        SELECT COUNT(*) FROM `product_suggestions` ps
        LEFT JOIN `users` u ON ps.user_id = u.id
        WHERE u.id IS NULL
    ) as orphaned_product_suggestions,
    (
        SELECT COUNT(*) FROM `shared_list` sl
        LEFT JOIN `users` u ON sl.owner_id = u.id
        WHERE u.id IS NULL
    ) as orphaned_shared_list_owner,
    (
        SELECT COUNT(*) FROM `shared_list` sl
        LEFT JOIN `users` u ON sl.shared_with_user_id = u.id
        WHERE u.id IS NULL
    ) as orphaned_shared_list_user,
    (
        SELECT COUNT(*) FROM `budgets` b
        LEFT JOIN `users` u ON b.user_id = u.id
        WHERE u.id IS NULL
    ) as orphaned_budgets,
    (
        SELECT COUNT(*) FROM `shopping_lists` sl
        LEFT JOIN `users` u ON sl.user_id = u.id
        WHERE u.id IS NULL
    ) as orphaned_shopping_lists,
    (
        SELECT COUNT(*) FROM `user_devices` ud
        LEFT JOIN `users` u ON ud.user_id = u.id
        WHERE u.id IS NULL
    ) as orphaned_devices;

-- ================================================================
-- 4. AJOUT DES CONTRAINTES DE CLÉS ÉTRANGÈRES
-- ================================================================

-- Note: Les contraintes seront ajoutées uniquement si elles n'existent pas déjà
-- Si une contrainte existe déjà, MySQL renverra une erreur mais la migration continuera

-- Ajouter les contraintes de clés étrangères pour product_suggestions
SET @constraint_exists = (
    SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA = DATABASE()
    AND TABLE_NAME = 'product_suggestions'
    AND CONSTRAINT_NAME = 'product_suggestions_ibfk_1'
);

SET @sql = IF(@constraint_exists = 0,
    'ALTER TABLE `product_suggestions` ADD CONSTRAINT `product_suggestions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE',
    'SELECT "Contrainte product_suggestions_ibfk_1 existe déjà" as message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Ajouter les contraintes de clés étrangères pour shared_list (owner_id)
SET @constraint_exists = (
    SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA = DATABASE()
    AND TABLE_NAME = 'shared_list'
    AND CONSTRAINT_NAME = 'shared_list_ibfk_1'
);

SET @sql = IF(@constraint_exists = 0,
    'ALTER TABLE `shared_list` ADD CONSTRAINT `shared_list_ibfk_1` FOREIGN KEY (`owner_id`) REFERENCES `users` (`id`) ON DELETE CASCADE',
    'SELECT "Contrainte shared_list_ibfk_1 existe déjà" as message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Ajouter les contraintes de clés étrangères pour shared_list (shared_with_user_id)
SET @constraint_exists = (
    SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA = DATABASE()
    AND TABLE_NAME = 'shared_list'
    AND CONSTRAINT_NAME = 'shared_list_ibfk_2'
);

SET @sql = IF(@constraint_exists = 0,
    'ALTER TABLE `shared_list` ADD CONSTRAINT `shared_list_ibfk_2` FOREIGN KEY (`shared_with_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE',
    'SELECT "Contrainte shared_list_ibfk_2 existe déjà" as message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Ajouter les contraintes de clés étrangères pour shared_list (list_id)
SET @constraint_exists = (
    SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA = DATABASE()
    AND TABLE_NAME = 'shared_list'
    AND CONSTRAINT_NAME = 'shared_list_ibfk_3'
);

SET @sql = IF(@constraint_exists = 0,
    'ALTER TABLE `shared_list` ADD CONSTRAINT `shared_list_ibfk_3` FOREIGN KEY (`list_id`) REFERENCES `shopping_lists` (`id`) ON DELETE CASCADE',
    'SELECT "Contrainte shared_list_ibfk_3 existe déjà" as message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Ajouter les contraintes de clés étrangères pour budgets (user_id)
SET @constraint_exists = (
    SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA = DATABASE()
    AND TABLE_NAME = 'budgets'
    AND CONSTRAINT_NAME = 'budgets_ibfk_1'
);

SET @sql = IF(@constraint_exists = 0,
    'ALTER TABLE `budgets` ADD CONSTRAINT `budgets_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE',
    'SELECT "Contrainte budgets_ibfk_1 existe déjà" as message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Ajouter les contraintes de clés étrangères pour budgets (list_id)
SET @constraint_exists = (
    SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA = DATABASE()
    AND TABLE_NAME = 'budgets'
    AND CONSTRAINT_NAME = 'budgets_ibfk_2'
);

SET @sql = IF(@constraint_exists = 0,
    'ALTER TABLE `budgets` ADD CONSTRAINT `budgets_ibfk_2` FOREIGN KEY (`list_id`) REFERENCES `shopping_lists` (`id`) ON DELETE SET NULL',
    'SELECT "Contrainte budgets_ibfk_2 existe déjà" as message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Ajouter les contraintes de clés étrangères pour shopping_lists
SET @constraint_exists = (
    SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA = DATABASE()
    AND TABLE_NAME = 'shopping_lists'
    AND CONSTRAINT_NAME = 'shopping_lists_ibfk_1'
);

SET @sql = IF(@constraint_exists = 0,
    'ALTER TABLE `shopping_lists` ADD CONSTRAINT `shopping_lists_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE',
    'SELECT "Contrainte shopping_lists_ibfk_1 existe déjà" as message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Ajouter les contraintes de clés étrangères pour list_items
SET @constraint_exists = (
    SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA = DATABASE()
    AND TABLE_NAME = 'list_items'
    AND CONSTRAINT_NAME = 'list_items_ibfk_1'
);

SET @sql = IF(@constraint_exists = 0,
    'ALTER TABLE `list_items` ADD CONSTRAINT `list_items_ibfk_1` FOREIGN KEY (`list_id`) REFERENCES `shopping_lists` (`id`) ON DELETE CASCADE',
    'SELECT "Contrainte list_items_ibfk_1 existe déjà" as message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Ajouter les contraintes de clés étrangères pour list_receipts
SET @constraint_exists = (
    SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA = DATABASE()
    AND TABLE_NAME = 'list_receipts'
    AND CONSTRAINT_NAME = 'list_receipts_ibfk_1'
);

SET @sql = IF(@constraint_exists = 0,
    'ALTER TABLE `list_receipts` ADD CONSTRAINT `list_receipts_ibfk_1` FOREIGN KEY (`list_id`) REFERENCES `shopping_lists` (`id`) ON DELETE CASCADE',
    'SELECT "Contrainte list_receipts_ibfk_1 existe déjà" as message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Ajouter les contraintes de clés étrangères pour user_devices
SET @constraint_exists = (
    SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA = DATABASE()
    AND TABLE_NAME = 'user_devices'
    AND CONSTRAINT_NAME = 'user_devices_ibfk_1'
);

SET @sql = IF(@constraint_exists = 0,
    'ALTER TABLE `user_devices` ADD CONSTRAINT `user_devices_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE',
    'SELECT "Contrainte user_devices_ibfk_1 existe déjà" as message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ================================================================
-- 5. RÉACTIVER LES VÉRIFICATIONS DE CLÉS ÉTRANGÈRES
-- ================================================================

SET FOREIGN_KEY_CHECKS = 1;

-- ================================================================
-- FIN DE LA MIGRATION
-- ================================================================
--
-- NOTES D'UTILISATION:
-- 1. Cette migration nettoie toutes les données orphelines
-- 2. Elle ajoute ensuite les contraintes de clés étrangères
-- 3. Les données orphelines seront DÉFINITIVEMENT supprimées
-- 4. FAITES UN BACKUP avant d'exécuter cette migration !
--
-- ORDRE D'EXÉCUTION:
-- 1. Faire un backup complet de la base de données
-- 2. Exécuter cette migration (008_fix_orphaned_data_production.sql)
-- 3. Exécuter la migration des email_preferences (007_production_update_email_preferences.sql)
--
-- ================================================================
