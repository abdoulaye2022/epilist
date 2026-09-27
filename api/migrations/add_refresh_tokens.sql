-- ============================================================
-- RÉVOCATION DES REFRESH TOKENS — 2026-09-27. Idempotente.
-- Chaque refresh token émis est enregistré (hachage SHA-256).
-- Un token révoqué est refusé au refresh ; désactiver un compte
-- révoque tous ses tokens. Les tokens émis AVANT cette table sont
-- acceptés une fois (grâce héritée) puis remplacés par un token suivi.
-- ============================================================

CREATE TABLE IF NOT EXISTS refresh_tokens (
    id INT NOT NULL AUTO_INCREMENT,
    user_id INT NOT NULL,
    token_hash CHAR(64) NOT NULL,
    expires_at DATETIME NOT NULL,
    revoked_at DATETIME NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_refresh_hash (token_hash),
    KEY idx_refresh_user (user_id),
    KEY idx_refresh_expires (expires_at),
    CONSTRAINT fk_refresh_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SELECT 'verification' AS v,
 (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='refresh_tokens') AS refresh_tokens_table;
