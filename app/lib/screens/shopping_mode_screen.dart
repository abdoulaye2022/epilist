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
//
// C'est aussi ici que le PRIX s'entre, article par article, avec le
// choix « Exact » ou « Approximatif ». Sans prix, « Terminer mes
// courses » laissait le budget inchangé : la liste n'avait aucun champ
// de prix, et le budget restait au même chiffre quoi qu'on achète.
// Terminer exige donc un montant — les prix, un total saisi, ou le
// reçu scanné — et le bouton dit pourquoi il est inactif.
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
import 'package:epilist/models/intelligence.dart';
import 'package:epilist/models/store.dart';
import 'package:epilist/services/intelligence_service.dart';
import 'package:epilist/services/receipt_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/utils/amount_text.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Peut-on terminer ses courses ?
///
/// Il faut un MONTANT, et c'est tout le sujet : « Terminer mes
/// courses » laissait le budget à son chiffre d'avant, quoi qu'on
/// achète. Trois façons d'en avoir un :
///   - le prix de chaque article coché est saisi ([sansPrix] à zéro) ;
///   - un total a été donné à la main ou lu sur le reçu
///     ([totalDeclare]) ;
///   - … et rien d'autre. Un panier vide ne compte pas : terminer des
///     courses sans avoir rien pris n'a pas de montant à enregistrer.
bool peutTerminerLesCourses({
  required double totalPanier,
  required int sansPrix,
  required bool totalDeclare,
}) {
  if (totalDeclare) return true;
  return totalPanier > 0 && sansPrix == 0;
}

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

  /// Ce qui reste du budget, tel que le serveur le calcule. Relu après
  /// chaque prix saisi : un budget affiché une fois à l'ouverture
  /// mentirait dès le deuxième article.
  BudgetForecast? _budget;

  /// Le total déclaré à la main (ou lu sur le reçu), quand les prix
  /// article par article n'ont pas été saisis.
  double? _totalDeclare;

  @override
  void initState() {
    super.initState();
    _relireBudget();
  }

  Future<void> _relireBudget() async {
    try {
      final f = await context.read<IntelligenceService>().getBudgetForecast();
      if (!mounted) return;
      setState(() => _budget = f.hasBudget ? f : null);
    } catch (_) {
      // Pas de budget, pas de réseau : la ligne ne s'affiche pas.
    }
  }

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
    _relireBudget();
  }

  /// Le prix d'un article, entré au magasin, étiquette sous les yeux.
  ///
  /// Deux prix n'ont pas la même valeur : celui qu'on lit sur
  /// l'étiquette et celui qu'on se rappelle. Le second s'affiche avec
  /// « ≈ », et le serveur ne l'apprend pas comme un prix observé — une
  /// alerte de baisse déclenchée sur un souvenir annoncerait une
  /// aubaine qui n'existe pas.
  Future<void> _saisirPrix(ListItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final montant = TextEditingController(
      text: item.price != null ? item.price!.toStringAsFixed(2) : '',
    );
    var approximatif = item.priceIsEstimate;
    String? erreur;

    final valide = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setLocal) => Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md + 2,
                    AppSpacing.lg,
                    AppSpacing.md + 2,
                    MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.shoppingPriceTitle(item.productName),
                        style: AppFonts.displayStyle(
                          size: 22,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: montant,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.price,
                          errorText: erreur,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Écrit, et pas deviné d'une couleur : deux puces
                      // qui disent laquelle est choisie.
                      Row(
                        children: [
                          for (final (valeur, libelle) in [
                            (false, l10n.shoppingPriceExact),
                            (true, l10n.shoppingPriceEstimate),
                          ])
                            Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.sm,
                              ),
                              child: ChoiceChip(
                                label: Text(libelle),
                                selected: approximatif == valeur,
                                showCheckmark: false,
                                onSelected:
                                    (_) =>
                                        setLocal(() => approximatif = valeur),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton(
                        onPressed: () {
                          final brut = montant.text.trim().replaceAll(',', '.');
                          final valeur = double.tryParse(brut);
                          if (brut.isEmpty || valeur == null || valeur < 0) {
                            setLocal(() => erreur = l10n.priceMustBeValid);
                            return;
                          }
                          Navigator.of(ctx).pop(true);
                        },
                        child: Text(l10n.save),
                      ),
                    ],
                  ),
                ),
          ),
    );
    if (valide != true || !mounted) return;

    final prix = double.tryParse(montant.text.trim().replaceAll(',', '.'));
    if (prix == null) return;
    context.read<ListItemBloc>().add(
      UpdateListItem(
        listId: widget.shoppingList.id,
        itemId: item.id,
        productName: item.productName,
        quantity: item.quantity,
        price: prix,
        priceIsEstimate: approximatif,
        storeName: item.storeName,
        categoryId: item.categoryId,
      ),
    );
    _relireBudget();
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

          // Le total en direct : ce que le panier coûte à cette
          // seconde. Il compte les articles COCHÉS, pas la liste
          // entière — ce qui n'est pas dans le panier n'est pas payé.
          final panier = items.where((i) => i.isPurchased).toList();
          final sansPrix = panier.where((i) => !i.hasPrice).length;
          final totalPanier = panier.fold<double>(
            0,
            (somme, i) => somme + (i.price ?? 0) * i.quantity,
          );
          final approximatif = panier.any(
            (i) => i.hasPrice && i.priceIsEstimate,
          );

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
              _argent(l10n, totalPanier, sansPrix, approximatif),
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
                    ..._finir(l10n, items, totalPanier, sansPrix),
                    const SizedBox(height: AppSpacing.sm + 4),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.pause_circle_outline),
                      label: Text(l10n.shoppingSaveForLater),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // « Enregistrer et revenir plus tard » laissait
                    // croire que sans ce bouton, rien n'etait garde.
                    // Tout est deja enregistre a chaque coche : le
                    // bouton ne fait que quitter.
                    Text(
                      l10n.shoppingPauseHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
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

  /// Ce que le panier coûte, et ce qu'il reste du budget.
  ///
  /// « Terminer mes courses » ne changeait pas le budget, parce que la
  /// liste n'avait aucun champ de prix : le budget restait au même
  /// chiffre quoi qu'on achète. Ces deux lignes-là sont la raison
  /// d'être du prix en magasin.
  Widget _argent(
    AppLocalizations l10n,
    double total,
    int sansPrix,
    bool approximatif,
  ) {
    final reste = _budget?.remaining;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md + 4,
        AppSpacing.sm + 4,
        AppSpacing.md + 4,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            approximatif
                ? l10n.shoppingTotalEstimated(amountText(context, total))
                : l10n.shoppingTotal(amountText(context, total)),
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          // « 29,89 $ » sans un mot de plus laissait croire que c'etait
          // le total de la liste, alors que trois articles n'avaient
          // pas de prix.
          if (sansPrix > 0)
            Text(
              l10n.itemsWithoutPrice(sansPrix),
              style: TextStyle(fontSize: 17.5, color: AppColors.warningInk),
            ),
          if (reste != null)
            Text(
              l10n.shoppingBudgetLeft(amountText(context, reste)),
              style: TextStyle(fontSize: 17.5, color: AppColors.textSecondary),
            ),
          if (_totalDeclare != null)
            Text(
              l10n.shoppingTotalGiven(amountText(context, _totalDeclare!)),
              style: TextStyle(fontSize: 17.5, color: AppColors.successInk),
            ),
        ],
      ),
    );
  }

  /// « Terminer mes courses », et ce qu'il faut pour y arriver.
  ///
  /// Sans montant, le bouton reste INACTIF et une phrase dit pourquoi :
  /// terminer sans montant ne changeait pas le budget, et c'est
  /// exactement ce qui faisait croire que le budget ne marchait pas.
  List<Widget> _finir(
    AppLocalizations l10n,
    List<ListItem> items,
    double total,
    int sansPrix,
  ) {
    final montantConnu = peutTerminerLesCourses(
      totalPanier: total,
      sansPrix: sansPrix,
      totalDeclare: _totalDeclare != null,
    );
    final restants = items.where((i) => !i.isPurchased).length;

    return [
      if (!montantConnu) ...[
        if (sansPrix > 0)
          Text(
            l10n.shoppingMissingPrices(sansPrix),
            style: TextStyle(
              fontSize: 17.5,
              fontWeight: FontWeight.w700,
              color: AppColors.warningInk,
            ),
          ),
        Text(
          l10n.shoppingFinishNeedsAmount,
          style: TextStyle(fontSize: 17.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm + 4),
        OutlinedButton.icon(
          onPressed: _donnerUnTotal,
          icon: const Icon(Icons.edit_outlined),
          label: Text(l10n.shoppingGiveTotal),
        ),
        const SizedBox(height: AppSpacing.sm + 4),
      ],
      FilledButton.icon(
        onPressed:
            montantConnu
                ? () => _finish(
                  items.length,
                  restants: restants,
                  achetes:
                      items
                          .where((i) => i.isPurchased)
                          .map((i) => i.productName)
                          .toList(),
                )
                : null,
        icon: const Icon(Icons.celebration_outlined),
        label: Text(l10n.shoppingFinish),
      ),
    ];
  }

  /// Un total saisi à la main, ou lu sur le reçu : il s'enregistre
  /// comme une facture de la liste, ce que le budget lit en premier.
  Future<void> _donnerUnTotal() async {
    final l10n = AppLocalizations.of(context)!;
    final montant = TextEditingController();
    var approximatif = false;
    String? erreur;

    final valide = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setLocal) => AlertDialog(
                  title: Text(l10n.shoppingGiveTotal),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: montant,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.totalAmount,
                          errorText: erreur,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          for (final (valeur, libelle) in [
                            (false, l10n.shoppingPriceExact),
                            (true, l10n.shoppingPriceEstimate),
                          ])
                            Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.sm,
                              ),
                              child: ChoiceChip(
                                label: Text(libelle),
                                selected: approximatif == valeur,
                                showCheckmark: false,
                                onSelected:
                                    (_) =>
                                        setLocal(() => approximatif = valeur),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(l10n.cancel),
                    ),
                    FilledButton(
                      onPressed: () {
                        final valeur = double.tryParse(
                          montant.text.trim().replaceAll(',', '.'),
                        );
                        if (valeur == null || valeur <= 0) {
                          setLocal(() => erreur = l10n.priceMustBeValid);
                          return;
                        }
                        Navigator.of(ctx).pop(true);
                      },
                      child: Text(l10n.save),
                    ),
                  ],
                ),
          ),
    );
    if (valide != true || !mounted) return;

    final valeur = double.tryParse(montant.text.trim().replaceAll(',', '.'));
    if (valeur == null) return;

    try {
      await context.read<ReceiptService>().createReceipt(
        listId: widget.shoppingList.id,
        storeName: widget.store?.name ?? l10n.shoppingMyShopping,
        totalAmount: valeur,
        purchaseDate: DateTime.now(),
        notes: approximatif ? l10n.shoppingPriceEstimate : null,
      );
      if (!mounted) return;
      setState(() => _totalDeclare = valeur);
      await _relireBudget();
    } catch (_) {
      if (!mounted) return;
      SmartSnackBarManager.showErrorSnackBar(context, l10n.error);
    }
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
      trailing: _prix(item, l10n),
    );
  }

  /// Le prix, à droite de la ligne : vide il appelle (« Prix »), rempli
  /// il s'affiche, avec « ≈ » quand il est approximatif.
  Widget _prix(ListItem item, AppLocalizations l10n) {
    final texte =
        !item.hasPrice
            ? l10n.shoppingPriceAdd
            : (item.priceIsEstimate
                ? l10n.shoppingPriceApprox(amountText(context, item.price!))
                : amountText(context, item.price!));

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.buttonSmall),
      child: OutlinedButton(
        onPressed: () => _saisirPrix(item),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 4),
          foregroundColor:
              item.hasPrice ? AppColors.primaryDark : AppColors.textSecondary,
        ),
        child: Text(
          texte,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  /// Fin des courses : l'ecran de reussite, en REMPLACANT le mode
  /// courses dans la pile — y revenir en arriere n'aurait aucun sens.
  void _finish(int total, {int restants = 0, List<String> achetes = const []}) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (_) => ShoppingSuccessScreen(
              listName: widget.shoppingList.name,
              itemsCount: total,
              remainingCount: restants,
              // De quoi boucler le cycle : ce qui est dans le panier
              // peut maintenant entrer dans la maison.
              purchasedNames: achetes,
            ),
      ),
    );
  }
}
