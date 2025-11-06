-- Migration: Système de suggestions intelligentes
-- Date: 2025-01-05
-- Description: Tables pour l'historique d'achats et suggestions basées sur l'IA

-- ============================================================================
-- TABLE: purchase_history
-- ============================================================================
-- Enregistre chaque achat pour analyse et suggestions
-- ============================================================================

CREATE TABLE IF NOT EXISTS purchase_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL COMMENT 'ID de l\'utilisateur',
    product_name VARCHAR(255) NOT NULL COMMENT 'Nom du produit acheté',
    normalized_name VARCHAR(255) NOT NULL COMMENT 'Nom normalisé pour regroupement',
    category_id INT NULL COMMENT 'Catégorie du produit',
    quantity INT DEFAULT 1 COMMENT 'Quantité achetée',
    price DECIMAL(10,2) NULL COMMENT 'Prix payé',
    store_name VARCHAR(255) NULL COMMENT 'Magasin d\'achat',
    barcode VARCHAR(50) NULL COMMENT 'Code-barres si disponible',
    purchased_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Date d\'achat',
    list_id INT NULL COMMENT 'Liste d\'origine',

    -- Métadonnées pour l'analyse
    day_of_week TINYINT COMMENT '1-7 (Lundi-Dimanche)',
    month TINYINT COMMENT '1-12',
    season ENUM('spring', 'summer', 'fall', 'winter') COMMENT 'Saison d\'achat',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Indexes pour analyses rapides
    INDEX idx_user_id (user_id),
    INDEX idx_product_name (normalized_name),
    INDEX idx_category (category_id),
    INDEX idx_purchased_at (purchased_at),
    INDEX idx_user_product (user_id, normalized_name),
    INDEX idx_user_date (user_id, purchased_at),
    INDEX idx_barcode (barcode),

    -- Clés étrangères
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
    FOREIGN KEY (list_id) REFERENCES shopping_lists(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Historique des achats pour suggestions intelligentes';

-- ============================================================================
-- TABLE: product_associations
-- ============================================================================
-- Produits fréquemment achetés ensemble (collaborative filtering)
-- ============================================================================

CREATE TABLE IF NOT EXISTS product_associations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_a VARCHAR(255) NOT NULL COMMENT 'Nom du produit A',
    product_b VARCHAR(255) NOT NULL COMMENT 'Nom du produit B',
    confidence DECIMAL(5,4) NOT NULL COMMENT 'Score de confiance (0-1)',
    support_count INT DEFAULT 0 COMMENT 'Nombre de co-occurrences',
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- Index
    INDEX idx_product_a (product_a),
    INDEX idx_confidence (confidence DESC),
    UNIQUE KEY unique_association (product_a, product_b)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Associations de produits pour suggestions';

-- ============================================================================
-- TABLE: user_purchase_patterns
-- ============================================================================
-- Patterns d'achat personnalisés par utilisateur
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_purchase_patterns (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    product_name VARCHAR(255) NOT NULL,

    -- Statistiques
    total_purchases INT DEFAULT 0,
    avg_quantity DECIMAL(5,2) DEFAULT 1.00,
    avg_price DECIMAL(10,2) NULL,
    avg_days_between INT NULL COMMENT 'Jours entre achats',
    last_purchased_at TIMESTAMP NULL,
    next_suggested_date DATE NULL COMMENT 'Prochaine date suggérée',

    -- Préférences
    preferred_store VARCHAR(255) NULL,
    preferred_category_id INT NULL,

    -- Scoring
    frequency_score DECIMAL(5,2) DEFAULT 0 COMMENT 'Score de fréquence (0-100)',
    recency_score DECIMAL(5,2) DEFAULT 0 COMMENT 'Score de récence (0-100)',
    regularity_score DECIMAL(5,2) DEFAULT 0 COMMENT 'Score de régularité (0-100)',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    -- Index
    INDEX idx_user_id (user_id),
    INDEX idx_next_suggested (next_suggested_date),
    INDEX idx_scores (frequency_score DESC, recency_score DESC),
    UNIQUE KEY unique_user_product (user_id, product_name),

    -- Clés étrangères
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (preferred_category_id) REFERENCES categories(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Patterns d\'achat personnalisés par utilisateur';

-- ============================================================================
-- TABLE: suggestion_feedback
-- ============================================================================
-- Feedback utilisateur sur les suggestions (pour améliorer l'algorithme)
-- ============================================================================

CREATE TABLE IF NOT EXISTS suggestion_feedback (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    action ENUM('accepted', 'rejected', 'modified') NOT NULL,
    suggested_quantity INT NULL,
    actual_quantity INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Index
    INDEX idx_user_id (user_id),
    INDEX idx_action (action),

    -- Clé étrangère
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Feedback sur les suggestions pour amélioration';

-- ============================================================================
-- FONCTION: Normaliser les noms de produits
-- ============================================================================

DELIMITER //

CREATE FUNCTION IF NOT EXISTS normalize_product_name(product_name VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    DECLARE normalized VARCHAR(255);

    -- Convertir en minuscules
    SET normalized = LOWER(product_name);

    -- Supprimer les accents (approximation)
    SET normalized = REPLACE(normalized, 'à', 'a');
    SET normalized = REPLACE(normalized, 'â', 'a');
    SET normalized = REPLACE(normalized, 'é', 'e');
    SET normalized = REPLACE(normalized, 'è', 'e');
    SET normalized = REPLACE(normalized, 'ê', 'e');
    SET normalized = REPLACE(normalized, 'ë', 'e');
    SET normalized = REPLACE(normalized, 'î', 'i');
    SET normalized = REPLACE(normalized, 'ï', 'i');
    SET normalized = REPLACE(normalized, 'ô', 'o');
    SET normalized = REPLACE(normalized, 'ù', 'u');
    SET normalized = REPLACE(normalized, 'û', 'u');
    SET normalized = REPLACE(normalized, 'ç', 'c');

    -- Supprimer les caractères spéciaux
    SET normalized = REGEXP_REPLACE(normalized, '[^a-z0-9 ]', '');

    -- Supprimer les espaces multiples
    SET normalized = REGEXP_REPLACE(normalized, ' +', ' ');

    -- Trim
    SET normalized = TRIM(normalized);

    RETURN normalized;
END//

DELIMITER ;

-- ============================================================================
-- TRIGGER: Auto-remplir purchase_history lors d'un achat
-- ============================================================================

DELIMITER //

CREATE TRIGGER IF NOT EXISTS after_item_purchased
AFTER UPDATE ON list_items
FOR EACH ROW
BEGIN
    -- Si l'article vient d'être marqué comme acheté
    IF NEW.is_purchased = 1 AND OLD.is_purchased = 0 THEN

        -- Déterminer la saison
        SET @season = CASE
            WHEN MONTH(NOW()) IN (3,4,5) THEN 'spring'
            WHEN MONTH(NOW()) IN (6,7,8) THEN 'summer'
            WHEN MONTH(NOW()) IN (9,10,11) THEN 'fall'
            ELSE 'winter'
        END;

        -- Insérer dans l'historique
        INSERT INTO purchase_history (
            user_id,
            product_name,
            normalized_name,
            category_id,
            quantity,
            price,
            store_name,
            barcode,
            list_id,
            day_of_week,
            month,
            season
        )
        SELECT
            sl.user_id,
            NEW.product_name,
            normalize_product_name(NEW.product_name),
            NEW.category_id,
            NEW.quantity,
            NEW.price,
            NEW.store_name,
            NEW.barcode,
            NEW.list_id,
            DAYOFWEEK(NOW()),
            MONTH(NOW()),
            @season
        FROM shopping_lists sl
        WHERE sl.id = NEW.list_id;

    END IF;
END//

DELIMITER ;

-- ============================================================================
-- PROCÉDURE: Calculer les patterns d'achat
-- ============================================================================

DELIMITER //

CREATE PROCEDURE IF NOT EXISTS calculate_purchase_patterns(IN p_user_id INT)
BEGIN
    -- Recalculer les patterns pour un utilisateur

    -- Supprimer les anciens patterns
    DELETE FROM user_purchase_patterns WHERE user_id = p_user_id;

    -- Calculer les nouveaux patterns
    INSERT INTO user_purchase_patterns (
        user_id,
        product_name,
        total_purchases,
        avg_quantity,
        avg_price,
        avg_days_between,
        last_purchased_at,
        next_suggested_date,
        preferred_store,
        frequency_score,
        recency_score,
        regularity_score
    )
    SELECT
        p_user_id,
        normalized_name,
        COUNT(*) as total,
        AVG(quantity) as avg_qty,
        AVG(price) as avg_prc,

        -- Calcul des jours moyens entre achats
        CASE
            WHEN COUNT(*) > 1 THEN
                DATEDIFF(MAX(purchased_at), MIN(purchased_at)) / (COUNT(*) - 1)
            ELSE NULL
        END as avg_days,

        MAX(purchased_at) as last_purchase,

        -- Prédiction de la prochaine date
        CASE
            WHEN COUNT(*) > 1 THEN
                DATE_ADD(MAX(purchased_at), INTERVAL
                    DATEDIFF(MAX(purchased_at), MIN(purchased_at)) / (COUNT(*) - 1) DAY)
            ELSE NULL
        END as next_date,

        -- Magasin préféré
        (SELECT store_name FROM purchase_history
         WHERE user_id = p_user_id AND normalized_name = ph.normalized_name
         AND store_name IS NOT NULL
         GROUP BY store_name
         ORDER BY COUNT(*) DESC LIMIT 1) as pref_store,

        -- Score de fréquence (0-100)
        LEAST(100, COUNT(*) * 10) as freq_score,

        -- Score de récence (0-100) - plus c'est récent, plus le score est élevé
        GREATEST(0, 100 - DATEDIFF(NOW(), MAX(purchased_at))) as rec_score,

        -- Score de régularité (0-100) - variance faible = régularité élevée
        CASE
            WHEN COUNT(*) > 2 THEN
                GREATEST(0, 100 - (STDDEV(DATEDIFF(purchased_at,
                    LAG(purchased_at) OVER (PARTITION BY normalized_name ORDER BY purchased_at))) * 5))
            ELSE 50
        END as reg_score

    FROM purchase_history ph
    WHERE user_id = p_user_id
    GROUP BY normalized_name
    HAVING COUNT(*) >= 2; -- Au moins 2 achats pour créer un pattern

END//

DELIMITER ;

-- ============================================================================
-- INDEX SUPPLÉMENTAIRES POUR PERFORMANCE
-- ============================================================================

-- Index pour les requêtes fréquentes
CREATE INDEX idx_purchase_user_product_date ON purchase_history(user_id, normalized_name, purchased_at DESC);

-- ============================================================================
-- DONNÉES DE TEST (Optionnel)
-- ============================================================================

-- Exemple d'historique d'achats
-- INSERT INTO purchase_history (user_id, product_name, normalized_name, quantity, price, store_name) VALUES
-- (1, 'Lait demi-écrémé', 'lait demi ecreme', 2, 1.50, 'Carrefour'),
-- (1, 'Pain de mie', 'pain de mie', 1, 2.00, 'Carrefour'),
-- (1, 'Yaourts nature', 'yaourts nature', 4, 3.50, 'Lidl');

-- ============================================================================
-- VÉRIFICATIONS POST-MIGRATION
-- ============================================================================

SELECT
    TABLE_NAME,
    TABLE_ROWS,
    CREATE_TIME,
    TABLE_COMMENT
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
AND TABLE_NAME IN ('purchase_history', 'product_associations', 'user_purchase_patterns', 'suggestion_feedback');

-- Vérifier les index
SHOW INDEX FROM purchase_history;
SHOW INDEX FROM user_purchase_patterns;

-- Vérifier la fonction
SHOW CREATE FUNCTION normalize_product_name;

-- Vérifier le trigger
SHOW CREATE TRIGGER after_item_purchased;

-- Vérifier la procédure
SHOW CREATE PROCEDURE calculate_purchase_patterns;

-- ============================================================================
-- ROLLBACK (En cas de problème)
-- ============================================================================
-- Pour annuler cette migration :
--
-- DROP TRIGGER IF EXISTS after_item_purchased;
-- DROP PROCEDURE IF EXISTS calculate_purchase_patterns;
-- DROP FUNCTION IF EXISTS normalize_product_name;
-- DROP TABLE IF EXISTS suggestion_feedback;
-- DROP TABLE IF EXISTS user_purchase_patterns;
-- DROP TABLE IF EXISTS product_associations;
-- DROP TABLE IF EXISTS purchase_history;
--
-- ============================================================================

SELECT 'Migration add_smart_suggestions.sql terminée avec succès!' AS Status;
