-- ============================================================================
-- ESPACES — PHASE 6 : communauté de prix anonymisée (§33)
-- ============================================================================
-- Idempotente.
--
-- Principe §33 : les prix observés peuvent nourrir des AGRÉGATS
-- communautaires (produit / magasin / région / prix / date) — JAMAIS
-- d'identité. La table community_prices ne contient aucun user_id :
-- seulement des statistiques par groupe, publiées uniquement si les
-- règles de qualité sont réunies (assez de contributeurs distincts,
-- assez d'observations, valeurs aberrantes écartées).
--
-- Chaque utilisateur peut se retirer (community_prices_enabled = 0) :
-- ses observations sont exclues du prochain recalcul.
--
-- Prérequis : add_spaces.sql ... add_spaces_phase5.sql.
-- ============================================================================

-- 1) Consentement de partage (retrait possible à tout moment)
SET @has_col := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'community_prices_enabled');
SET @sql := IF(@has_col = 0,
    'ALTER TABLE users ADD COLUMN community_prices_enabled TINYINT(1) NOT NULL DEFAULT 1 AFTER email_marketing_consent',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2) Agrégats matérialisés — reconstruits par public/community_refresh.php
CREATE TABLE IF NOT EXISTS community_prices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    normalized_name VARCHAR(255) NOT NULL,
    product_label VARCHAR(255) NOT NULL,
    store_key VARCHAR(255) NOT NULL,
    store_label VARCHAR(255) NOT NULL,
    region VARCHAR(120) NOT NULL DEFAULT '',
    country VARCHAR(2) NOT NULL DEFAULT '',
    observations INT NOT NULL,
    contributors INT NOT NULL,
    min_price DECIMAL(10,2) NOT NULL,
    median_price DECIMAL(10,2) NOT NULL,
    avg_price DECIMAL(10,2) NOT NULL,
    last_observed_at DATE NOT NULL,
    computed_at DATETIME NOT NULL,
    UNIQUE KEY uq_community (normalized_name, store_key, region, country),
    INDEX idx_comm_product (normalized_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- Vérification
-- ----------------------------------------------------------------------------
SELECT
    (SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'community_prices_enabled') AS consentement,
    (SELECT COUNT(*) FROM community_prices) AS agregats;
