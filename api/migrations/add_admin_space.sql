-- ============================================================
-- ESPACE ADMINISTRATEUR — versions de l'app mobile + monitoring.
-- Date : 2026-09-27. Idempotente (rejouable sans erreur).
--
-- app_versions : une ligne par plateforme (configuration, pas
-- historique). Livrée ÉTEINTE (active=0, versions NULL) : rien ne
-- se passe tant que l'admin n'a pas renseigné et activé.
-- Les URL des magasins sont servies par le serveur (pas codées en
-- dur dans le binaire) : corrigeable sans republier.
-- ============================================================

CREATE TABLE IF NOT EXISTS app_versions (
    id INT NOT NULL AUTO_INCREMENT,
    platform VARCHAR(10) NOT NULL COMMENT 'ios | android',
    current_version VARCHAR(20) NULL COMMENT 'publiee sur le magasin',
    minimum_version VARCHAR(20) NULL COMMENT 'en dessous = blocage',
    message_fr TEXT NULL,
    message_en TEXT NULL,
    store_url VARCHAR(300) NULL,
    force_update TINYINT NOT NULL DEFAULT 0,
    active TINYINT NOT NULL DEFAULT 0,
    stats_updated INT NOT NULL DEFAULT 0,
    stats_dismissed INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_app_versions_platform (platform)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO app_versions (platform, store_url, active)
SELECT 'ios', 'https://apps.apple.com/ca/app/epilist/id6748285596', 0
WHERE NOT EXISTS (SELECT 1 FROM app_versions WHERE platform = 'ios');

INSERT INTO app_versions (platform, store_url, active)
SELECT 'android', 'https://play.google.com/store/apps/details?id=com.m2atech.epilist', 0
WHERE NOT EXISTS (SELECT 1 FROM app_versions WHERE platform = 'android');

-- Journal d'erreurs API pour l'écran Monitoring -----------------------
CREATE TABLE IF NOT EXISTS api_error_logs (
    id INT NOT NULL AUTO_INCREMENT,
    method VARCHAR(8) NOT NULL,
    path VARCHAR(255) NOT NULL,
    status SMALLINT NOT NULL,
    message TEXT NULL,
    user_id INT NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_error_logs_created (created_at),
    KEY idx_error_logs_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SELECT 'verification' AS v,
 (SELECT COUNT(*) FROM app_versions) AS app_versions_rows,
 (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='api_error_logs') AS error_logs_table;

-- 2FA administrateur : code OTP envoyé par email à la connexion web ----
SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='users' AND column_name='admin_otp_code');
SET @sql=IF(@c=0,'ALTER TABLE users ADD COLUMN admin_otp_code VARCHAR(255) NULL AFTER role','SELECT "admin_otp_code ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='users' AND column_name='admin_otp_expires_at');
SET @sql=IF(@c=0,'ALTER TABLE users ADD COLUMN admin_otp_expires_at DATETIME NULL AFTER admin_otp_code','SELECT "admin_otp_expires_at ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
