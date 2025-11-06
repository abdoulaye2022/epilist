# 🚀 Migration Production - 6 Novembre 2025

## Nouvelles Migrations à Appliquer

### Migration 010: Ajout de `purchased_at` aux list_items

**Fichier**: `migrations/010_add_purchased_at_to_list_items.sql`
**Date**: 2025-11-06
**Impact**: Faible - Ajoute une colonne optionnelle
**Temps estimé**: < 1 minute

### Migration 011: Création de la table `devices` (FCM/Notifications)

**Fichier**: `migrations/011_create_devices_table.sql`
**Date**: 2025-11-06
**Impact**: Moyen - Nouvelle table pour notifications push
**Temps estimé**: < 1 minute

---

## Migration 010: purchased_at

#### Description
Ajoute une colonne `purchased_at` (TIMESTAMP) à la table `list_items` pour tracer la date exacte d'achat des items.

#### Modifications
1. ✅ Ajoute la colonne `purchased_at` (NULL par défaut)
2. ✅ Initialise `purchased_at` = `updated_at` pour les items déjà achetés
3. ✅ Crée l'index `idx_purchased_at` pour optimiser les requêtes
4. ✅ Crée l'index composite `idx_list_purchased` pour les requêtes budget

#### Avantages
- Permet de tracker précisément quand un item a été acheté
- Améliore les performances des requêtes budget (analyse des dépenses par période)
- Prépare pour de futures fonctionnalités d'analytics

---

## Migration 011: Table devices

#### Description
Crée la table `devices` pour stocker les informations des appareils et leurs tokens FCM/APNS pour les notifications push.

#### Modifications
1. ✅ Crée la table `devices` avec les colonnes:
   - `id`: Clé primaire auto-incrémentée
   - `user_id`: Référence vers l'utilisateur (FK)
   - `device_id`: Identifiant unique du device (UUID)
   - `platform`: Type de plateforme (ios/android/web)
   - `push_token`: Token FCM pour notifications
   - `apns_token`: Token APNS (iOS uniquement, optionnel)
   - `app_version`, `os_version`, `device_model`: Informations device
   - `is_active`: Statut actif/inactif
   - `last_active_at`: Dernière activité
   - `created_at`, `updated_at`: Timestamps

2. ✅ Crée les index pour optimiser les requêtes:
   - `idx_user_id`: Index sur user_id
   - `idx_device_id`: Index sur device_id
   - `idx_platform`: Index sur platform
   - `idx_is_active`: Index sur is_active
   - `idx_last_active`: Index sur last_active_at

3. ✅ Contrainte unique `unique_user_device` (user_id + device_id)
4. ✅ Foreign key vers `users` avec CASCADE

#### Avantages
- Supporte les notifications push Firebase (FCM)
- Un utilisateur peut avoir plusieurs devices
- Tracking de l'activité par device
- Possibilité de désactiver un device sans le supprimer
- Préparation pour le mode hors ligne (future évolution)

---

## 📋 Checklist de Migration Production

### Avant la Migration

- [ ] **Backup de la base de données**
  ```bash
  # Sur le serveur de production
  mysqldump -u epilist_user -p epilist_prod > backup_before_migration_2025-11-06.sql
  ```

- [ ] **Vérifier l'espace disque**
  ```bash
  df -h
  # Assurez-vous d'avoir au moins 1GB libre
  ```

- [ ] **Vérifier le nombre de lignes dans list_items**
  ```sql
  SELECT COUNT(*) as total_items,
         SUM(is_purchased = 1) as purchased_items
  FROM list_items;
  ```

### Exécution des Migrations

**⚠️ IMPORTANT**: Exécuter les migrations dans l'ordre (010 puis 011)

#### Option 1: Via phpMyAdmin (Recommandé)

**Migration 010:**
1. Se connecter à phpMyAdmin
2. Sélectionner la base `epilist_prod` (ou votre nom de BDD prod)
3. Aller dans l'onglet "SQL"
4. Copier-coller le contenu de `migrations/010_add_purchased_at_to_list_items.sql`
5. Cliquer sur "Exécuter"
6. Vérifier le résultat (devrait afficher "Migration complétée")

