// screens/shopping_mode_screen.dart - Mode « Je suis au magasin » (§25-30) :
// interface simplifiée pour l'exécution des courses. Grandes zones
// tactiles, progression visible, regroupement par rayon dans l'ordre du
// magasin actif. Le toggle passe par le ListItemBloc existant : le hors
// ligne fonctionne comme partout.
//
// Un article coché RESTE à sa place, dans son rayon. Il était retiré de
// sa section et renvoyé tout en bas de l'écran, derrière un bouton en
// forme d'œil : au milieu des courses, un article qui disparaît du
// rayon où on vient de le prendre fait douter de l'avoir pris. Le
// filtre écrit — Tout, À prendre, Dans le panier — remplace l'œil.
import 'package:epilist/widgets/common/app_top_bar.dart';
import 'package:epilist/widgets/common/app_drawer.dart';
import 'package:epilist/widgets/common/main_bottom_bar.dart';
import 'package:epilist/widgets/common/main_shell_scope.dart';
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

/// Ce que l'écran montre. Les trois valeurs portent un libellé ÉCRIT :
/// un œil barré ne dit pas ce qu'il cache.
enum ShoppingFilter {
  tout,
  aPrendre,
  dansLePanier;

  /// Cet article a-t-il sa place à l'écran ? `coche` = déjà dans le
  /// panier.
  bool accepte(bool coche) => switch (this) {
    ShoppingFilter.tout => true,
    ShoppingFilter.aPrendre => !coche,
    ShoppingFilter.dansLePanier => coche,
  };
}

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
  ShoppingFilter _filtre = ShoppingFilter.tout;

  void _toggle(ListItem item) {
    final remet = !item.isPurchased;
    context.read<ListItemBloc>().add(
      TogglePurchasedStatus(
        listId: widget.shoppingList.id,
        itemId: item.id,
        isPurchased: remet,
      ),
    );
    // Décoché par erreur : on le dit, et on offre de revenir dessus.
    // Un article coché par mégarde, c'est un produit oublié au magasin.
    if (!remet) _annulable(item);
  }

  void _annulable(ListItem item) {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.shoppingBackToGet(item.productName)),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: l10n.undoAction,
          onPressed: () {
            context.read<ListItemBloc>().add(
              TogglePurchasedStatus(
                listId: widget.shoppingList.id,
                itemId: item.id,
                isPurchased: true,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      bottomNavigationBar: const AppPageBottomBar(tab: MainTab.lists),
      appBar: AppTopBar(title: widget.store?.name ?? widget.shoppingList.name),
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

          // Tri par rayon (ordre du magasin), non classés à la fin.
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

          final montres =
              sorted.where((i) => _filtre.accepte(i.isPurchased)).toList();

          return Column(
            children: [
              // Le compteur vivant de la planche, accroché en haut : il
              // ne défile pas avec la liste, et il s'annonce aux
              // lecteurs d'écran à chaque article coché.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: AppCounterCard(
                  count: l10n.shoppingBasketCount(done, total),
                  sentence: l10n.shoppingBasketSentence(total - done, done),
                  ratio: progress,
                ),
              ),
              _filtres(l10n, total - done, done),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    32,
                  ),
                  children: [
                    if (montres.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xl,
                        ),
                        child: Text(
                          l10n.shoppingNothingHere,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    else
                      ..._grouped(montres, l10n),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: () => _finish(total),
                      icon: const Icon(Icons.celebration_outlined),
                      label: Text(l10n.shoppingFinish),
                    ),
                    const SizedBox(height: AppSpacing.sm + 4),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.pause_circle_outline),
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

  /// Trois puces, trois libellés écrits, chacune avec son compte.
  Widget _filtres(AppLocalizations l10n, int aPrendre, int dansLePanier) {
    final choix = <(ShoppingFilter, String)>[
      (ShoppingFilter.tout, l10n.shoppingFilterAll),
      (ShoppingFilter.aPrendre, '${l10n.shoppingFilterToGet} ($aPrendre)'),
      (ShoppingFilter.dansLePanier, '${l10n.shoppingInBasket} ($dansLePanier)'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm + 4,
        AppSpacing.md,
        0,
      ),
      child: Row(
        children: [
          for (final (valeur, libelle) in choix)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(libelle),
                selected: _filtre == valeur,
                showCheckmark: false,
                onSelected: (_) => setState(() => _filtre = valeur),
              ),
            ),
        ],
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
