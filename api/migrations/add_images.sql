-- Migration : URLs d'images (avatars utilisateurs, photos de produits)
-- Idempotente. A appliquer en local ET en prod (phpMyAdmin).

SET @c = (SELECT COUNT(*) FROM information_schema.columns
          WHERE table_schema = DATABASE() AND table_name = 'users' AND column_name = 'avatar_url');
SET @sql = IF(@c = 0,
    'ALTER TABLE users ADD COLUMN avatar_url VARCHAR(500) NULL AFTER sso_provider',
    'SELECT "users.avatar_url deja presente"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @c = (SELECT COUNT(*) FROM information_schema.columns
          WHERE table_schema = DATABASE() AND table_name = 'list_items' AND column_name = 'image_url');
SET @sql = IF(@c = 0,
    'ALTER TABLE list_items ADD COLUMN image_url VARCHAR(500) NULL AFTER barcode',
    'SELECT "list_items.image_url deja presente"');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SELECT 'verification' AS v,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='users' AND column_name='avatar_url') AS users_avatar,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='list_items' AND column_name='image_url') AS items_image;
