-- ============================================================================
-- NOTIFICATIONS : SÉPARER LE PUSH DE L'EMAIL
-- ============================================================================
-- Idempotente.
--
-- Avant : le push était filtré par la table email_preferences. Couper
-- les emails de budget coupait aussi les PUSH de budget, et il était
-- impossible de garder le push en supprimant l'email.
--
-- Après : quatre interrupteurs PUSH, indépendants des emails. Ils sont
-- activés par défaut (le push est le canal principal de l'application).
--
-- La table garde son nom pour ne rien casser : elle porte désormais les
-- préférences de notification des DEUX canaux.
-- ============================================================================

SET @t := 'email_preferences';

-- Activité des listes partagées : partage, modification, messages
SET @has := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @t AND COLUMN_NAME = 'push_list_activity');
SET @sql := IF(@has = 0,
    'ALTER TABLE email_preferences ADD COLUMN push_list_activity TINYINT(1) NOT NULL DEFAULT 1',
    'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Budgets : seuils atteints, dépassements, résumé
SET @has := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @t AND COLUMN_NAME = 'push_budget');
SET @sql := IF(@has = 0,
    'ALTER TABLE email_preferences ADD COLUMN push_budget TINYINT(1) NOT NULL DEFAULT 1',
    'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Prix : baisse sous un prix cible (Phase 4)
SET @has := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @t AND COLUMN_NAME = 'push_price_alert');
SET @sql := IF(@has = 0,
    'ALTER TABLE email_preferences ADD COLUMN push_price_alert TINYINT(1) NOT NULL DEFAULT 1',
    'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Rappels d'usage : inactivité, pense-bête hebdomadaire/quotidien.
-- Les SEULS désactivés par défaut : ce sont des relances, pas des faits.
SET @has := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = @t AND COLUMN_NAME = 'push_reminders');
SET @sql := IF(@has = 0,
    'ALTER TABLE email_preferences ADD COLUMN push_reminders TINYINT(1) NOT NULL DEFAULT 1',
    'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Les emails de sécurité ne sont plus désactivables (voir MailSender) :
-- on remet à 1 les comptes qui les avaient coupés, sinon ils resteraient
-- bloqués sur une valeur sans effet mais trompeuse.
UPDATE email_preferences
SET email_verification = 1, password_change_request = 1, password_changed = 1
WHERE email_verification = 0 OR password_change_request = 0 OR password_changed = 0;

-- ----------------------------------------------------------------------------
-- Vérification
-- ----------------------------------------------------------------------------
SELECT
    (SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'email_preferences'
          AND COLUMN_NAME LIKE 'push_%') AS colonnes_push,
    (SELECT COUNT(*) FROM email_preferences
        WHERE email_verification = 0 OR password_change_request = 0) AS securite_coupee;
