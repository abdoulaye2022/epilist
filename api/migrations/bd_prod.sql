-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: orzhcorepilist.mysql.db
-- Generation Time: Nov 07, 2025 at 03:41 AM
-- Server version: 8.4.6-6
-- PHP Version: 8.1.33

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `orzhcorepilist`
--

-- --------------------------------------------------------

--
-- Table structure for table `budgets`
--

CREATE TABLE `budgets` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `list_id` int DEFAULT NULL,
  `name` varchar(255) NOT NULL,
  `budget_amount` decimal(10,2) NOT NULL,
  `period_type` enum('weekly','monthly','yearly','custom') NOT NULL DEFAULT 'monthly',
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `alert_threshold` tinyint UNSIGNED NOT NULL DEFAULT '80',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `icon_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'category',
  `color_hex` varchar(7) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '#4CAF50',
  `order_index` int NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `currencies`
--

CREATE TABLE `currencies` (
  `id` int NOT NULL,
  `code` varchar(3) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Code ISO 4217 (USD, CAD, EUR)',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Nom complet de la devise',
  `symbol` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Symbole de la devise ($, €, £)',
  `is_active` tinyint(1) DEFAULT '1' COMMENT 'Si la devise est disponible',
  `is_popular` tinyint(1) DEFAULT '0' COMMENT 'Si la devise est populaire',
  `display_order` int DEFAULT '999' COMMENT 'Ordre d''affichage',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `email_preferences`
--

CREATE TABLE `email_preferences` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `email_verification` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Email de vérification de compte',
  `password_change_request` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Email de demande de changement de mot de passe',
  `password_changed` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Email de confirmation de changement de mot de passe',
  `list_shared_with_me` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Notif quand une liste est partagée avec moi',
  `list_item_added` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Notif quand un article est ajouté à une liste partagée',
  `list_item_checked` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Notif quand un article est coché dans une liste partagée',
  `list_completed` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Notif quand une liste partagée est complétée',
  `budget_alert` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Alertes quand le budget est dépassé',
  `budget_summary` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Résumé mensuel du budget',
  `marketing_emails` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Emails marketing et promotions',
  `product_updates` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Nouvelles fonctionnalités et mises à jour',
  `tips_and_tricks` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Conseils et astuces d''utilisation',
  `notification_frequency` enum('realtime','daily','weekly') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'realtime' COMMENT 'Fréquence des notifications',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `list_items`
--

CREATE TABLE `list_items` (
  `id` int NOT NULL,
  `list_id` int NOT NULL,
  `product_name` text NOT NULL,
  `quantity` int DEFAULT '1',
  `price` double DEFAULT NULL,
  `store_name` text,
  `is_purchased` tinyint(1) DEFAULT '0',
  `purchased_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `list_messages`
--

