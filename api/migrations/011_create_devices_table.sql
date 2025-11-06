-- ================================================================
-- MIGRATION: Création de la table devices pour FCM
-- ================================================================
-- Description: Crée la table pour stocker les devices (push notifications)
-- Date: 2025-11-06
-- Version: 1.0
-- ================================================================

-- Désactiver les vérifications de clés étrangères temporairement
SET FOREIGN_KEY_CHECKS = 0;

-- ================================================================
-- 1. CRÉER LA TABLE DEVICES
-- ================================================================

CREATE TABLE IF NOT EXISTS `devices` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT UNSIGNED NOT NULL,
    `device_id` VARCHAR(255) NOT NULL COMMENT 'Unique device identifier (UUID)',
    `platform` ENUM('ios', 'android', 'web') NOT NULL,
    `push_token` TEXT NOT NULL COMMENT 'FCM token',
    `apns_token` TEXT NULL COMMENT 'APNS token for iOS (optional)',
    `app_version` VARCHAR(50) NULL,
    `os_version` VARCHAR(50) NULL,
    `device_model` VARCHAR(100) NULL,
    `is_active` BOOLEAN DEFAULT TRUE,
    `last_active_at` TIMESTAMP NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- Contraintes
    CONSTRAINT `fk_devices_user_id` FOREIGN KEY (`user_id`)
        REFERENCES `users` (`id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    -- Index
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_device_id` (`device_id`),
    INDEX `idx_platform` (`platform`),
    INDEX `idx_is_active` (`is_active`),
    INDEX `idx_last_active` (`last_active_at`),

    -- Un device_id est unique par utilisateur
    UNIQUE KEY `unique_user_device` (`user_id`, `device_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Devices enregistrés pour les notifications push';

-- ================================================================
-- 2. RÉACTIVER LES VÉRIFICATIONS DE CLÉS ÉTRANGÈRES
-- ================================================================

SET FOREIGN_KEY_CHECKS = 1;

-- ================================================================
-- 3. VÉRIFICATION FINALE
-- ================================================================

SELECT
    'Migration complétée' as status,
    (SELECT COUNT(*) FROM information_schema.TABLES
     WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'devices') as table_exists,
    (SELECT COUNT(*) FROM information_schema.STATISTICS
     WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'devices'
     AND INDEX_NAME = 'idx_user_id') as index_user_id_exists,
    (SELECT COUNT(*) FROM information_schema.STATISTICS
     WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'devices'
     AND INDEX_NAME = 'unique_user_device') as unique_constraint_exists;

-- ================================================================
-- FIN DE LA MIGRATION
-- ================================================================
--
-- NOTES D'UTILISATION:
-- 1. Cette table stocke les devices pour les notifications push FCM
-- 2. Un user peut avoir plusieurs devices (iPhone, iPad, Android, etc.)
-- 3. Le push_token est le token FCM
-- 4. L'apns_token est optionnel (pour iOS uniquement)
-- 5. is_active permet de désactiver un device sans le supprimer
--
-- UTILISATION DANS L'API:
-- POST /devices/register - Enregistrer un nouveau device
-- PUT /devices/{deviceId} - Mettre à jour un device
-- DELETE /devices/{deviceId} - Supprimer un device
--
-- ROLLBACK (si nécessaire):
-- DROP TABLE IF EXISTS `devices`;
--
-- ================================================================
