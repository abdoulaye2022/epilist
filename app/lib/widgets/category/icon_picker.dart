// widgets/category/icon_picker.dart
import 'package:epilist/theme/app_theme.dart';
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
      {'code': 'restaurant', 'label': 'Restaurant', 'labelEn': 'Restaurant'},
      {'code': 'local_dining', 'label': 'Couverts', 'labelEn': 'Cutlery'},
      {'code': 'fastfood', 'label': 'Fast Food', 'labelEn': 'Fast food'},
      {'code': 'lunch_dining', 'label': 'Déjeuner', 'labelEn': 'Lunch'},
      {'code': 'dinner_dining', 'label': 'Dîner', 'labelEn': 'Dinner'},
      {'code': 'breakfast_dining', 'label': 'Petit-déjeuner', 'labelEn': 'Breakfast'},
      {'code': 'local_pizza', 'label': 'Pizza', 'labelEn': 'Pizza'},
      {'code': 'local_cafe', 'label': 'Café', 'labelEn': 'Coffee'},
      {'code': 'local_bar', 'label': 'Bar', 'labelEn': 'Bar'},
      {'code': 'bakery_dining', 'label': 'Boulangerie', 'labelEn': 'Bakery'},
      {'code': 'icecream', 'label': 'Glace', 'labelEn': 'Ice cream'},
      {'code': 'cake', 'label': 'Gâteau', 'labelEn': 'Cake'},
      {'code': 'apple', 'label': 'Pomme', 'labelEn': 'Apple'},
      {'code': 'egg', 'label': 'Œuf', 'labelEn': 'Egg'},
      {'code': 'set_meal', 'label': 'Repas', 'labelEn': 'Meal'},
      {'code': 'ramen_dining', 'label': 'Ramen', 'labelEn': 'Ramen'},
    ],
    'Shopping': [
      {'code': 'shopping_cart', 'label': 'Panier', 'labelEn': 'Cart'},
      {'code': 'shopping_bag', 'label': 'Sac', 'labelEn': 'Bag'},
      {'code': 'local_grocery_store', 'label': 'Épicerie', 'labelEn': 'Grocery'},
      {'code': 'store', 'label': 'Magasin', 'labelEn': 'Store'},
      {'code': 'storefront', 'label': 'Devanture', 'labelEn': 'Storefront'},
      {'code': 'local_mall', 'label': 'Centre commercial', 'labelEn': 'Mall'},
      {'code': 'shopping_basket', 'label': 'Panier', 'labelEn': 'Cart'},
    ],
    'Maison': [
      {'code': 'home', 'label': 'Maison', 'labelEn': 'Home'},
      {'code': 'house', 'label': 'Maison 2', 'labelEn': 'House'},
      {'code': 'cottage', 'label': 'Cottage', 'labelEn': 'Cottage'},
      {'code': 'light', 'label': 'Lumière', 'labelEn': 'Light'},
      {'code': 'bed', 'label': 'Lit', 'labelEn': 'Bed'},
      {'code': 'chair', 'label': 'Chaise', 'labelEn': 'Chair'},
      {'code': 'table_restaurant', 'label': 'Table', 'labelEn': 'Table'},
      {'code': 'kitchen', 'label': 'Cuisine', 'labelEn': 'Kitchen'},
      {'code': 'bathtub', 'label': 'Baignoire', 'labelEn': 'Bathtub'},
      {'code': 'shower', 'label': 'Douche', 'labelEn': 'Shower'},
    ],
    'Hygiène': [
      {'code': 'cleaning_services', 'label': 'Nettoyage', 'labelEn': 'Cleaning'},
      {'code': 'clean_hands', 'label': 'Mains propres', 'labelEn': 'Clean hands'},
      {'code': 'soap', 'label': 'Savon', 'labelEn': 'Soap'},
      {'code': 'face', 'label': 'Visage', 'labelEn': 'Face'},
      {'code': 'spa', 'label': 'Spa', 'labelEn': 'Spa'},
      {'code': 'sanitizer', 'label': 'Désinfectant', 'labelEn': 'Sanitizer'},
    ],
    'Santé': [
      {'code': 'medical_services', 'label': 'Médical', 'labelEn': 'Medical'},
      {'code': 'medication', 'label': 'Médicament', 'labelEn': 'Medication'},
      {'code': 'vaccines', 'label': 'Vaccin', 'labelEn': 'Vaccine'},
      {'code': 'health_and_safety', 'label': 'Santé', 'labelEn': 'Health'},
      {'code': 'favorite', 'label': 'Cœur', 'labelEn': 'Heart'},
      {'code': 'monitor_heart', 'label': 'Moniteur', 'labelEn': 'Monitor'},
    ],
    'Animaux': [
      {'code': 'pets', 'label': 'Animaux', 'labelEn': 'Pets'},
      {'code': 'pet_supplies', 'label': 'Fournitures', 'labelEn': 'Supplies'},
    ],
    'Bébé': [
      {'code': 'child_care', 'label': 'Garde d\'enfant'},
      {'code': 'baby_changing_station', 'label': 'Change bébé', 'labelEn': 'Diaper change'},
      {'code': 'toys', 'label': 'Jouets', 'labelEn': 'Toys'},
      {'code': 'stroller', 'label': 'Poussette', 'labelEn': 'Stroller'},
    ],
    'Autre': [
      {'code': 'category', 'label': 'Catégorie', 'labelEn': 'Category'},
      {'code': 'label', 'label': 'Étiquette', 'labelEn': 'Label'},
      {'code': 'eco', 'label': 'Écologie', 'labelEn': 'Eco'},
      {'code': 'emoji_nature', 'label': 'Nature', 'labelEn': 'Nature'},
      {'code': 'stars', 'label': 'Étoiles', 'labelEn': 'Stars'},
      {'code': 'auto_awesome', 'label': 'Génial', 'labelEn': 'Awesome'},
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
                _groupLabel(context, entry.key),
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
          (icon['labelEn'] ?? '').toLowerCase().contains(_searchQuery) ||
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
              : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? theme.primaryColor : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Icon(
          Category.getIconDataFromCode(icon['code']!),
          color: isSelected ? theme.primaryColor : AppColors.textSecondary,
          size: 28,
        ),
      ),
    );
  }
  /// Libellé de l'icône dans la langue de l'appareil.
  String _labelFor(Map<String, String> icon) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    return (isEn ? icon['labelEn'] : icon['label']) ?? icon['label'] ?? '';
  }

  static const Map<String, String> _groupEn = {
    'Nourriture': 'Food',
    'Shopping': 'Shopping',
    'Maison': 'Home',
    'Hygiène': 'Hygiene',
    'Santé': 'Health',
    'Animaux': 'Pets',
    'Bébé': 'Baby',
    'Autres': 'Other',
    'Divers': 'Other',
    'Autre': 'Other',
  };

  String _groupLabel(BuildContext context, String key) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    return isEn ? (_groupEn[key] ?? key) : key;
  }

}
