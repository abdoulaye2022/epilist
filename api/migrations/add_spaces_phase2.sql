-- ============================================================
-- ESPACES — PHASE 2 (foyer) : rattachement des tables métier.
-- Date : 2026-09-30. Idempotente (rejouable sans erreur).
-- Prérequis : add_spaces.sql (Phase 1).
--
-- Patron (docs/migration-espaces.md) : colonnes ADDITIVES space_id +
-- created_by_user_id, backfill vers l'espace PERSONNEL du user_id.
-- user_id n'est JAMAIS supprimé. list_items/list_receipts/
-- list_messages héritent de l'espace via list_id (pas de colonne),
-- mais list_items reçoit l'attribution (« ajouté par / acheté par »).
-- ============================================================

-- Utilitaire répété : ajout de colonne si absente.
-- 1. shopping_lists ---------------------------------------------------
SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='shopping_lists' AND column_name='space_id');
SET @sql=IF(@c=0,'ALTER TABLE shopping_lists ADD COLUMN space_id INT NULL AFTER user_id, ADD COLUMN created_by_user_id INT NULL AFTER space_id, ADD KEY idx_sl_space (space_id)','SELECT "sl ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 2. budgets ----------------------------------------------------------
SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='budgets' AND column_name='space_id');
SET @sql=IF(@c=0,'ALTER TABLE budgets ADD COLUMN space_id INT NULL AFTER user_id, ADD COLUMN created_by_user_id INT NULL AFTER space_id, ADD KEY idx_budget_space (space_id)','SELECT "budgets ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 3. home_inventory ---------------------------------------------------
SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='home_inventory' AND column_name='space_id');
SET @sql=IF(@c=0,'ALTER TABLE home_inventory ADD COLUMN space_id INT NULL AFTER user_id, ADD COLUMN created_by_user_id INT NULL AFTER space_id, ADD KEY idx_inv_space (space_id)','SELECT "inventory ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 4. stores (remplace le vestige household_id, jamais lu) -------------
SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='stores' AND column_name='space_id');
SET @sql=IF(@c=0,'ALTER TABLE stores ADD COLUMN space_id INT NULL AFTER user_id, ADD COLUMN created_by_user_id INT NULL AFTER space_id, ADD KEY idx_store_space (space_id)','SELECT "stores ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 5. recurring_lists --------------------------------------------------
SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='recurring_lists' AND column_name='space_id');
SET @sql=IF(@c=0,'ALTER TABLE recurring_lists ADD COLUMN space_id INT NULL AFTER user_id, ADD COLUMN created_by_user_id INT NULL AFTER space_id, ADD KEY idx_rec_space (space_id)','SELECT "recurring ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 6. meal_plans -------------------------------------------------------
SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='meal_plans' AND column_name='space_id');
SET @sql=IF(@c=0,'ALTER TABLE meal_plans ADD COLUMN space_id INT NULL AFTER user_id, ADD COLUMN created_by_user_id INT NULL AFTER space_id, ADD KEY idx_mp_space (space_id)','SELECT "meal_plans ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 7. recipes ----------------------------------------------------------
SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='recipes' AND column_name='space_id');
SET @sql=IF(@c=0,'ALTER TABLE recipes ADD COLUMN space_id INT NULL AFTER user_id, ADD COLUMN created_by_user_id INT NULL AFTER space_id, ADD KEY idx_recipe_space (space_id)','SELECT "recipes ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 8. list_items : attribution (« ajouté par », « acheté par ») --------
SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='list_items' AND column_name='created_by_user_id');
SET @sql=IF(@c=0,'ALTER TABLE list_items ADD COLUMN created_by_user_id INT NULL AFTER store_name, ADD COLUMN purchased_by_user_id INT NULL AFTER created_by_user_id','SELECT "items ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 8b. home_inventory : l'unicité produit devient PAR ESPACE (le même
--     produit peut exister dans le personnel ET dans le foyer).
SET @c=(SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='home_inventory' AND index_name='uq_inventory_user_product');
SET @sql=IF(@c>0,'ALTER TABLE home_inventory DROP INDEX uq_inventory_user_product','SELECT "old idx gone"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
SET @c=(SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='home_inventory' AND index_name='uq_inventory_space_product');
SET @sql=IF(@c=0,'ALTER TABLE home_inventory ADD UNIQUE KEY uq_inventory_space_product (space_id, normalized_name)','SELECT "new idx ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 9. Journal d'activité (événements STRUCTURÉS : type + payload JSON,
--    le rendu traduit fr/en se fait côté client) ----------------------
CREATE TABLE IF NOT EXISTS space_activities (
    id INT NOT NULL AUTO_INCREMENT,
    space_id INT NOT NULL,
    user_id INT NULL,
    type VARCHAR(40) NOT NULL,
    payload JSON NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_act_space (space_id, created_at),
    CONSTRAINT fk_act_space FOREIGN KEY (space_id) REFERENCES spaces(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. Backfills idempotents : espace personnel du propriétaire --------
UPDATE shopping_lists t JOIN spaces s ON s.owner_user_id = t.user_id AND s.type='personal' AND s.deleted_at IS NULL
   SET t.space_id = s.id, t.created_by_user_id = t.user_id WHERE t.space_id IS NULL;
UPDATE budgets t JOIN spaces s ON s.owner_user_id = t.user_id AND s.type='personal' AND s.deleted_at IS NULL
   SET t.space_id = s.id, t.created_by_user_id = t.user_id WHERE t.space_id IS NULL;
UPDATE home_inventory t JOIN spaces s ON s.owner_user_id = t.user_id AND s.type='personal' AND s.deleted_at IS NULL
   SET t.space_id = s.id, t.created_by_user_id = t.user_id WHERE t.space_id IS NULL;
UPDATE stores t JOIN spaces s ON s.owner_user_id = t.user_id AND s.type='personal' AND s.deleted_at IS NULL
   SET t.space_id = s.id, t.created_by_user_id = t.user_id WHERE t.space_id IS NULL;
UPDATE recurring_lists t JOIN spaces s ON s.owner_user_id = t.user_id AND s.type='personal' AND s.deleted_at IS NULL
   SET t.space_id = s.id, t.created_by_user_id = t.user_id WHERE t.space_id IS NULL;
UPDATE meal_plans t JOIN spaces s ON s.owner_user_id = t.user_id AND s.type='personal' AND s.deleted_at IS NULL
   SET t.space_id = s.id, t.created_by_user_id = t.user_id WHERE t.space_id IS NULL;
UPDATE recipes t JOIN spaces s ON s.owner_user_id = t.user_id AND s.type='personal' AND s.deleted_at IS NULL
   SET t.space_id = s.id, t.created_by_user_id = t.user_id WHERE t.space_id IS NULL;
-- Attribution héritée : le propriétaire de la liste a ajouté l'article.
UPDATE list_items li JOIN shopping_lists sl ON sl.id = li.list_id
   SET li.created_by_user_id = sl.user_id
 WHERE li.created_by_user_id IS NULL;
UPDATE list_items li JOIN shopping_lists sl ON sl.id = li.list_id
   SET li.purchased_by_user_id = sl.user_id
 WHERE li.purchased_by_user_id IS NULL AND li.is_purchased = 1;

SELECT 'verification' AS v,
 (SELECT COUNT(*) FROM shopping_lists WHERE space_id IS NULL) AS sl_null,
 (SELECT COUNT(*) FROM budgets WHERE space_id IS NULL) AS budgets_null,
 (SELECT COUNT(*) FROM home_inventory WHERE space_id IS NULL) AS inv_null,
 (SELECT COUNT(*) FROM stores WHERE space_id IS NULL) AS stores_null,
 (SELECT COUNT(*) FROM recurring_lists WHERE space_id IS NULL) AS rec_null,
 (SELECT COUNT(*) FROM meal_plans WHERE space_id IS NULL) AS mp_null,
 (SELECT COUNT(*) FROM recipes WHERE space_id IS NULL) AS recipes_null,
 (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='space_activities') AS activities_table;
