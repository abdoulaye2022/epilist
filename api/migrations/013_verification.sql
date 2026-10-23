-- ============================================================================
-- VERIFICATION D'APRES-MIGRATIONS 013 ET 014. NE MODIFIE RIEN.
-- ============================================================================
--
-- A coller dans l'onglet SQL de phpMyAdmin, sur la base de PRODUCTION,
-- APRES 013_analyse_23_octobre.sql ET 014_zones_de_rangement.sql.
--
-- Que des SELECT : il lit, il compte, il dit. Rejouable.
--
-- Il verifie les TYPES, et pas seulement la presence des colonnes :
-- une date en VARCHAR, un enum sans sa nouvelle valeur ou un index
-- absent passent la verification naive et cassent au premier
-- enregistrement.
--
-- Lecture : la colonne `verdict`. Tant qu'une ligne ne dit pas « ok »,
-- ne pas pousser le code — l'API lirait quelque chose qui n'est pas la.
-- ============================================================================

SELECT 'A. A LA MAISON — zone, peremption et niveau' AS controle, '' AS attendu, '' AS trouve, '' AS verdict
UNION ALL
-- La zone de rangement (migration 014). Ce n'est pas un detail
-- d'affichage : c'est elle qui donne son fond colore a chaque bloc de
-- l'ecran, et c'est pour rester lisible SUR ces fonds que le badge
-- d'etat est plein.
SELECT 'home_inventory.zone', 'varchar',
       IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'home_inventory'
                  AND COLUMN_NAME = 'zone'), 'absente'),
       IF((SELECT DATA_TYPE FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'home_inventory'
              AND COLUMN_NAME = 'zone') = 'varchar', 'ok', 'ECHEC')
UNION ALL
SELECT 'index idx_inventory_zone', 'existe',
       IF((SELECT COUNT(*) FROM information_schema.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'home_inventory'
              AND INDEX_NAME = 'idx_inventory_zone') > 0, 'oui', 'non'),
       IF((SELECT COUNT(*) FROM information_schema.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'home_inventory'
              AND INDEX_NAME = 'idx_inventory_zone') > 0, 'ok', 'ECHEC')
UNION ALL
SELECT 'zones hors des quatre valeurs (doit etre 0)', '0',
       CONCAT((SELECT COUNT(*) FROM home_inventory
                WHERE zone IS NOT NULL
                  AND zone NOT IN ('pantry','fridge','freezer','household')), ' ligne(s)'),
       IF((SELECT COUNT(*) FROM home_inventory
            WHERE zone IS NOT NULL
              AND zone NOT IN ('pantry','fridge','freezer','household')) = 0, 'ok', 'ECHEC')
UNION ALL
SELECT CONCAT('home_inventory.', c.nom), c.type,
       IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'home_inventory' AND COLUMN_NAME = c.nom), 'absente'),
       IF((SELECT DATA_TYPE FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'home_inventory' AND COLUMN_NAME = c.nom) = c.type,
          'ok', 'ECHEC')
FROM (
    -- Une date de peremption en VARCHAR se comparerait comme du texte :
    -- « 2026-9-5 » viendrait apres « 2026-11-30 ».
    SELECT 'expires_at' AS nom, 'date' AS type
    UNION ALL SELECT 'level', 'varchar'
) AS c
UNION ALL
-- L'index sert la requete « qu'est-ce qui perime cette semaine ? », qui
-- traverse l'inventaire a chaque ouverture de l'ecran.
SELECT 'index idx_inventory_peremption', 'existe',
       IF((SELECT COUNT(*) FROM information_schema.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'home_inventory'
              AND INDEX_NAME = 'idx_inventory_peremption') > 0, 'oui', 'non'),
       IF((SELECT COUNT(*) FROM information_schema.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'home_inventory'
              AND INDEX_NAME = 'idx_inventory_peremption') > 0, 'ok', 'ECHEC')

UNION ALL SELECT '', '', '', ''
UNION ALL
SELECT 'B. LISTE — le prix exact ou approximatif', '', '', ''
UNION ALL
SELECT 'list_items.price_is_estimate', 'tinyint',
       IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'list_items'
                  AND COLUMN_NAME = 'price_is_estimate'), 'absente'),
       IF((SELECT DATA_TYPE FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'list_items'
              AND COLUMN_NAME = 'price_is_estimate') = 'tinyint', 'ok', 'ECHEC')
UNION ALL
-- Defaut 0 : les articles deja en base portent des prix EXACTS, et
-- doivent le rester. Un defaut a NULL les rendrait tous douteux.
SELECT 'price_is_estimate : defaut', '0',
       IFNULL((SELECT COLUMN_DEFAULT FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'list_items'
                  AND COLUMN_NAME = 'price_is_estimate'), 'aucun'),
       IF(IFNULL((SELECT COLUMN_DEFAULT FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'list_items'
                     AND COLUMN_NAME = 'price_is_estimate'), 'aucun') = '0', 'ok', 'ECHEC')

