-- ============================================================================
-- ETAPE 1 — PREREQUIS DE LA MIGRATION 012. NE MODIFIE RIEN.
-- ============================================================================
--
-- A coller dans l'onglet SQL de phpMyAdmin, sur la base de PRODUCTION,
-- AVANT 012_planche_version_b.sql.
--
-- Ce fichier ne contient que des SELECT : il lit, il compte, il dit. Il
-- n'ecrit pas une ligne. On peut le rejouer autant de fois qu'on veut.
--
-- Il repond a UNE question : la base de production a-t-elle de quoi
-- recevoir la migration 012 ?
--
-- La colonne `verdict` dit quoi faire. Tant qu'une seule ligne porte
-- « MANQUE », ne pas jouer 012 : elle echouerait au milieu, laissant la
-- base a moitie migree.
-- ============================================================================

SELECT 'A. PREREQUIS — tables attendues par la migration 012' AS controle,
       '' AS detail, '' AS verdict
UNION ALL
SELECT
    CONCAT('table ', t.nom),
    CONCAT('vient de ', t.migration),
    IF((SELECT COUNT(*) FROM information_schema.TABLES
         WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = t.nom) = 1,
       'ok', 'MANQUE — jouer d''abord cette migration')
FROM (
    SELECT 'stores'            AS nom, 'add_stores_and_aisle_order.sql' AS migration
    UNION ALL SELECT 'recipes',           'add_household_intelligence.sql'
    UNION ALL SELECT 'meal_plan_recipes', 'add_household_intelligence.sql'
    UNION ALL SELECT 'space_invitations', 'add_spaces.sql'
    UNION ALL SELECT 'price_alerts',      'add_spaces_phase4.sql'
    UNION ALL SELECT 'users',             'schema de base'
    UNION ALL SELECT 'list_items',        'schema de base'
    UNION ALL SELECT 'shopping_lists',    'schema de base'
) AS t

UNION ALL
SELECT '', '', ''
UNION ALL
SELECT 'B. ETAT — la migration 012 est-elle deja passee ?', '', ''
UNION ALL
-- Six colonnes attendues sur stores, deux tables de favoris, deux
-- colonnes de repas, une table d'images, deux colonnes d'invitation.
SELECT 'stores : adresse et horaires',
       CONCAT((SELECT COUNT(*) FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'stores'
                  AND COLUMN_NAME IN ('address','city','postal_code','latitude','longitude','opening_hours')),
              ' colonnes sur 6'),
       IF((SELECT COUNT(*) FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'stores'
              AND COLUMN_NAME IN ('address','city','postal_code','latitude','longitude','opening_hours')) = 6,
          'deja fait', 'a faire')
UNION ALL
SELECT 'table store_favorites', '',
       IF((SELECT COUNT(*) FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'store_favorites') = 1,
          'deja fait', 'a faire')
UNION ALL
SELECT 'table recipe_favorites', '',
       IF((SELECT COUNT(*) FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'recipe_favorites') = 1,
          'deja fait', 'a faire')
UNION ALL
SELECT 'meal_plan_recipes : jour et moment',
       CONCAT((SELECT COUNT(*) FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'meal_plan_recipes'
                  AND COLUMN_NAME IN ('weekday','meal_slot')), ' colonnes sur 2'),
       IF((SELECT COUNT(*) FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'meal_plan_recipes'
              AND COLUMN_NAME IN ('weekday','meal_slot')) = 2,
          'deja fait', 'a faire')
UNION ALL
SELECT 'table product_images', '',
       IF((SELECT COUNT(*) FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'product_images') = 1,
          'deja fait', 'a faire')
UNION ALL
SELECT 'space_invitations : nom et telephone',
       CONCAT((SELECT COUNT(*) FROM information_schema.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'space_invitations'
                  AND COLUMN_NAME IN ('invitee_name','invitee_phone')), ' colonnes sur 2'),
       IF((SELECT COUNT(*) FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'space_invitations'
              AND COLUMN_NAME IN ('invitee_name','invitee_phone')) = 2,
          'deja fait', 'a faire')

UNION ALL
SELECT '', '', ''
UNION ALL
SELECT 'C. VOLUME — ce que la migration va toucher', '', ''
UNION ALL
SELECT 'magasins', CONCAT((SELECT COUNT(*) FROM stores), ' lignes'),
       'colonnes ajoutees, nulles : aucune ligne reecrite'
UNION ALL
SELECT 'invitations', CONCAT((SELECT COUNT(*) FROM space_invitations), ' lignes'),
       'colonnes ajoutees, nulles : aucune ligne reecrite'
UNION ALL
SELECT 'articles avec photo',
       CONCAT((SELECT COUNT(*) FROM list_items
                WHERE image_url IS NOT NULL AND image_url <> '' AND deleted_at IS NULL), ' lignes'),
       'ce que l''etape 3 remontera dans product_images'

UNION ALL
SELECT '', '', ''
UNION ALL
SELECT 'D. LIGATURES — le normaliseur corrige change-t-il une clef ?', '', ''
UNION ALL
-- « Œuf » donnait « uf » : la ligature n'etait pas traduite, puis le
-- filtre la jetait. Si des lignes en portent, leur clef CHANGERA, et il
-- faudra les reindexer. Zero en local ; a verifier ici.
SELECT 'purchase_history avec oe ou ae lies',
       CONCAT((SELECT COUNT(*) FROM purchase_history WHERE product_name REGEXP '[ŒœÆæ]'), ' lignes'),
       IF((SELECT COUNT(*) FROM purchase_history WHERE product_name REGEXP '[ŒœÆæ]') = 0,
          'rien a reindexer',
          'ATTENTION — ces produits changeront de clef, me le dire avant')
UNION ALL
SELECT 'product_aliases avec oe ou ae lies',
       CONCAT((SELECT COUNT(*) FROM product_aliases WHERE alias REGEXP '[ŒœÆæ]'), ' lignes'),
       IF((SELECT COUNT(*) FROM product_aliases WHERE alias REGEXP '[ŒœÆæ]') = 0,
          'rien a reindexer',
          'ATTENTION — ces alias changeront de clef, me le dire avant');
