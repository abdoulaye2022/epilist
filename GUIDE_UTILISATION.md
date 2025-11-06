# Guide d'utilisation des nouvelles fonctionnalités EpiList

## Table des matières
1. [Scanner de codes-barres](#scanner-de-codes-barres)
2. [Thème Material Design 3](#thème-material-design-3)
3. [Animations modernes](#animations-modernes)
4. [Nouvelles cartes](#nouvelles-cartes)
5. [Migration base de données](#migration-base-de-données)

---

## 1. Scanner de codes-barres

### Intégration dans votre application

#### Étape 1: Importer les fichiers nécessaires
```dart
import 'package:epilist/screens/barcode_scanner_screen.dart';
import 'package:epilist/services/product_api_service.dart';
import 'package:epilist/models/product_info.dart';
import 'package:epilist/widgets/list_detail/product_info_dialog.dart';
```

#### Étape 2: Ouvrir le scanner
```dart
// Dans votre widget (ex: AddItemDialog)
Future<void> _scanBarcode(BuildContext context) async {
  // Ouvrir l'écran de scan
  final barcode = await Navigator.push<String>(
    context,
    MaterialPageRoute(
      builder: (context) => BarcodeScannerScreen(
        listId: widget.listId,
      ),
    ),
  );

  if (barcode != null) {
    // Le code-barres a été scanné
    await _handleScannedBarcode(barcode);
  }
}
```

#### Étape 3: Traiter le code-barres
```dart
Future<void> _handleScannedBarcode(String barcode) async {
  final apiService = ProductApiService();

  try {
    // Rechercher le produit sur OpenFoodFacts
    final product = await apiService.getProductByBarcode(barcode);

    if (product != null && mounted) {
      // Afficher les informations du produit
      await showDialog(
        context: context,
        builder: (context) => ProductInfoDialog(
          product: product,
          onAddToList: () {
            // Remplir le formulaire avec les données du produit
            _productNameController.text = product.displayName;
            _scannedBarcode = barcode;

            // Si le produit a un prix estimé, le pré-remplir
            // (peut être ajouté à l'API OpenFoodFacts dans le futur)
          },
        ),
      );
    } else {
      // Produit non trouvé
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produit non trouvé dans la base de données'),
        ),
      );
    }
  } catch (e) {
    // Erreur lors de la recherche
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur: $e')),
    );
  }
}
```

#### Exemple complet: Bouton de scan dans un formulaire
```dart
Row(
  children: [
    Expanded(
      child: TextFormField(
        controller: _productNameController,
        decoration: const InputDecoration(
          labelText: 'Nom du produit',
          hintText: 'Ex: Lait, Pain, Pommes...',
        ),
      ),
    ),
    const SizedBox(width: 8),
    IconButton(
      icon: const Icon(Icons.qr_code_scanner),
      onPressed: () => _scanBarcode(context),
      tooltip: 'Scanner un code-barres',
      style: IconButton.styleFrom(
        backgroundColor: Colors.green.withOpacity(0.1),
        foregroundColor: Colors.green,
      ),
    ),
  ],
),
```

---

## 2. Thème Material Design 3

### Application du thème

#### Dans main.dart
```dart
import 'package:epilist/config/app_theme.dart';

MaterialApp(
  title: 'EpiList',
  theme: AppTheme.lightTheme,  // Appliquer le thème
  // ... reste du code
);
```

### Utilisation des couleurs du thème

```dart
// Dans vos widgets
final theme = Theme.of(context);

Container(
  color: theme.colorScheme.primary,        // Vert principal
  child: Text(
    'Hello',
    style: theme.textTheme.titleLarge,     // Typography MD3
  ),
);
```

### Constantes d'espacement

```dart
import 'package:epilist/config/app_theme.dart';

Padding(
  padding: const EdgeInsets.all(AppTheme.spacingM),  // 16px
  child: Column(
    children: [
      // Contenu avec espacement cohérent
      const SizedBox(height: AppTheme.spacingL),  // 24px
      // ...
    ],
  ),
);
```

### Border radius cohérents

```dart
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppTheme.radiusL),  // 16px
    color: Colors.white,
  ),
);
```

---

## 3. Animations modernes

### FadeInAnimation

```dart
import 'package:epilist/widgets/animations/fade_in_animation.dart';

FadeInAnimation(
  duration: const Duration(milliseconds: 500),
  delay: const Duration(milliseconds: 100),
  child: YourWidget(),
);
```

### SlideInAnimation

```dart
import 'package:epilist/widgets/animations/fade_in_animation.dart';

SlideInAnimation(
  duration: const Duration(milliseconds: 500),
  offsetY: 50.0,  // Distance de départ en pixels
  child: YourWidget(),
);
```

### ScaleInAnimation

```dart
ScaleInAnimation(
  duration: const Duration(milliseconds: 500),
  startScale: 0.8,  // Commence à 80% de la taille
  curve: Curves.elasticOut,  // Animation rebondissante
  child: YourWidget(),
);
```

### Animation de liste échelonnée

```dart
StaggeredListAnimation(
  delayBetweenItems: const Duration(milliseconds: 100),
  itemDuration: const Duration(milliseconds: 500),
  children: [
    ModernListCard(...),
    ModernListCard(...),
    ModernListCard(...),
  ],
);
```

### Shimmer loading

```dart
// Placeholder pendant le chargement
if (isLoading)
  ShimmerCard(height: 100, width: double.infinity)
else
  YourActualWidget(),
```

---

## 4. Nouvelles cartes

### ModernListCard - Carte de liste d'épicerie

```dart
import 'package:epilist/widgets/cards/modern_list_card.dart';

ModernListCard(
  title: 'Courses de la semaine',
  subtitle: 'Créée il y a 2 jours',
  itemCount: 15,
  completedCount: 8,
  totalAmount: 125.50,
  isShared: true,
  collaboratorCount: 3,
  onTap: () {
    // Navigation vers les détails
  },
  onLongPress: () {
    // Afficher le menu contextuel
  },
  gradientColors: [
    Colors.white,
    Colors.green.withOpacity(0.05),
  ],
);
```

### ModernListItemCard - Carte d'article

```dart
ModernListItemCard(
  productName: 'Lait 2%',
  quantity: 2,
  price: 5.99,
  store: 'Metro',
  isPurchased: false,
  onToggle: () {
    // Marquer comme acheté
  },
  onEdit: () {
    // Éditer l'article
  },
  onDelete: () {
    // Supprimer l'article
  },
);
```

### Exemple avec animations

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return SlideInAnimation(
      delay: Duration(milliseconds: index * 50),
      child: ModernListItemCard(
        productName: items[index].name,
        quantity: items[index].quantity,
        // ...
      ),
    );
  },
);
```

---

## 5. Migration base de données

### Exécution de la migration

#### Option 1: Ligne de commande
```bash
cd /api/migrations
mysql -u root epilist < add_barcode_to_list_items.sql
```

#### Option 2: phpMyAdmin
1. Ouvrir phpMyAdmin
2. Sélectionner la base de données `epilist`
3. Aller dans l'onglet SQL
4. Copier-coller le contenu de `add_barcode_to_list_items.sql`
5. Cliquer sur "Exécuter"

### Vérification après migration

```sql
-- Vérifier la colonne barcode
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'list_items'
AND COLUMN_NAME = 'barcode';

-- Vérifier la table scanned_products
SELECT COUNT(*) FROM scanned_products;
```

### Modification du modèle ListItem.php

```php
// Dans /api/src/Models/ListItem.php

protected $fillable = [
    'shopping_list_id',
    'product_name',
    'barcode',        // ← AJOUTER CETTE LIGNE
    'quantity',
    'price',
    'store_name',
    'is_purchased',
];
```

### Modification du controller

```php
// Dans /api/src/Controllers/ListItemController.php
// Méthode store()

public function store(Request $request, Response $response, array $args): Response
{
    $validated = $this->validate($request, [
        'product_name' => 'required|string|min:2|max:255',
        'barcode' => 'nullable|string|max:50',  // ← AJOUTER
        'quantity' => 'required|integer|min:1|max:999',
        'price' => 'nullable|numeric|min:0|max:999999.99',
        'store_name' => 'nullable|string|min:2|max:255',
    ]);

    $item = ListItem::create([
        'shopping_list_id' => $listId,
        'product_name' => $validated['product_name'],
        'barcode' => $validated['barcode'] ?? null,  // ← AJOUTER
        'quantity' => $validated['quantity'],
        'price' => $validated['price'] ?? null,
        'store_name' => $validated['store_name'] ?? null,
    ]);

    // ...
}
```

---

## Exemples d'utilisation complète

### Exemple 1: Écran de liste avec animations

```dart
class ShoppingListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes listes'),
      ),
      body: BlocBuilder<ShoppingListBloc, ShoppingListState>(
        builder: (context, state) {
          if (state is ShoppingListLoading) {
            return ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                return ShimmerCard(height: 150);
              },
            );
          }

          if (state is ShoppingListLoaded) {
            return StaggeredListAnimation(
              children: state.lists.map((list) {
                return ModernListCard(
                  title: list.name,
                  itemCount: list.itemCount,
                  completedCount: list.completedCount,
                  totalAmount: list.totalAmount,
                  isShared: list.isShared,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/list-detail',
                      arguments: list.id,
                    );
                  },
                );
              }).toList(),
            );
          }

          return const Center(child: Text('Aucune liste'));
        },
      ),
      floatingActionButton: ScaleInAnimation(
        delay: const Duration(milliseconds: 500),
        child: FloatingActionButton.extended(
          onPressed: () {
            // Créer une nouvelle liste
          },
          icon: const Icon(Icons.add),
          label: const Text('Nouvelle liste'),
        ),
      ),
    );
  }
}
```

### Exemple 2: Formulaire avec scan

```dart
class AddItemDialog extends StatefulWidget {
  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _productController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  String? _scannedBarcode;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ajouter un article',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Nom du produit avec bouton scan
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _productController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du produit',
                      hintText: 'Ex: Lait, Pain...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scanBarcode,
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingM),

            // Autres champs...
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantité',
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: AppTheme.spacingL),

            // Boutons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Ajouter'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerScreen(
          listId: widget.listId,
        ),
      ),
    );

    if (barcode != null) {
      final apiService = ProductApiService();
      final product = await apiService.getProductByBarcode(barcode);

      if (product != null && mounted) {
        setState(() {
          _productController.text = product.displayName;
          _scannedBarcode = barcode;
        });
      }
    }
  }

  void _submit() {
    // Envoyer à l'API avec le barcode
    context.read<ListItemBloc>().add(
      AddListItem(
        productName: _productController.text,
        quantity: int.parse(_quantityController.text),
        price: double.tryParse(_priceController.text),
        barcode: _scannedBarcode,  // ← Inclure le barcode
      ),
    );
    Navigator.pop(context);
  }
}
```

---

## Bonnes pratiques

### 1. Animations
- Utilisez des animations cohérentes (300-500ms)
- N'abusez pas des animations (risque de ralentir l'app)
- Utilisez le shimmer pour les chargements longs

### 2. Thème
- Utilisez toujours `Theme.of(context)` au lieu de couleurs hard-codées
- Utilisez les constantes d'espacement `AppTheme.spacingX`
- Utilisez les constantes de border radius `AppTheme.radiusX`

### 3. Performance
- Utilisez `const` partout où possible
- Évitez de recréer des widgets inutilement
- Utilisez `ListView.builder` pour les longues listes

### 4. Scanner
- Gérez toujours les permissions caméra
- Affichez un message clair si le produit n'est pas trouvé
- Proposez la saisie manuelle comme alternative

---

## Dépannage

### Le scanner ne fonctionne pas
1. Vérifiez les permissions dans `AndroidManifest.xml` et `Info.plist`
2. Testez sur un appareil réel (pas l'émulateur)
3. Vérifiez que la caméra fonctionne

### Les animations sont saccadées
1. Activez le mode release: `flutter run --release`
2. Réduisez la durée des animations
3. Évitez les animations multiples simultanées

### Le thème ne s'applique pas
1. Vérifiez que vous utilisez `AppTheme.lightTheme` dans `MaterialApp`
2. Redémarrez l'application complètement
3. Vérifiez que vous utilisez `Theme.of(context)`

---

**Date de création:** 4 janvier 2025
**Version:** 1.1.4
**Auteur:** EpiList Development Team
