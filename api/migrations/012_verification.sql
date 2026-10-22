-- ============================================================================
-- VERIFICATION D'APRES-MIGRATION 012. NE MODIFIE RIEN.
-- ============================================================================
--
-- A coller dans l'onglet SQL de phpMyAdmin, sur la base de PRODUCTION,
-- APRES 012_planche_version_b.sql.
--
-- Que des SELECT : il lit, il compte, il dit. Rejouable.
--
-- Il ne se contente pas de verifier que les colonnes EXISTENT. Une
-- table peut naitre sans ses clefs etrangeres, une colonne avec le
-- mauvais type, un JSON en VARCHAR : tout cela passe la verification
-- naive, et casse au premier enregistrement.
--
-- Lecture : la colonne `verdict`. Tant qu'une ligne ne dit pas « ok »,
-- ne pas pousser le code — l'API lirait quelque chose qui n'est pas la.
-- ============================================================================

SELECT 'A. MAGASINS — adresse, coordonnees, horaires' AS controle, '' AS attendu, '' AS trouve, '' AS verdict
UNION ALL
SELECT CONCAT('stores.', c.nom), c.type,
       IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'stores' AND COLUMN_NAME = c.nom), 'absente'),
       IF((SELECT DATA_TYPE FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'stores' AND COLUMN_NAME = c.nom) = c.type,
          'ok', 'ECHEC')
FROM (
    SELECT 'address' AS nom, 'varchar' AS type
    UNION ALL SELECT 'city',        'varchar'
    UNION ALL SELECT 'postal_code', 'varchar'
    UNION ALL SELECT 'latitude',    'decimal'
    UNION ALL SELECT 'longitude',   'decimal'
    -- Un JSON tombe en VARCHAR si le serveur MySQL est trop vieux
    -- (< 5.7) : les heures d'ouverture ne se reliraient pas.
    UNION ALL SELECT 'opening_hours', 'json'
) AS c

UNION ALL SELECT '', '', '', ''
UNION ALL
SELECT 'B. FAVORIS — portes par le MEMBRE, pas par l''objet', '', '', ''
UNION ALL
SELECT CONCAT('table ', t.nom), 'existe',
       IF((SELECT COUNT(*) FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = t.nom) = 1, 'oui', 'non'),
       IF((SELECT COUNT(*) FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = t.nom) = 1, 'ok', 'ECHEC')
FROM (SELECT 'store_favorites' AS nom UNION ALL SELECT 'recipe_favorites') AS t
UNION ALL
-- Sans la clef unique, appuyer deux fois sur l'etoile creerait deux
-- lignes, et le favori ne se retirerait plus jamais completement.
SELECT CONCAT(u.tbl, ' : clef unique'), '1 clef',
       CONCAT((SELECT COUNT(DISTINCT INDEX_NAME) FROM information_schema.STATISTICS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = u.tbl
                  AND NON_UNIQUE = 0 AND INDEX_NAME <> 'PRIMARY'), ' clef(s)'),
       IF((SELECT COUNT(DISTINCT INDEX_NAME) FROM information_schema.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = u.tbl
              AND NON_UNIQUE = 0 AND INDEX_NAME <> 'PRIMARY') >= 1, 'ok', 'ECHEC')
FROM (SELECT 'store_favorites' AS tbl UNION ALL SELECT 'recipe_favorites') AS u
UNION ALL
-- Sans les clefs etrangeres, supprimer un magasin laisserait ses
-- favoris orphelins, et la liste afficherait des etoiles fantomes.
SELECT CONCAT(f.tbl, ' : clefs etrangeres'), '2 clefs',
       CONCAT((SELECT COUNT(*) FROM information_schema.KEY_COLUMN_USAGE
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = f.tbl
                  AND REFERENCED_TABLE_NAME IS NOT NULL), ' clef(s)'),
       IF((SELECT COUNT(*) FROM information_schema.KEY_COLUMN_USAGE
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = f.tbl
              AND REFERENCED_TABLE_NAME IS NOT NULL) = 2, 'ok', 'ECHEC — table MyISAM ?')
FROM (SELECT 'store_favorites' AS tbl UNION ALL SELECT 'recipe_favorites') AS f
UNION ALL
-- La fausse route : une colonne is_favorite sur recipes aurait valu
-- pour TOUS les comptes, les recettes livrees etant partagees.
SELECT 'recipes.is_favorite retiree', 'absente',
       IF((SELECT COUNT(*) FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'recipes'
              AND COLUMN_NAME = 'is_favorite') = 0, 'absente', 'PRESENTE'),
       IF((SELECT COUNT(*) FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'recipes'
              AND COLUMN_NAME = 'is_favorite') = 0, 'ok', 'ECHEC')

UNION ALL SELECT '', '', '', ''
UNION ALL
SELECT 'C. REPAS — un plat, un jour', '', '', ''
UNION ALL
SELECT CONCAT('meal_plan_recipes.', m.nom), 'existe',
       IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'meal_plan_recipes'
                  AND COLUMN_NAME = m.nom), 'absente'),
       IF((SELECT COUNT(*) FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'meal_plan_recipes'
              AND COLUMN_NAME = m.nom) = 1, 'ok', 'ECHEC')
FROM (SELECT 'weekday' AS nom UNION ALL SELECT 'meal_slot') AS m

