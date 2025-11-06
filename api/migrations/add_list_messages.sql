-- Migration: Ajout du système de chat pour les listes partagées
-- Date: 2025-01-05
-- Description: Création de la table list_messages pour permettre les discussions en temps réel

-- ============================================================================
-- TABLE: list_messages
-- ============================================================================
-- Stocke tous les messages de chat pour les listes partagées
-- ============================================================================

CREATE TABLE IF NOT EXISTS list_messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    list_id INT NOT NULL COMMENT 'ID de la liste de courses',
    user_id INT NOT NULL COMMENT 'ID de l\'utilisateur qui envoie le message',
    message TEXT NOT NULL COMMENT 'Contenu du message',
    message_type ENUM('text', 'image', 'system') DEFAULT 'text' COMMENT 'Type de message',
    image_url VARCHAR(500) NULL COMMENT 'URL de l\'image si message_type = image',
    is_read BOOLEAN DEFAULT FALSE COMMENT 'Message lu par tous les membres',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL COMMENT 'Soft delete',

    -- Indexes pour optimiser les performances
    INDEX idx_list_id (list_id),
    INDEX idx_user_id (user_id),
    INDEX idx_created_at (created_at),
    INDEX idx_list_created (list_id, created_at),

    -- Clés étrangères
    FOREIGN KEY (list_id) REFERENCES shopping_lists(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Messages de chat pour les listes partagées';

-- ============================================================================
-- TABLE: message_read_status
-- ============================================================================
-- Suit qui a lu quel message (pour les indicateurs de lecture)
-- ============================================================================

CREATE TABLE IF NOT EXISTS message_read_status (
    id INT AUTO_INCREMENT PRIMARY KEY,
    message_id INT NOT NULL COMMENT 'ID du message',
    user_id INT NOT NULL COMMENT 'ID de l\'utilisateur qui a lu',
    read_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Indexes
    INDEX idx_message_id (message_id),
    INDEX idx_user_id (user_id),
    UNIQUE KEY unique_message_user (message_id, user_id),

    -- Clés étrangères
    FOREIGN KEY (message_id) REFERENCES list_messages(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Statut de lecture des messages';

-- ============================================================================
-- DONNÉES DE TEST (Optionnel - Décommentez pour tester)
-- ============================================================================

-- Exemple de messages système
-- INSERT INTO list_messages (list_id, user_id, message, message_type) VALUES
-- (1, 1, 'Liste créée', 'system'),
-- (1, 1, 'Bonjour! N\'oublie pas le pain', 'text'),
-- (1, 2, 'D\'accord, je prends aussi du lait?', 'text');

-- ============================================================================
-- VÉRIFICATIONS POST-MIGRATION
-- ============================================================================

-- Vérifier que les tables ont été créées
SELECT
    TABLE_NAME,
    TABLE_ROWS,
    CREATE_TIME,
    TABLE_COMMENT
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
AND TABLE_NAME IN ('list_messages', 'message_read_status');

-- Vérifier les indexes
SHOW INDEX FROM list_messages;
SHOW INDEX FROM message_read_status;

-- ============================================================================
-- ROLLBACK (En cas de problème)
-- ============================================================================
-- Pour annuler cette migration, exécutez les commandes suivantes:
--
-- DROP TABLE IF EXISTS message_read_status;
-- DROP TABLE IF EXISTS list_messages;
--
-- ============================================================================

-- Migration terminée avec succès ✓
SELECT 'Migration add_list_messages.sql terminée avec succès!' AS Status;
