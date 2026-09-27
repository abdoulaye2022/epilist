-- ============================================================
-- INTELLIGENCE DU FOYER — prédictions, inventaire maison, repas,
-- listes récurrentes. Date : 2026-09-27. Idempotente (rejouable).
--
-- Portée : PAR UTILISATEUR (le projet n'a pas de notion de foyer ;
-- le partage passe par les listes partagées existantes).
-- Le moteur de prédiction lit purchase_history à la volée : aucune
-- procédure stockée, aucun trigger (leçons de add_smart_suggestions).
-- ============================================================

-- 1. Inventaire maison ultra-simple ----------------------------------
CREATE TABLE IF NOT EXISTS home_inventory (
    id INT NOT NULL AUTO_INCREMENT,
    user_id INT NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    normalized_name VARCHAR(255) NOT NULL,
    category_id INT NULL,
    status VARCHAR(15) NOT NULL DEFAULT 'at_home' COMMENT 'at_home | running_low | out',
    quantity DECIMAL(10,3) NULL COMMENT 'facultatif, jamais requis',
    unit VARCHAR(10) NULL,
    source VARCHAR(10) NOT NULL DEFAULT 'manual' COMMENT 'manual | estimated',
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_inventory_user_product (user_id, normalized_name),
    KEY idx_inventory_user_status (user_id, status),
    CONSTRAINT fk_inventory_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Préférences de prédiction par produit ---------------------------
CREATE TABLE IF NOT EXISTS product_prediction_prefs (
    id INT NOT NULL AUTO_INCREMENT,
    user_id INT NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    normalized_name VARCHAR(255) NOT NULL,
    enabled TINYINT NOT NULL DEFAULT 1 COMMENT '0 = ne plus jamais suggerer',
    snoozed_until DATETIME NULL,
    last_feedback VARCHAR(20) NULL COMMENT 'added | not_now | still_have | never',
    custom_frequency_days INT NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_pred_prefs_user_product (user_id, normalized_name),
    CONSTRAINT fk_pred_prefs_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Recettes (user_id NULL = recette de base fournie par EpiList) ---
CREATE TABLE IF NOT EXISTS recipes (
    id INT NOT NULL AUTO_INCREMENT,
    user_id INT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT NULL,
    servings INT NOT NULL DEFAULT 4,
    preparation_time INT NULL COMMENT 'minutes',
    category VARCHAR(30) NULL,
    image_url VARCHAR(500) NULL,
    active TINYINT NOT NULL DEFAULT 1,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_recipes_user (user_id, active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS recipe_ingredients (
    id INT NOT NULL AUTO_INCREMENT,
    recipe_id INT NOT NULL,
    ingredient_name VARCHAR(150) NOT NULL,
    normalized_name VARCHAR(150) NOT NULL,
    quantity DECIMAL(10,3) NOT NULL DEFAULT 1,
    unit VARCHAR(10) NULL COMMENT 'kg, g, L, ml, un',
    optional TINYINT NOT NULL DEFAULT 0,
    category_kind VARCHAR(30) NULL,
    PRIMARY KEY (id),
    KEY idx_recipe_ing_recipe (recipe_id),
    CONSTRAINT fk_recipe_ing_recipe FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Plans de repas ---------------------------------------------------
CREATE TABLE IF NOT EXISTS meal_plans (
    id INT NOT NULL AUTO_INCREMENT,
    user_id INT NOT NULL,
    name VARCHAR(150) NOT NULL,
    people INT NOT NULL DEFAULT 4,
    budget_max DECIMAL(10,2) NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_meal_plans_user (user_id),
    CONSTRAINT fk_meal_plans_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS meal_plan_recipes (
    id INT NOT NULL AUTO_INCREMENT,
    meal_plan_id INT NOT NULL,
    recipe_id INT NOT NULL,
    servings INT NOT NULL DEFAULT 4,
    PRIMARY KEY (id),
    KEY idx_mpr_plan (meal_plan_id),
    CONSTRAINT fk_mpr_plan FOREIGN KEY (meal_plan_id) REFERENCES meal_plans(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Listes récurrentes ------------------------------------------------
CREATE TABLE IF NOT EXISTS recurring_lists (
    id INT NOT NULL AUTO_INCREMENT,
    user_id INT NOT NULL,
    name VARCHAR(150) NOT NULL,
    recurrence_type VARCHAR(10) NOT NULL DEFAULT 'weekly' COMMENT 'weekly | biweekly | monthly',
    weekday TINYINT NULL COMMENT '1=lundi ... 7=dimanche (weekly/biweekly)',
    next_run_at DATETIME NOT NULL,
    store_id INT NULL,
    enabled TINYINT NOT NULL DEFAULT 1,
    auto_generate TINYINT NOT NULL DEFAULT 0,
    last_generated_at DATETIME NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_recurring_user (user_id),
    KEY idx_recurring_due (enabled, auto_generate, next_run_at),
    CONSTRAINT fk_recurring_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS recurring_list_items (
    id INT NOT NULL AUTO_INCREMENT,
    recurring_list_id INT NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    normalized_name VARCHAR(255) NOT NULL,
    default_quantity INT NOT NULL DEFAULT 1,
    unit VARCHAR(10) NULL,
    optional TINYINT NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    KEY idx_rli_list (recurring_list_id),
    CONSTRAINT fk_rli_list FOREIGN KEY (recurring_list_id) REFERENCES recurring_lists(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Recettes de base (seed idempotent, user_id NULL) ------------------
INSERT INTO recipes (user_id, name, description, servings, preparation_time, category)
SELECT NULL, 'Poulet et riz', 'Poulet rôti, riz et légumes', 4, 45, 'souper'
WHERE NOT EXISTS (SELECT 1 FROM recipes WHERE name = 'Poulet et riz' AND user_id IS NULL);

INSERT INTO recipes (user_id, name, description, servings, preparation_time, category)
SELECT NULL, 'Spaghetti bolognaise', 'Pâtes, sauce tomate et boeuf haché', 4, 35, 'souper'
WHERE NOT EXISTS (SELECT 1 FROM recipes WHERE name = 'Spaghetti bolognaise' AND user_id IS NULL);

INSERT INTO recipes (user_id, name, description, servings, preparation_time, category)
SELECT NULL, 'Tacos', 'Tortillas, boeuf haché, tomates et fromage', 4, 30, 'souper'
WHERE NOT EXISTS (SELECT 1 FROM recipes WHERE name = 'Tacos' AND user_id IS NULL);

INSERT INTO recipes (user_id, name, description, servings, preparation_time, category)
SELECT NULL, 'Omelette aux légumes', 'Oeufs, poivrons, oignons et fromage', 2, 15, 'dejeuner'
WHERE NOT EXISTS (SELECT 1 FROM recipes WHERE name = 'Omelette aux légumes' AND user_id IS NULL);

INSERT INTO recipes (user_id, name, description, servings, preparation_time, category)
SELECT NULL, 'Poisson et pommes de terre', 'Filet de poisson au four, pommes de terre rôties', 4, 40, 'souper'
WHERE NOT EXISTS (SELECT 1 FROM recipes WHERE name = 'Poisson et pommes de terre' AND user_id IS NULL);

INSERT INTO recipes (user_id, name, description, servings, preparation_time, category)
SELECT NULL, 'Chili con carne', 'Boeuf haché, haricots rouges, tomates et riz', 6, 50, 'souper'
WHERE NOT EXISTS (SELECT 1 FROM recipes WHERE name = 'Chili con carne' AND user_id IS NULL);

INSERT INTO recipes (user_id, name, description, servings, preparation_time, category)
SELECT NULL, 'Sauté de légumes au riz', 'Légumes sautés, riz et sauce soya', 4, 25, 'souper'
WHERE NOT EXISTS (SELECT 1 FROM recipes WHERE name = 'Sauté de légumes au riz' AND user_id IS NULL);

INSERT INTO recipes (user_id, name, description, servings, preparation_time, category)
SELECT NULL, 'Salade César au poulet', 'Laitue romaine, poulet grillé, croûtons et parmesan', 4, 25, 'diner'
WHERE NOT EXISTS (SELECT 1 FROM recipes WHERE name = 'Salade César au poulet' AND user_id IS NULL);

-- Ingrédients des recettes de base (idempotent par recette + nom)
-- Poulet et riz
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Poulet', 'poulet', 1.2, 'kg', 0, 'meat' FROM recipes r
WHERE r.name = 'Poulet et riz' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'poulet');
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Riz', 'riz', 0.5, 'kg', 0, 'pantry' FROM recipes r
WHERE r.name = 'Poulet et riz' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'riz');
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Carottes', 'carottes', 4, 'un', 0, 'fruits_vegetables' FROM recipes r
WHERE r.name = 'Poulet et riz' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'carottes');
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Oignons', 'oignons', 2, 'un', 0, 'fruits_vegetables' FROM recipes r
WHERE r.name = 'Poulet et riz' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'oignons');

-- Spaghetti bolognaise
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Spaghetti', 'spaghetti', 0.5, 'kg', 0, 'pantry' FROM recipes r
WHERE r.name = 'Spaghetti bolognaise' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'spaghetti');
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Boeuf haché', 'boeuf hache', 0.5, 'kg', 0, 'meat' FROM recipes r
WHERE r.name = 'Spaghetti bolognaise' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'boeuf hache');
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Sauce tomate', 'sauce tomate', 1, 'un', 0, 'pantry' FROM recipes r
WHERE r.name = 'Spaghetti bolognaise' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'sauce tomate');
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Parmesan', 'parmesan', 1, 'un', 1, 'dairy' FROM recipes r
WHERE r.name = 'Spaghetti bolognaise' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'parmesan');

-- Tacos
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Tortillas', 'tortillas', 12, 'un', 0, 'bakery' FROM recipes r
WHERE r.name = 'Tacos' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'tortillas');
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Boeuf haché', 'boeuf hache', 0.5, 'kg', 0, 'meat' FROM recipes r
WHERE r.name = 'Tacos' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'boeuf hache');
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Tomates', 'tomates', 4, 'un', 0, 'fruits_vegetables' FROM recipes r
WHERE r.name = 'Tacos' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'tomates');
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Fromage râpé', 'fromage rape', 0.2, 'kg', 0, 'dairy' FROM recipes r
WHERE r.name = 'Tacos' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'fromage rape');
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Laitue', 'laitue', 1, 'un', 1, 'fruits_vegetables' FROM recipes r
WHERE r.name = 'Tacos' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'laitue');

