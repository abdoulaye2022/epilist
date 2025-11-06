-- ================================================================
-- MIGRATION DE PRODUCTION : Email Preferences
-- ================================================================
-- Description: Mise à jour de la base de données de production
--              pour ajouter la fonctionnalité de préférences d'emails
-- Date: 2025-11-06
-- Version: 1.0
-- ================================================================

-- Désactiver les vérifications de clés étrangères temporairement
SET FOREIGN_KEY_CHECKS = 0;

-- ================================================================
-- 1. Création de la table email_preferences
-- ================================================================

CREATE TABLE IF NOT EXISTS `email_preferences` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,

    -- Préférences pour les emails transactionnels
    `email_verification` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Email de vérification de compte',
    `password_change_request` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Email de demande de changement de mot de passe',
    `password_changed` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Email de confirmation de changement de mot de passe',

    -- Préférences pour les emails de notification
    `list_shared_with_me` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Notif quand une liste est partagée avec moi',
    `list_item_added` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Notif quand un article est ajouté à une liste partagée',
    `list_item_checked` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Notif quand un article est coché dans une liste partagée',
    `list_completed` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Notif quand une liste partagée est complétée',

    -- Préférences pour les emails de budget
    `budget_alert` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Alertes quand le budget est dépassé',
    `budget_summary` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Résumé mensuel du budget',

    -- Préférences pour les emails marketing
    `marketing_emails` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Emails marketing et promotions',
    `product_updates` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Nouvelles fonctionnalités et mises à jour',
    `tips_and_tricks` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Conseils et astuces d''utilisation',

    -- Fréquence des notifications groupées
    `notification_frequency` ENUM('realtime', 'daily', 'weekly') NOT NULL DEFAULT 'realtime' COMMENT 'Fréquence des notifications',

    -- Timestamps
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- Clés étrangères et index
    UNIQUE KEY `unique_user_preferences` (`user_id`),
    CONSTRAINT `fk_email_prefs_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================================
-- 2. Création des index pour améliorer les performances
-- ================================================================

-- Index pour les requêtes par fréquence de notification
SET @index_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'email_preferences'
    AND INDEX_NAME = 'idx_notification_frequency'
);

SET @sql = IF(@index_exists = 0,
    'CREATE INDEX `idx_notification_frequency` ON `email_preferences` (`notification_frequency`)',
    'SELECT "Index idx_notification_frequency existe déjà" as message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Index pour les requêtes sur les emails marketing
SET @index_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'email_preferences'
    AND INDEX_NAME = 'idx_marketing_emails'
);

SET @sql = IF(@index_exists = 0,
    'CREATE INDEX `idx_marketing_emails` ON `email_preferences` (`marketing_emails`)',
    'SELECT "Index idx_marketing_emails existe déjà" as message'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ================================================================
-- 3. Création des préférences par défaut pour les utilisateurs existants
-- ================================================================

-- Insérer des préférences par défaut pour tous les utilisateurs
-- qui n'ont pas encore d'entrée dans email_preferences
INSERT INTO `email_preferences` (`user_id`)
SELECT `id` FROM `users`
WHERE `id` NOT IN (
    SELECT `user_id` FROM `email_preferences`
)
AND `deleted_at` IS NULL;

-- ================================================================
-- 4. Vérifications post-migration
-- ================================================================

-- Compter le nombre d'utilisateurs sans préférences email (devrait être 0)
SELECT
    COUNT(*) as users_without_preferences,
    'Si ce nombre est 0, la migration est réussie' as status
FROM `users` u
LEFT JOIN `email_preferences` ep ON u.id = ep.user_id
WHERE u.deleted_at IS NULL
AND ep.id IS NULL;

-- Afficher les statistiques de la table email_preferences
SELECT
    COUNT(*) as total_preferences,
    SUM(marketing_emails = 1) as users_with_marketing_enabled,
    SUM(marketing_emails = 0) as users_with_marketing_disabled,
    COUNT(DISTINCT notification_frequency) as different_frequencies
FROM `email_preferences`;

-- ================================================================
-- 5. Réactiver les vérifications de clés étrangères
-- ================================================================

SET FOREIGN_KEY_CHECKS = 1;

-- ================================================================
-- FIN DE LA MIGRATION
-- ================================================================
--
-- NOTES D'UTILISATION:
-- 1. Cette migration est idempotente (peut être exécutée plusieurs fois)
-- 2. Tous les utilisateurs existants recevront des préférences par défaut
--    avec toutes les notifications activées
-- 3. Les nouveaux utilisateurs devront avoir leurs préférences créées
--    automatiquement lors de l'inscription (via le code PHP)
--
-- ROLLBACK (si nécessaire):
-- DROP INDEX IF EXISTS `idx_notification_frequency` ON `email_preferences`;
-- DROP INDEX IF EXISTS `idx_marketing_emails` ON `email_preferences`;
-- DROP TABLE IF EXISTS `email_preferences`;
--
-- ================================================================