UNION ALL SELECT '', '', '', ''
UNION ALL
SELECT 'C. BUDGET — periode de paie et renouvellement', '', '', ''
UNION ALL
-- MODIFY et non ADD : l'enum existait, il lui manquait une valeur.
SELECT 'budgets.period_type connait biweekly', 'oui',
       IF(LOCATE('biweekly', IFNULL((SELECT COLUMN_TYPE FROM information_schema.COLUMNS
                                      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'budgets'
                                        AND COLUMN_NAME = 'period_type'), '')) > 0, 'oui', 'non'),
       IF(LOCATE('biweekly', IFNULL((SELECT COLUMN_TYPE FROM information_schema.COLUMNS
                                      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'budgets'
                                        AND COLUMN_NAME = 'period_type'), '')) > 0, 'ok', 'ECHEC')
UNION ALL
SELECT CONCAT('budgets.', c.nom), c.type,
       IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'budgets' AND COLUMN_NAME = c.nom), 'absente'),
       IF((SELECT DATA_TYPE FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'budgets' AND COLUMN_NAME = c.nom) = c.type,
          'ok', 'ECHEC')
FROM (
    SELECT 'auto_renew' AS nom, 'tinyint' AS type
    UNION ALL SELECT 'renewed_at', 'timestamp'
) AS c
UNION ALL
-- Sans renewed_at nulle au depart, le cron croirait tous les budgets
-- deja renouveles et n'en recreerait aucun.
SELECT 'budgets deja renouveles (doit etre 0 au depart)', '0',
       CONCAT((SELECT COUNT(*) FROM budgets WHERE renewed_at IS NOT NULL), ' ligne(s)'),
       'ok'

UNION ALL SELECT '', '', '', ''
UNION ALL
SELECT 'D. ALERTES DE PRIX — le resume hebdomadaire', '', '', ''
UNION ALL
SELECT 'email_preferences.price_alert_digest', 'tinyint',
       IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'email_preferences'
                  AND COLUMN_NAME = 'price_alert_digest'), 'absente'),
       IF((SELECT DATA_TYPE FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'email_preferences'
              AND COLUMN_NAME = 'price_alert_digest') = 'tinyint', 'ok', 'ECHEC')
UNION ALL
-- Defaut 0 : qui recoit aujourd'hui une notification par produit la
-- garde, et choisit le resume s'il le veut.
SELECT 'price_alert_digest : defaut', '0',
       IFNULL((SELECT COLUMN_DEFAULT FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'email_preferences'
                  AND COLUMN_NAME = 'price_alert_digest'), 'aucun'),
       IF(IFNULL((SELECT COLUMN_DEFAULT FROM information_schema.COLUMNS
                   WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'email_preferences'
                     AND COLUMN_NAME = 'price_alert_digest'), 'aucun') = '0', 'ok', 'ECHEC')

UNION ALL SELECT '', '', '', ''
UNION ALL
SELECT 'E. RECETTES — la recherche par nom et par ingredient', '', '', ''
UNION ALL
SELECT CONCAT('index ', i.nom), 'existe',
       IF((SELECT COUNT(*) FROM information_schema.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = i.tbl AND INDEX_NAME = i.nom) > 0,
          'oui', 'non'),
       IF((SELECT COUNT(*) FROM information_schema.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = i.tbl AND INDEX_NAME = i.nom) > 0,
          'ok', 'ECHEC')
FROM (
    SELECT 'idx_recipes_nom' AS nom, 'recipes' AS tbl
    UNION ALL SELECT 'idx_ingredients_nom', 'recipe_ingredients'
) AS i

UNION ALL SELECT '', '', '', ''
UNION ALL
SELECT 'F. COHERENCE DES ETATS D''INVENTAIRE', '', '', ''
UNION ALL
-- LE cas de la capture : « Alerte rupture » sur un produit dont il
-- restait deux, pour un seuil de un. La migration l'a corrige ; aucune
-- ligne ne doit plus etre dans ce cas.
SELECT 'ruptures avec du stock (doit etre 0)', '0',
       CONCAT((SELECT COUNT(*) FROM home_inventory
                WHERE status = 'out' AND quantity IS NOT NULL AND quantity > 0), ' ligne(s)'),
       IF((SELECT COUNT(*) FROM home_inventory
            WHERE status = 'out' AND quantity IS NOT NULL AND quantity > 0) = 0, 'ok', 'ECHEC')
UNION ALL
SELECT 'stocks bas au-dessus du seuil (doit etre 0)', '0',
       CONCAT((SELECT COUNT(*) FROM home_inventory
                WHERE status = 'running_low' AND quantity IS NOT NULL
                  AND min_quantity IS NOT NULL AND quantity > min_quantity), ' ligne(s)'),
       IF((SELECT COUNT(*) FROM home_inventory
            WHERE status = 'running_low' AND quantity IS NOT NULL
              AND min_quantity IS NOT NULL AND quantity > min_quantity) = 0, 'ok', 'ECHEC')
