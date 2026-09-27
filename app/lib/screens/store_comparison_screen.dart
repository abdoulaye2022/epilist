// screens/store_comparison_screen.dart - Comparateur de magasins et plan
// d'achat optimisé pour une liste. Même langage visuel que Budgets et
// Analytiques : chips de sections, cartes du thème.
//
// Honnêteté des données avant tout : couverture affichée (« 10 prix
// connus sur 12 articles »), fraîcheur de chaque prix, et rappel que ce
// sont les prix de VOS achats, pas des prix officiels.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/price_intelligence.dart';
import 'package:epilist/services/price_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StoreComparisonScreen extends StatefulWidget {
  final int listId;
  final String listName;

  const StoreComparisonScreen({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  State<StoreComparisonScreen> createState() => _StoreComparisonScreenState();
}

enum _Section { comparison, optimization }

class _StoreComparisonScreenState extends State<StoreComparisonScreen> {
  _Section _section = _Section.comparison;
  int _windowDays = 90;
  int _maxStores = 2;

  ComparisonResult? _comparison;
  OptimizationResult? _optimization;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final service = context.read<PriceService>();
    try {
      final results = await Future.wait([
        service.getStoreComparison(widget.listId, days: _windowDays),
        service.getOptimization(widget.listId,
            maxStores: _maxStores, days: _windowDays),
      ]);
      if (!mounted) return;
      setState(() {
        _comparison = results[0] as ComparisonResult;
        _optimization = results[1] as OptimizationResult;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.storeComparisonTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildChips(l10n),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _buildBody(l10n),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChips(AppLocalizations l10n) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        children: [
          ChoiceChip(
            label: Text(l10n.compareStores),
            selected: _section == _Section.comparison,
            showCheckmark: false,
            onSelected: (_) =>
                setState(() => _section = _Section.comparison),
          ),
          const SizedBox(width: AppSpacing.sm),
          ChoiceChip(
            label: Text(l10n.optimizePlan),
            selected: _section == _Section.optimization,
            showCheckmark: false,
            onSelected: (_) =>
                setState(() => _section = _Section.optimization),
          ),
          const SizedBox(width: AppSpacing.md),
          // Fenêtre de temps configurable (30/90/180/365 jours)
          for (final days in const [30, 90, 180, 365]) ...[
            ChoiceChip(
              label: Text(l10n.daysShort(days)),
              selected: _windowDays == days,
              showCheckmark: false,
              onSelected: (_) {
                setState(() => _windowDays = days);
                _load();
              },
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary)),
        ],
      );
    }

    final children = <Widget>[
      Text(widget.listName,
          style:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(
        l10n.comparisonBasedOn(_windowDays),
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      const SizedBox(height: AppSpacing.md),
      if (_section == _Section.comparison)
        ..._comparisonContent(l10n)
      else
        ..._optimizationContent(l10n),
      const SizedBox(height: AppSpacing.lg),
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
      children: children,
    );
  }

  // --- Comparateur -------------------------------------------------------

  List<Widget> _comparisonContent(AppLocalizations l10n) {
    final c = _comparison;
    if (c == null || c.stores.isEmpty) {
      return [_emptyCard(l10n.noComparisonData)];
    }
    return c.stores.map((s) => _storeCard(l10n, s)).toList();
  }

  Widget _storeCard(AppLocalizations l10n, StoreComparison s) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        title: Text(s.storeName ?? '—',
            style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        subtitle: Text(
          l10n.knownPricesOn(s.knownItems, s.itemsCount),
          style:
              const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: FormattedAmount(
          amount: s.estimatedTotal,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary),
        ),
        children: s.items
            .map((it) => Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          it.quantity > 1
                              ? '${it.name} ×${it.quantity}'
                              : it.name,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      if (it.price == null)
                        Text(l10n.unknownPrice,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textDisabled,
                                fontStyle: FontStyle.italic))
                      else ...[
                        _freshnessChip(l10n, it.freshness),
                        const SizedBox(width: AppSpacing.sm),
                        FormattedAmount(
                          amount: it.price! * it.quantity,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _freshnessChip(AppLocalizations l10n, String? freshness) {
    final (label, color) = switch (freshness) {
      'fresh' => (l10n.priceFreshnessFresh, AppColors.primary),
      'acceptable' => (l10n.priceFreshnessAcceptable, AppColors.primary),
      'old' => (l10n.priceFreshnessOld, AppColors.warning),
      _ => (l10n.priceFreshnessStale, AppColors.textDisabled),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(label, style: TextStyle(fontSize: 10.5, color: color)),
    );
  }

  // --- Optimiseur ---------------------------------------------------------

  List<Widget> _optimizationContent(AppLocalizations l10n) {
    final o = _optimization;
    if (o == null || !o.feasible) {
      return [_emptyCard(l10n.notEnoughPriceData)];
    }

    final splitWorthIt = o.planStores.length > 1;
    return [
      // Nombre maximal de magasins (1 à 3)
      Row(
        children: [
          Text('${l10n.maxStoresLabel} : ',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          for (final n in const [1, 2, 3]) ...[
            const SizedBox(width: AppSpacing.xs),
            ChoiceChip(
              label: Text('$n'),
              selected: _maxStores == n,
              showCheckmark: false,
              onSelected: (_) {
                setState(() => _maxStores = n);
                _load();
              },
            ),
          ],
        ],
      ),
      const SizedBox(height: AppSpacing.md),

      // Référence : tout au même endroit
      if (o.singleStoreName != null && o.singleStoreTotal != null)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            l10n.singleStorePlan(
              o.singleStoreName!,
              '${o.singleStoreTotal!.toStringAsFixed(2)} \$',
            ),
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
        ),

      if (!splitWorthIt && _maxStores > 1)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            l10n.notWorthSplitting,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
        ),

      if (o.saving > 0.005)
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm + 4),
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              const Icon(Icons.savings_outlined,
                  size: 18, color: AppColors.primaryDark),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.estimatedSaving('${o.saving.toStringAsFixed(2)} \$'),
                style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark),
              ),
            ],
          ),
        ),

      ...o.planStores.map((store) => Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storefront_outlined,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(store.storeName ?? '—',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                      ),
                      FormattedAmount(
                        amount: store.subtotal,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...store.items.map((it) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                it.quantity > 1
                                    ? '${it.name} ×${it.quantity}'
                                    : it.name,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            FormattedAmount(
                              amount: it.price * it.quantity,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          )),

      if (o.estimatedElsewhere.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            l10n.estimatedElsewhereNote(
              o.estimatedElsewhere.map((e) => e.name).join(', '),
            ),
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
    ];
  }

  Widget _emptyCard(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(Icons.storefront_outlined,
              size: 56, color: Colors.grey[400]),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
