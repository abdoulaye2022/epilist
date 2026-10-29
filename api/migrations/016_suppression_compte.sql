-- Migration 016 — la suppression de compte efface vraiment.
--
-- Avant : confirmer la suppression mettait is_active = 0 et deleted_at,
-- puis l'API repondait « Compte supprime avec succes ». La ligne users
-- restait entiere — courriel, prenom, nom, empreinte du mot de passe —
-- avec les listes, les recus et les images. anonymizeData() existait
-- dans le modele et n'etait appelee nulle part.
--
-- Cette migration pose les trois choses qui manquaient :
--
--   1. users.anonymized_at : la date ou la ligne a ete videe de ses
--      donnees personnelles. C'est ce champ, et non deleted_at, qui dit
--      « il n'y a plus rien d'identifiant ici ».
--
--   2. L'UTILISATEUR RESERVE (« Utilisateur supprime »). Les messages
--      de clavardage appartiennent a la conversation d'une liste, pas
--      seulement a leur auteur : les effacer trouerait l'historique des
--      autres membres. Mais list_messages.user_id est en ON DELETE
--      CASCADE — purger la ligne users emporterait les messages. Les
--      messages d'un compte supprime sont donc re-attribues a cette
--      ligne reservee, qui n'est jamais supprimee et ne peut pas servir
--      a se connecter (password_hash NULL, is_active = 0).
--      Tous les comptes supprimes se confondent en un seul auteur :
--      c'est voulu, c'est le choix le plus sobre pour la vie privee.
--
--   3. account_deletion_requests : les demandes venues du SITE, hors de
--      l'application (exigence Google Play : une URL publique). Une
--      demande n'est qu'un courriel + l'empreinte d'un jeton a usage
--      unique ; le compte n'est touche qu'au clic sur le lien recu.
--
-- Rejouable. Rien n'est detruit. Retour en arriere en fin de fichier.

-- 1. users.anonymized_at ---------------------------------------------
SET @c = (SELECT COUNT(*) FROM information_schema.columns
          WHERE table_schema = DATABASE()
            AND table_name = 'users'
            AND column_name = 'anonymized_at');
SET @sql = IF(@c = 0,
    'ALTER TABLE users ADD COLUMN anonymized_at DATETIME NULL COMMENT ''Date ou la ligne a ete videe de ses donnees personnelles'' AFTER deleted_at',
    'SELECT "users.anonymized_at deja presente"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Un index : la purge des comptes anonymises de plus de 30 jours et le
-- script de rattrapage balaient cette colonne a chaque passage.
SET @c = (SELECT COUNT(*) FROM information_schema.statistics
          WHERE table_schema = DATABASE()
            AND table_name = 'users'
            AND index_name = 'idx_users_anonymized_at');
SET @sql = IF(@c = 0,
    'ALTER TABLE users ADD INDEX idx_users_anonymized_at (anonymized_at)',
    'SELECT "idx_users_anonymized_at deja present"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 2. L'utilisateur reserve -------------------------------------------
-- Insere une seule fois. Le courriel .local n'existe pas et ne peut pas
-- recevoir de courrier ; password_hash NULL rend tout mot de passe
-- invalide (password_verify sur null echoue) ; is_active = 0 l'exclut
-- des taches planifiees et des envois.
INSERT INTO users (
    first_name, last_name, email, password_hash,
    terms_accepted, is_active, email_verified, role,
    currency_id, language, email_marketing_consent,
    anonymized_at, created_at, updated_at
)
SELECT 'Utilisateur', 'supprime', 'deleted@deleted.local', NULL,
       0, 0, 0, 'user',
       1, 'fr', 0,
       NOW(), NOW(), NOW()
  FROM DUAL
 WHERE NOT EXISTS (
       SELECT 1 FROM users WHERE email = 'deleted@deleted.local'
 );

-- 3. Les demandes de suppression venues du site ----------------------
CREATE TABLE IF NOT EXISTS account_deletion_requests (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    email           VARCHAR(150) NOT NULL COMMENT 'Courriel saisi sur le site',
    user_id         INT NULL COMMENT 'Compte vise, si le courriel en designe un',
    token_hash      CHAR(64) NOT NULL COMMENT 'SHA-256 du jeton ; le jeton clair ne vit que dans le courriel',
    language        VARCHAR(2) NOT NULL DEFAULT 'fr',
    ip_address      VARCHAR(45) NULL,
    expires_at      DATETIME NOT NULL,
    confirmed_at    DATETIME NULL,
    created_at      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_adr_token (token_hash),
    KEY idx_adr_email (email),
    KEY idx_adr_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Demandes de suppression de compte faites depuis le site web';

-- 4. Verification -----------------------------------------------------
SELECT 'verification 016' AS controle,
  (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'users'
      AND column_name = 'anonymized_at')                                AS colonne_anonymized_at,
  (SELECT COUNT(*) FROM users
    WHERE email = 'deleted@deleted.local')                              AS utilisateur_reserve,
  (SELECT COUNT(*) FROM users
    WHERE email = 'deleted@deleted.local'
      AND password_hash IS NULL AND is_active = 0
      AND deleted_at IS NULL)                                           AS reserve_conforme,
  (SELECT COUNT(*) FROM information_schema.tables
    WHERE table_schema = DATABASE()
      AND table_name = 'account_deletion_requests')                     AS table_demandes,
  (SELECT COUNT(*) FROM users
    WHERE deleted_at IS NOT NULL AND anonymized_at IS NULL)             AS comptes_a_rattraper;

-- Attendu : colonne_anonymized_at = 1, utilisateur_reserve = 1,
--           reserve_conforme = 1, table_demandes = 1.
-- comptes_a_rattraper = le nombre de comptes « supprimes » avant cette
-- migration et qui contiennent encore des donnees personnelles. C'est
-- exactement ce que traite scripts/backfill_deleted_accounts.php.
-- deleted_at NULL sur la ligne reservee est voulu : avec deleted_at,
-- Eloquent (SoftDeletes) ne chargerait plus la relation et les messages
-- re-attribues perdraient leur auteur a l'affichage.

-- ---------------------------------------------------------------------
-- RETOUR EN ARRIERE (a jouer a la main) :
--
--   DROP TABLE IF EXISTS account_deletion_requests;
--   ALTER TABLE users DROP INDEX idx_users_anonymized_at;
--   ALTER TABLE users DROP COLUMN anonymized_at;
--
-- L'utilisateur reserve ne doit PAS etre supprime s'il porte deja des
-- messages re-attribues : la contrainte ON DELETE CASCADE de
-- list_messages.user_id les emporterait. Pour le retirer sans perte,
-- verifier d'abord :
--   SELECT COUNT(*) FROM list_messages
--    WHERE user_id = (SELECT id FROM users WHERE email = 'deleted@deleted.local');
-- ---------------------------------------------------------------------
