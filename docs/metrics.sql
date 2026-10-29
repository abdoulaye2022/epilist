-- docs/metrics.sql — les chiffres du produit, et comment les obtenir.
--
-- À LIRE AVANT DE COPIER UNE REQUÊTE.
--
-- 1. La table de partage s'appelle `shared_list`, AU SINGULIER.
-- 2. Toutes les tables principales sont en suppression douce : chaque
--    requête doit filtrer `deleted_at IS NULL`, sinon elle compte des
--    comptes et des listes qui n'existent plus.
-- 3. `user_activity_days` (migration 019) est la SEULE source fiable
--    d'activité. `user_devices.last_active_at` ne s'écrit qu'à
--    l'enregistrement d'un appareil et au rafraîchissement du jeton
--    push : il rate ceux qui refusent les notifications et tout usage
--    hors ligne.
-- 4. Elle commence le jour où la migration 019 est appliquée. Toute
--    rétention antérieure est inconnue, et le rester : mieux vaut un
--    trou qu'un chiffre inventé.
-- 5. Les comptes supprimés disparaissent de ces chiffres (phase 2) :
--    leur ligne `users` part à la purge des trente jours, et
--    `user_activity_days` suit par cascade. Une cohorte ancienne peut
--    donc se « dégonfler » avec le temps. C'est voulu.

-- =====================================================================
-- 1. L'ÉTAT DES LIEUX
-- =====================================================================

-- Comptes, vérifications, et activité récente.
SELECT
  (SELECT COUNT(*) FROM users
    WHERE deleted_at IS NULL AND anonymized_at IS NULL)                 AS comptes,
  (SELECT COUNT(*) FROM users
    WHERE deleted_at IS NULL AND anonymized_at IS NULL
      AND email_verified = 1)                                           AS comptes_verifies,
  (SELECT COUNT(DISTINCT user_id) FROM user_activity_days
    WHERE activity_date >= CURDATE() - INTERVAL 1 DAY)                  AS actifs_hier,
  (SELECT COUNT(DISTINCT user_id) FROM user_activity_days
    WHERE activity_date >= CURDATE() - INTERVAL 7 DAY)                  AS actifs_7j,
  (SELECT COUNT(DISTINCT user_id) FROM user_activity_days
    WHERE activity_date >= CURDATE() - INTERVAL 30 DAY)                 AS actifs_30j;

-- Actifs par jour, sur un mois. C'est la courbe à regarder après une
-- campagne : une bosse qui retombe au niveau d'avant en trois jours
-- signifie que la campagne a amené des visites, pas des usages.
SELECT activity_date AS jour,
       COUNT(DISTINCT user_id) AS actifs
  FROM user_activity_days
 WHERE activity_date >= CURDATE() - INTERVAL 30 DAY
 GROUP BY activity_date
 ORDER BY activity_date;

-- =====================================================================
-- 2. RÉTENTION PAR COHORTE
-- =====================================================================
-- Une cohorte = les comptes créés le même mois. « Revenu à J7 » veut
-- dire : au moins un jour d'activité entre J+7 et J+13 inclus — pas
-- « exactement le septième jour », qui ne mesurerait que le hasard.

WITH cohortes AS (
  SELECT u.id,
         DATE(u.created_at)                        AS jour_inscription,
         DATE_FORMAT(u.created_at, '%Y-%m')        AS cohorte
    FROM users u
   WHERE u.deleted_at IS NULL
     AND u.anonymized_at IS NULL
     -- Avant la migration 019, aucune activité n'était enregistrée :
     -- inclure ces comptes donnerait une rétention artificiellement
     -- nulle. Remplacer la date ci-dessous par celle de la migration.
     AND u.created_at >= '2026-10-29'
)
SELECT c.cohorte,
       COUNT(*)                                                         AS inscrits,
       SUM(EXISTS (SELECT 1 FROM user_activity_days a
                    WHERE a.user_id = c.id
                      AND a.activity_date BETWEEN c.jour_inscription + INTERVAL 1 DAY
                                              AND c.jour_inscription + INTERVAL 1 DAY)) AS revenus_j1,
       SUM(EXISTS (SELECT 1 FROM user_activity_days a
                    WHERE a.user_id = c.id
                      AND a.activity_date BETWEEN c.jour_inscription + INTERVAL 7 DAY
                                              AND c.jour_inscription + INTERVAL 13 DAY)) AS revenus_j7,
       SUM(EXISTS (SELECT 1 FROM user_activity_days a
                    WHERE a.user_id = c.id
                      AND a.activity_date BETWEEN c.jour_inscription + INTERVAL 30 DAY
                                              AND c.jour_inscription + INTERVAL 36 DAY)) AS revenus_j30
  FROM cohortes c
 GROUP BY c.cohorte
 ORDER BY c.cohorte;