UNION ALL
SELECT 'zeros non declares en rupture (doit etre 0)', '0',
       CONCAT((SELECT COUNT(*) FROM home_inventory
                WHERE status <> 'out' AND quantity IS NOT NULL AND quantity <= 0), ' ligne(s)'),
       IF((SELECT COUNT(*) FROM home_inventory
            WHERE status <> 'out' AND quantity IS NOT NULL AND quantity <= 0) = 0, 'ok', 'ECHEC')
UNION ALL
SELECT 'niveaux hors des trois valeurs (doit etre 0)', '0',
       CONCAT((SELECT COUNT(*) FROM home_inventory
                WHERE level IS NOT NULL AND level NOT IN ('full','half','low')), ' ligne(s)'),
       IF((SELECT COUNT(*) FROM home_inventory
            WHERE level IS NOT NULL AND level NOT IN ('full','half','low')) = 0, 'ok', 'ECHEC')

UNION ALL SELECT '', '', '', ''
UNION ALL
SELECT 'G. VOLUME (pour information, aucun verdict)', '', '', ''
UNION ALL
SELECT 'provisions suivies', '', CONCAT((SELECT COUNT(*) FROM home_inventory), ' ligne(s)'), ''
UNION ALL
SELECT 'articles de liste avec un prix', '',
       CONCAT((SELECT COUNT(*) FROM list_items WHERE price IS NOT NULL AND deleted_at IS NULL), ' article(s)'), ''
UNION ALL
SELECT 'budgets actifs', '', CONCAT((SELECT COUNT(*) FROM budgets WHERE is_active = 1), ' budget(s)'), ''
UNION ALL
SELECT 'recettes ecrites a la main', '',
       CONCAT((SELECT COUNT(*) FROM recipes WHERE user_id IS NOT NULL), ' recette(s)'), ''

UNION ALL SELECT '', '', '', ''
UNION ALL
SELECT 'H. VERDICT', '', '', ''
UNION ALL
-- Deux colonnes sur home_inventory, une sur list_items, deux sur
-- budgets, une sur email_preferences : six. Plus trois index.
SELECT 'colonnes de la migration 013', '6',
       CONCAT(
         (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = 'home_inventory' AND COLUMN_NAME IN ('expires_at','level'))
       + (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = 'list_items' AND COLUMN_NAME = 'price_is_estimate')
       + (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = 'budgets' AND COLUMN_NAME IN ('auto_renew','renewed_at'))
       + (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = 'email_preferences' AND COLUMN_NAME = 'price_alert_digest'),
       ' sur 6'),
       IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME = 'home_inventory' AND COLUMN_NAME IN ('expires_at','level'))
        + (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME = 'list_items' AND COLUMN_NAME = 'price_is_estimate')
        + (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME = 'budgets' AND COLUMN_NAME IN ('auto_renew','renewed_at'))
        + (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME = 'email_preferences' AND COLUMN_NAME = 'price_alert_digest') = 6,
          'ok', 'INCOMPLET')
UNION ALL
SELECT 'colonne de la migration 014 (zone)', '1',
       CONCAT((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE()
                AND TABLE_NAME = 'home_inventory' AND COLUMN_NAME = 'zone'), ' sur 1'),
       IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME = 'home_inventory' AND COLUMN_NAME = 'zone') = 1, 'ok', 'INCOMPLET')
UNION ALL
SELECT 'index des migrations 013 et 014', '4',
       CONCAT((SELECT COUNT(DISTINCT CONCAT(TABLE_NAME, INDEX_NAME)) FROM information_schema.STATISTICS
                WHERE TABLE_SCHEMA = DATABASE()
                  AND INDEX_NAME IN ('idx_inventory_peremption','idx_recipes_nom',
                                     'idx_ingredients_nom','idx_inventory_zone')),
              ' sur 4'),
       IF((SELECT COUNT(DISTINCT CONCAT(TABLE_NAME, INDEX_NAME)) FROM information_schema.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE()
              AND INDEX_NAME IN ('idx_inventory_peremption','idx_recipes_nom',
                                 'idx_ingredients_nom','idx_inventory_zone')) = 4,
          'ok', 'INCOMPLET')
UNION ALL
SELECT 'enum period_type', 'avec biweekly',
       IF(LOCATE('biweekly', IFNULL((SELECT COLUMN_TYPE FROM information_schema.COLUMNS
                                      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'budgets'
                                        AND COLUMN_NAME = 'period_type'), '')) > 0, 'oui', 'non'),
       IF(LOCATE('biweekly', IFNULL((SELECT COLUMN_TYPE FROM information_schema.COLUMNS
                                      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'budgets'
                                        AND COLUMN_NAME = 'period_type'), '')) > 0,
          'TOUT EST LA — le code peut partir', 'INCOMPLET — ne pas pousser');
