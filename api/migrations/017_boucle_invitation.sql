-- Migration 017 — la boucle d'invitation.
--
-- Le probleme : un lien de partage ne ramene personne. Le jeton vit
-- dans une URL ; quelqu'un qui clique, installe l'application depuis le
-- magasin, puis l'ouvre, arrive sur l'ecran de bienvenue — le lien est
-- perdu entre les deux. Et sur un ordinateur, le lien envoyait vers
-- l'App Store, meme sur Windows.
--
-- Cette migration pose les deux choses qui manquaient :
--
--   1. shared_list.invite_code : un code COURT, six caracteres, que la
--      personne peut lire sur un ecran, retenir trois secondes et taper
--      dans l'application apres l'avoir installee. C'est le chemin de
--      secours quand le lien ne survit pas au passage par le magasin —
--      c'est-a-dire presque toujours.
--
--      L'alphabet exclut 0, O, 1, I et L : un code se transmet souvent
--      a voix haute ou depuis une photo d'ecran.
--
--   2. users.signup_source et users.signup_share_id : d'ou vient ce
--      compte. Sans ces deux colonnes, « combien d'inscriptions une
--      invitation a-t-elle produites » n'a pas de reponse, et la boucle
--      ne se mesure pas.
--
-- Rejouable. Rien n'est detruit. Retour en arriere en fin de fichier.

-- 1. Le code d'invitation ----------------------------------------------
SET @c = (SELECT COUNT(*) FROM information_schema.columns
          WHERE table_schema = DATABASE()
            AND table_name = 'shared_list'
            AND column_name = 'invite_code');
SET @sql = IF(@c = 0,
    'ALTER TABLE shared_list ADD COLUMN invite_code CHAR(6) NULL COMMENT ''Code court a taper apres installation ; alphabet sans 0 O 1 I L'' AFTER share_token',
    'SELECT "shared_list.invite_code deja presente"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Unique, mais NULL autorise en plusieurs exemplaires : les partages
-- d'avant cette migration n'ont pas de code, et c'est sans consequence.
SET @c = (SELECT COUNT(*) FROM information_schema.statistics
          WHERE table_schema = DATABASE()
            AND table_name = 'shared_list'
            AND index_name = 'uq_shared_list_invite_code');
SET @sql = IF(@c = 0,
    'ALTER TABLE shared_list ADD UNIQUE KEY uq_shared_list_invite_code (invite_code)',
    'SELECT "uq_shared_list_invite_code deja present"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 2. D'ou vient un compte ----------------------------------------------
SET @c = (SELECT COUNT(*) FROM information_schema.columns
          WHERE table_schema = DATABASE()
            AND table_name = 'users'
            AND column_name = 'signup_source');
SET @sql = IF(@c = 0,
    'ALTER TABLE users ADD COLUMN signup_source VARCHAR(30) NULL COMMENT ''direct, share_link, invite_code, install_referrer'' AFTER language',
    'SELECT "users.signup_source deja presente"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c = (SELECT COUNT(*) FROM information_schema.columns
          WHERE table_schema = DATABASE()
            AND table_name = 'users'
            AND column_name = 'signup_share_id');
SET @sql = IF(@c = 0,
    'ALTER TABLE users ADD COLUMN signup_share_id INT NULL COMMENT ''shared_list.id du partage qui a amene ce compte'' AFTER signup_source',
    'SELECT "users.signup_share_id deja presente"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Pas de cle etrangere vers shared_list : un partage revoque puis purge
-- ne doit pas emporter l'information « ce compte vient d'une invitation »,
-- ni bloquer la purge. L'identifiant reste, orphelin, et c'est voulu.
SET @c = (SELECT COUNT(*) FROM information_schema.statistics
          WHERE table_schema = DATABASE()
            AND table_name = 'users'
            AND index_name = 'idx_users_signup_source');
SET @sql = IF(@c = 0,
    'ALTER TABLE users ADD INDEX idx_users_signup_source (signup_source)',
    'SELECT "idx_users_signup_source deja present"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 3. Verification -------------------------------------------------------
SELECT 'verification 017' AS controle,
  (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'shared_list'
      AND column_name = 'invite_code')                                  AS colonne_invite_code,
  (SELECT COUNT(*) FROM information_schema.statistics
    WHERE table_schema = DATABASE() AND table_name = 'shared_list'
      AND index_name = 'uq_shared_list_invite_code')                    AS index_unique,
  (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'users'
      AND column_name IN ('signup_source', 'signup_share_id'))          AS colonnes_provenance,
  (SELECT COUNT(*) FROM shared_list
    WHERE invite_code IS NOT NULL)                                      AS partages_avec_code,
  (SELECT COUNT(*) FROM shared_list
    WHERE status = 'pending' AND invite_code IS NULL
      AND (expires_at IS NULL OR expires_at > NOW()))                   AS partages_en_attente_sans_code;

-- Attendu : colonne_invite_code = 1, index_unique = 1,
--           colonnes_provenance = 2.
-- partages_en_attente_sans_code : les liens envoyes AVANT cette
-- migration. Ils continuent de fonctionner par leur lien ; ils n'auront
-- simplement pas de code court. Les nouveaux en auront un.

-- ---------------------------------------------------------------------
-- RETOUR EN ARRIERE (a jouer a la main) :
--
--   ALTER TABLE users DROP INDEX idx_users_signup_source;
--   ALTER TABLE users DROP COLUMN signup_share_id;
--   ALTER TABLE users DROP COLUMN signup_source;
--   ALTER TABLE shared_list DROP INDEX uq_shared_list_invite_code;
--   ALTER TABLE shared_list DROP COLUMN invite_code;
--
-- Les liens de partage ne dependent pas du code : les retirer ne casse
-- aucun partage en cours.
-- ---------------------------------------------------------------------