-- La même chose en pourcentages, pour la lecture rapide.
-- Une cohorte de moins de trente comptes ne se lit pas : à ce volume,
-- deux personnes font dix points de pourcentage.
WITH cohortes AS (
  SELECT u.id,
         DATE(u.created_at)                 AS jour_inscription,
         DATE_FORMAT(u.created_at, '%Y-%m') AS cohorte
    FROM users u
   WHERE u.deleted_at IS NULL AND u.anonymized_at IS NULL
     AND u.created_at >= '2026-10-29'
), mesures AS (
  SELECT c.cohorte,
         COUNT(*) AS inscrits,
         SUM(EXISTS (SELECT 1 FROM user_activity_days a
                      WHERE a.user_id = c.id
                        AND a.activity_date = c.jour_inscription + INTERVAL 1 DAY)) AS j1,
         SUM(EXISTS (SELECT 1 FROM user_activity_days a
                      WHERE a.user_id = c.id
                        AND a.activity_date BETWEEN c.jour_inscription + INTERVAL 7 DAY
                                                AND c.jour_inscription + INTERVAL 13 DAY)) AS j7,
         SUM(EXISTS (SELECT 1 FROM user_activity_days a
                      WHERE a.user_id = c.id
                        AND a.activity_date BETWEEN c.jour_inscription + INTERVAL 30 DAY
                                                AND c.jour_inscription + INTERVAL 36 DAY)) AS j30
    FROM cohortes c
   GROUP BY c.cohorte
)
SELECT cohorte,
       inscrits,
       ROUND(100 * j1 / inscrits, 1)  AS pct_j1,
       ROUND(100 * j7 / inscrits, 1)  AS pct_j7,
       ROUND(100 * j30 / inscrits, 1) AS pct_j30,
       CASE WHEN inscrits < 30 THEN 'volume trop faible' ELSE '' END AS avertissement
  FROM mesures
 ORDER BY cohorte;

-- =====================================================================
-- 3. LA BOUCLE D'INVITATION (phase 4)
-- =====================================================================
-- Un partage créé n'est pas un partage accepté, et un lien envoyé n'est
-- pas un compte créé. Les trois colonnes se lisent ensemble.

SELECT p.mois,
       p.liens_crees,
       p.liens_acceptes,
       ROUND(100 * p.liens_acceptes / p.liens_crees, 1)                 AS pct_acceptes,
       (SELECT COUNT(*) FROM users u
         WHERE u.signup_share_id IS NOT NULL
           AND u.deleted_at IS NULL
           AND DATE_FORMAT(u.created_at, '%Y-%m') = p.mois)             AS comptes_nes_d_une_invitation
  FROM (
    SELECT DATE_FORMAT(s.created_at, '%Y-%m') AS mois,
           COUNT(*)                           AS liens_crees,
           SUM(s.status = 'accepted')         AS liens_acceptes
      FROM shared_list s
     WHERE s.deleted_at IS NULL
     GROUP BY DATE_FORMAT(s.created_at, '%Y-%m')
  ) AS p
 ORDER BY p.mois;

-- Par quel chemin les comptes arrivent. `install_referrer` ne peut
-- venir que d'Android ; iOS n'a pas d'équivalent, d'où l'existence du
-- code à six caractères (`invite_code`).
SELECT COALESCE(signup_source, 'inconnu') AS provenance,
       COUNT(*)                           AS comptes
  FROM users
 WHERE deleted_at IS NULL AND anonymized_at IS NULL
 GROUP BY provenance
 ORDER BY comptes DESC;

-- Le coefficient viral, mois par mois : combien de comptes chaque
-- compte amène. Au-dessus de 1, la boucle se nourrit elle-même ; en
-- dessous, chaque nouvel utilisateur doit être payé.
SELECT DATE_FORMAT(u.created_at, '%Y-%m')                               AS mois,
       COUNT(*)                                                         AS comptes_du_mois,
       SUM(u.signup_share_id IS NOT NULL)                               AS venus_d_une_invitation,
       ROUND(SUM(u.signup_share_id IS NOT NULL) / COUNT(*), 2)          AS coefficient
  FROM users u
 WHERE u.deleted_at IS NULL AND u.anonymized_at IS NULL
 GROUP BY mois
 ORDER BY mois;

-- =====================================================================
-- 4. LE PARCOURS DE DÉPART (phase 5)
-- =====================================================================

