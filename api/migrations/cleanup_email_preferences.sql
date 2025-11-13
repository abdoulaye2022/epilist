-- Migration: Nettoyage des colonnes inutilisées dans email_preferences
-- Date: 2025-11-12
-- Description: Suppression des préférences qui ne sont pas implémentées dans le code

-- 1. Supprimer les colonnes inutilisées
ALTER TABLE email_preferences
DROP COLUMN list_item_added,
DROP COLUMN list_item_checked,
DROP COLUMN marketing_emails,
DROP COLUMN product_updates,
DROP COLUMN notification_frequency;

-- Vérification: Afficher la structure finale de la table
-- DESCRIBE email_preferences;
