// widgets/list_detail/item_filters_bar.dart - DESIGN INSPIRÉ DE BUDGET_FILTERS
import 'package:flutter/material.dart';
import 'package:epilist/models/list_item.dart';
import 'package:epilist/l10n/app_localizations.dart';

enum ItemSortBy {
  name,
  price,
  store,
  dateAdded,
}

class ItemFilterCriteria {
  String? storeName;
  double? minPrice;
  double? maxPrice;
  int? categoryId;
  ItemSortBy sortBy;
  bool ascending;
  bool showOnlyPurchased;
  bool showOnlyUnpurchased;

  ItemFilterCriteria({
    this.storeName,
    this.minPrice,
    this.maxPrice,
    this.categoryId,
    this.sortBy = ItemSortBy.dateAdded,
    this.ascending = true,
    this.showOnlyPurchased = false,
    this.showOnlyUnpurchased = false,
  });

  bool get hasActiveFilters =>
      storeName != null ||
      minPrice != null ||
      maxPrice != null ||
      categoryId != null ||
      showOnlyPurchased ||
      showOnlyUnpurchased;

  int get activeFiltersCount {
    int count = 0;
    if (storeName != null) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (categoryId != null) count++;
    if (showOnlyPurchased || showOnlyUnpurchased) count++;
    return count;
  }

  List<ListItem> apply(List<ListItem> items) {
    List<ListItem> filtered = List.from(items);

    // Filtrer par magasin
    if (storeName != null && storeName!.isNotEmpty) {
      filtered = filtered
          .where((item) =>
              item.storeName != null &&
              item.storeName!.toLowerCase().contains(storeName!.toLowerCase()))
          .toList();
    }

    // Filtrer par prix minimum
    if (minPrice != null) {
      filtered = filtered
          .where((item) => item.price != null && item.price! >= minPrice!)
          .toList();
    }

    // Filtrer par prix maximum
    if (maxPrice != null) {
      filtered = filtered
          .where((item) => item.price != null && item.price! <= maxPrice!)
          .toList();
    }

    // Filtrer par catégorie
    if (categoryId != null) {
      filtered = filtered
          .where((item) => item.categoryId == categoryId)
          .toList();
    }

    // Filtrer par statut d'achat
    if (showOnlyPurchased) {
      filtered = filtered.where((item) => item.isPurchased).toList();
    }
    if (showOnlyUnpurchased) {
      filtered = filtered.where((item) => !item.isPurchased).toList();
    }

    // Trier
    filtered.sort((a, b) {
      int comparison = 0;

      switch (sortBy) {
        case ItemSortBy.name:
          comparison = a.productName.compareTo(b.productName);
          break;
        case ItemSortBy.price:
          final priceA = a.price ?? 0;
          final priceB = b.price ?? 0;
          comparison = priceA.compareTo(priceB);
          break;
        case ItemSortBy.store:
          final storeA = a.storeName ?? '';
          final storeB = b.storeName ?? '';
          comparison = storeA.compareTo(storeB);
          break;
        case ItemSortBy.dateAdded:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
      }

      return ascending ? comparison : -comparison;
    });

    return filtered;
  }
}

class ItemFiltersBar extends StatefulWidget {
  final ItemFilterCriteria criteria;
  final ValueChanged<ItemFilterCriteria> onCriteriaChanged;
  final List<String> availableStores;
  final List<Map<String, dynamic>> availableCategories;

  const ItemFiltersBar({
    super.key,
    required this.criteria,
    required this.onCriteriaChanged,
    required this.availableStores,
    this.availableCategories = const [],
  });

  @override
  State<ItemFiltersBar> createState() => _ItemFiltersBarState();
}

