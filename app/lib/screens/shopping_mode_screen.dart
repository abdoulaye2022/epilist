// screens/shopping_mode_screen.dart - Mode « Je suis au magasin » (§25-30) :
// interface simplifiée pour l'exécution des courses. Grandes zones
// tactiles, progression visible, regroupement par rayon dans l'ordre du
// magasin actif, articles cochés repliés. Le toggle passe par le
// ListItemBloc existant : le hors ligne fonctionne comme partout.
import 'package:epilist/blocs/category/category_bloc.dart';
import 'package:epilist/blocs/list_item/list_item_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/category.dart';
import 'package:epilist/models/list_item.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/models/store.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShoppingModeScreen extends StatefulWidget {
  final ShoppingList shoppingList;
  final Store? store;

  /// categoryId -> position du rayon dans le magasin (vide = ordre neutre).
  final Map<int, int> aisleRank;

  const ShoppingModeScreen({
    super.key,
    required this.shoppingList,
    this.store,
    this.aisleRank = const {},
  });

  @override
  State<ShoppingModeScreen> createState() => _ShoppingModeScreenState();
}

class _ShoppingModeScreenState extends State<ShoppingModeScreen> {
  bool _showCompleted = false;

  void _toggle(ListItem item) {
    context.read<ListItemBloc>().add(TogglePurchasedStatus(
          listId: widget.shoppingList.id,
          itemId: item.id,
          isPurchased: !item.isPurchased,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.store?.name ?? widget.shoppingList.name),
        actions: [
          IconButton(
            tooltip: _showCompleted
                ? l10n.hideCompletedItems
                : l10n.showCompletedItems,
            icon: Icon(_showCompleted
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined),
            onPressed: () =>
                setState(() => _showCompleted = !_showCompleted),
          ),
        ],
      ),
      body: BlocBuilder<ListItemBloc, ListItemState>(
        builder: (context, state) {
          final items = state is ListItemLoaded
              ? state.items.where((i) => i.listId == widget.shoppingList.id).toList()
              : <ListItem>[];
          if (items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final done = items.where((i) => i.isPurchased).length;
          final total = items.length;
          final progress = total > 0 ? done / total : 0.0;

          // Tri par rayon (ordre du magasin), non classés à la fin
          final sorted = [...items]..sort((a, b) {
              int rank(ListItem i) => i.categoryId != null
                  ? (widget.aisleRank[i.categoryId!] ?? 1 << 20)
                  : 1 << 20;
              final r = rank(a).compareTo(rank(b));
              return r != 0
                  ? r
                  : a.productName
                      .toLowerCase()
                      .compareTo(b.productName.toLowerCase());
            });

          final remaining =
              sorted.where((i) => !i.isPurchased).toList();
          final completed = sorted.where((i) => i.isPurchased).toList();

          return Column(
            children: [
              // Progression bien visible (§29)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          done == total
                              ? l10n.shoppingDone
                              : l10n.itemsRemaining(total - done),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        Text(
                          '${l10n.itemsProgress(done, total)} · ${(progress * 100).round()} %',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: AppColors.border,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.sm, AppSpacing.md, 32),
                  children: [
                    ..._grouped(remaining, l10n),
                    if (_showCompleted && completed.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      const Divider(),
                      ...completed.map((i) => _bigTile(i, l10n)),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Regroupe par rayon avec en-têtes, dans l'ordre du magasin.
  List<Widget> _grouped(List<ListItem> items, AppLocalizations l10n) {
    final categoryState = context.read<CategoryBloc>().state;
    final categoriesById = <int, Category>{
      if (categoryState is CategoryLoaded)
        for (final cat in categoryState.categories) cat.id: cat,
    };

    String headerFor(ListItem item) {
      final catId = item.categoryId;
      if (catId == null || categoriesById[catId] == null) {
        return l10n.uncategorizedAisle;
      }
      return categoriesById[catId]!.name;
    }

    final rows = <Widget>[];
    String? current;
    for (final item in items) {
      final header = headerFor(item);
      if (header != current) {
        current = header;
        final cat =
            item.categoryId != null ? categoriesById[item.categoryId!] : null;
        rows.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Row(
            children: [
              Icon(cat?.icon ?? Icons.help_outline,
                  size: 18, color: cat?.color ?? AppColors.textDisabled),
              const SizedBox(width: 8),
              Text(header,
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              const Expanded(child: Divider(color: AppColors.border)),
            ],
          ),
        ));
      }
      rows.add(_bigTile(item, l10n));
    }
    return rows;
  }

  /// Grande zone tactile : toute la carte coche/décoche.
  Widget _bigTile(ListItem item, AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => _toggle(item),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Row(
            children: [
              Icon(
                item.isPurchased
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 28,
                color: item.isPurchased
                    ? AppColors.primary
                    : AppColors.textDisabled,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  item.quantity > 1
                      ? '${item.productName} ×${item.quantity}'
                      : item.productName,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w600,
                    decoration: item.isPurchased
                        ? TextDecoration.lineThrough
                        : null,
                    color: item.isPurchased
                        ? AppColors.textDisabled
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
