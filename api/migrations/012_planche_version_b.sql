-- ============================================================================
-- PLANCHE « VERSION B » — ce que l'interface demande et que la base ne
-- portait pas. 2026-10-22. Idempotente (rejouable sans erreur).
-- ============================================================================
--
-- Cinq manques, releves ecran par ecran en appliquant la planche, et
-- signales jusqu'ici comme « NON FAIT, FAUTE DE DONNEES » :
--
--   1. Mes magasins     — la planche montre l'adresse et les horaires ;
--                         `stores` n'avait que son nom et son slug.
--   2. Mes magasins     — l'etoile « Favori » vivait dans les
--                         preferences de l'APPAREIL, donc perdue au
--                         changement de telephone et invisible pour les
--                         autres membres de l'espace.
--   3. Planifier mes repas — « Lundi vert, Mardi jaune, Mercredi bleu » :
--                         aucun lien entre un plat et un jour.
--   4. Recettes favorites  — la grille de la planche n'avait rien a
--                         trier. Le favori est porte par le MEMBRE :
--                         les recettes livrees sont partagees.
--   5. Alertes de prix  — « vrais visuels produits en grand » : aucune
--                         image joignable a un produit.
--
-- Le cinquieme ne se resout PAS par une colonne sur price_alerts. Une
-- photo appartient au PRODUIT, pas a l'alerte : prise une fois sur un
-- article de liste, elle doit servir l'alerte, la suggestion et
-- l'historique. D'ou une table partagee, product_images.
--
-- Prerequis : add_stores_and_aisle_order.sql, add_household_intelligence.sql,
-- add_spaces.sql ... add_spaces_phase6.sql.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1) stores : ou il est, quand il ouvre, et s'il compte
-- ----------------------------------------------------------------------------
-- La distance ne se stocke pas : elle se CALCULE entre la position du
-- telephone et ces coordonnees. Les enregistrer en base figerait une
-- distance depuis un point qui n'a pas de sens.
--
-- opening_hours est un JSON par jour, heures locales au magasin :
--   {"mon":["08:00","21:00"], "sat":["09:00","20:00"], "sun":null}
-- `null` ou jour absent = ferme. Un tableau de deux heures = une plage.
-- Ce format tient les jours feries en le completant plus tard, sans
-- nouvelle migration.

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'stores' AND COLUMN_NAME = 'address');
SET @sql := IF(@c = 0,
    'ALTER TABLE stores ADD COLUMN address VARCHAR(255) NULL AFTER slug',
    'SELECT "stores.address deja presente"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'stores' AND COLUMN_NAME = 'city');
SET @sql := IF(@c = 0,
    'ALTER TABLE stores ADD COLUMN city VARCHAR(120) NULL AFTER address',
    'SELECT "stores.city deja presente"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'stores' AND COLUMN_NAME = 'postal_code');
SET @sql := IF(@c = 0,
    'ALTER TABLE stores ADD COLUMN postal_code VARCHAR(20) NULL AFTER city',
    'SELECT "stores.postal_code deja presente"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'stores' AND COLUMN_NAME = 'latitude');
SET @sql := IF(@c = 0,
    'ALTER TABLE stores ADD COLUMN latitude DECIMAL(10,7) NULL AFTER postal_code',
    'SELECT "stores.latitude deja presente"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'stores' AND COLUMN_NAME = 'longitude');
SET @sql := IF(@c = 0,
    'ALTER TABLE stores ADD COLUMN longitude DECIMAL(10,7) NULL AFTER latitude',
    'SELECT "stores.longitude deja presente"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'stores' AND COLUMN_NAME = 'opening_hours');
SET @sql := IF(@c = 0,
    'ALTER TABLE stores ADD COLUMN opening_hours JSON NULL COMMENT ''{"mon":["08:00","21:00"],"sun":null}'' AFTER longitude',
    'SELECT "stores.opening_hours deja presente"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Le favori est porte par le MEMBRE, pas par le magasin : dans un espace
-- partage, le magasin de quartier de l'un n'est pas celui de l'autre.
CREATE TABLE IF NOT EXISTS store_favorites (
    id INT NOT NULL AUTO_INCREMENT,
    store_id INT NOT NULL,
    user_id INT NOT NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_store_favorite (store_id, user_id),
    KEY idx_store_fav_user (user_id),
    CONSTRAINT fk_store_fav_store FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE,
    CONSTRAINT fk_store_fav_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 2) recipe_favorites : la grille de recettes favorites de la planche
-- ----------------------------------------------------------------------------
-- UNE FAUSSE ROUTE, corrigee avant d'etre poussee : une colonne
-- `recipes.is_favorite` avait d'abord ete posee. Elle etait fausse par
-- construction — les huit recettes livrees avec l'application ont
-- `user_id IS NULL`, donc elles sont PARTAGEES : un favori pose par une
-- personne aurait valu pour tout le monde. Comme pour les magasins, le
-- favori appartient au MEMBRE.
--
-- La colonne est retiree ici si elle traine (elle n'a jamais porte la
-- moindre valeur a 1).
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'recipes' AND COLUMN_NAME = 'is_favorite');
SET @sql := IF(@c = 1,
    'ALTER TABLE recipes DROP COLUMN is_favorite',
    'SELECT "recipes.is_favorite deja absente"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'recipes' AND INDEX_NAME = 'idx_recipes_favorite');
SET @sql := IF(@c > 0,
    'DROP INDEX idx_recipes_favorite ON recipes',
    'SELECT "index favori deja absent"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

CREATE TABLE IF NOT EXISTS recipe_favorites (
    id INT NOT NULL AUTO_INCREMENT,
    recipe_id INT NOT NULL,
    user_id INT NOT NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_recipe_favorite (recipe_id, user_id),
    KEY idx_recipe_fav_user (user_id),
    CONSTRAINT fk_recipe_fav_recipe FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE,
    CONSTRAINT fk_recipe_fav_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 3) meal_plan_recipes : le plat trouve son jour
-- ----------------------------------------------------------------------------
-- weekday suit la convention deja posee par recurring_lists.weekday :
-- 1 = lundi ... 7 = dimanche. NULL = plat du plan, sans jour assigne.
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'meal_plan_recipes' AND COLUMN_NAME = 'weekday');
SET @sql := IF(@c = 0,
    'ALTER TABLE meal_plan_recipes ADD COLUMN weekday TINYINT NULL COMMENT ''1=lundi ... 7=dimanche, NULL=non assigne'' AFTER servings',
    'SELECT "meal_plan_recipes.weekday deja presente"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Midi ou soir : la planche ne montre qu'un plat par jour, mais deux
-- repas par jour est la suite evidente, et l'ajouter maintenant coute
-- une colonne nulle plutot qu'une migration de plus.
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'meal_plan_recipes' AND COLUMN_NAME = 'meal_slot');
SET @sql := IF(@c = 0,
    'ALTER TABLE meal_plan_recipes ADD COLUMN meal_slot VARCHAR(10) NULL COMMENT ''lunch | dinner | NULL'' AFTER weekday',
    'SELECT "meal_plan_recipes.meal_slot deja presente"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'meal_plan_recipes' AND INDEX_NAME = 'idx_mpr_jour');
SET @sql := IF(@c = 0,
    'CREATE INDEX idx_mpr_jour ON meal_plan_recipes(meal_plan_id, weekday)',
    'SELECT "index jour deja present"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ----------------------------------------------------------------------------
-- 4) product_images : la photo appartient au produit, pas a l'ecran
-- ----------------------------------------------------------------------------
-- `list_items.image_url` existait deja, mais rattachee a UN article
-- d'UNE liste : la meme boite de pates photographiee la semaine
-- derniere ne pouvait pas illustrer l'alerte de prix d'aujourd'hui.
--
-- Clef : (space_id, normalized_name). L'espace, car une photo prise par
-- un membre sert tout le foyer ; le nom normalise, car c'est la clef
-- que tout le reste du projet utilise deja (purchase_history,
-- product_aliases, community_prices).
--
-- La normalisation est faite en PHP (ListItem::normalizeProductName) et
-- JAMAIS en SQL : deux implementations des memes regles finiraient par
-- diverger. Le remplissage depuis les articles existants est donc confie
-- a scripts/seed_product_images.php, pas a cette migration.
CREATE TABLE IF NOT EXISTS product_images (
    id INT NOT NULL AUTO_INCREMENT,
    space_id INT NULL,
    normalized_name VARCHAR(255) NOT NULL,
    product_label VARCHAR(255) NOT NULL COMMENT 'Le nom tel qu''il a ete saisi, pour l''affichage',
    image_url VARCHAR(500) NOT NULL,
    source VARCHAR(20) NOT NULL DEFAULT 'user' COMMENT 'user | barcode | receipt',
    created_by_user_id INT NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_product_image (space_id, normalized_name),
    KEY idx_product_image_name (normalized_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ----------------------------------------------------------------------------
-- 5) space_invitations : le nom, et le telephone
-- ----------------------------------------------------------------------------
-- La planche decrit le panneau « Ajouter un membre de la famille » :
-- nom, courriel OU telephone, role, confirmation ecrite.
--
-- Le nom sert tout de suite : il personnalise le courriel d'invitation
-- (« Bonjour Sara »), et la liste des invitations en attente cesse
-- d'etre une colonne d'adresses.
--
-- Le telephone est ENREGISTRE, mais rien ne l'envoie : l'application n'a
-- aucun fournisseur SMS, et en ajouter un est une decision de produit
-- avec un cout recurrent, pas une migration. La colonne existe pour que
-- l'invitant garde le moyen de relancer la personne lui-meme ; l'envoi
-- reste par courriel.
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'space_invitations' AND COLUMN_NAME = 'invitee_name');
SET @sql := IF(@c = 0,
    'ALTER TABLE space_invitations ADD COLUMN invitee_name VARCHAR(120) NULL AFTER email',
    'SELECT "space_invitations.invitee_name deja presente"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'space_invitations' AND COLUMN_NAME = 'invitee_phone');
SET @sql := IF(@c = 0,
    'ALTER TABLE space_invitations ADD COLUMN invitee_phone VARCHAR(40) NULL COMMENT ''Enregistre, jamais envoye : aucun fournisseur SMS'' AFTER invitee_name',
    'SELECT "space_invitations.invitee_phone deja presente"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ----------------------------------------------------------------------------
-- Verification
-- ----------------------------------------------------------------------------
SELECT
    (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'stores'
        AND COLUMN_NAME IN ('address','city','postal_code','latitude','longitude','opening_hours')) AS magasin_6_colonnes,
    (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'store_favorites') AS table_favoris,
    (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'recipe_favorites') AS table_recettes_favorites,
    (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'recipes' AND COLUMN_NAME = 'is_favorite') AS colonne_fausse_route_restante,
    (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'meal_plan_recipes' AND COLUMN_NAME IN ('weekday','meal_slot')) AS repas_2_colonnes,
    (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'product_images') AS table_images,
    (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'space_invitations' AND COLUMN_NAME IN ('invitee_name','invitee_phone')) AS invitation_2_colonnes;
