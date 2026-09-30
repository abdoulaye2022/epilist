// screens/pre_shopping_screen.dart - « Avant les courses » (§28,
// Phase 5). Le brief de l'espace actif en un écran : budget du mois,
// à racheter probablement (prédictions), ruptures/sous seuil, prix
// repérés récemment, demandes d'achat en attente (espaces pro), et
// les économies estimées DOCUMENTÉES (§30). L'icône de l'AppBar ouvre
// « Est-ce un bon prix ? » (§29) : verdict prudent + les chiffres.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/services/space_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PreShoppingScreen extends StatefulWidget {
  const PreShoppingScreen({super.key});

  @override
  State<PreShoppingScreen> createState() => _PreShoppingScreenState();
}

class _PreShoppingScreenState extends State<PreShoppingScreen> {
  Map<String, dynamic>? _brief;
  Map<String, dynamic>? _savings;
  bool _error = false;

  SpaceService get _service => context.read<SpaceService>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait(
          [_service.getPreShopping(), _service.getSavings()]);
      if (!mounted) return;
      setState(() {
        _brief = results[0];
        _savings = results[1];
        _error = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = true);
    }
  }

  String _money(num v) => v.toDouble().toStringAsFixed(2);

  // --- « Est-ce un bon prix ? » (§29) -----------------------------------

  Future<void> _openPriceCheck() async {
    final l10n = AppLocalizations.of(context)!;
    final product = TextEditingController();
    final price = TextEditingController();
    Map<String, dynamic>? result;
    bool checking = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocal) {
          final verdict = result?['verdict'] as String?;
          final (verdictLabel, verdictColor) = switch (verdict) {
            'good' => (l10n.priceCheckGood, AppColors.primaryDark),
            'fair' => (l10n.priceCheckFair, const Color(0xFFB45309)),
            'high' => (l10n.priceCheckHigh, AppColors.error),
            'unknown' => (l10n.priceCheckUnknown, AppColors.textSecondary),
            _ => ('', AppColors.textSecondary),
          };
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppDialogHeader(
                    icon: Icons.price_check_rounded,
                    title: l10n.priceCheckTitle,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: product,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.priceAlertProduct,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: price,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.priceCheckPrice,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (verdict != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm + 4),
                      decoration: BoxDecoration(
                        color: verdictColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            verdictLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: verdictColor,
                            ),
                          ),
                          if (verdict != 'unknown' &&
                              result?['usual_price'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                l10n.priceCheckUsual(
                                    _money(result!['usual_price'] as num),
                                    _money(result!['good_price'] as num)),
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary),
                              ),
                            ),
                          // Repère communautaire anonymisé (§33)
                          if (result?['community'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                l10n.communityLine(
                                    _money((result!['community']
                                        as Map)['median_price'] as num),
                                    ((result!['community'] as Map)['store_label']
                                            as String?) ??
                                        '—',
                                    (result!['community']
                                            as Map)['contributors'] as int? ??
                                        0),
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  AppDialogActions(
                    cancelLabel: l10n.close,
                    submitLabel: l10n.priceCheckAction,
                    onCancel: () => Navigator.pop(dialogContext),
                    onSubmit: checking
                        ? () {}
                        : () async {
                            final name = product.text.trim();
                            final p = double.tryParse(
                                price.text.trim().replaceAll(',', '.'));
                            if (name.isEmpty || p == null || p <= 0) return;
                            setLocal(() => checking = true);
                            try {
                              final r = await _service.checkPrice(name, p);
                              if (!dialogContext.mounted) return;
                              setLocal(() {
                                checking = false;
                                result = r;
                              });
                            } catch (_) {
                              if (!dialogContext.mounted) return;
                              setLocal(() => checking = false);
                            }
                          },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Rendu -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.preShopping),
        actions: [
          IconButton(
            tooltip: l10n.priceCheckTitle,
            icon: const Icon(Icons.price_check_rounded),
            onPressed: _openPriceCheck,
          ),
        ],
      ),
      body: _brief == null && !_error
          ? const Center(child: CircularProgressIndicator())
          : _error
              ? Center(
                  child: Text(l10n.anErrorOccurred,
                      style: const TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: _sections(l10n),
                  ),
                ),
    );
  }

  List<Widget> _sections(AppLocalizations l10n) {
    final brief = _brief!;
    final budget = brief['budget'] as Map<String, dynamic>?;
    final restock = (brief['restock'] as List? ?? []);
    final inventory = (brief['inventory_alerts'] as List? ?? []);
    final priceWatch = (brief['price_watch'] as List? ?? []);
    final pending = brief['pending_requests'] as int?;
    final savingsTotal = (_savings?['total_saving'] as num?)?.toDouble() ?? 0;
    final savingsItems = (_savings?['items'] as List? ?? []);

    return [
      // Budget du mois
      if (budget != null)
        _card(
          icon: Icons.savings_outlined,
          title: l10n.preShoppingBudget,
          child: Text(
            l10n.preShoppingBudgetRemaining(
                _money(budget['remaining'] as num? ?? 0),
                budget['days_left'] as int? ?? 0),
            style: const TextStyle(
                fontSize: 14, color: AppColors.textPrimary, height: 1.4),
          ),
        ),

      // Demandes d'achat en attente (espaces pro)
      if (pending != null && pending > 0)
        _card(
          icon: Icons.assignment_outlined,
          title: l10n.purchaseRequests,
          child: Text(
            l10n.preShoppingRequests(pending),
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
        ),

      // À racheter probablement
      _card(
        icon: Icons.replay_rounded,
        title: l10n.preShoppingRestock,
        child: restock.isEmpty
            ? Text(l10n.preShoppingRestockEmpty,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary))
            : Column(
                children: [
                  for (final r in restock.cast<Map<String, dynamic>>())
                    _line(
                      (r['product_name'] as String?) ?? '',
                      trailing: _statusChip(r['status'] as String? ?? '',
                          (r['below_min'] as bool?) ?? false, l10n),
                      sub: r['usual_store'] as String?,
                    ),
                ],
              ),
      ),

      // Ruptures / sous le seuil
      if (inventory.isNotEmpty)
        _card(
          icon: Icons.remove_shopping_cart_outlined,
          title: l10n.preShoppingInventory,
          child: Column(
            children: [
              for (final i in inventory.cast<Map<String, dynamic>>())
                _line(
                  (i['product_name'] as String?) ?? '',
                  sub: i['quantity'] != null && i['min_quantity'] != null
                      ? '${_money(i['quantity'] as num)}${i['unit'] ?? ''} / ${_money(i['min_quantity'] as num)}${i['unit'] ?? ''}'
                      : null,
                  trailing: const Icon(Icons.warning_amber_rounded,
                      size: 18, color: AppColors.error),
                ),
            ],
          ),
        ),

      // Prix repérés récemment
      if (priceWatch.isNotEmpty)
        _card(
          icon: Icons.trending_down_rounded,
          title: l10n.preShoppingPriceWatch,
          child: Column(
            children: [
              for (final a in priceWatch.cast<Map<String, dynamic>>())
                _line(
                  (a['product_name'] as String?) ?? '',
                  sub: a['last_notified_price'] != null
                      ? l10n.priceAlertLastSeen(
                          _money(a['last_notified_price'] as num), '')
                      : null,
                  trailing: Text(
                    l10n.priceAlertTargetChip(
                        _money(a['target_price'] as num? ?? 0)),
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark),
                  ),
                ),
            ],
          ),
        ),

      // Économies estimées documentées (§30)
      _card(
        icon: Icons.celebration_outlined,
        title: l10n.savingsTitle,
        child: savingsTotal <= 0
            ? Text(l10n.savingsEmpty,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.savingsTotal(_money(savingsTotal)),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  for (final s
                      in savingsItems.take(5).cast<Map<String, dynamic>>())
                    _line(
                      (s['product_name'] as String?) ?? '',
                      sub: l10n.savingsLine(_money(s['paid'] as num? ?? 0),
                          _money(s['usual_price'] as num? ?? 0)),
                      trailing: Text(
                        '+${_money(s['saving'] as num? ?? 0)} \$',
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark),
                      ),
                    ),
                ],
              ),
      ),
    ];
  }

  Widget _statusChip(String status, bool belowMin, AppLocalizations l10n) {
    final (label, color) = switch (status) {
      'overdue' => (l10n.statusOverdue, AppColors.error),
      'likely_needed' => (l10n.statusLikelyNeeded, const Color(0xFFB45309)),
      _ => (l10n.statusSoon, AppColors.primaryDark),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        belowMin ? '$label ↓' : label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _line(String title, {String? sub, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                if (sub != null && sub.isNotEmpty)
                  Text(sub,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _card(
      {required IconData icon, required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryDark),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