-- Omelette aux légumes
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Oeufs', 'oeufs', 6, 'un', 0, 'dairy' FROM recipes r
WHERE r.name = 'Omelette aux légumes' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'oeufs');
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Poivrons', 'poivrons', 2, 'un', 0, 'fruits_vegetables' FROM recipes r
WHERE r.name = 'Omelette aux légumes' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'poivrons');
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Oignons', 'oignons', 1, 'un', 0, 'fruits_vegetables' FROM recipes r
WHERE r.name = 'Omelette aux légumes' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'oignons');
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Fromage râpé', 'fromage rape', 0.1, 'kg', 1, 'dairy' FROM recipes r
WHERE r.name = 'Omelette aux légumes' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'fromage rape');

-- Poisson et pommes de terre
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Filet de poisson', 'filet de poisson', 0.8, 'kg', 0, 'seafood' FROM recipes r
WHERE r.name = 'Poisson et pommes de terre' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'filet de poisson');
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Pommes de terre', 'pommes de terre', 1, 'kg', 0, 'fruits_vegetables' FROM recipes r
WHERE r.name = 'Poisson et pommes de terre' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'pommes de terre');
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Citron', 'citron', 1, 'un', 1, 'fruits_vegetables' FROM recipes r
WHERE r.name = 'Poisson et pommes de terre' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'citron');

