// screens/store_aisle_order_screen.dart - Ordre des rayons d'un magasin.
// Glisser-déposer les rayons (kinds des catégories par défaut) dans l'ordre
// où on parcourt le magasin ; sauvegarde à chaque dépôt (optimiste).
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/blocs/category/category_bloc.dart';
import 'package:epilist/blocs/store/store_bloc.dart';
import 'package:epilist/blocs/store/store_event.dart';
import 'package:epilist/blocs/store/store_state.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/category.dart';
import 'package:epilist/models/store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StoreAisleOrderScreen extends StatefulWidget {
  final int storeId;

  const StoreAisleOrderScreen({super.key, required this.storeId});

  @override
  State<StoreAisleOrderScreen> createState() => _StoreAisleOrderScreenState();
}

class _StoreAisleOrderScreenState extends State<StoreAisleOrderScreen> {
  /// Rayons dans l'ordre affiché : (kind, catégorie représentative).
  List<MapEntry<String, Category>> _aisles = [];
  bool _initialized = false;

  Store? _storeFrom(StoreState state) {
    final stores = switch (state) {
      StoreLoaded(:final stores) => stores,
      StoreOperationSuccess(:final stores) => stores,
      StoreError(:final stores) => stores,
      _ => const <Store>[],
    };
    for (final s in stores) {
      if (s.id == widget.storeId) return s;
    }
    return null;
  }

  /// Construit la liste des rayons : d'abord ceux déjà ordonnés pour ce
  /// magasin, puis les kinds restants dans l'ordre des catégories.
  void _initAisles(Store store, List<Category> categories) {
    final byKind = <String, Category>{};
    for (final cat in categories) {
      if (cat.kind != null && cat.deletedAt == null) {
        byKind.putIfAbsent(cat.kind!, () => cat);
      }
    }

    final ordered = <MapEntry<String, Category>>[];
    for (final kind in store.categoryOrder) {
      final cat = byKind.remove(kind);
      if (cat != null) ordered.add(MapEntry(kind, cat));
    }
    final remaining = byKind.entries.toList()
      ..sort((a, b) => a.value.orderIndex.compareTo(b.value.orderIndex));
    ordered.addAll(remaining.map((e) => MapEntry(e.key, e.value)));

    _aisles = ordered;
    _initialized = true;
  }

  void _save() {
    context.read<StoreBloc>().add(
          SaveCategoryOrder(
            widget.storeId,
            _aisles.map((e) => e.key).toList(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<StoreBloc, StoreState>(
      builder: (context, storeState) {
        final store = _storeFrom(storeState);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store?.name ?? '',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  l10n.aisleOrder,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          body: BlocBuilder<CategoryBloc, CategoryState>(
            builder: (context, categoryState) {
              if (store == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (categoryState is! CategoryLoaded) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!_initialized) {
                _initAisles(store, categoryState.categories);
              }

              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.swipe_vertical,
                            color: AppColors.accent, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.aisleOrderHint,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[900],
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _aisles.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex--;
                          final moved = _aisles.removeAt(oldIndex);
                          _aisles.insert(newIndex, moved);
                        });
                        _save();
                      },
                      itemBuilder: (context, index) {
                        final aisle = _aisles[index];
                        final cat = aisle.value;
                        return Card(
                          key: ValueKey(aisle.key),
                          color: Colors.white,
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: cat.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: cat.color,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Icon(cat.icon, size: 20, color: cat.color),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    cat.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: ReorderableDragStartListener(
                              index: index,
                              child: Icon(Icons.drag_handle,
                                  color: AppColors.textDisabled),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