**Migration 011:**
7. Dans le même onglet "SQL"
8. Copier-coller le contenu de `migrations/011_create_devices_table.sql`
9. Cliquer sur "Exécuter"
10. Vérifier le résultat (devrait afficher "Migration complétée")

#### Option 2: Via MySQL CLI

```bash
# Se connecter au serveur MySQL
mysql -u epilist_user -p epilist_prod

# Exécuter les migrations dans l'ordre
source /path/to/migrations/010_add_purchased_at_to_list_items.sql
source /path/to/migrations/011_create_devices_table.sql

# OU en une ligne (bash)
mysql -u epilist_user -p epilist_prod < migrations/010_add_purchased_at_to_list_items.sql
mysql -u epilist_user -p epilist_prod < migrations/011_create_devices_table.sql
```

#### Option 3: Via Script PHP (Si accès SSH)

```bash
# Sur le serveur de production
cd /path/to/epilist/api
php -r "
\$db = new PDO('mysql:host=localhost;dbname=epilist_prod', 'epilist_user', 'password');
\$sql = file_get_contents('migrations/010_add_purchased_at_to_list_items.sql');
\$db->exec(\$sql);
echo 'Migration exécutée avec succès';
"
```

### Vérification Post-Migration

```sql
-- Vérifier que la colonne existe
DESCRIBE list_items;

-- Vérifier les index
SHOW INDEX FROM list_items WHERE Key_name LIKE 'idx_%';

-- Vérifier les données
SELECT
    COUNT(*) as total_items,
    SUM(is_purchased = 1) as purchased_items,
    SUM(is_purchased = 1 AND purchased_at IS NOT NULL) as items_with_date
FROM list_items;

-- Les 3 valeurs devraient être identiques
```

### Résultat Attendu

```
status: Migration complétée
column_exists: 1
items_with_purchase_date: [nombre d'items achetés]
index_purchased_at_exists: 1
index_list_purchased_exists: 1
```

---

## ⚠️ Rollback (En cas de problème)

Si vous devez annuler la migration:

```sql
-- Supprimer les index
DROP INDEX IF EXISTS `idx_purchased_at` ON `list_items`;
DROP INDEX IF EXISTS `idx_list_purchased` ON `list_items`;

-- Supprimer la colonne
ALTER TABLE `list_items` DROP COLUMN `purchased_at`;
```

**OU** restaurer le backup:

```bash
mysql -u epilist_user -p epilist_prod < backup_before_migration_2025-11-06.sql
```

---

## 📊 Impact sur l'Application

### Compatibilité
- ✅ **Rétro-compatible**: L'ancienne version de l'app continue de fonctionner
- ✅ **Colonne optionnelle**: NULL autorisé, pas de contraintes
- ✅ **Pas de changement API**: Les endpoints existants fonctionnent sans modification

### Optimisations Future
Une fois la migration appliquée, vous pourrez:
1. Tracker précisément les dates d'achat
2. Générer des rapports de dépenses par période
3. Améliorer les fonctionnalités budget/analytics

---

## 🔍 Monitoring Post-Migration

### Vérifier les Performances

```sql
-- Vérifier que les nouveaux index sont utilisés
EXPLAIN SELECT * FROM list_items
WHERE is_purchased = 1
AND purchased_at BETWEEN '2025-01-01' AND '2025-12-31';

-- Devrait montrer l'utilisation de idx_list_purchased
```

### Logs à Surveiller

Après migration, surveiller les logs PHP pour:
- Erreurs SQL liées à `purchased_at`
- Performance des requêtes budget
- Temps de réponse des endpoints

---

## ✅ Validation Finale

- [ ] Migration exécutée sans erreur
- [ ] Colonne `purchased_at` visible dans `list_items`
- [ ] Index `idx_purchased_at` créé
- [ ] Index `idx_list_purchased` créé
- [ ] Items achetés ont `purchased_at` défini
- [ ] Application fonctionne normalement
- [ ] Aucune erreur dans les logs

---

## 📝 Notes

- **Idempotente**: Peut être exécutée plusieurs fois sans problème
- **Rapide**: Prend moins d'1 minute même avec 100k items
- **Sans downtime**: L'application reste disponible pendant la migration
- **Réversible**: Facile à rollback si nécessaire

---

**Responsable**: Mohamed Ahmed Abdoulaye
**Date**: 6 Novembre 2025
**Version**: 1.0.0