-- Chili con carne
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Boeuf haché', 'boeuf hache', 0.7, 'kg', 0, 'meat' FROM recipes r
WHERE r.name = 'Chili con carne' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'boeuf hache');
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Haricots rouges', 'haricots rouges', 2, 'un', 0, 'pantry' FROM recipes r
WHERE r.name = 'Chili con carne' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'haricots rouges');
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Tomates en dés', 'tomates en des', 2, 'un', 0, 'pantry' FROM recipes r
WHERE r.name = 'Chili con carne' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'tomates en des');
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Riz', 'riz', 0.5, 'kg', 0, 'pantry' FROM recipes r
WHERE r.name = 'Chili con carne' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'riz');

-- Sauté de légumes au riz
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Riz', 'riz', 0.5, 'kg', 0, 'pantry' FROM recipes r
WHERE r.name = 'Sauté de légumes au riz' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'riz');
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Brocoli', 'brocoli', 1, 'un', 0, 'fruits_vegetables' FROM recipes r
WHERE r.name = 'Sauté de légumes au riz' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'brocoli');
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Poivrons', 'poivrons', 2, 'un', 0, 'fruits_vegetables' FROM recipes r
WHERE r.name = 'Sauté de légumes au riz' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'poivrons');
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Sauce soya', 'sauce soya', 1, 'un', 1, 'pantry' FROM recipes r
WHERE r.name = 'Sauté de légumes au riz' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'sauce soya');

-- Salade César au poulet
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Poulet', 'poulet', 0.6, 'kg', 0, 'meat' FROM recipes r
WHERE r.name = 'Salade César au poulet' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'poulet');
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Laitue romaine', 'laitue romaine', 2, 'un', 0, 'fruits_vegetables' FROM recipes r
WHERE r.name = 'Salade César au poulet' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'laitue romaine');
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Croûtons', 'croutons', 1, 'un', 0, 'bakery' FROM recipes r
WHERE r.name = 'Salade César au poulet' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'croutons');
INSERT INTO recipe_ingredients (recipe_id, ingredient_name, normalized_name, quantity, unit, optional, category_kind)
SELECT r.id, 'Parmesan', 'parmesan', 1, 'un', 0, 'dairy' FROM recipes r
WHERE r.name = 'Salade César au poulet' AND r.user_id IS NULL
AND NOT EXISTS (SELECT 1 FROM recipe_ingredients i WHERE i.recipe_id = r.id AND i.normalized_name = 'parmesan');

-- Vérification -----------------------------------------------------------
SELECT 'verification' AS v,
 (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name IN
  ('home_inventory','product_prediction_prefs','recipes','recipe_ingredients','meal_plans','meal_plan_recipes','recurring_lists','recurring_list_items')) AS tables_count,
 (SELECT COUNT(*) FROM recipes WHERE user_id IS NULL) AS base_recipes,
 (SELECT COUNT(*) FROM recipe_ingredients) AS ingredients;
