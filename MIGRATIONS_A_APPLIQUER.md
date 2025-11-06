# ✅ Migrations à Appliquer en Production

## Résumé Rapide

**Date**: 6 Novembre 2025
**Nombre de migrations**: 2
**Temps estimé total**: < 2 minutes
**Impact**: Faible à Moyen - Pas de downtime

---

## 📋 Checklist Rapide

### Avant
- [ ] Backup de la base de données prod
- [ ] Vérifier l'espace disque (>1GB libre)
- [ ] Avoir accès phpMyAdmin ou MySQL CLI

### Migrations à exécuter (dans l'ordre)
- [ ] **Migration 010**: `010_add_purchased_at_to_list_items.sql`
- [ ] **Migration 011**: `011_create_devices_table.sql`

### Après
- [ ] Vérifier que les migrations sont complétées
- [ ] Tester l'application (login, listes, notifications)
- [ ] Surveiller les logs pendant 1 heure

---

## 🚀 Exécution Rapide (phpMyAdmin)

### Étape 1: Backup
```sql
-- Via phpMyAdmin: Exporter la BDD avant migration
```

### Étape 2: Migration 010 (purchased_at)
1. Aller dans phpMyAdmin → Sélectionner BDD prod
2. Onglet "SQL"
3. Coller le contenu de `api/migrations/010_add_purchased_at_to_list_items.sql`
4. Cliquer "Exécuter"
5. ✅ Vérifier: "Migration complétée"

### Étape 3: Migration 011 (devices table)
1. Dans le même onglet "SQL"
2. Coller le contenu de `api/migrations/011_create_devices_table.sql`
3. Cliquer "Exécuter"
4. ✅ Vérifier: "Migration complétée"

---

## 📊 Détails des Migrations

### Migration 010: purchased_at
**Objectif**: Tracker la date exacte d'achat des items

**Modifications**:
- ✅ Ajoute colonne `purchased_at` à `list_items`
- ✅ Initialise avec `updated_at` pour items déjà achetés
- ✅ Crée 2 index pour performances

**Impact**:
- ✅ Rétro-compatible
- ✅ Optionnel (NULL autorisé)
- ✅ Améliore analytics budget

---

### Migration 011: devices
**Objectif**: Supporte notifications push FCM/APNS

**Modifications**:
- ✅ Crée table `devices`
- ✅ Colonnes: device_id, platform, push_token, apns_token, etc.
- ✅ Foreign key vers `users`
- ✅ 5 index pour performances

**Impact**:
- ✅ Nouvelle fonctionnalité notifications
- ✅ Multi-device par utilisateur
- ✅ Prépare mode hors ligne (future)

---

## ⚠️ Points d'Attention

### Mode Hors Ligne
**Note importante**: Le mode hors ligne implémenté dans l'app Flutter utilise **SharedPreferences** côté client. Il n'y a **PAS de table serveur** pour la queue d'actions offline.

- ✅ Cache local: SharedPreferences (app Flutter)
- ✅ Queue actions: SharedPreferences (app Flutter)
- ✅ Synchronisation: Via API existante
- ❌ Pas de table `offline_queue` côté serveur (non nécessaire)

### Table devices
La table `devices` créée par la migration 011 est pour:
- ✅ Notifications push FCM/APNS
- ✅ Tracking des appareils actifs
- ⚠️ Peut être utilisée future pour sync offline (mais pas obligatoire)

---

## 🔍 Vérification Post-Migration

### Migration 010
```sql
-- Vérifier la colonne
DESCRIBE list_items;
-- Doit montrer: purchased_at | timestamp | YES

-- Vérifier les données
SELECT COUNT(*) as achetés_avec_date
FROM list_items
WHERE is_purchased = 1 AND purchased_at IS NOT NULL;
```

### Migration 011
```sql
-- Vérifier la table
SHOW TABLES LIKE 'devices';
-- Doit montrer: devices

-- Vérifier la structure
DESCRIBE devices;
-- Doit montrer 14 colonnes

-- Vérifier les index
SHOW INDEX FROM devices;
-- Doit montrer 5+ index
```

---

## 🆘 Rollback (si problème)

### Migration 010
```sql
DROP INDEX IF EXISTS `idx_purchased_at` ON `list_items`;
DROP INDEX IF EXISTS `idx_list_purchased` ON `list_items`;
ALTER TABLE `list_items` DROP COLUMN `purchased_at`;
```

### Migration 011
```sql
DROP TABLE IF EXISTS `devices`;
```

### Restauration complète
```bash
mysql -u epilist_user -p epilist_prod < backup_before_migration_2025-11-06.sql
```

---

## 📞 Support

Si problème pendant la migration:
1. **NE PAS PANIQUER**
2. Copier le message d'erreur
3. Vérifier le rollback ci-dessus
4. Restaurer le backup si nécessaire

---

## ✅ Validation Finale

Une fois les migrations appliquées:

- [ ] Colonne `purchased_at` existe dans `list_items`
- [ ] Table `devices` créée avec 14 colonnes
- [ ] Application fonctionne (login + listes)
- [ ] Notifications fonctionnent (si activées)
- [ ] Aucune erreur dans les logs

**Durée totale**: ~2 minutes
**Downtime**: 0 minute
**Risque**: Faible ✅

---

**Document détaillé**: Voir `api/MIGRATION_PRODUCTION_2025-11-06.md`
