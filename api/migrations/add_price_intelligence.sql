-- ============================================================
-- INTELLIGENCE PRIX — reçus OCR, historique de prix, comparateur
-- Date : 2026-09-27. Idempotente (rejouable sans erreur).
--
-- Réutilise l'existant au lieu de dupliquer :
--  * purchase_history  = l'historique de prix (étendu : magasin, reçu,
--    source, unité) — déjà alimenté à chaque achat.
--  * list_receipts     = les reçus (étendus : magasin, totaux, devise,
--    image GCS, source, signature anti-doublon).
--  * stores            = référentiel magasins (tri par rayon).
-- Nouveau : receipt_items (lignes de reçu), product_aliases
-- (apprentissage libellé-reçu -> produit canonique = nom normalisé).
-- ============================================================

-- 1. list_receipts : colonnes d'import structuré ---------------------
SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='list_receipts' AND column_name='store_id');
SET @sql=IF(@c=0,'ALTER TABLE list_receipts ADD COLUMN store_id INT NULL AFTER store_name','SELECT "store_id ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='list_receipts' AND column_name='receipt_number');
SET @sql=IF(@c=0,'ALTER TABLE list_receipts ADD COLUMN receipt_number VARCHAR(60) NULL AFTER store_id','SELECT "receipt_number ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='list_receipts' AND column_name='subtotal');
SET @sql=IF(@c=0,'ALTER TABLE list_receipts ADD COLUMN subtotal DECIMAL(10,2) NULL AFTER total_amount','SELECT "subtotal ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='list_receipts' AND column_name='taxes');
SET @sql=IF(@c=0,'ALTER TABLE list_receipts ADD COLUMN taxes DECIMAL(10,2) NULL AFTER subtotal','SELECT "taxes ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='list_receipts' AND column_name='currency');
SET @sql=IF(@c=0,"ALTER TABLE list_receipts ADD COLUMN currency VARCHAR(3) NULL AFTER taxes",'SELECT "currency ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='list_receipts' AND column_name='image_url');
SET @sql=IF(@c=0,'ALTER TABLE list_receipts ADD COLUMN image_url VARCHAR(500) NULL AFTER currency','SELECT "image_url ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='list_receipts' AND column_name='source');
SET @sql=IF(@c=0,"ALTER TABLE list_receipts ADD COLUMN source VARCHAR(20) NOT NULL DEFAULT 'manual' COMMENT 'manual | receipt_ocr' AFTER image_url",'SELECT "source ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Signature anti-doublon : sha1(user|store|date|total|numero)
SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='list_receipts' AND column_name='signature');
SET @sql=IF(@c=0,'ALTER TABLE list_receipts ADD COLUMN signature CHAR(40) NULL AFTER source','SELECT "signature ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c=(SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='list_receipts' AND index_name='idx_receipts_signature');
SET @sql=IF(@c=0,'CREATE INDEX idx_receipts_signature ON list_receipts(signature)','SELECT "idx signature ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 2. receipt_items : lignes de reçu -----------------------------------
CREATE TABLE IF NOT EXISTS receipt_items (
    id INT NOT NULL AUTO_INCREMENT,
    receipt_id INT NOT NULL,
    raw_label VARCHAR(255) NOT NULL COMMENT 'Libelle brut du recu (MLK 2% 4L)',
    product_name VARCHAR(255) NULL COMMENT 'Produit canonique choisi',
    normalized_name VARCHAR(255) NULL,
    quantity DECIMAL(10,3) NOT NULL DEFAULT 1,
    unit VARCHAR(10) NULL COMMENT 'kg, g, L, ml, un',
    unit_price DECIMAL(10,4) NULL,
    line_price DECIMAL(10,2) NOT NULL,
    confidence TINYINT NULL COMMENT '0-100, score OCR/parsing',
    position SMALLINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_receipt_items_receipt (receipt_id),
    KEY idx_receipt_items_normalized (normalized_name),
    CONSTRAINT fk_receipt_items_receipt FOREIGN KEY (receipt_id)
        REFERENCES list_receipts(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. purchase_history : devient l'historique de prix complet ----------
SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='purchase_history' AND column_name='store_id');
SET @sql=IF(@c=0,'ALTER TABLE purchase_history ADD COLUMN store_id INT NULL AFTER store_name','SELECT "ph.store_id ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='purchase_history' AND column_name='receipt_id');
SET @sql=IF(@c=0,'ALTER TABLE purchase_history ADD COLUMN receipt_id INT NULL AFTER list_id','SELECT "ph.receipt_id ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='purchase_history' AND column_name='source');
SET @sql=IF(@c=0,"ALTER TABLE purchase_history ADD COLUMN source VARCHAR(20) NOT NULL DEFAULT 'shopping_list' COMMENT 'shopping_list | receipt_ocr | manual' AFTER receipt_id",'SELECT "ph.source ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='purchase_history' AND column_name='unit');
SET @sql=IF(@c=0,'ALTER TABLE purchase_history ADD COLUMN unit VARCHAR(10) NULL AFTER quantity','SELECT "ph.unit ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c=(SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='purchase_history' AND column_name='unit_price');
SET @sql=IF(@c=0,"ALTER TABLE purchase_history ADD COLUMN unit_price DECIMAL(10,4) NULL COMMENT 'prix normalise par unite (kg, L, un)' AFTER unit",'SELECT "ph.unit_price ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Index du comparateur : produit x magasin x date
SET @c=(SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='purchase_history' AND index_name='idx_ph_norm_store_date');
SET @sql=IF(@c=0,'CREATE INDEX idx_ph_norm_store_date ON purchase_history(normalized_name, store_id, purchased_at)','SELECT "idx comparateur ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c=(SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='purchase_history' AND index_name='idx_ph_user_norm_date');
SET @sql=IF(@c=0,'CREATE INDEX idx_ph_user_norm_date ON purchase_history(user_id, normalized_name, purchased_at)','SELECT "idx historique ok"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- 4. product_aliases : apprentissage libelle recu -> produit ----------
CREATE TABLE IF NOT EXISTS product_aliases (
    id INT NOT NULL AUTO_INCREMENT,
    user_id INT NOT NULL,
    store_id INT NULL COMMENT 'NULL = alias valable pour tous les magasins',
    alias VARCHAR(255) NOT NULL COMMENT 'Libelle brut du recu',
    normalized_alias VARCHAR(255) NOT NULL,
    product_name VARCHAR(255) NOT NULL COMMENT 'Produit canonique',
    normalized_name VARCHAR(255) NOT NULL,
    barcode VARCHAR(50) NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_alias_user_store (user_id, store_id, normalized_alias),
    KEY idx_aliases_user (user_id),
    CONSTRAINT fk_aliases_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Verification -----------------------------------------------------------
SELECT 'verification' AS v,
 (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='list_receipts' AND column_name IN ('store_id','subtotal','taxes','currency','image_url','source','signature','receipt_number')) AS receipts_cols,
 (SELECT COUNT(*) FROM information_schema.tables  WHERE table_schema=DATABASE() AND table_name='receipt_items') AS receipt_items,
 (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='purchase_history' AND column_name IN ('store_id','receipt_id','source','unit','unit_price')) AS ph_cols,
 (SELECT COUNT(*) FROM information_schema.tables  WHERE table_schema=DATABASE() AND table_name='product_aliases') AS product_aliases;
