-- ============================================================================
-- VÉRIFICATION EN DEUX ÉTAPES (2FA) PAR EMAIL — OPTIONNELLE
-- ============================================================================
-- Idempotente.
--
-- Avant : le 2FA était IMPOSÉ aux comptes administrateur (et indisponible
-- pour les autres). Désormais c'est un réglage par utilisateur, désactivé
-- par défaut, que chacun active s'il le souhaite.
--
-- Les colonnes admin_otp_code / admin_otp_expires_at sont CONSERVÉES et
-- réutilisées : elles portent maintenant le code à usage unique de
-- n'importe quel utilisateur, pas seulement d'un admin.
-- ============================================================================

SET @has_col := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'two_factor_enabled');
SET @sql := IF(@has_col = 0,
    'ALTER TABLE users ADD COLUMN two_factor_enabled TINYINT(1) NOT NULL DEFAULT 0 AFTER admin_otp_expires_at',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Les administrateurs subissaient déjà le 2FA : on NE LEUR RETIRE PAS leur
-- protection au passage. Ils peuvent la désactiver eux-mêmes ensuite.
-- (Ne s'applique qu'au premier passage : WHERE two_factor_enabled = 0 et
--  colonne fraîchement créée -> pas de réactivation d'un choix ultérieur.)
SET @sql := IF(@has_col = 0,
    'UPDATE users SET two_factor_enabled = 1 WHERE role = ''admin''',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ----------------------------------------------------------------------------
-- Vérification
-- ----------------------------------------------------------------------------
SELECT
    (SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users'
          AND COLUMN_NAME = 'two_factor_enabled') AS colonne_ok,
    (SELECT COUNT(*) FROM users WHERE two_factor_enabled = 1) AS comptes_2fa_actif,
    (SELECT COUNT(*) FROM users WHERE two_factor_enabled = 0) AS comptes_sans_2fa;