class _ItemFiltersBarState extends State<ItemFiltersBar> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasActiveFilters = widget.criteria.hasActiveFilters;
    final themeColor = Theme.of(context).primaryColor;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // En-tête avec bouton d'expansion (identique à budget_filters)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: hasActiveFilters ? themeColor : Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.filtersAndSort,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: hasActiveFilters ? themeColor : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  // Badge avec compteur (identique à budget_filters)
                  if (hasActiveFilters) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.criteria.activeFiltersCount.toString(),
                        style: TextStyle(
                          color: themeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _clearAllFilters,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.clear,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),

          if (_isExpanded) ...[
            const Divider(height: 1, color: Colors.grey),
            // ConstrainedBox pour éviter l'overflow (identique à budget_filters)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tri (style vertical identique à budget_filters)
                    _buildFilterSection(l10n.sortBy, _buildSortOptions()),
                    const SizedBox(height: 16),

                    // Filtre par magasin
                    _buildFilterSection(
                        l10n.filterByStore, _buildStoreFilter()),
                    const SizedBox(height: 16),

                    // Filtre par catégorie
                    if (widget.availableCategories.isNotEmpty)
                      _buildFilterSection('Catégorie', _buildCategoryFilter()),
                    if (widget.availableCategories.isNotEmpty)
                      const SizedBox(height: 16),

                    // Filtre par statut
                    _buildFilterSection(l10n.status, _buildStatusFilters()),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterSection(String title, Widget content) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  // Options de tri en style vertical (identique à budget_filters)
  Widget _buildSortOptions() {
    final l10n = AppLocalizations.of(context)!;
    final sortOptions = [
      {'key': ItemSortBy.name, 'label': l10n.sortByName, 'icon': Icons.sort_by_alpha},
      {'key': ItemSortBy.price, 'label': l10n.sortByPrice, 'icon': Icons.attach_money},
      {'key': ItemSortBy.store, 'label': l10n.sortByStore, 'icon': Icons.store},
      {
        'key': ItemSortBy.dateAdded,
        'label': l10n.sortByDateAdded,
        'icon': Icons.calendar_today
      },
    ];

    final themeColor = Theme.of(context).primaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: sortOptions.map((option) {
        final isActive = widget.criteria.sortBy == option['key'];
        final isAscending = widget.criteria.ascending;

        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (isActive) {
                  // Inverser l'ordre
                  widget.onCriteriaChanged(
                    ItemFilterCriteria(
                      storeName: widget.criteria.storeName,
                      minPrice: widget.criteria.minPrice,
                      maxPrice: widget.criteria.maxPrice,
                      categoryId: widget.criteria.categoryId,
                      sortBy: option['key'] as ItemSortBy,
                      ascending: !isAscending,
                      showOnlyPurchased: widget.criteria.showOnlyPurchased,
                      showOnlyUnpurchased: widget.criteria.showOnlyUnpurchased,
                    ),
                  );
                } else {
                  // Activer ce tri
                  widget.onCriteriaChanged(
                    ItemFilterCriteria(
                      storeName: widget.criteria.storeName,
                      minPrice: widget.criteria.minPrice,
                      maxPrice: widget.criteria.maxPrice,
                      categoryId: widget.criteria.categoryId,
                      sortBy: option['key'] as ItemSortBy,
                      ascending: true,
                      showOnlyPurchased: widget.criteria.showOnlyPurchased,
                      showOnlyUnpurchased: widget.criteria.showOnlyUnpurchased,
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? themeColor.withValues(alpha: 0.1)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: isActive
                      ? Border.all(
                          color: themeColor,
                          width: 2,
                        )
                      : Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      option['icon'] as IconData,
                      size: 20,
                      color: isActive ? themeColor : Colors.grey[600],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option['label'] as String,
                        style: TextStyle(
                          color: isActive ? themeColor : Colors.black87,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 16,
                          color: themeColor,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStoreFilter() {
    final l10n = AppLocalizations.of(context)!;
    if (widget.availableStores.isEmpty) {
      return Text(
        l10n.noStoresAvailable,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          label: l10n.allStores,
          value: null,
          activeValue: widget.criteria.storeName,
          onChanged: (value) {
            widget.onCriteriaChanged(
              ItemFilterCriteria(
                storeName: value,
                minPrice: widget.criteria.minPrice,
                maxPrice: widget.criteria.maxPrice,
                sortBy: widget.criteria.sortBy,
                ascending: widget.criteria.ascending,
                showOnlyPurchased: widget.criteria.showOnlyPurchased,
                showOnlyUnpurchased: widget.criteria.showOnlyUnpurchased,
              ),
            );
          },
        ),
        ...widget.availableStores.map(
          (store) => _buildFilterChip(
            label: store,
            value: store,
            activeValue: widget.criteria.storeName,
            onChanged: (value) {
              widget.onCriteriaChanged(
                ItemFilterCriteria(
                  storeName: value,
                  minPrice: widget.criteria.minPrice,
                  maxPrice: widget.criteria.maxPrice,
                  categoryId: widget.criteria.categoryId,
                  sortBy: widget.criteria.sortBy,
                  ascending: widget.criteria.ascending,
                  showOnlyPurchased: widget.criteria.showOnlyPurchased,
                  showOnlyUnpurchased: widget.criteria.showOnlyUnpurchased,
                ),
              );
            },
            icon: Icons.store,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusFilters() {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          label: l10n.purchased,
          value: 'purchased',
          activeValue:
              widget.criteria.showOnlyPurchased ? 'purchased' : null,
          onChanged: (value) {
            widget.onCriteriaChanged(
              ItemFilterCriteria(
                storeName: widget.criteria.storeName,
                minPrice: widget.criteria.minPrice,
                maxPrice: widget.criteria.maxPrice,
                categoryId: widget.criteria.categoryId,
                sortBy: widget.criteria.sortBy,
                ascending: widget.criteria.ascending,
                showOnlyPurchased: value == 'purchased',
                showOnlyUnpurchased: false,
              ),
            );
          },
          icon: Icons.check_circle,
          color: Colors.green[600],
        ),
        _buildFilterChip(
          label: l10n.unpurchased,
          value: 'unpurchased',
          activeValue:
              widget.criteria.showOnlyUnpurchased ? 'unpurchased' : null,
          onChanged: (value) {
            widget.onCriteriaChanged(
              ItemFilterCriteria(
                storeName: widget.criteria.storeName,
                minPrice: widget.criteria.minPrice,
                maxPrice: widget.criteria.maxPrice,
                categoryId: widget.criteria.categoryId,
                sortBy: widget.criteria.sortBy,
                ascending: widget.criteria.ascending,
                showOnlyPurchased: false,
                showOnlyUnpurchased: value == 'unpurchased',
              ),
            );
          },
          icon: Icons.radio_button_unchecked,
          color: Colors.orange[600],
        ),
      ],
    );
  }

  // Widget de chip identique à budget_filters
  Widget _buildFilterChip({
    required String label,
    required String? value,
    required String? activeValue,
    required Function(String?) onChanged,
    IconData? icon,
    Color? color,
  }) {
    final isActive = (value == null && activeValue == null) ||
        (value != null && value == activeValue);

    final themeColor = Theme.of(context).primaryColor;
    final chipColor = color ?? themeColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isActive) {
            onChanged(null);
          } else {
            onChanged(value);
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? chipColor : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? chipColor : Colors.grey[300]!,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isActive ? Colors.white : chipColor,
                ),
                const SizedBox(width: 6),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.black87,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Option "Toutes les catégories"
        _buildFilterChip(
          label: 'Toutes',
          value: null,
          activeValue: widget.criteria.categoryId?.toString(),
          onChanged: (value) {
            widget.onCriteriaChanged(
              ItemFilterCriteria(
                storeName: widget.criteria.storeName,
                minPrice: widget.criteria.minPrice,
                maxPrice: widget.criteria.maxPrice,
                categoryId: null,
                sortBy: widget.criteria.sortBy,
                ascending: widget.criteria.ascending,
                showOnlyPurchased: widget.criteria.showOnlyPurchased,
                showOnlyUnpurchased: widget.criteria.showOnlyUnpurchased,
              ),
            );
          },
          icon: Icons.all_inclusive,
        ),
        // Catégories disponibles
        ...widget.availableCategories.map((category) {
          return _buildFilterChip(
            label: category['name'] as String,
            value: category['id'].toString(),
            activeValue: widget.criteria.categoryId?.toString(),
            onChanged: (value) {
              widget.onCriteriaChanged(
                ItemFilterCriteria(
                  storeName: widget.criteria.storeName,
                  minPrice: widget.criteria.minPrice,
                  maxPrice: widget.criteria.maxPrice,
                  categoryId: value != null ? int.tryParse(value) : null,
                  sortBy: widget.criteria.sortBy,
                  ascending: widget.criteria.ascending,
                  showOnlyPurchased: widget.criteria.showOnlyPurchased,
                  showOnlyUnpurchased: widget.criteria.showOnlyUnpurchased,
                ),
              );
            },
            icon: Icons.category,
          );
        }),
      ],
    );
  }

  String _getCategoryName(int categoryId) {
    try {
      final category = widget.availableCategories.firstWhere(
        (cat) => cat['id'] == categoryId,
      );
      return category['name'] as String;
    } catch (e) {
      return 'Catégorie $categoryId';
    }
  }

  String _getSortLabel() {
    final l10n = AppLocalizations.of(context)!;
    switch (widget.criteria.sortBy) {
      case ItemSortBy.name:
        return l10n.sortByName;
      case ItemSortBy.price:
        return l10n.sortByPrice;
      case ItemSortBy.store:
        return l10n.sortByStore;
      case ItemSortBy.dateAdded:
        return l10n.sortByDateAdded;
    }
  }

  void _clearAllFilters() {
    widget.onCriteriaChanged(ItemFilterCriteria());
  }
}
