-- ============================================================================
-- ANALYSE DU 23 OCTOBRE — ce que les onze points demandent et que la
-- base ne portait pas. 2026-10-23. Idempotente (rejouable sans erreur).
-- ============================================================================
--
-- Sept manques, releves point par point :
--
--   1. A la maison      — « Alerte rupture : il n'y en a plus a la
--                         maison » s'affichait a cote de « Quantite
--                         restante : 2, pour un seuil de 1 ». L'etat
--                         etait SAISI a la main, a cote d'une quantite
--                         qui disait le contraire. Il se CALCULE
--                         maintenant depuis la quantite ; la colonne
--                         status garde le choix manuel des produits
--                         sans quantite.
--   2. A la maison      — « peremption 2 a 3 jours avant la date » :
--                         aucune date de peremption nulle part.
--   3. A la maison      — « Plein / Moitie / Presque vide » pour le
--                         liquide vaisselle, qui ne se compte pas.
--   4. Liste de la semaine — « un choix Exact ou Approximatif. Le prix
--                         approximatif s'affiche avec le signe ≈ » :
--                         `list_items.price` ne disait pas d'ou il
--                         venait.
--   5. Budget           — « aux deux semaines (cycle de paie) » :
--                         l'enum des periodes ne connaissait que
--                         semaine, mois, annee et personnalise.
--                         Beaucoup de menages budgetent selon leur
--                         paie, pas selon le calendrier.
--   6. Budget           — « le budget se renouvelle-t-il
--                         automatiquement a la fin de la periode ? » :
--                         la question se pose a l'utilisatrice, et sa
--                         reponse se garde.
--   7. Alertes de prix  — « un resume hebdomadaire plutot qu'une
--                         alerte par produit ».
--
-- Prerequis : 012_planche_version_b.sql, add_household_intelligence.sql,
-- add_price_intelligence.sql, add_push_preferences.sql.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1) home_inventory : la date de peremption
-- ----------------------------------------------------------------------------
-- Facultative, et elle le reste : la plupart des provisions n'en ont
-- pas d'utile. Quand elle est la, l'alerte « A terminer dans 2 jours »
-- se calcule a la lecture — aucun etat a maintenir.

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'home_inventory' AND COLUMN_NAME = 'expires_at');
SET @sql := IF(@c = 0,
    'ALTER TABLE home_inventory ADD COLUMN expires_at DATE NULL COMMENT ''peremption, facultative'' AFTER unit',
    'SELECT "home_inventory.expires_at deja presente"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- L'index sert la requete « qu'est-ce qui perime cette semaine ? », qui
-- traverse l'inventaire d'un espace a chaque ouverture de l'ecran.
SET @c := (SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'home_inventory' AND INDEX_NAME = 'idx_inventory_peremption');
SET @sql := IF(@c = 0,
    'CREATE INDEX idx_inventory_peremption ON home_inventory(expires_at)',
    'SELECT "index peremption deja present"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ----------------------------------------------------------------------------
-- 2) home_inventory : le niveau, pour ce qui ne se compte pas
-- ----------------------------------------------------------------------------
-- « La saisie de chaque quantite est longue au depart. » Un liquide
-- vaisselle n'a pas de quantite juste : il est plein, a moitie, ou
-- presque vide. Trois valeurs, VARCHAR et non ENUM, pour la meme raison
-- que `status` : une quatrieme valeur ne doit pas demander de migration.
--
-- `level` et `quantity` ne se contredisent pas : l'un OU l'autre. Quand
-- la quantite est la, c'est elle qui parle.

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'home_inventory' AND COLUMN_NAME = 'level');
SET @sql := IF(@c = 0,
    'ALTER TABLE home_inventory ADD COLUMN level VARCHAR(12) NULL COMMENT ''full | half | low, pour les produits sans quantite'' AFTER expires_at',
    'SELECT "home_inventory.level deja presente"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ----------------------------------------------------------------------------
-- 3) list_items : le prix est-il exact ou approximatif ?
-- ----------------------------------------------------------------------------
-- « Terminer mes courses » laissait le budget inchange parce qu'aucun
-- prix n'etait saisi. Exiger un prix ne suffit pas : un prix de tete
-- (« a peu pres 8 $ ») et un prix lu sur l'etiquette ne valent pas la
-- meme chose. Le total s'affiche alors avec ≈, et l'historique de prix
-- n'apprend QUE des prix exacts.

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'list_items' AND COLUMN_NAME = 'price_is_estimate');
SET @sql := IF(@c = 0,
    'ALTER TABLE list_items ADD COLUMN price_is_estimate TINYINT(1) NOT NULL DEFAULT 0 COMMENT ''1 = prix approximatif, affiche avec ~'' AFTER price',
    'SELECT "list_items.price_is_estimate deja presente"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ----------------------------------------------------------------------------
-- 4) budgets : la periode de paie
-- ----------------------------------------------------------------------------
-- MODIFY et non ADD : l'enum existe, il lui manque une valeur. Rejouer
-- la migration repasse le meme MODIFY, sans effet.
--
-- La verification porte sur le TYPE, pas sur la presence de la colonne :
-- une colonne presente mais sans 'biweekly' doit etre modifiee.

