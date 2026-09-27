// screens/inventory_screen.dart - Inventaire maison ultra-simple :
// trois sections (Bientôt terminé / À la maison / Terminé), changement
// d'état en un geste, recherche, ajout. Un produit marqué « Terminé »
// propose l'ajout à la liste récente (ou l'ajoute seul si le réglage
// auto_add_out_of_stock est activé).
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/intelligence.dart';
import 'package:epilist/services/intelligence_service.dart';
import 'package:epilist/services/list_item_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await context.read<IntelligenceService>().getInventory();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _setStatus(InventoryItem item, String status) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await context
          .read<IntelligenceService>()
          .setInventoryStatus(item.productName, status);
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
    final state = context.read<ShoppingListBloc>().state;
    final lists = state is ShoppingListLoaded ? state.lists : [];
    if (lists.isEmpty) return;
    final listId = lists.first.id;

    Future<void> add() async {
      try {
        await context.read<ListItemService>().forceAddListItem(
              listId: listId,
              productName: productName,
            );
        if (!mounted) return;
        SmartSnackBarManager.showSuccessSnackBar(
            context, l10n.addedToList(productName));
      } catch (_) {}
    }

    if (await IntelligenceSettings.get(IntelligenceSettings.keyAutoAddOut,
        defaultValue: false)) {
      await add();
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.addToListQuestion(productName)),
        action: SnackBarAction(label: l10n.predictionAdd, onPressed: add),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _addProduct() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
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
      await context
          .read<IntelligenceService>()
          .setInventoryStatus(name.trim(), 'at_home');
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final filtered = _search.isEmpty
        ? _items
        : _items
            .where((i) =>
                i.productName.toLowerCase().contains(_search.toLowerCase()))
            .toList();

    final sections = <(String, String, List<InventoryItem>)>[
      ('running_low', l10n.inventoryRunningLow,
          filtered.where((i) => i.status == 'running_low').toList()),
      ('at_home', l10n.inventoryAtHome,
          filtered.where((i) => i.status == 'at_home').toList()),
      ('out', l10n.inventoryOut,
          filtered.where((i) => i.status == 'out').toList()),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.inventoryTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        backgroundColor: AppColors.primary,
        tooltip: l10n.inventoryAddProduct,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, 96),
                children: [
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
                    Icon(Icons.kitchen_outlined,
                        size: 56, color: Colors.grey[400]),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.inventoryEmpty,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13.5, color: AppColors.textSecondary),
                    ),
                  ] else
                    for (final (status, title, items) in sections)
                      if (items.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                              top: AppSpacing.md, bottom: AppSpacing.sm),
                          child: Row(
                            children: [
                              _statusDot(status),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '$title (${items.length})',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        ...items.map((i) => _itemCard(i, l10n)),
                      ],
                ],
              ),
            ),
    );
  }

  Color _statusColor(String status) => switch (status) {
        'out' => AppColors.error,
        'running_low' => AppColors.warning,
        _ => AppColors.primary,
      };

  Widget _statusDot(String status) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: _statusColor(status),
          shape: BoxShape.circle,
        ),
      );

  Widget _itemCard(InventoryItem item, AppLocalizations l10n) {
    // L'estimation n'est montrée que si elle diffère de l'état manuel
    final showEstimate = item.status == 'at_home' &&
        (item.estimatedStatus == 'running_low' ||
            item.estimatedStatus == 'out');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w600)),
                  if (showEstimate)
                    Text(
                      l10n.inventoryProbablyLow,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.warning),
                    ),
                ],
              ),
            ),
            // Trois pastilles d'état, changement en un tap
            for (final status in const ['at_home', 'running_low', 'out'])
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xs),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  onTap: item.status == status
                      ? null
                      : () => _setStatus(item, status),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: item.status == status
                          ? _statusColor(status).withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: item.status == status
                            ? _statusColor(status)
                            : AppColors.border,
                      ),
                    ),
                    child: Icon(
                      switch (status) {
                        'out' => Icons.remove_shopping_cart_outlined,
                        'running_low' => Icons.hourglass_bottom,
                        _ => Icons.home_outlined,
                      },
                      size: 17,
                      color: item.status == status
                          ? _statusColor(status)
                          : AppColors.textDisabled,
                    ),
                  ),
                ),
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  size: 18, color: AppColors.textDisabled),
              onSelected: (_) async {
                await context
                    .read<IntelligenceService>()
                    .deleteInventoryItem(item.id);
                _load();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'remove',
                  child: Text(l10n.removeFromInventory),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
