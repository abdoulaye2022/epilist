// screens/inventory_screen.dart - « À la maison ».
//
// L'écran ne fonctionnait pas, et la raison était simple : l'ÉTAT était
// saisi d'un côté (trois pastilles), la QUANTITÉ de l'autre (un
// formulaire), et rien ne les reliait. Une capture montrait « Alerte
// rupture : il n'y en a plus à la maison » juste sous « Quantité
// restante : 2, pour un seuil de 1 ». Les deux étaient vrais
// séparément, et faux ensemble.
//
// Maintenant la quantité décide : zéro = rupture, au seuil ou en
// dessous = stock bas, au-dessus = disponible. Les trois pastilles de
// saisie disparaissent — on ne déclare plus un état, on dit combien il
// en reste, avec « − » et « + ».
//
// Ce qui ne se compte pas (le liquide vaisselle, la farine) se suit au
// NIVEAU : plein, à moitié, presque vide. Et ce qui se périme porte sa
// date, avec l'alerte « À terminer dans 2 jours ».
import 'package:epilist/widgets/common/app_top_bar.dart';
import 'package:epilist/widgets/common/app_drawer.dart';
import 'package:epilist/widgets/common/main_bottom_bar.dart';
import 'package:epilist/widgets/common/main_shell_scope.dart';
import 'package:epilist/utils/add_product_to_list.dart';
import 'package:epilist/widgets/common/app_states.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/intelligence.dart';
import 'package:epilist/services/screen_cache.dart';
import 'package:epilist/services/intelligence_service.dart';
import 'package:epilist/theme/app_icons.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/app_dialog.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<InventoryItem> _items = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    final cached = ScreenCache.read<List<InventoryItem>>('inventory');
    if (cached != null) {
      _items = cached;
      _loading = false;
    }
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await context.read<IntelligenceService>().getInventory();
      if (!mounted) return;
      ScreenCache.write('inventory', items);
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /// L'état d'un produit, dans l'ordre de ce qui presse.
  ///
  /// La rupture d'abord : il manque. Puis le stock bas. Puis la
  /// péremption, qui ne concerne que ce qui est encore là. Disponible
  /// en dernier, et c'est un état à part entière — l'écran n'avait rien
  /// pour le dire, et l'absence d'alerte devait se lire comme une
  /// bonne nouvelle.
  StockState _etat(InventoryItem i) {
    if (i.status == 'out') return StockState.rupture;
    if (i.status == 'running_low' || i.belowMin) return StockState.stockBas;
    if (i.expiringSoon) return StockState.peremption;
    return StockState.disponible;
  }

  String _etatEcrit(InventoryItem i, AppLocalizations l10n) {
    final etat = _etat(i);
    if (etat == StockState.peremption) {
      final jours = i.daysToExpiry ?? 0;
      return jours < 0
          ? l10n.inventoryExpired(-jours)
          : l10n.inventoryExpiringIn(jours);
    }
    return switch (etat) {
      StockState.rupture => l10n.stockStateOut,
      StockState.stockBas => l10n.stockStateLow,
      _ => l10n.stockStateAvailable,
    };
  }

  // --- Quantité : « − » et « + » ----------------------------------------

  /// Un appui doit répondre tout de suite : la ligne change d'abord, le
  /// serveur suit. En cas d'échec, on remet la valeur d'avant et on le
  /// dit — sans quoi l'écran mentirait jusqu'au prochain chargement.
  Future<void> _ajuster(InventoryItem item, double delta) async {
    final l10n = AppLocalizations.of(context)!;
    final avant = item;
    final cible = ((item.quantity ?? 0) + delta).clamp(0.0, 99999.0);
    if (cible == item.quantity) return;

    setState(() => _remplace(item.id, _devine(item, cible)));
    try {
      final frais = await context
          .read<IntelligenceService>()
          .setInventoryQuantity(item.id, cible);
      if (!mounted) return;
      setState(() => _remplace(item.id, frais));
      ScreenCache.write('inventory', _items);
    } catch (_) {
      if (!mounted) return;
      setState(() => _remplace(avant.id, avant));
      SmartSnackBarManager.showErrorSnackBar(context, l10n.error);
    }
  }

  /// La ligne telle qu'elle sera, en appliquant la MÊME règle que le
  /// serveur. Dupliquée ici pour que l'affichage optimiste ne montre
  /// pas un état que le serveur va contredire une seconde plus tard.
  InventoryItem _devine(InventoryItem item, double quantite) {
    final seuil = item.minQuantity;
    final statut =
        quantite <= 0
            ? 'out'
            : (seuil != null && quantite <= seuil ? 'running_low' : 'at_home');
    return item.copyWith(
      quantity: quantite,
      status: statut,
      belowMin: seuil != null && quantite <= seuil,
    );
  }

  void _remplace(int id, InventoryItem frais) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i >= 0) _items[i] = frais;
  }

  Future<void> _setStatus(InventoryItem item, String status) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await context.read<IntelligenceService>().setInventoryStatus(
        item.productName,
        status,
      );
      await _load();
      if (status == 'out' && mounted) {
        await _offerAddToList(item.productName);
      }
    } catch (e) {
      if (!mounted) return;
      SmartSnackBarManager.showErrorSnackBar(context, l10n.error);
    }
  }

  /// Produit terminé -> proposition d'ajout à la liste la plus récente
  /// (ajout direct si le réglage auto est activé).
  Future<void> _offerAddToList(String productName) async {
    final l10n = AppLocalizations.of(context)!;
    if (await IntelligenceSettings.get(
      IntelligenceSettings.keyAutoAddOut,
      defaultValue: false,
    )) {
      if (!mounted) return;
      await addProductToList(context, productName);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.addToListQuestion(productName)),
        action: SnackBarAction(
          label: l10n.predictionAdd,
          onPressed: () => addProductToList(context, productName),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _addProduct() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n.inventoryAddProduct),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.inventoryProductName),
              onSubmitted: (v) => Navigator.of(ctx).pop(v),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(controller.text),
                child: Text(l10n.add),
              ),
            ],
          ),
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    try {
      await context.read<IntelligenceService>().setInventoryStatus(
        name.trim(),
        'at_home',
      );
      await _load();
    } catch (_) {}
  }

  String _qty(double v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1);

  String _avecUnite(double v, String? unite) =>
      unite == null || unite.isEmpty ? _qty(v) : '${_qty(v)} $unite';

  String _niveauEcrit(String niveau, AppLocalizations l10n) => switch (niveau) {
    'full' => l10n.inventoryLevelFull,
    'half' => l10n.inventoryLevelHalf,
    _ => l10n.inventoryLevelLow,
  };

  /// Quantité, seuil, date de péremption et niveau.
  ///
  /// Le champ du seuil s'appelait « Seuil d'alerte (min) » : « min » se
  /// lit minutes autant que minimum, alors que la valeur attendue est
  /// un nombre d'unités. Il demande maintenant « Prévenez-moi quand il
  /// en reste », avec l'unité du produit affichée dans le champ.
  Future<void> _editThresholds(InventoryItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final quantity = TextEditingController(
      text: item.quantity != null ? _qty(item.quantity!) : '',
    );
    final unit = TextEditingController(text: item.unit ?? '');
    final minQty = TextEditingController(
      text: item.minQuantity != null ? _qty(item.minQuantity!) : '',
    );
    final reorder = TextEditingController(
      text: item.reorderQuantity != null ? _qty(item.reorderQuantity!) : '',
    );
    DateTime? peremption = item.expiresAt;
    String? niveau = item.level;

    double? parse(TextEditingController c) =>
        double.tryParse(c.text.trim().replaceAll(',', '.'));

    // Erreurs de saisie, affichées sous les champs concernés.
    String? quantityError;
    String? minError;
    String? reorderError;

    /// Valide un champ numérique facultatif : vide = accepté, sinon il
    /// doit être un nombre positif.
    String? optionalNumber(TextEditingController c) {
      final raw = c.text.trim();
      if (raw.isEmpty) return null;
      final value = parse(c);
      if (value == null) return l10n.invalidNumber;
      if (value < 0) return l10n.invalidNumber;
      return null;
    }

    final saved = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setLocal) => Dialog(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppDialogHeader(
                          icon: AppIcons.inventory,
                          title: l10n.inventoryThresholdsTitle,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        // Le produit concerné, en sous-titre : l'en-tête porte
                        // l'intention, pas le nom.
                        Padding(
                          padding: const EdgeInsets.only(left: 48),
                          child: Text(
                            item.productName,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: quantity,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  labelText: l10n.inventoryQuantity,
                                  errorText: quantityError,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.sm,
                                    ),
                                  ),
                                  isDense: true,
                                ),
                                onChanged: (_) {
                                  setLocal(() => quantityError = null);
                                },
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: TextField(
                                controller: unit,
                                decoration: InputDecoration(
                                  labelText: l10n.inventoryUnit,
                                  hintText: 'kg',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.sm,
                                    ),
                                  ),
                                  isDense: true,
                                ),
                                onChanged: (_) => setLocal(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: minQty,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.inventoryMinQuantity,
                            // L'unité du produit, DANS le champ : « 1 »
                            // tout seul ne dit pas un sac, un litre ou
                            // un kilo.
                            suffixText:
                                unit.text.trim().isEmpty
                                    ? null
                                    : unit.text.trim(),
                            helperText: l10n.inventoryMinQuantityHint,
                            helperMaxLines: 3,
                            errorText: minError,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            isDense: true,
                          ),
                          onChanged: (_) {
                            if (minError != null) {
                              setLocal(() => minError = null);
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: reorder,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.inventoryReorderQuantity,
                            suffixText:
                                unit.text.trim().isEmpty
                                    ? null
                                    : unit.text.trim(),
                            helperText: l10n.inventoryReorderQuantityHint,
                            helperMaxLines: 3,
                            errorText: reorderError,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            isDense: true,
                          ),
                          onChanged: (_) {
                            if (reorderError != null) {
                              setLocal(() => reorderError = null);
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        // La date de péremption, facultative. Sans elle,
                        // « bientôt périmé » ne pouvait pas exister.
                        Text(
                          l10n.inventoryExpiryDate,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final choisie = await showDatePicker(
                                    context: ctx,
                                    initialDate: peremption ?? DateTime.now(),
                                    firstDate: DateTime.now().subtract(
                                      const Duration(days: 365),
                                    ),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365 * 5),
                                    ),
                                  );
                                  if (choisie != null) {
                                    setLocal(() => peremption = choisie);
                                  }
                                },
                                icon: const Icon(Icons.event_outlined),
                                label: Text(
                                  peremption == null
                                      ? l10n.inventoryExpiryPick
                                      : DateFormat.yMMMd(
                                        locale,
                                      ).format(peremption!),
                                ),
                              ),
                            ),
                            if (peremption != null)
                              IconButton(
                                tooltip: l10n.inventoryExpiryNone,
                                onPressed:
                                    () => setLocal(() => peremption = null),
                                icon: const Icon(Icons.close_rounded),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        // Le niveau, pour ce qui ne se compte pas.
                        Text(
                          l10n.inventoryLevel,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          l10n.inventoryLevelHint,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final (valeur, libelle) in [
                              (null, l10n.inventoryLevelNone),
                              ('full', l10n.inventoryLevelFull),
                              ('half', l10n.inventoryLevelHalf),
                              ('low', l10n.inventoryLevelLow),
                            ])
                              ChoiceChip(
                                label: Text(libelle),
                                selected: niveau == valeur,
                                showCheckmark: false,
                                onSelected:
                                    (_) => setLocal(() => niveau = valeur),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppDialogActions(
                          cancelLabel: l10n.cancel,
                          submitLabel: l10n.save,
                          onCancel: () => Navigator.of(ctx).pop(false),
                          onSubmit: () {
                            // Validation à l'enregistrement : le formulaire ne
                            // se ferme pas tant qu'il reste une erreur.
                            final qError = optionalNumber(quantity);
                            final mError = optionalNumber(minQty);
                            final rError = optionalNumber(reorder);

                            if (qError != null ||
                                mError != null ||
                                rError != null) {
                              setLocal(() {
                                quantityError = qError;
                                minError = mError;
                                reorderError = rError;
                              });
                              return;
                            }
                            Navigator.of(ctx).pop(true);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
    if (saved != true || !mounted) return;
    try {
      await context.read<IntelligenceService>().setInventoryStatus(
        item.productName,
        item.status,
        quantity: parse(quantity),
        unit: unit.text.trim().isEmpty ? null : unit.text.trim(),
        minQuantity: parse(minQty),
        reorderQuantity: parse(reorder),
        sendExpiresAt: true,
        expiresAt: peremption,
        sendLevel: true,
        level: niveau,
      );
      await _load();
    } catch (_) {
      if (!mounted) return;
      SmartSnackBarManager.showErrorSnackBar(context, l10n.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final filtered =
        _search.isEmpty
            ? _items
            : _items
                .where(
                  (i) => i.productName.toLowerCase().contains(
                    _search.toLowerCase(),
                  ),
                )
                .toList();

    // Une zone par état, dans l'ordre de ce qui presse. Un produit
    // n'apparaît QUE dans une zone : il était possible de voir le même
    // sac de riz annoncé « Stock bas » et rangé dans « Terminé ».
    final zones = <(StockState, String, List<InventoryItem>)>[
      (
        StockState.rupture,
        l10n.inventoryOut,
        filtered.where((i) => _etat(i) == StockState.rupture).toList(),
      ),
      (
        StockState.stockBas,
        l10n.inventoryRunningLow,
        filtered.where((i) => _etat(i) == StockState.stockBas).toList(),
      ),
      (
        StockState.peremption,
        l10n.inventoryZoneExpiring,
        filtered.where((i) => _etat(i) == StockState.peremption).toList(),
      ),
      (
        StockState.disponible,
        l10n.inventoryAtHome,
        filtered.where((i) => _etat(i) == StockState.disponible).toList(),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      bottomNavigationBar: const AppPageBottomBar(tab: MainTab.sections),
      appBar: AppTopBar(title: l10n.inventoryTitle),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        backgroundColor: AppColors.primary,
        tooltip: l10n.inventoryAddProduct,
        child: Icon(Icons.add, color: AppColors.onPrimary),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    96,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        l10n.inventoryIntro,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    TextField(
                      decoration: InputDecoration(
                        hintText: l10n.search,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _search = v),
                    ),
                    if (_items.isEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Icon(
                        AppIcons.inventory,
                        size: 56,
                        color: AppColors.textDisabled,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.inventoryEmpty,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ] else
                      for (final (etat, title, items) in zones)
                        if (items.isNotEmpty)
                          // Une zone par etat, en-tete teinte de la
                          // couleur de l'etat : la carte dit de quoi
                          // elle parle avant qu'on lise une ligne.
                          AppZoneCard(
                            title: '$title (${items.length})',
                            tint: AppStateBadge.couleurDe(etat),
                            icon: _iconeDeZone(etat),
                            children: [
                              for (final (n, i) in items.indexed)
                                _itemLine(i, l10n, first: n == 0),
                              // « Un bouton Ajouter un produit dans
                              // chaque zone » : le bouton flottant est
                              // loin quand on vient de lire une ligne.
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.sm,
                                ),
                                child: OutlinedButton.icon(
                                  onPressed: _addProduct,
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(
                                      0,
                                      AppSizes.buttonSmall,
                                    ),
                                  ),
                                  icon: const Icon(Icons.add),
                                  label: Text(l10n.inventoryAddProduct),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
    );
  }

  IconData _iconeDeZone(StockState etat) => switch (etat) {
    StockState.rupture => Icons.remove_shopping_cart_outlined,
    StockState.stockBas => Icons.hourglass_bottom,
    StockState.peremption => Icons.watch_later_outlined,
    StockState.disponible => Icons.home_outlined,
  };

  /// Une ligne de provision DANS sa zone : son nom, son état écrit avec
  /// son badge, sa quantité réglable, et ce qu'on peut en faire.
  Widget _itemLine(
    InventoryItem item,
    AppLocalizations l10n, {
    required bool first,
  }) {
    final estimation =
        item.status == 'at_home' &&
        (item.estimatedStatus == 'running_low' ||
            item.estimatedStatus == 'out');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 4),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: first ? Colors.transparent : AppColors.primaryLight,
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Le badge PLEIN et l'état écrit : la couleur ne
                    // porte jamais seule le sens, et la forme aide qui
                    // distingue mal le vert et le rouge.
                    AppStateChip(
                      state: _etat(item),
                      label: _etatEcrit(item, l10n),
                    ),
                    if (item.minQuantity != null && item.quantity != null)
                      Text(
                        l10n.inventoryQuantityThreshold(
                          _avecUnite(item.quantity!, item.unit),
                          _avecUnite(item.minQuantity!, item.unit),
                        ),
                        style: TextStyle(
                          fontSize: 17.5,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    if (item.quantity == null && item.level != null)
                      Text(
                        l10n.inventoryLevelLine(
                          _niveauEcrit(item.level!, l10n),
                        ),
                        style: TextStyle(
                          fontSize: 17.5,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    if (estimation)
                      Text(
                        l10n.inventoryProbablyLow,
                        style: TextStyle(
                          fontSize: 17.5,
                          color: AppColors.warningInk,
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 22,
                  color: AppColors.textSecondary,
                ),
                onSelected: (action) async {
                  switch (action) {
                    case 'thresholds':
                      await _editThresholds(item);
                    case 'out':
                      await _setStatus(item, 'out');
                    default:
                      await context
                          .read<IntelligenceService>()
                          .deleteInventoryItem(item.id);
                      await _load();
                  }
                },
                itemBuilder:
                    (_) => [
                      PopupMenuItem(
                        value: 'thresholds',
                        child: Text(l10n.inventoryThresholds),
                      ),
                      // Pour un produit suivi au niveau ou sans
                      // quantité : sans « − », rien ne permettrait de
                      // dire qu'il est fini.
                      if (item.quantity == null && item.status != 'out')
                        PopupMenuItem(
                          value: 'out',
                          child: Text(l10n.stockStateOut),
                        ),
                      PopupMenuItem(
                        value: 'remove',
                        child: Text(l10n.removeFromInventory),
                      ),
                    ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              if (item.quantity != null) ...[
                _pas(
                  item,
                  -1,
                  Icons.remove_rounded,
                  l10n.inventoryMinusOne,
                  actif: (item.quantity ?? 0) > 0,
                ),
                const SizedBox(width: AppSpacing.sm),
                // La quantite, ENTRE les deux boutons : c'est ce qui
                // change quand on appuie.
                Text(
                  _avecUnite(item.quantity!, item.unit),
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _pas(item, 1, Icons.add_rounded, l10n.inventoryPlusOne),
                const Spacer(),
              ],
              if (item.quantity == null) const Spacer(),
              if (_etat(item) != StockState.disponible)
                OutlinedButton.icon(
                  onPressed: () => addProductToList(context, item.productName),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, AppSizes.buttonSmall),
                  ),
                  icon: const Icon(Icons.add_shopping_cart_outlined),
                  label: Text(l10n.addToMyList),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Un bouton « − » ou « + » : 56 dp de cible, pas 24.
  Widget _pas(
    InventoryItem item,
    double delta,
    IconData icone,
    String libelle, {
    bool actif = true,
  }) {
    return SizedBox(
      width: AppSizes.buttonSmall,
      height: AppSizes.buttonSmall,
      child: OutlinedButton(
        onPressed: actif ? () => _ajuster(item, delta) : null,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
        ),
        child: Semantics(
          label: libelle,
          button: true,
          child: Icon(icone, size: 26),
        ),
      ),
    );
  }
}