SELECT
  COUNT(*)                                                              AS comptes_recents,
  SUM(onboarding_done_at IS NOT NULL)                                   AS ont_vu_le_parcours,
  SUM(onboarding_done_at IS NULL)                                       AS ne_l_ont_pas_encore_vu
  FROM users
 WHERE deleted_at IS NULL AND anonymized_at IS NULL
   AND created_at >= '2026-10-29';

-- La question qui compte : ceux qui ont traversé le parcours
-- reviennent-ils plus que les autres ? Comparer les deux lignes.
SELECT CASE WHEN u.onboarding_done_at IS NULL THEN 'sans parcours' ELSE 'avec parcours' END AS groupe,
       COUNT(*)                                                         AS comptes,
       ROUND(100 * SUM(EXISTS (SELECT 1 FROM user_activity_days a
                                WHERE a.user_id = u.id
                                  AND a.activity_date BETWEEN DATE(u.created_at) + INTERVAL 7 DAY
                                                          AND DATE(u.created_at) + INTERVAL 13 DAY))
                 / COUNT(*), 1)                                         AS pct_revenus_j7
  FROM users u
 WHERE u.deleted_at IS NULL AND u.anonymized_at IS NULL
   AND u.created_at >= '2026-10-29'
   AND u.created_at <= CURDATE() - INTERVAL 14 DAY   -- laisser le temps de revenir
 GROUP BY groupe;

-- =====================================================================
-- 5. L'USAGE RÉEL
-- =====================================================================

-- Que font les comptes actifs du mois ? Sans ces proportions, « des
-- budgets et des reçus » reste une phrase de site.
WITH actifs AS (
  SELECT DISTINCT user_id AS id
    FROM user_activity_days
   WHERE activity_date >= CURDATE() - INTERVAL 30 DAY
)
SELECT
  (SELECT COUNT(*) FROM actifs)                                         AS actifs_30j,
  ROUND(100 * (SELECT COUNT(DISTINCT l.user_id) FROM shopping_lists l
                WHERE l.deleted_at IS NULL AND l.user_id IN (SELECT id FROM actifs))
            / NULLIF((SELECT COUNT(*) FROM actifs), 0), 1)              AS pct_avec_liste,
  ROUND(100 * (SELECT COUNT(DISTINCT b.user_id) FROM budgets b
                WHERE b.deleted_at IS NULL AND b.user_id IN (SELECT id FROM actifs))
            / NULLIF((SELECT COUNT(*) FROM actifs), 0), 1)              AS pct_avec_budget,
  ROUND(100 * (SELECT COUNT(DISTINCT l.user_id)
                 FROM list_receipts r JOIN shopping_lists l ON l.id = r.list_id
                WHERE r.deleted_at IS NULL AND l.deleted_at IS NULL
                  AND l.user_id IN (SELECT id FROM actifs))
            / NULLIF((SELECT COUNT(*) FROM actifs), 0), 1)              AS pct_avec_recu,
  ROUND(100 * (SELECT COUNT(DISTINCT s.owner_id) FROM shared_list s
                WHERE s.deleted_at IS NULL AND s.owner_id IN (SELECT id FROM actifs))
            / NULLIF((SELECT COUNT(*) FROM actifs), 0), 1)              AS pct_qui_partagent;

-- Le nombre réel de devises actives — le site a longtemps annoncé
-- « 150+ » sans que rien ne le soutienne (phase 3).
SELECT COUNT(*)                        AS devises_en_base,
       SUM(is_active = 1)              AS devises_actives
  FROM currencies;

-- =====================================================================
-- 6. CE QUI RESTE À NETTOYER
-- =====================================================================

-- Comptes « supprimés » jamais anonymisés : ils ne devraient plus
-- exister depuis le rattrapage de la phase 2.
SELECT COUNT(*) AS comptes_a_rattraper
  FROM users
 WHERE deleted_at IS NOT NULL AND anonymized_at IS NULL;

-- Comptes anonymisés qui attendent la purge des trente jours.
SELECT COUNT(*) AS en_attente_de_purge
  FROM users
 WHERE anonymized_at IS NOT NULL
   AND anonymized_at < NOW() - INTERVAL 30 DAY;

-- Comptes jamais vérifiés et jamais revenus : ils occupent une adresse
-- courriel que leur propriétaire réel ne peut plus utiliser.
SELECT COUNT(*) AS jamais_verifies_ni_revenus
  FROM users u
 WHERE u.deleted_at IS NULL
   AND u.email_verified = 0
   AND u.created_at < NOW() - INTERVAL 30 DAY
   AND NOT EXISTS (SELECT 1 FROM user_activity_days a
                    WHERE a.user_id = u.id
                      AND a.activity_date > DATE(u.created_at));