SET @t := (SELECT COLUMN_TYPE FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'budgets' AND COLUMN_NAME = 'period_type');
SET @sql := IF(@t IS NOT NULL AND LOCATE('biweekly', @t) = 0,
    'ALTER TABLE budgets MODIFY COLUMN period_type ENUM(''weekly'',''biweekly'',''monthly'',''yearly'',''custom'') NOT NULL DEFAULT ''monthly''',
    'SELECT "budgets.period_type connait deja biweekly"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ----------------------------------------------------------------------------
-- 5) budgets : se renouvelle-t-il tout seul ?
-- ----------------------------------------------------------------------------
-- La question etait ouverte dans l'analyse. Elle se tranche a
-- l'utilisatrice, budget par budget, et non par un choix de conception
-- impose a tous : un budget d'epicerie du mois se renouvelle, un budget
-- « reception de Noel » non.
--
-- Defaut 0 : les budgets existants gardent exactement le comportement
-- qu'ils ont aujourd'hui.

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'budgets' AND COLUMN_NAME = 'auto_renew');
SET @sql := IF(@c = 0,
    'ALTER TABLE budgets ADD COLUMN auto_renew TINYINT(1) NOT NULL DEFAULT 0 COMMENT ''1 = recree la periode suivante a l''''echeance'' AFTER is_active',
    'SELECT "budgets.auto_renew deja presente"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Le renouvellement doit savoir ce qu'il a deja fait : sans cela, deux
-- passages du cron le meme jour creeraient deux periodes.
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'budgets' AND COLUMN_NAME = 'renewed_at');
SET @sql := IF(@c = 0,
    'ALTER TABLE budgets ADD COLUMN renewed_at TIMESTAMP NULL DEFAULT NULL COMMENT ''date du renouvellement qui a succede a ce budget'' AFTER auto_renew',
    'SELECT "budgets.renewed_at deja presente"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ----------------------------------------------------------------------------
-- 6) email_preferences : le resume hebdomadaire des baisses de prix
-- ----------------------------------------------------------------------------
-- « sur demande seulement, avec un resume hebdomadaire plutot qu'une
-- alerte par produit ». Defaut 0 : qui a aujourd'hui une notification
-- par produit la garde, et choisit le resume s'il le veut.
--
-- Aucune table de file d'attente : le resume relit
-- price_alerts.last_triggered_at des sept derniers jours. Le
-- declenchement est deja enregistre la.

SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'email_preferences' AND COLUMN_NAME = 'price_alert_digest');
SET @sql := IF(@c = 0,
    'ALTER TABLE email_preferences ADD COLUMN price_alert_digest TINYINT(1) NOT NULL DEFAULT 0 COMMENT ''1 = un resume par semaine au lieu d''''une notification par produit'' AFTER push_price_alert',
    'SELECT "email_preferences.price_alert_digest deja presente"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ----------------------------------------------------------------------------
-- 7) recipes : le repas ecrit a la main
-- ----------------------------------------------------------------------------
-- « Ecrire mon repas : nom, nombre de personnes, ingredients
-- facultatifs. » La table porte deja user_id (NULL = recette livree
-- avec l'application) : rien a ajouter pour la propriete.
--
-- Il manque l'index qui tient la recherche « par nom ou par
-- ingredient » : sans lui, chaque frappe dans le champ de recherche
-- traverse toute la table.

SET @c := (SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'recipes' AND INDEX_NAME = 'idx_recipes_nom');
SET @sql := IF(@c = 0,
    'CREATE INDEX idx_recipes_nom ON recipes(name)',
    'SELECT "index nom de recette deja present"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c := (SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'recipe_ingredients' AND INDEX_NAME = 'idx_ingredients_nom');
SET @sql := IF(@c = 0,
    'CREATE INDEX idx_ingredients_nom ON recipe_ingredients(normalized_name)',
    'SELECT "index nom d ingredient deja present"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ----------------------------------------------------------------------------
-- 8) Remise en coherence des etats d'inventaire deja enregistres
-- ----------------------------------------------------------------------------
-- La capture montrait « Alerte rupture : il n'y en a plus a la maison »
-- sur un produit dont la quantite etait 2, pour un seuil de 1. L'etat
-- etait saisi a la main, la quantite aussi, et rien ne les reliait.
--
-- Desormais la quantite decide. Les lignes deja en base gardent leur
-- incoherence si on ne les touche pas : ces deux UPDATE la corrigent
-- une fois, et seulement la ou une quantite existe.
--
-- Rupture : seulement a zero.
UPDATE home_inventory
   SET status = 'at_home'
 WHERE status = 'out'
   AND quantity IS NOT NULL
   AND quantity > 0
   AND (min_quantity IS NULL OR quantity > min_quantity);

UPDATE home_inventory
   SET status = 'running_low'
 WHERE status = 'out'
   AND quantity IS NOT NULL
   AND quantity > 0
   AND min_quantity IS NOT NULL
   AND quantity <= min_quantity;

-- Au-dessus du seuil : ce n'est pas un stock bas.
UPDATE home_inventory
   SET status = 'at_home'
 WHERE status = 'running_low'
   AND quantity IS NOT NULL
   AND min_quantity IS NOT NULL
   AND quantity > min_quantity;

-- A zero : c'est une rupture, quoi qu'en dise l'etat saisi.
UPDATE home_inventory
   SET status = 'out'
 WHERE status <> 'out'
   AND quantity IS NOT NULL
   AND quantity <= 0;

-- ============================================================================
-- FIN. Verification : 013_verification.sql
-- ============================================================================
