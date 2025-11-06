-- Migration: Create email_preferences table
-- Description: Table pour gérer les préférences d'email des utilisateurs
-- Date: 2025-01-06

CREATE TABLE IF NOT EXISTS `email_preferences` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,

    -- Préférences pour les emails transactionnels (toujours activés, mais trackés)
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
    `tips_and_tricks` TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Conseils et astuces d\'utilisation',

    -- Fréquence des notifications groupées
    `notification_frequency` ENUM('realtime', 'daily', 'weekly') NOT NULL DEFAULT 'realtime' COMMENT 'Fréquence des notifications',

    -- Timestamps
    `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- Clés étrangères et index
    UNIQUE KEY `unique_user_preferences` (`user_id`),
    CONSTRAINT `fk_email_prefs_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Index pour améliorer les performances des requêtes
CREATE INDEX `idx_notification_frequency` ON `email_preferences` (`notification_frequency`);
CREATE INDEX `idx_marketing_emails` ON `email_preferences` (`marketing_emails`);

-- Créer des préférences par défaut pour tous les utilisateurs existants
INSERT INTO `email_preferences` (`user_id`)
SELECT `id` FROM `users`
WHERE `id` NOT IN (SELECT `user_id` FROM `email_preferences`);
