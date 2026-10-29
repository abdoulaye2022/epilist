-- Migration 019 — un jour d'activite par personne, et rien de plus.
--
-- POURQUOI CETTE TABLE EXISTE. La retention — combien de gens reviennent
-- a J1, J7, J30 — ne se calcule aujourd'hui avec rien de fiable :
-- `users` n'a aucune colonne d'activite, et le seul indicateur,
-- `user_devices.last_active_at`, n'est ecrit qu'a l'enregistrement d'un
-- appareil et au rafraichissement du jeton push. Il rate donc tous ceux
-- qui refusent les notifications, ceux dont l'initialisation echoue, et
-- tout usage hors ligne. Le chiffre sous-estime l'activite reelle, et
-- personne ne sait de combien.
--
-- CE QU'ELLE CONTIENT, ET RIEN D'AUTRE : un identifiant de compte, et
-- une DATE. Pas d'heure, pas de page vue, pas d'action, pas d'adresse
-- IP, pas d'appareil. On peut repondre a « combien de gens sont revenus
-- le lendemain » sans rien savoir de ce qu'ils ont fait.
--
-- Une seule ligne par personne et par jour : l'unicite est dans la
-- base, pas dans le code qui ecrit.
--
-- Rejouable. Retour en arriere en fin de fichier.

CREATE TABLE IF NOT EXISTS user_activity_days (
    user_id       INT NOT NULL,
    activity_date DATE NOT NULL,
    created_at    TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, activity_date),
    KEY idx_activity_date (activity_date),
    CONSTRAINT fk_activity_user FOREIGN KEY (user_id)
        REFERENCES users (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Un jour ou un compte a utilise l application. Aucune autre donnee.';

-- La cle etrangere en CASCADE n'est pas un detail : a la suppression
-- d'un compte (phase 2), ces lignes doivent partir avec lui, sans que
-- le service de suppression ait a les connaitre.

SELECT 'verification 019' AS controle,
  (SELECT COUNT(*) FROM information_schema.tables
    WHERE table_schema = DATABASE() AND table_name = 'user_activity_days')  AS table_presente,
  (SELECT COUNT(*) FROM information_schema.key_column_usage
    WHERE table_schema = DATABASE() AND table_name = 'user_activity_days'
      AND referenced_table_name = 'users')                                  AS cle_etrangere,
  (SELECT COUNT(*) FROM user_activity_days)                                 AS jours_enregistres;

-- Attendu : table_presente = 1, cle_etrangere = 1.
-- jours_enregistres = 0 au depart : la table se remplit d'elle-meme, un
-- jour a la fois, des que l'API tourne avec le middleware.

-- ---------------------------------------------------------------------
-- RETOUR EN ARRIERE :
--   DROP TABLE IF EXISTS user_activity_days;
-- Rien d'autre n'en depend : aucune fonctionnalite ne la lit, seules
-- les requetes de docs/metrics.sql s'y appuient.
-- ---------------------------------------------------------------------
