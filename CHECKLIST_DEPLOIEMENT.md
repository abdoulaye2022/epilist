# Checklist de déploiement EpiList - Version 1.1.4

## ✅ Vérifications avant déploiement

### 1. Code Flutter

#### 1.1 Dépendances
```bash
cd /Users/mohamedahmedabdoulaye/Documents/mes-projets/epilist/app
flutter pub get
```
✅ Vérifier qu'il n'y a pas d'erreurs

#### 1.2 Analyse du code
```bash
flutter analyze
```
✅ S'assurer qu'il n'y a pas d'erreurs critiques (warnings acceptables)

#### 1.3 Test de compilation
```bash
# Android
flutter build apk --debug

# iOS (si sur Mac)
flutter build ios --debug
```
✅ La compilation doit réussir sans erreur

---

### 2. Base de données

#### 2.1 Backup de la base actuelle
```bash
mysqldump -u root epilist > backup_avant_migration_$(date +%Y%m%d_%H%M%S).sql
```
✅ Backup créé et sauvegardé

#### 2.2 Exécution de la migration
```bash
cd /Users/mohamedahmedabdoulaye/Documents/mes-projets/epilist/api/migrations
mysql -u root epilist < add_barcode_to_list_items.sql
```
✅ Migration exécutée sans erreur

#### 2.3 Vérification de la migration
```sql
-- Se connecter à MySQL
mysql -u root epilist

-- Vérifier la colonne barcode
DESCRIBE list_items;

-- Vérifier la table scanned_products
DESCRIBE scanned_products;

-- Vérifier l'index
SHOW INDEX FROM list_items WHERE Key_name = 'idx_barcode';
```
✅ Colonne `barcode` présente
✅ Table `scanned_products` créée
✅ Index `idx_barcode` créé

---

### 3. Backend PHP

#### 3.1 Modifier ListItem.php
**Fichier:** `/api/src/Models/ListItem.php`

Ajouter dans `$fillable`:
```php
protected $fillable = [
    'shopping_list_id',
    'product_name',
    'barcode',        // ← AJOUTER
    'quantity',
    'price',
    'store_name',
    'is_purchased',
];
```
✅ Modification effectuée

#### 3.2 Modifier ListItemController.php
**Fichier:** `/api/src/Controllers/ListItemController.php`

Dans la validation:
```php
$rules = [
    'product_name' => 'required|string|min:2|max:255',
    'barcode' => 'nullable|string|max:50',  // ← AJOUTER
    'quantity' => 'required|integer|min:1|max:999',
    // ...
];
```

Dans la création:
```php
$item = ListItem::create([
    'shopping_list_id' => $listId,
    'product_name' => $validated['product_name'],
    'barcode' => $validated['barcode'] ?? null,  // ← AJOUTER
    'quantity' => $validated['quantity'],
    // ...
]);
```
✅ Modifications effectuées

#### 3.3 Test de l'API
```bash
# Test création d'article sans barcode (doit fonctionner)
curl -X POST http://localhost/api/shopping-lists/1/items \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "product_name": "Test produit",
    "quantity": 1
  }'

# Test création d'article avec barcode (doit fonctionner)
curl -X POST http://localhost/api/shopping-lists/1/items \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "product_name": "Test produit avec barcode",
    "quantity": 1,
    "barcode": "1234567890123"
  }'
```
✅ Les deux requêtes fonctionnent

---

### 4. Application Flutter

#### 4.1 Appliquer le thème
**Fichier:** `/app/lib/main.dart`

Ajouter l'import:
```dart
import 'package:epilist/config/app_theme.dart';
```

Dans MaterialApp:
```dart
MaterialApp(
  title: 'EpiList',
  theme: AppTheme.lightTheme,  // ← AJOUTER
  // ... reste du code
)
```
✅ Thème appliqué

#### 4.2 Ajouter les permissions

**Android:** `/app/android/app/src/main/AndroidManifest.xml`
```xml
<manifest>
  <!-- Ajouter ces lignes -->
  <uses-permission android:name="android.permission.CAMERA" />
  <uses-feature android:name="android.hardware.camera" android:required="false" />

  <application>
    ...
  </application>
</manifest>
```
✅ Permissions Android ajoutées

**iOS:** `/app/ios/Runner/Info.plist`
```xml
<dict>
  <!-- Ajouter ces lignes -->
  <key>NSCameraUsageDescription</key>
  <string>EpiList a besoin d'accéder à la caméra pour scanner les codes-barres des produits</string>

  <!-- Reste du fichier -->
</dict>
```
✅ Permissions iOS ajoutées

---

### 5. Tests fonctionnels

#### 5.1 Test du scanner
```
1. Ouvrir l'app
2. Créer/ouvrir une liste
3. Appuyer sur le bouton d'ajout d'article
4. Appuyer sur l'icône de scan
5. Scanner un code-barres
6. Vérifier que le produit s'affiche
7. Ajouter à la liste
```
✅ Scanner fonctionne
✅ Produit récupéré depuis OpenFoodFacts
✅ Article ajouté avec barcode