UNION ALL SELECT '', '', '', ''
UNION ALL
SELECT 'D. PHOTOS DE PRODUITS', '', '', ''
UNION ALL
SELECT 'table product_images', 'existe',
       IF((SELECT COUNT(*) FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'product_images') = 1, 'oui', 'non'),
       IF((SELECT COUNT(*) FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'product_images') = 1, 'ok', 'ECHEC')
UNION ALL
-- La clef unique est (space_id, normalized_name) : sans elle, une
-- deuxieme photo du meme produit creerait une deuxieme ligne, et
-- l'alerte en prendrait une au hasard.
SELECT 'product_images : clef (space_id, normalized_name)', '2 colonnes',
       CONCAT((SELECT COUNT(*) FROM information_schema.STATISTICS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'product_images'
                  AND INDEX_NAME = 'uq_product_image'), ' colonne(s)'),
       IF((SELECT COUNT(*) FROM information_schema.STATISTICS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'product_images'
              AND INDEX_NAME = 'uq_product_image') = 2, 'ok', 'ECHEC')
UNION ALL
SELECT 'product_images : lignes posees',
       'etape 3 (semis)',
       CONCAT((SELECT COUNT(*) FROM product_images), ' ligne(s)'),
       IF((SELECT COUNT(*) FROM product_images) > 0,
          'ok — le semis est passe',
          'a faire — etape 3, ou aucune photo en base')
UNION ALL
-- Le semis est fini quand toute photo d'article a sa ligne de produit.
SELECT 'articles photographies sans ligne produit', '0',
       CONCAT((SELECT COUNT(DISTINCT li.product_name)
                 FROM list_items li
                 JOIN shopping_lists sl ON sl.id = li.list_id
                WHERE li.image_url IS NOT NULL AND li.image_url <> ''
                  AND li.deleted_at IS NULL AND sl.deleted_at IS NULL), ' produit(s) photographie(s)'),
       IF((SELECT COUNT(*) FROM list_items li
             JOIN shopping_lists sl ON sl.id = li.list_id
            WHERE li.image_url IS NOT NULL AND li.image_url <> ''
              AND li.deleted_at IS NULL AND sl.deleted_at IS NULL) = 0
          OR (SELECT COUNT(*) FROM product_images) > 0,
          'ok', 'a faire — lancer l''etape 3')

UNION ALL SELECT '', '', '', ''
UNION ALL
SELECT 'E. INVITATIONS — nom et telephone', '', '', ''
UNION ALL
SELECT CONCAT('space_invitations.', i.nom), 'existe',
       IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'space_invitations'
                  AND COLUMN_NAME = i.nom), 'absente'),
       IF((SELECT COUNT(*) FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'space_invitations'
              AND COLUMN_NAME = i.nom) = 1, 'ok', 'ECHEC')
FROM (SELECT 'invitee_name' AS nom UNION ALL SELECT 'invitee_phone') AS i

UNION ALL SELECT '', '', '', ''
UNION ALL
SELECT 'F. RIEN N''A ETE PERDU', '', '', ''
UNION ALL
-- La migration n'ecrit aucune donnee : ces comptes doivent etre les
-- memes qu'avant. Les comparer a ceux du bloc C de 012_prerequis.sql.
SELECT 'magasins', 'inchange', CONCAT((SELECT COUNT(*) FROM stores), ' ligne(s)'), 'a comparer aux prerequis'
UNION ALL
SELECT 'recettes', 'inchange', CONCAT((SELECT COUNT(*) FROM recipes), ' ligne(s)'), 'a comparer aux prerequis'
UNION ALL
SELECT 'invitations', 'inchange', CONCAT((SELECT COUNT(*) FROM space_invitations), ' ligne(s)'), 'a comparer aux prerequis'
UNION ALL
SELECT 'plats de plans de repas', 'inchange', CONCAT((SELECT COUNT(*) FROM meal_plan_recipes), ' ligne(s)'), 'a comparer aux prerequis'

UNION ALL SELECT '', '', '', ''
UNION ALL
SELECT 'G. VERDICT', '', '', ''
UNION ALL
-- Six colonnes sur stores, trois tables neuves, deux colonnes de
-- repas, deux d'invitation : treize. (Ecrit « 14 » au premier jet, ce
-- qui faisait crier INCOMPLET sur une migration parfaitement passee.)
SELECT 'colonnes et tables de la migration 012', '13',
       CONCAT(
         (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = 'stores'
           AND COLUMN_NAME IN ('address','city','postal_code','latitude','longitude','opening_hours'))
       + (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME IN ('store_favorites','recipe_favorites','product_images'))
       + (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = 'meal_plan_recipes' AND COLUMN_NAME IN ('weekday','meal_slot'))
       + (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = 'space_invitations' AND COLUMN_NAME IN ('invitee_name','invitee_phone')),
       ' sur 13'),
       IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME = 'stores'
            AND COLUMN_NAME IN ('address','city','postal_code','latitude','longitude','opening_hours'))
         + (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME IN ('store_favorites','recipe_favorites','product_images'))
         + (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME = 'meal_plan_recipes' AND COLUMN_NAME IN ('weekday','meal_slot'))
         + (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME = 'space_invitations' AND COLUMN_NAME IN ('invitee_name','invitee_phone')) = 13,
          'TOUT EST LA — le code peut partir',
          'INCOMPLET — ne pas pousser');
