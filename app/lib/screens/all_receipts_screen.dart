// screens/all_receipts_screen.dart - Onglet « Factures » : toutes les
// factures de l'espace actif, sans choisir de liste d'abord.
//
// Pourquoi cet écran existe : ReceiptsScreen exige un `shoppingList`, et
// les treize routes de factures de l'API vivaient toutes sous
// /shopping-lists/{listId}/receipts. Voir ses dépenses imposait donc de
// se souvenir de la liste à laquelle on avait rattaché un reçu — ce que
// personne ne retient. La route GET /receipts rend ce détour inutile.
import 'package:epilist/widgets/common/app_top_bar.dart';
import 'package:epilist/widgets/common/app_drawer.dart';
import 'package:epilist/widgets/common/main_bottom_bar.dart';
import 'package:epilist/widgets/common/main_shell_scope.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/receipt.dart';
import 'package:epilist/screens/receipts_screen.dart';
import 'package:epilist/services/receipt_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/utils/list_picker.dart';
import 'package:epilist/utils/receipt_scan_flow.dart';
import 'package:epilist/widgets/common/app_empty_state.dart';
import 'package:epilist/widgets/common/app_card.dart';
import 'package:epilist/widgets/common/app_section_header.dart';
import 'package:epilist/widgets/common/app_search_field.dart';
import 'package:epilist/widgets/receipts/receipt_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class AllReceiptsScreen extends StatefulWidget {
  const AllReceiptsScreen({super.key});

  @override
  State<AllReceiptsScreen> createState() => _AllReceiptsScreenState();
}

class _AllReceiptsScreenState extends State<AllReceiptsScreen> {
  final _search = TextEditingController();
  String _query = '';

  ReceiptsOverview? _overview;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final overview = await context.read<ReceiptService>().getAllReceipts();
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  List<Receipt> get _shown {
    final all = _overview?.receipts ?? const <Receipt>[];
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where(
          (r) =>
              r.storeName.toLowerCase().contains(q) ||
              (r.listName ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _scan() async {
    final list = await pickShoppingList(context, where: (l) => l.canEdit);
    if (list == null || !mounted) return;
    final saved = await startReceiptScan(context, listId: list.id);
    if (saved && mounted) _load();
  }

  /// Ouvre l'écran de la liste porteuse : c'est là que vivent la
  /// modification, la suppression, l'export et les statistiques.
  Future<void> _openList(Receipt receipt) async {
    final lists = await accessibleLists(context);
    if (!mounted) return;
    final matching = lists.where((l) => l.id == receipt.listId);
    if (matching.isEmpty) return;
    final list = matching.first;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReceiptsScreen(shoppingList: list)),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      bottomNavigationBar: const AppPageBottomBar(tab: MainTab.sections),
      appBar: AppTopBar(
        title: l10n.allReceiptsTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.refresh,
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'all_receipts_scan',
        onPressed: _scan,
        icon: const Icon(Icons.document_scanner_outlined),
        label: Text(l10n.scanReceipt),
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody(l10n)),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading && _overview == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _overview == null) {
      return AppEmptyState(
        icon: Icons.cloud_off_rounded,
        title: l10n.errorLoadingReceipts,
        actionLabel: l10n.retry,
        onAction: _load,
      );
    }

    final all = _overview?.receipts ?? const <Receipt>[];
    if (all.isEmpty) {
      return AppEmptyState(
        icon: Icons.receipt_long_outlined,
        title: l10n.noReceipts,
        message: l10n.allReceiptsEmptyHint,
        actionLabel: l10n.scanReceipt,
        onAction: _scan,
      );
    }

    final shown = _shown;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        96,
      ),
      children: [
        _buildSummary(l10n, all),
        const SizedBox(height: AppSpacing.sm + 4),
        AppSearchField(
          controller: _search,
          hintText: l10n.allReceiptsSearchHint,
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: AppSpacing.md),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Column(
              children: [
                Text(
                  l10n.noResultsFound,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.tryOtherKeywords,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          )
        else
          ..._groupedByMonth(shown, l10n),
        if (_overview?.truncated == true)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              l10n.allReceiptsTruncated,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  /// En-tête : nombre de factures, total, magasins distincts.
  Widget _buildSummary(AppLocalizations l10n, List<Receipt> all) {
    final total =
        _overview?.formattedTotal ??
        all.fold<double>(0, (sum, r) => sum + r.totalAmount).toStringAsFixed(2);
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 22,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.receiptsSummary(all.length, total),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${_overview?.uniqueStores ?? 0} ${l10n.stores}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Regroupement par mois : une facture se cherche par « quand », pas
  /// par rang dans une liste sans fin.
  List<Widget> _groupedByMonth(List<Receipt> receipts, AppLocalizations l10n) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final monthFormat = DateFormat.yMMMM(locale);
    final widgets = <Widget>[];
    String? currentMonth;

    for (final receipt in receipts) {
      final label = monthFormat.format(receipt.purchaseDate);
      if (label != currentMonth) {
        currentMonth = label;
        widgets.add(
          AppSectionHeader(
            title: label,
            padding: EdgeInsets.only(
              top: widgets.isEmpty ? 0 : AppSpacing.sm,
              bottom: AppSpacing.sm,
            ),
          ),
        );
      }
      widgets.add(
        ReceiptCard(
          receipt: receipt,
          canEdit: false,
          onOpenList: () => _openList(receipt),
        ),
      );
    }
    return widgets;
  }
}
