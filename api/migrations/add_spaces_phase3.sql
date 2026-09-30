-- ============================================================
-- ESPACES — PHASE 3 (restaurant) : fournisseurs, demandes d'achat,
-- inventaire quantitatif. Date : 2026-09-30. Idempotente.
-- Prérequis : add_spaces.sql, add_spaces_phase2.sql.
-- ============================================================

-- 1. Fournisseurs (espaces professionnels, §22) -----------------------
CREATE TABLE IF NOT EXISTS suppliers (
    id INT NOT NULL AUTO_INCREMENT,
    space_id INT NOT NULL,
    name VARCHAR(150) NOT NULL,
    contact_name VARCHAR(150) NULL,
    phone VARCHAR(40) NULL,
    email VARCHAR(150) NULL,
    notes TEXT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_by_user_id INT NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    PRIMARY KEY (id),
    KEY idx_suppliers_space (space_id, is_active),
    CONSTRAINT fk_suppliers_space FOREIGN KEY (space_id) REFERENCES spaces(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Inventaire quantitatif (§21) : seuils sur home_inventory ---------
SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='home_inventory' AND column_name='min_quantity');
SET @sql=IF(@c=0,'ALTER TABLE home_inventory ADD COLUMN min_quantity DECIMAL(10,3) NULL AFTER quantity, ADD COLUMN reorder_quantity DECIMAL(10,3) NULL AFTER min_quantity, ADD COLUMN preferred_supplier_id INT NULL AFTER reorder_quantity','SELECT "inv qty ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 3. Demandes d'achat (§20) ------------------------------------------
CREATE TABLE IF NOT EXISTS purchase_requests (
    id INT NOT NULL AUTO_INCREMENT,
    space_id INT NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    normalized_name VARCHAR(255) NOT NULL,
    quantity DECIMAL(10,3) NULL,
    unit VARCHAR(10) NULL,
    note VARCHAR(500) NULL,
    status ENUM('draft','pending','approved','rejected','purchased','cancelled') NOT NULL DEFAULT 'pending',
    requested_by INT NOT NULL,
    approved_by INT NULL,
    decided_at DATETIME NULL,
    decision_comment VARCHAR(500) NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_pr_space (space_id, status),
    KEY idx_pr_requester (requested_by),
    CONSTRAINT fk_pr_space FOREIGN KEY (space_id) REFERENCES spaces(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Historique des changements de statut (§20) -----------------------
CREATE TABLE IF NOT EXISTS purchase_request_events (
    id INT NOT NULL AUTO_INCREMENT,
    request_id INT NOT NULL,
    user_id INT NULL,
    from_status VARCHAR(20) NULL,
    to_status VARCHAR(20) NOT NULL,
    comment VARCHAR(500) NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_pre_request (request_id),
    CONSTRAINT fk_pre_request FOREIGN KEY (request_id) REFERENCES purchase_requests(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SELECT 'verification' AS v,
 (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='suppliers') AS suppliers_table,
 (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='purchase_requests') AS requests_table,
 (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='home_inventory' AND column_name='min_quantity') AS inv_min_col;
