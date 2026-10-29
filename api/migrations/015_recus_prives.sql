-- Migration 015 — les photos de recus deviennent PRIVEES.
--
-- Pourquoi : jusqu'ici l'image d'un recu etait televersee en
-- 'predefinedAcl' => 'publicRead' et la base gardait son URL publique.
-- Quiconque connaissait cette URL lisait le recu — magasin, date,
-- montants — sans compte et sans jeton. Une URL non devinable n'est pas
-- une URL privee : elle fuit par un partage d'ecran, un presse-papier,
-- un journal de proxy.
--
-- Ce que fait cette migration :
--   1. ajoute list_receipts.image_path : la CLE de l'objet dans le
--      stockage, ex. « prod/receipts/a1b2....jpg » ;
--   2. remplit image_path a partir des URL deja en base ;
--   3. laisse image_url EN PLACE. Elle n'est pas supprimee ici, et c'est
--      voulu : les applications deja installees (2.2.1 et avant) lisent
--      ce champ. Le retirer afficherait une erreur chez elles. Il sera
--      retire quand le parc aura tourne.
--
-- Rien n'est detruit, la migration est rejouable, et elle ne touche
-- AUCUN objet du stockage : rendre les fichiers prives est le travail de
-- scripts/make_receipts_private.php, a lancer separement.
--
-- Retour en arriere : voir le bloc commente en fin de fichier.

-- 1. La colonne -------------------------------------------------------
SET @c = (SELECT COUNT(*) FROM information_schema.columns
          WHERE table_schema = DATABASE()
            AND table_name = 'list_receipts'
            AND column_name = 'image_path');
SET @sql = IF(@c = 0,
    'ALTER TABLE list_receipts ADD COLUMN image_path VARCHAR(500) NULL COMMENT ''Cle de l objet dans le stockage prive ; remplace image_url'' AFTER image_url',
    'SELECT "list_receipts.image_path deja presente"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 2. Les URL deja en base deviennent des cles -------------------------
-- On ne coupe pas sur une longueur fixe : le nom du bucket est
-- configurable (GCS_BUCKET), donc le prefixe varie. On coupe apres le
-- troisieme « / » qui suit « storage.googleapis.com/ », c'est-a-dire
-- apres le nom du bucket.
UPDATE list_receipts
   SET image_path = SUBSTRING(
           image_url,
           LOCATE('/', image_url, LOCATE('storage.googleapis.com/', image_url) + 23) + 1
       )
 WHERE image_path IS NULL
   AND image_url IS NOT NULL
   AND image_url LIKE 'https://storage.googleapis.com/%';

-- Une valeur qui n'est pas une URL de notre stockage est deja une cle.
UPDATE list_receipts
   SET image_path = image_url
 WHERE image_path IS NULL
   AND image_url IS NOT NULL
   AND image_url <> ''
   AND image_url NOT LIKE '%://%';

-- 3. Verification -----------------------------------------------------
SELECT 'verification 015' AS controle,
  (SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'list_receipts'
      AND column_name = 'image_path')                                   AS colonne_presente,
  (SELECT COUNT(*) FROM list_receipts
    WHERE image_url IS NOT NULL AND image_url <> '')                    AS lignes_avec_url,
  (SELECT COUNT(*) FROM list_receipts
    WHERE image_path IS NOT NULL AND image_path <> '')                  AS lignes_avec_cle,
  (SELECT COUNT(*) FROM list_receipts
    WHERE image_url IS NOT NULL AND image_url <> ''
      AND (image_path IS NULL OR image_path = ''))                      AS restent_a_convertir,
  (SELECT COUNT(*) FROM list_receipts
    WHERE image_path LIKE '%://%')                                      AS cles_mal_formees;

-- Attendu : colonne_presente = 1, lignes_avec_cle = lignes_avec_url,
--           restent_a_convertir = 0, cles_mal_formees = 0.

-- ---------------------------------------------------------------------
-- RETOUR EN ARRIERE (a jouer a la main, rien n'est perdu entre-temps) :
--
--   ALTER TABLE list_receipts DROP COLUMN image_path;
--
-- image_url n'ayant jamais ete modifiee, l'application d'avant
-- fonctionne a nouveau des que les objets redeviennent publics.
-- ---------------------------------------------------------------------