#### 5.2 Test de saisie manuelle
```
1. Ajouter un article sans scanner
2. Vérifier que ça fonctionne toujours
```
✅ Saisie manuelle fonctionne

#### 5.3 Test des animations
```
1. Naviguer entre les écrans
2. Vérifier les transitions fluides
3. Vérifier le shimmer loading
```
✅ Animations fluides
✅ Pas de lag

#### 5.4 Test du thème
```
1. Vérifier les couleurs cohérentes
2. Vérifier les cartes modernes
3. Vérifier les boutons Material 3
```
✅ Thème appliqué correctement
✅ Design cohérent

---

### 6. Tests de régression

#### 6.1 Fonctionnalités existantes
```
✅ Création de liste
✅ Ajout d'article (sans barcode)
✅ Modification d'article
✅ Suppression d'article
✅ Marquage acheté/non acheté
✅ Partage de liste
✅ Budget
✅ Reçus
✅ Analytics
✅ Profil
```

#### 6.2 Notifications
```
✅ Notifications push reçues
✅ Budgets alertes
✅ Listes partagées
```

---

### 7. Performance

#### 7.1 Temps de démarrage
```bash
# Mesurer le temps de démarrage
flutter run --profile
```
✅ < 3 secondes sur appareil moyen

#### 7.2 Taille de l'app
```bash
# Android
flutter build apk --release
ls -lh build/app/outputs/flutter-apk/app-release.apk

# iOS
flutter build ios --release
```
✅ APK < 50 MB
✅ IPA < 60 MB

#### 7.3 Mémoire
```
# Utiliser Flutter DevTools
flutter pub global activate devtools
flutter pub global run devtools
```
✅ Pas de fuite mémoire
✅ Usage RAM < 200 MB

---

### 8. Sécurité

#### 8.1 Permissions
```
✅ Caméra: Seulement pour le scanner
✅ Internet: Pour l'API
✅ Pas de permissions inutiles
```

#### 8.2 API
```
✅ Token JWT vérifié
✅ Validation des entrées
✅ Pas d'injection SQL
✅ HTTPS activé
```

---

### 9. Documentation

```
✅ AMELIORATIONS.md créé et complet
✅ GUIDE_UTILISATION.md créé et complet
✅ CHECKLIST_DEPLOIEMENT.md créé (ce fichier)
✅ Commentaires dans le code
✅ Migration SQL documentée
```

---

### 10. Déploiement production

#### 10.1 Préparer le build
```bash
cd /Users/mohamedahmedabdoulaye/Documents/mes-projets/epilist/app

# Android
flutter build apk --release --split-per-abi

# iOS
flutter build ios --release
```

#### 10.2 Version
**Fichier:** `/app/pubspec.yaml`
```yaml
# Vérifier la version
version: 1.1.4+20  # ← Incrémenter si nécessaire
```
✅ Version à jour

#### 10.3 Changelog
Créer un changelog des modifications:
```
Version 1.1.4:
- Ajout du scanner de codes-barres
- Nouvelle interface Material Design 3
- Animations fluides
- Suppression des emojis (code professionnel)
- Optimisation des performances
- Cache intelligent des produits
```
✅ Changelog créé

---

### 11. Post-déploiement

#### 11.1 Monitoring (24h après)
```
✅ Pas de crash reports
✅ Pas d'erreurs API
✅ Notifications fonctionnent
✅ Scanner utilisé par les utilisateurs
```

#### 11.2 Feedback utilisateurs
```
✅ Interface appréciée
✅ Scanner facile à utiliser
✅ Pas de bugs majeurs reportés
```

#### 11.3 Analytics
```
✅ Temps de chargement acceptable
✅ Taux de rétention stable/amélioré
✅ Taux d'utilisation du scanner
```

---

## 🚨 Rollback si problème

### Si problème avec la migration
```sql
-- Supprimer l'index
DROP INDEX idx_barcode ON list_items;

-- Supprimer la colonne
ALTER TABLE list_items DROP COLUMN barcode;

-- Supprimer la table de cache
DROP TABLE IF EXISTS scanned_products;

-- Restaurer le backup
mysql -u root epilist < backup_avant_migration_YYYYMMDD_HHMMSS.sql
```

### Si problème avec l'app
```bash
# Revenir au commit précédent
git log  # Noter le hash du commit avant les changements
git revert COMMIT_HASH

# Rebuild
flutter clean
flutter pub get
flutter build apk --release
```

---

## 📞 Support

En cas de problème:
1. Consulter les logs: `flutter logs`
2. Vérifier la base de données
3. Tester en mode debug
4. Consulter GUIDE_UTILISATION.md
5. Consulter AMELIORATIONS.md

---

## ✅ Validation finale

Date: _______________
Responsable: _______________

- [ ] Toutes les vérifications ci-dessus effectuées
- [ ] Tests passés avec succès
- [ ] Backup effectué
- [ ] Migration réussie
- [ ] Documentation à jour
- [ ] Prêt pour production

**Signature:** _______________

---

**Version du document:** 1.0
**Date de création:** 4 janvier 2025
**Dernière mise à jour:** 4 janvier 2025
