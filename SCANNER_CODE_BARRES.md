# 📱 Scanner de Code-Barres EpiList

## 🎯 Fonctionnalité

Le scanner de code-barres permet d'ajouter rapidement des produits à votre liste de courses en scannant simplement leur code-barres. L'application récupère automatiquement les informations du produit depuis la base de données Open Food Facts.

## ✨ Fonctionnalités

### 1. Scanner Intégré
- **Caméra en temps réel** avec animation de ligne de scan
- **Détection automatique** des codes-barres (EAN-13, UPC, etc.)
- **Torche/Flash** pour scanner dans des conditions de faible luminosité
- **Changement de caméra** (avant/arrière)
- **Feedback visuel** lors de la détection

### 2. Intégration Open Food Facts
- **Base de données mondiale** de produits alimentaires
- **Informations complètes** : nom, marque, quantité, image, nutriments
- **API gratuite** et collaborative
- **Support multilingue** (français, anglais, etc.)

### 3. Dialogue de Confirmation
- **Image du produit** en haute résolution
- **Informations détaillées** : marque, contenance, code-barres
- **Actions** : Confirmer ou annuler l'ajout

## 📖 Comment utiliser

### Sur appareil réel (téléphone/tablette)

1. **Ouvrir le dialogue d'ajout d'article**
   - Cliquez sur le bouton  "+" dans une liste

2. **Lancer le scanner**
   - Cliquez sur le bouton "Scanner un code-barres" (icône QR code)

3. **Scanner le produit**
   - Pointez la caméra vers le code-barres
   - Maintenez l'appareil stable
   - Le scan se fait automatiquement

4. **Confirmer le produit**
   - Un dialogue s'affiche avec l'image et les informations
   - Cliquez sur "Ajouter à la liste" pour confirmer
   - Ou "Annuler" pour recommencer

5. **Finaliser l'ajout**
   - Le nom du produit est automatiquement rempli
   - Ajustez la quantité et le prix si nécessaire
   - Cliquez sur "Ajouter"

### Sur simulateur/émulateur

Sur un simulateur iOS/Android, le scanner photo n'est pas disponible. Un dialogue de saisie manuelle du code-barres apparaît à la place.

1. **Entrer le code-barres manuellement**
   - Tapez un code-barres valide (ex: 3017620422003 pour Nutella)
   - Cliquez sur "Rechercher"

2. **Le reste du processus est identique** à l'utilisation sur appareil réel

## 🛠️ Technologies utilisées

- **mobile_scanner** : Package Flutter pour scanner les codes-barres
- **Open Food Facts API** : API REST pour récupérer les informations produits
- **HTTP** : Communication avec l'API
- **Cached Network Image** : Chargement optimisé des images

## 🔧 Configuration requise

### Permissions

#### iOS (`Info.plist`)
```xml
<key>NSCameraUsageDescription</key>
<string>EpiList a besoin d'accéder à votre caméra pour scanner les codes-barres des produits</string>
```

#### Android (`AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
```

### Dépendances (`pubspec.yaml`)
```yaml
dependencies:
  mobile_scanner: ^5.2.3
  http: ^1.2.0
  equatable: ^2.0.7
```

## 📝 Exemples de codes-barres pour tester

Voici quelques codes-barres valides dans Open Food Facts :

| Produit | Code-barres | Marque |
|---------|-------------|--------|
| Nutella | 3017620422003 | Ferrero |
| Coca-Cola | 5449000000996 | Coca-Cola |
| Kit Kat | 7622300489434 | Nestlé |
| Pringles Original | 5053990102426 | Pringles |
| Danone Activia | 3033490004378 | Danone |

## 🐛 Dépannage

### Le scanner ne se lance pas
- **Vérifiez les permissions** : L'app doit avoir accès à la caméra
- **Redémarrez l'app** après avoir accordé les permissions
- **Sur simulateur** : Utilisez le dialogue de saisie manuelle

### Le code-barres n'est pas détecté
- **Améliorez l'éclairage** : Utilisez la torche
- **Tenez l'appareil stable** : Évitez les mouvements brusques
- **Distance optimale** : 10-20 cm du code-barres
- **Nettoyez la lentille** de la caméra

### Produit non trouvé
- **Vérifiez le code-barres** : Certains produits ne sont pas dans Open Food Facts
- **Contribuez à Open Food Facts** : Ajoutez le produit vous-même
- **Utilisez la saisie manuelle** : Ajoutez le produit sans scanner

### Erreur de connexion
- **Vérifiez votre connexion Internet** : L'API nécessite une connexion
- **Réessayez** : L'API peut parfois être lente
- **Patientez** : Un timeout de 10 secondes est configuré

## 🚀 Améliorations futures

### Court terme
- ✅ Dialogue de confirmation avec image
- ⏳ Sauvegarder le code-barres dans la base de données
- ⏳ Afficher l'historique des scans
- ⏳ Cache des produits scannés

### Long terme
- ⏳ Scanner plusieurs produits d'affilée
- ⏳ Détection automatique des promotions
- ⏳ Comparaison de prix entre magasins
- ⏳ Scanner les tickets de caisse
- ⏳ Mode hors ligne avec cache

## 📚 Ressources

- [Open Food Facts](https://world.openfoodfacts.org/)
- [API Documentation](https://openfoodfacts.github.io/openfoodfacts-server/api/)
- [mobile_scanner Package](https://pub.dev/packages/mobile_scanner)
- [Contribuer à Open Food Facts](https://world.openfoodfacts.org/contribute)

## 👥 Contribution

Pour contribuer à l'amélioration du scanner :

1. Testez avec différents types de codes-barres
2. Signalez les bugs sur GitHub
3. Proposez des améliorations
4. Ajoutez des produits manquants sur Open Food Facts

---

**Note** : Open Food Facts est un projet collaboratif. Si un produit n'est pas trouvé, vous pouvez l'ajouter sur [openfoodfacts.org](https://world.openfoodfacts.org/) pour aider la communauté !
