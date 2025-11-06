-- Migration: Ajout du champ language à la table users
-- Date: 2025-01-06
-- Description: Permet de stocker la langue préférée de l'utilisateur (fr ou en)

-- Ajouter la colonne language
ALTER TABLE users
ADD COLUMN language VARCHAR(2) DEFAULT 'fr' AFTER currency_id;

-- Créer un index pour optimiser les requêtes
CREATE INDEX idx_users_language ON users(language);

-- Mettre à jour les utilisateurs existants avec la langue française par défaut
UPDATE users SET language = 'fr' WHERE language IS NULL;

-- Commentaire de la colonne
ALTER TABLE users MODIFY COLUMN language VARCHAR(2) DEFAULT 'fr' COMMENT 'Langue préférée de l\'utilisateur (fr, en)';
