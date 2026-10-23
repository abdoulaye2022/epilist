-- ============================================================================
-- OU EST RANGE CE PRODUIT. 2026-10-23. Idempotente (rejouable sans erreur).
-- ============================================================================
--
-- L'analyse demande, pour chaque provision : « nom, ZONE, quantite,
-- unite, seuil minimal, date de peremption facultative ». La zone
-- manquait, et elle n'est pas un detail d'affichage :
--
--   « Les zones ont des fonds colores (lilas, menthe, miel, creme),
--     donc une icone coloree mince peut disparaitre. »
--
-- C'est la raison d'etre du badge plein pose par la migration 013 : il
-- doit rester lisible sur le fond de SA ZONE. Sans la zone, l'ecran
-- groupait par etat, et le badge se posait sur la couleur de son propre
-- etat — ce qui n'etait pas la question.
--
-- Quatre zones, et l'analyse les nomme en passant, dans le tableau des
-- icones : « ne represente qu'une zone sur quatre (garde-manger,
-- entretien) » — avec le refrigerateur et le congelateur.
--
-- VARCHAR et non ENUM, pour la meme raison que `status` et `level` :
-- une cinquieme zone (le cellier, le garage) ne doit pas demander une
-- migration de plus.
--
-- NULL reste permis : un produit suivi avant cette migration n'a pas de
-- zone, et il serait faux de lui en inventer une. L'ecran le range dans
-- « Ailleurs ».
--
-- Prerequis : add_household_intelligence.sql, 013_analyse_23_octobre.sql.
-- ============================================================================

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'home_inventory' AND COLUMN_NAME = 'zone');
SET @sql := IF(@c = 0,
    'ALTER TABLE home_inventory ADD COLUMN zone VARCHAR(20) NULL COMMENT ''pantry | fridge | freezer | household, NULL = ailleurs'' AFTER category_id',
    'SELECT "home_inventory.zone deja presente"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- L'index sert l'affichage : l'ecran lit l'inventaire d'un espace zone
-- par zone, a chaque ouverture.
SET @c := (SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'home_inventory' AND INDEX_NAME = 'idx_inventory_zone');
SET @sql := IF(@c = 0,
    'CREATE INDEX idx_inventory_zone ON home_inventory(space_id, zone)',
    'SELECT "index zone deja present"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ============================================================================
-- FIN. Verification : bloc A de 013_verification.sql, qui couvre les deux.
-- ============================================================================
