# ⚡ Démarrage Ultra-Rapide - EpiList v1.1.4

## 🎯 En 3 commandes (5 minutes)

```bash
# 1. Vérifier que tout est prêt
./verify_setup.sh

# 2. Exécuter la migration de la base de données
mysql -u root epilist < api/migrations/add_barcode_to_list_items.sql

# 3. Lancer l'application
cd app && flutter run
```

## ✅ C'est tout!

Votre application EpiList est maintenant prête avec:
- ✅ Scanner de codes-barres
- ✅ Interface Material Design 3
- ✅ Animations fluides
- ✅ Code professionnel (sans emojis)

---

## 📚 Pour en savoir plus

| Besoin | Document |
|--------|----------|
| Vue d'ensemble complète | [README_AMELIORATIONS.md](./README_AMELIORATIONS.md) |
| Détails techniques | [AMELIORATIONS.md](./AMELIORATIONS.md) |
| Exemples de code | [GUIDE_UTILISATION.md](./GUIDE_UTILISATION.md) |
| Checklist déploiement | [CHECKLIST_DEPLOIEMENT.md](./CHECKLIST_DEPLOIEMENT.md) |

---

## 🔧 Configuration minimale requise

### 1. Ajouter dans `/api/src/Models/ListItem.php`:
```php
'barcode',  // ← Dans $fillable
```

### 2. Permissions Android (`AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### 3. Permissions iOS (`Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>EpiList a besoin de la caméra pour scanner les codes-barres</string>
```

---

## 🎨 Utiliser le nouveau thème (optionnel)

Dans `/app/lib/main.dart`:
```dart
import 'package:epilist/config/app_theme.dart';

MaterialApp(
  theme: AppTheme.lightTheme,  // ← Ajouter cette ligne
  // ...
)
```

---

## 🐛 Problème?

```bash
# Nettoyer et réinstaller
cd app
flutter clean
flutter pub get
flutter run
```

---

**Temps total: 5 minutes** ⏱️
**Difficulté: Facile** 🟢
**Risque: Très faible** ✅