CREATE TABLE `list_messages` (
  `id` int NOT NULL,
  `list_id` int NOT NULL COMMENT 'ID de la liste de courses',
  `user_id` int NOT NULL COMMENT 'ID de l''utilisateur qui envoie le message',
  `message` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Contenu du message',
  `message_type` enum('text','image','system') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'text' COMMENT 'Type de message',
  `image_url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'URL de l''image si message_type = image',
  `is_read` tinyint(1) DEFAULT '0' COMMENT 'Message lu par tous les membres',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL COMMENT 'Soft delete'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Messages de chat pour les listes partagées';

-- --------------------------------------------------------

--
-- Table structure for table `list_receipts`
--

CREATE TABLE `list_receipts` (
  `id` int NOT NULL,
  `list_id` int NOT NULL,
  `store_name` varchar(255) NOT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `notes` text,
  `purchase_date` date NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `message_read_status`
--

CREATE TABLE `message_read_status` (
  `id` int NOT NULL,
  `message_id` int NOT NULL COMMENT 'ID du message',
  `user_id` int NOT NULL COMMENT 'ID de l''utilisateur qui a lu',
  `read_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Statut de lecture des messages';

-- --------------------------------------------------------

--
-- Table structure for table `product_associations`
--

CREATE TABLE `product_associations` (
  `id` int NOT NULL,
  `product_a` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Nom du produit A',
  `product_b` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Nom du produit B',
  `confidence` decimal(5,4) NOT NULL COMMENT 'Score de confiance (0-1)',
  `support_count` int DEFAULT '0' COMMENT 'Nombre de co-occurrences',
  `last_updated` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Associations de produits pour suggestions';

-- --------------------------------------------------------

--
-- Table structure for table `product_suggestions`
--

CREATE TABLE `product_suggestions` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `product_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `normalized_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `price` decimal(10,2) DEFAULT NULL,
  `store_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `usage_count` int DEFAULT '1',
  `last_used_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `purchase_history`
--

CREATE TABLE `purchase_history` (
  `id` int NOT NULL,
  `user_id` int NOT NULL COMMENT 'ID de l''utilisateur',
  `product_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Nom du produit acheté',
  `normalized_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Nom normalisé pour regroupement',
  `category_id` int DEFAULT NULL COMMENT 'Catégorie du produit',
  `quantity` int DEFAULT '1' COMMENT 'Quantité achetée',
  `price` decimal(10,2) DEFAULT NULL COMMENT 'Prix payé',
  `store_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Magasin d''achat',
  `barcode` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Code-barres si disponible',
  `purchased_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Date d''achat',
  `list_id` int DEFAULT NULL COMMENT 'Liste d''origine',
  `day_of_week` tinyint DEFAULT NULL COMMENT '1-7 (Lundi-Dimanche)',
  `month` tinyint DEFAULT NULL COMMENT '1-12',
  `season` enum('spring','summer','fall','winter') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Saison d''achat',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Historique des achats pour suggestions intelligentes';

-- --------------------------------------------------------

--
-- Table structure for table `scanned_products`
--

CREATE TABLE `scanned_products` (
  `id` int NOT NULL,
  `barcode` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `product_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `brand` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `quantity` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `image_url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nutriments` json DEFAULT NULL,
  `source` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'openfoodfacts',
  `last_scanned_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `shared_list`
--

CREATE TABLE `shared_list` (
  `id` int NOT NULL,
  `list_id` int NOT NULL,
  `owner_id` int NOT NULL,
  `shared_with_user_id` int DEFAULT NULL,
  `permission` enum('readOnly','edit','admin') NOT NULL,
  `shared_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `is_active` tinyint(1) DEFAULT '1',
  `share_token` varchar(64) DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL,
  `expires_at` datetime DEFAULT NULL,
  `accepted_at` datetime DEFAULT NULL,
  `declined_at` datetime DEFAULT NULL,
  `revoked_at` datetime DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `shopping_lists`
--

CREATE TABLE `shopping_lists` (
  `id` int NOT NULL,
  `user_id` int DEFAULT NULL,
  `name` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `suggestion_feedback`
--

CREATE TABLE `suggestion_feedback` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `product_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `action` enum('accepted','rejected','modified') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `suggested_quantity` int DEFAULT NULL,
  `actual_quantity` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Feedback sur les suggestions pour amélioration';

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int NOT NULL,
  `first_name` varchar(50) NOT NULL,
  `last_name` varchar(50) NOT NULL,
  `email` varchar(150) NOT NULL,
  `password_hash` text CHARACTER SET latin1 COLLATE latin1_swedish_ci,
  `terms_accepted` tinyint(1) DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `password_change_code` varchar(6) DEFAULT NULL,
  `password_change_code_expires_at` datetime DEFAULT NULL,
  `account_deletion_code` varchar(6) DEFAULT NULL,
  `account_deletion_code_expires_at` datetime DEFAULT NULL,
  `deletion_reason` varchar(255) DEFAULT NULL,
  `is_deletion_requested` tinyint(1) NOT NULL DEFAULT '0',
  `deletion_requested_at` datetime DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `email_verification_code` varchar(255) DEFAULT NULL,
  `email_verification_code_expires_at` datetime DEFAULT NULL,
  `email_verified_at` datetime DEFAULT NULL,
  `email_verified` tinyint(1) DEFAULT '0',
  `currency_id` int DEFAULT '1',
  `email_marketing_consent` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Consentement pour recevoir les emails marketing et campagnes',
  `email_marketing_unsubscribed_at` timestamp NULL DEFAULT NULL COMMENT 'Date de désabonnement des emails marketing',
  `unsubscribe_token` varchar(64) DEFAULT NULL COMMENT 'Token unique pour le lien de désabonnement'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `user_devices`
--

CREATE TABLE `user_devices` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `device_id` varchar(255) NOT NULL,
  `platform` enum('android','ios') NOT NULL,
  `push_token` varchar(512) NOT NULL,
  `app_version` varchar(50) DEFAULT NULL,
  `os_version` varchar(50) DEFAULT NULL,
  `device_model` varchar(100) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `last_active_at` timestamp NULL DEFAULT NULL,
  `notification_preferences` json DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_purchase_patterns`
--

CREATE TABLE `user_purchase_patterns` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `product_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `total_purchases` int DEFAULT '0',
  `avg_quantity` decimal(5,2) DEFAULT '1.00',
  `avg_price` decimal(10,2) DEFAULT NULL,
  `avg_days_between` int DEFAULT NULL COMMENT 'Jours entre achats',
  `last_purchased_at` timestamp NULL DEFAULT NULL,
  `next_suggested_date` date DEFAULT NULL COMMENT 'Prochaine date suggérée',
  `preferred_store` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `preferred_category_id` int DEFAULT NULL,
  `frequency_score` decimal(5,2) DEFAULT '0.00' COMMENT 'Score de fréquence (0-100)',
  `recency_score` decimal(5,2) DEFAULT '0.00' COMMENT 'Score de récence (0-100)',
  `regularity_score` decimal(5,2) DEFAULT '0.00' COMMENT 'Score de régularité (0-100)',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Patterns d''achat personnalisés par utilisateur';

-- --------------------------------------------------------

--
-- Table structure for table `user_sso_links`
--

CREATE TABLE `user_sso_links` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `provider` enum('google','apple') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `sso_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'ID unique du provider (sub pour Google/Apple)',
  `user_info` json DEFAULT NULL COMMENT 'Informations utilisateur du provider',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `last_login_at` timestamp NULL DEFAULT NULL COMMENT 'Dernière connexion via ce provider'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `budgets`
--
ALTER TABLE `budgets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_list_id` (`list_id`),
  ADD KEY `idx_start_date` (`start_date`),
  ADD KEY `idx_is_active` (`is_active`);

--
-- Indexes for table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_deleted_at` (`deleted_at`),
  ADD KEY `idx_order_index` (`order_index`);

--
-- Indexes for table `currencies`
--
ALTER TABLE `currencies`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`),
  ADD KEY `idx_code` (`code`),
  ADD KEY `idx_active` (`is_active`),
  ADD KEY `idx_popular` (`is_popular`),
  ADD KEY `idx_display_order` (`display_order`);

--
-- Indexes for table `email_preferences`
--
ALTER TABLE `email_preferences`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_user_preferences` (`user_id`),
  ADD KEY `idx_notification_frequency` (`notification_frequency`),
  ADD KEY `idx_marketing_emails` (`marketing_emails`);

--
-- Indexes for table `list_items`
--
ALTER TABLE `list_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `list_id` (`list_id`),
  ADD KEY `idx_purchased_at` (`purchased_at`),
  ADD KEY `idx_list_purchased` (`list_id`,`is_purchased`,`purchased_at`);

--
-- Indexes for table `list_messages`
--
ALTER TABLE `list_messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_list_id` (`list_id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_created_at` (`created_at`),
  ADD KEY `idx_list_created` (`list_id`,`created_at`);

--
-- Indexes for table `list_receipts`
--
ALTER TABLE `list_receipts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_list_id` (`list_id`),
  ADD KEY `idx_store_name` (`store_name`);

--
-- Indexes for table `message_read_status`
--
ALTER TABLE `message_read_status`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_message_user` (`message_id`,`user_id`),
  ADD KEY `idx_message_id` (`message_id`),
  ADD KEY `idx_user_id` (`user_id`);

--
-- Indexes for table `product_associations`
--
ALTER TABLE `product_associations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_association` (`product_a`,`product_b`),
  ADD KEY `idx_product_a` (`product_a`),
  ADD KEY `idx_confidence` (`confidence` DESC);

--
-- Indexes for table `product_suggestions`
--
ALTER TABLE `product_suggestions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_user_product` (`user_id`,`normalized_name`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_normalized_name` (`normalized_name`),
  ADD KEY `idx_user_normalized` (`user_id`,`normalized_name`),
  ADD KEY `idx_usage_count` (`usage_count`),
  ADD KEY `idx_last_used` (`last_used_at`);

--
-- Indexes for table `purchase_history`
--
ALTER TABLE `purchase_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_product_name` (`normalized_name`),
  ADD KEY `idx_category` (`category_id`),
  ADD KEY `idx_purchased_at` (`purchased_at`),
  ADD KEY `idx_user_product` (`user_id`,`normalized_name`),
  ADD KEY `idx_user_date` (`user_id`,`purchased_at`),
  ADD KEY `idx_barcode` (`barcode`),
  ADD KEY `list_id` (`list_id`),
  ADD KEY `idx_purchase_user_product_date` (`user_id`,`normalized_name`,`purchased_at` DESC);

--
-- Indexes for table `scanned_products`
--
ALTER TABLE `scanned_products`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_barcode` (`barcode`),
  ADD KEY `idx_last_scanned` (`last_scanned_at`);

--
-- Indexes for table `shared_list`
--
ALTER TABLE `shared_list`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `share_token` (`share_token`),
  ADD KEY `shared_list_ibfk_1` (`owner_id`),
  ADD KEY `shared_list_ibfk_2` (`shared_with_user_id`),
  ADD KEY `shared_list_ibfk_3` (`list_id`);

--
-- Indexes for table `shopping_lists`
--
ALTER TABLE `shopping_lists`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `suggestion_feedback`
--
ALTER TABLE `suggestion_feedback`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_action` (`action`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `unsubscribe_token` (`unsubscribe_token`),
  ADD KEY `idx_active_deletion_requested` (`is_active`,`is_deletion_requested`),
  ADD KEY `currency_id` (`currency_id`);

--
-- Indexes for table `user_devices`
--
ALTER TABLE `user_devices`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_user_device` (`user_id`,`device_id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_device_id` (`device_id`),
  ADD KEY `idx_platform` (`platform`),
  ADD KEY `idx_is_active` (`is_active`),
  ADD KEY `idx_last_active` (`last_active_at`);

--
-- Indexes for table `user_purchase_patterns`
--
ALTER TABLE `user_purchase_patterns`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_user_product` (`user_id`,`product_name`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_next_suggested` (`next_suggested_date`),
  ADD KEY `idx_scores` (`frequency_score` DESC,`recency_score` DESC),
  ADD KEY `preferred_category_id` (`preferred_category_id`);

--
-- Indexes for table `user_sso_links`
--
ALTER TABLE `user_sso_links`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_provider_sso_id` (`provider`,`sso_id`),
  ADD UNIQUE KEY `unique_user_provider` (`user_id`,`provider`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_provider` (`provider`),
  ADD KEY `idx_sso_id` (`sso_id`),
  ADD KEY `idx_last_login` (`last_login_at`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `budgets`
--
ALTER TABLE `budgets`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `categories`
--
ALTER TABLE `categories`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `currencies`
--
ALTER TABLE `currencies`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `email_preferences`
--
ALTER TABLE `email_preferences`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `list_items`
--
ALTER TABLE `list_items`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `list_messages`
--
ALTER TABLE `list_messages`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `list_receipts`
--
ALTER TABLE `list_receipts`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `message_read_status`
--
ALTER TABLE `message_read_status`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `product_associations`
--
ALTER TABLE `product_associations`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `product_suggestions`
--
ALTER TABLE `product_suggestions`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `purchase_history`
--
ALTER TABLE `purchase_history`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `scanned_products`
--
ALTER TABLE `scanned_products`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `shared_list`
--
ALTER TABLE `shared_list`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `shopping_lists`
--
ALTER TABLE `shopping_lists`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `suggestion_feedback`
--
ALTER TABLE `suggestion_feedback`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_devices`
--
ALTER TABLE `user_devices`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_purchase_patterns`
--
ALTER TABLE `user_purchase_patterns`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_sso_links`
--
ALTER TABLE `user_sso_links`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `budgets`
--
ALTER TABLE `budgets`
  ADD CONSTRAINT `budgets_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `budgets_ibfk_2` FOREIGN KEY (`list_id`) REFERENCES `shopping_lists` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `categories`
--
ALTER TABLE `categories`
  ADD CONSTRAINT `categories_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `email_preferences`
--
ALTER TABLE `email_preferences`
  ADD CONSTRAINT `fk_email_prefs_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `list_items`
--
ALTER TABLE `list_items`
  ADD CONSTRAINT `list_items_ibfk_1` FOREIGN KEY (`list_id`) REFERENCES `shopping_lists` (`id`);

--
-- Constraints for table `list_messages`
--
ALTER TABLE `list_messages`
  ADD CONSTRAINT `list_messages_ibfk_1` FOREIGN KEY (`list_id`) REFERENCES `shopping_lists` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `list_messages_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `list_receipts`
--
ALTER TABLE `list_receipts`
  ADD CONSTRAINT `list_receipts_ibfk_1` FOREIGN KEY (`list_id`) REFERENCES `shopping_lists` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `message_read_status`
--
ALTER TABLE `message_read_status`
  ADD CONSTRAINT `message_read_status_ibfk_1` FOREIGN KEY (`message_id`) REFERENCES `list_messages` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `message_read_status_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `product_suggestions`
--
ALTER TABLE `product_suggestions`
  ADD CONSTRAINT `product_suggestions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `purchase_history`
--
ALTER TABLE `purchase_history`
  ADD CONSTRAINT `purchase_history_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `purchase_history_ibfk_2` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `purchase_history_ibfk_3` FOREIGN KEY (`list_id`) REFERENCES `shopping_lists` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `shared_list`
--
ALTER TABLE `shared_list`
  ADD CONSTRAINT `shared_list_ibfk_1` FOREIGN KEY (`owner_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `shared_list_ibfk_2` FOREIGN KEY (`shared_with_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `shared_list_ibfk_3` FOREIGN KEY (`list_id`) REFERENCES `shopping_lists` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `shopping_lists`
--
ALTER TABLE `shopping_lists`
  ADD CONSTRAINT `shopping_lists_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `suggestion_feedback`
--
ALTER TABLE `suggestion_feedback`
  ADD CONSTRAINT `suggestion_feedback_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_devices`
--
ALTER TABLE `user_devices`
  ADD CONSTRAINT `user_devices_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_purchase_patterns`
--
ALTER TABLE `user_purchase_patterns`
  ADD CONSTRAINT `user_purchase_patterns_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_purchase_patterns_ibfk_2` FOREIGN KEY (`preferred_category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `user_sso_links`
--
ALTER TABLE `user_sso_links`
  ADD CONSTRAINT `user_sso_links_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
