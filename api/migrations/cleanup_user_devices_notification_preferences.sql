-- Migration: Suppression de la colonne notification_preferences inutilisée
-- Date: 2025-11-13
-- Description: La colonne notification_preferences dans user_devices créait de la confusion
--              car le système utilise déjà la table email_preferences pour gérer toutes les préférences.
--              Cette colonne n'était pas utilisée par le code.

-- Supprimer la colonne inutilisée
ALTER TABLE user_devices
DROP COLUMN notification_preferences;

-- Vérification: Afficher la structure finale de la table
-- DESCRIBE user_devices;
