// widgets/category/icon_picker.dart
import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../l10n/app_localizations.dart';

class IconPickerDialog extends StatefulWidget {
  final String selectedIconCode;

  const IconPickerDialog({
    Key? key,
    required this.selectedIconCode,
  }) : super(key: key);

  @override
  State<IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<IconPickerDialog> {
  late String _selectedIconCode;
  String _searchQuery = '';

  // Liste des icônes populaires par catégorie
  final Map<String, List<Map<String, String>>> _iconCategories = {
    'Nourriture': [
      {'code': 'restaurant', 'label': 'Restaurant'},
      {'code': 'local_dining', 'label': 'Couverts'},
      {'code': 'fastfood', 'label': 'Fast Food'},
      {'code': 'lunch_dining', 'label': 'Déjeuner'},
      {'code': 'dinner_dining', 'label': 'Dîner'},
      {'code': 'breakfast_dining', 'label': 'Petit-déjeuner'},
      {'code': 'local_pizza', 'label': 'Pizza'},
      {'code': 'local_cafe', 'label': 'Café'},
      {'code': 'local_bar', 'label': 'Bar'},
      {'code': 'bakery_dining', 'label': 'Boulangerie'},
      {'code': 'icecream', 'label': 'Glace'},
      {'code': 'cake', 'label': 'Gâteau'},
      {'code': 'apple', 'label': 'Pomme'},
      {'code': 'egg', 'label': 'Œuf'},
      {'code': 'set_meal', 'label': 'Repas'},
      {'code': 'ramen_dining', 'label': 'Ramen'},
    ],
    'Shopping': [
      {'code': 'shopping_cart', 'label': 'Panier'},
      {'code': 'shopping_bag', 'label': 'Sac'},
      {'code': 'local_grocery_store', 'label': 'Épicerie'},
      {'code': 'store', 'label': 'Magasin'},
      {'code': 'storefront', 'label': 'Devanture'},
      {'code': 'local_mall', 'label': 'Centre commercial'},
      {'code': 'shopping_basket', 'label': 'Panier'},
    ],
    'Maison': [
      {'code': 'home', 'label': 'Maison'},
      {'code': 'house', 'label': 'Maison 2'},
      {'code': 'cottage', 'label': 'Cottage'},
      {'code': 'light', 'label': 'Lumière'},
      {'code': 'bed', 'label': 'Lit'},
      {'code': 'chair', 'label': 'Chaise'},
      {'code': 'table_restaurant', 'label': 'Table'},
      {'code': 'kitchen', 'label': 'Cuisine'},
      {'code': 'bathtub', 'label': 'Baignoire'},
      {'code': 'shower', 'label': 'Douche'},
    ],
    'Hygiène': [
      {'code': 'cleaning_services', 'label': 'Nettoyage'},
      {'code': 'clean_hands', 'label': 'Mains propres'},
      {'code': 'soap', 'label': 'Savon'},
      {'code': 'face', 'label': 'Visage'},
      {'code': 'spa', 'label': 'Spa'},
      {'code': 'sanitizer', 'label': 'Désinfectant'},
    ],
    'Santé': [
      {'code': 'medical_services', 'label': 'Médical'},
      {'code': 'medication', 'label': 'Médicament'},
      {'code': 'vaccines', 'label': 'Vaccin'},
      {'code': 'health_and_safety', 'label': 'Santé'},
      {'code': 'favorite', 'label': 'Cœur'},
      {'code': 'monitor_heart', 'label': 'Moniteur'},
    ],
    'Animaux': [
      {'code': 'pets', 'label': 'Animaux'},
      {'code': 'pet_supplies', 'label': 'Fournitures'},
    ],
    'Bébé': [
      {'code': 'child_care', 'label': 'Garde d\'enfant'},
      {'code': 'baby_changing_station', 'label': 'Change bébé'},
      {'code': 'toys', 'label': 'Jouets'},
      {'code': 'stroller', 'label': 'Poussette'},
    ],
    'Autre': [
      {'code': 'category', 'label': 'Catégorie'},
      {'code': 'label', 'label': 'Étiquette'},
      {'code': 'eco', 'label': 'Écologie'},
      {'code': 'emoji_nature', 'label': 'Nature'},
      {'code': 'stars', 'label': 'Étoiles'},
      {'code': 'auto_awesome', 'label': 'Génial'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedIconCode = widget.selectedIconCode;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.category,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.selectIcon,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Barre de recherche
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: l10n.searchIcon,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),

            // Grille d'icônes
            Expanded(
              child: _searchQuery.isEmpty
                  ? _buildCategorizedIcons(theme)
                  : _buildSearchResults(theme, l10n),
            ),

            // Boutons d'action
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(_selectedIconCode);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(l10n.select),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorizedIcons(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: _iconCategories.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                entry.key,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: entry.value.length,
              itemBuilder: (context, index) {
                final icon = entry.value[index];
                return _buildIconTile(icon, theme);
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSearchResults(ThemeData theme, AppLocalizations l10n) {
    final allIcons = <Map<String, String>>[];
    for (var category in _iconCategories.values) {
      allIcons.addAll(category);
    }

    final filteredIcons = allIcons.where((icon) {
      return icon['label']!.toLowerCase().contains(_searchQuery) ||
          icon['code']!.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredIcons.isEmpty) {
      return Center(
        child: Text(l10n.noIconFound),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: filteredIcons.length,
      itemBuilder: (context, index) {
        return _buildIconTile(filteredIcons[index], theme);
      },
    );
  }

  Widget _buildIconTile(Map<String, String> icon, ThemeData theme) {
    final isSelected = _selectedIconCode == icon['code'];

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIconCode = icon['code']!;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withValues(alpha: 0.2)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Icon(
          Category.getIconDataFromCode(icon['code']!),
          color: isSelected ? theme.primaryColor : Colors.grey[700],
          size: 28,
        ),
      ),
    );
  }
}
