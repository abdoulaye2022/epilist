-- ============================================================
-- ESPACES (personnel / foyer / restaurant / organisation)
-- Date : 2026-09-30. Idempotente (rejouable sans erreur).
--
-- Phase 1 (fondation) : trois tables + backfill de l'espace
-- personnel de chaque utilisateur existant. AUCUNE table métier
-- n'est modifiée dans cette phase (voir docs/audit-espaces-epilist.md).
-- ============================================================

-- 1. Espaces ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS spaces (
    id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(120) NOT NULL,
    type ENUM('personal','household','restaurant','organization') NOT NULL DEFAULT 'personal',
    owner_user_id INT NOT NULL,
    -- Localisation de l'ESPACE (jamais l'adresse personnelle de
    -- l'utilisateur) : tout est optionnel (voir cahier des charges §6).
    country VARCHAR(2) NULL,
    region VARCHAR(120) NULL,
    city VARCHAR(120) NULL,
    postal_code VARCHAR(20) NULL,
    currency VARCHAR(3) NULL,
    settings JSON NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    PRIMARY KEY (id),
    KEY idx_spaces_owner (owner_user_id),
    KEY idx_spaces_type (type),
    CONSTRAINT fk_spaces_owner FOREIGN KEY (owner_user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Membres ---------------------------------------------------------
-- role : jeu de permissions par défaut ; permissions : surcharges
-- fines par membre (JSON, ex. {"manage_budgets": false}).
CREATE TABLE IF NOT EXISTS space_members (
    id INT NOT NULL AUTO_INCREMENT,
    space_id INT NOT NULL,
    user_id INT NOT NULL,
    role ENUM('owner','admin','manager','member','viewer') NOT NULL DEFAULT 'member',
    permissions JSON NULL,
    status ENUM('active','removed','left') NOT NULL DEFAULT 'active',
    invited_by INT NULL,
    joined_at DATETIME NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_space_user (space_id, user_id),
    KEY idx_members_user (user_id, status),
    CONSTRAINT fk_members_space FOREIGN KEY (space_id) REFERENCES spaces(id) ON DELETE CASCADE,
    CONSTRAINT fk_members_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Invitations -----------------------------------------------------
-- Même cycle de vie que shared_list (pending/accepted/declined/
-- expired/revoked) + lien par jeton, réutilisé par les deep links.
CREATE TABLE IF NOT EXISTS space_invitations (
    id INT NOT NULL AUTO_INCREMENT,
    space_id INT NOT NULL,
    email VARCHAR(150) NOT NULL,
    role ENUM('admin','manager','member','viewer') NOT NULL DEFAULT 'member',
    token CHAR(64) NOT NULL,
    status ENUM('pending','accepted','declined','expired','revoked') NOT NULL DEFAULT 'pending',
    invited_by INT NOT NULL,
    expires_at DATETIME NOT NULL,
    accepted_at DATETIME NULL,
    declined_at DATETIME NULL,
    revoked_at DATETIME NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_space_invite_token (token),
    KEY idx_invites_space (space_id, status),
    KEY idx_invites_email (email, status),
    CONSTRAINT fk_invites_space FOREIGN KEY (space_id) REFERENCES spaces(id) ON DELETE CASCADE,
    CONSTRAINT fk_invites_user FOREIGN KEY (invited_by) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Backfill : un espace personnel par utilisateur existant ---------
-- Idempotent : ne crée rien pour un utilisateur qui possède déjà un
-- espace personnel. Le nom sera affiché traduit côté client (le type
-- 'personal' fait foi) ; « Personnel » n'est qu'une valeur de repli.
INSERT INTO spaces (name, type, owner_user_id, currency, created_at)
SELECT 'Personnel', 'personal', u.id,
       (SELECT c.code FROM currencies c WHERE c.id = u.currency_id),
       NOW()
FROM users u
WHERE NOT EXISTS (
    SELECT 1 FROM spaces s
    WHERE s.owner_user_id = u.id AND s.type = 'personal' AND s.deleted_at IS NULL
);

-- Chaque propriétaire est membre 'owner' de son espace personnel.
INSERT INTO space_members (space_id, user_id, role, status, joined_at)
SELECT s.id, s.owner_user_id, 'owner', 'active', NOW()
FROM spaces s
WHERE s.type = 'personal' AND s.deleted_at IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM space_members m
    WHERE m.space_id = s.id AND m.user_id = s.owner_user_id
  );

SELECT 'verification' AS v,
 (SELECT COUNT(*) FROM spaces) AS spaces_total,
 (SELECT COUNT(*) FROM spaces WHERE type='personal') AS personal_spaces,
 (SELECT COUNT(*) FROM space_members) AS members_total,
 (SELECT COUNT(*) FROM users) AS users_total;
