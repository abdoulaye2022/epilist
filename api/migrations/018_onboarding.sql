-- Migration 018 — le parcours de depart ne se montre qu'une fois.
--
-- La phase 5 ajoute deux ou trois ecrans apres la premiere connexion :
-- creer sa premiere liste, inviter quelqu'un du foyer, poser un budget.
-- Chacun avec « Passer ».
--
-- Le drapeau vit COTE SERVEUR, et pas dans les preferences du
-- telephone : quelqu'un qui change d'appareil, reinstalle, ou ouvre
-- l'application sur une tablette a deja fait ce parcours. Le lui
-- remontrer donnerait l'impression d'un compte neuf.
--
-- Une date plutot qu'un booleen : elle dit aussi QUAND, ce qui permet
-- de mesurer l'effet du parcours sur les inscriptions qui suivent.
--
-- Rejouable. Retour en arriere en fin de fichier.

SET @c = (SELECT COUNT(*) FROM information_schema.columns
          WHERE table_schema = DATABASE()
            AND table_name = 'users'
            AND column_name = 'onboarding_done_at');
SET @sql = IF(@c = 0,
    'ALTER TABLE users ADD COLUMN onboarding_done_at DATETIME NULL COMMENT ''Date ou le parcours de depart a ete termine ou passe'' AFTER signup_share_id',
    'SELECT "users.onboarding_done_at deja presente"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Les comptes qui existaient AVANT ce parcours ne doivent pas le voir :
-- ils ont deja leurs listes, et un « Creez votre premiere liste » leur
-- ferait croire a une perte de donnees.
UPDATE users
   SET onboarding_done_at = COALESCE(created_at, NOW())
 WHERE onboarding_done_at IS NULL
   AND created_at < NOW();

SELECT 'verification 018' AS controle,
  (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'users'
      AND column_name = 'onboarding_done_at')                           AS colonne_presente,
  (SELECT COUNT(*) FROM users WHERE onboarding_done_at IS NOT NULL)     AS comptes_exemptes,
  (SELECT COUNT(*) FROM users WHERE onboarding_done_at IS NULL)         AS comptes_qui_verront_le_parcours;

-- Attendu : colonne_presente = 1, comptes_qui_verront_le_parcours = 0
-- juste apres la migration (tous les comptes existants sont exemptes).
-- Les comptes crees ensuite partiront a NULL et verront le parcours.

-- ---------------------------------------------------------------------
-- RETOUR EN ARRIERE :
--   ALTER TABLE users DROP COLUMN onboarding_done_at;
-- ---------------------------------------------------------------------
