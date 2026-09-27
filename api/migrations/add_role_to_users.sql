-- Migration : colonne users.role pour reserver les routes d'administration
-- (campagnes marketing, outils de debug). Idempotente.
-- Application : mysql -u <user> -p epilist < add_role_to_users.sql
-- Puis promouvoir le compte administrateur :
--   UPDATE users SET role = 'admin' WHERE email = '<ton-email>';

SET @col_exists = (
    SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'users' AND column_name = 'role'
);

SET @sql = IF(@col_exists = 0,
    "ALTER TABLE users ADD COLUMN role VARCHAR(20) NOT NULL DEFAULT 'user' AFTER is_active",
    'SELECT "colonne role deja presente"');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
