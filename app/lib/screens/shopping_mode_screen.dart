// screens/shopping_mode_screen.dart - Mode « Je suis au magasin » (§25-30) :
// interface simplifiée pour l'exécution des courses. Grandes zones
// tactiles, progression visible, regroupement par rayon dans l'ordre du
// magasin actif, articles cochés repliés. Le toggle passe par le
// ListItemBloc existant : le hors ligne fonctionne comme partout.
import 'package:epilist/screens/shopping_success_screen.dart';
import 'package:epilist/widgets/common/app_meters.dart';
import 'package:epilist/widgets/common/app_states.dart';
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
    context.read<ListItemBloc>().add(
      TogglePurchasedStatus(
        listId: widget.shoppingList.id,
        itemId: item.id,
        isPurchased: !item.isPurchased,
      ),
    );
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
            tooltip:
                _showCompleted
                    ? l10n.hideCompletedItems
                    : l10n.showCompletedItems,
            icon: Icon(
              _showCompleted
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
            onPressed: () => setState(() => _showCompleted = !_showCompleted),
          ),
        ],
      ),
      body: BlocBuilder<ListItemBloc, ListItemState>(
        builder: (context, state) {
          final items =
              state is ListItemLoaded
                  ? state.items
                      .where((i) => i.listId == widget.shoppingList.id)
                      .toList()
                  : <ListItem>[];
          if (items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final done = items.where((i) => i.isPurchased).length;
          final total = items.length;
          final progress = total > 0 ? done / total : 0.0;

          // Tri par rayon (ordre du magasin), non classés à la fin
          final sorted = [...items]..sort((a, b) {
            int rank(ListItem i) =>
                i.categoryId != null
                    ? (widget.aisleRank[i.categoryId!] ?? 1 << 20)
                    : 1 << 20;
            final r = rank(a).compareTo(rank(b));
            return r != 0
                ? r
                : a.productName.toLowerCase().compareTo(
                  b.productName.toLowerCase(),
                );
          });

          final remaining = sorted.where((i) => !i.isPurchased).toList();
          final completed = sorted.where((i) => i.isPurchased).toList();

          return Column(
            children: [
              // Le compteur vivant de la planche. Il s'annonce aux
              // lecteurs d'ecran a chaque article coche, ce qui est
              // tout l'interet d'un compteur pendant les courses.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: AppCounterCard(
                  count: l10n.shoppingItemsRemainingOf(total - done, total),
                  sentence: l10n.shoppingBasketSentence(total - done, done),
                  ratio: progress,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    32,
                  ),
                  children: [
                    ..._grouped(remaining, l10n),
                    if (_showCompleted && completed.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      const Divider(),
                      ...completed.map((i) => _bigTile(i, l10n)),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: () => _finish(total),
                      icon: const Icon(Icons.celebration_outlined),
                      label: Text(l10n.shoppingFinish),
                    ),
                    const SizedBox(height: AppSpacing.sm + 4),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.bookmark_outline),
                      label: Text(l10n.shoppingSaveForLater),
                    ),
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
        rows.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Row(
              children: [
                Icon(
                  cat?.icon ?? Icons.help_outline,
                  size: 24,
                  color: cat?.color ?? AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Text(
                  header,
                  style: AppFonts.displayStyle(
                    size: 20,
                    color: AppColors.primary,
                    weight: 700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Divider(color: AppColors.border)),
              ],
            ),
          ),
        );
      }
      rows.add(_bigTile(item, l10n));
    }
    return rows;
  }

  /// La ligne cochable de la planche : 64 dp de haut, case de 34.
  ///
  /// Avant : un cercle de 28 dans une carte, et un nom en 16,5. La
  /// quantite etait collee au nom (« Pommes ×6 ») au lieu d'etre sa
  /// propre ligne.
  Widget _bigTile(ListItem item, AppLocalizations l10n) {
    return AppCheckRow(
      checked: item.isPurchased,
      title: item.productName,
      subtitle:
          item.quantity > 1 ? '${l10n.voiceQuantity} : ${item.quantity}' : null,
      doneLabel: l10n.shoppingInBasket,
      onChanged: (_) => _toggle(item),
    );
  }

  /// Fin des courses : l'ecran de reussite, en REMPLACANT le mode
  /// courses dans la pile — y revenir en arriere n'aurait aucun sens.
  void _finish(int total) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (_) => ShoppingSuccessScreen(
              listName: widget.shoppingList.name,
              itemsCount: total,
            ),
      ),
    );
  }
}
