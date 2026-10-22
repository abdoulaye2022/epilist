// screens/pre_shopping_screen.dart - « Avant les courses » (§28,
// Phase 5). Le brief de l'espace actif en un écran : budget du mois,
// à racheter probablement (prédictions), ruptures/sous seuil, prix
// repérés récemment, demandes d'achat en attente (espaces pro), et
// les économies estimées DOCUMENTÉES (§30). L'icône de l'AppBar ouvre
// « Est-ce un bon prix ? » (§29) : verdict prudent + les chiffres.
import 'package:epilist/screens/inventory_screen.dart';
import 'package:epilist/utils/shopping_mode_launcher.dart';
import 'package:epilist/widgets/common/app_meters.dart';
import 'package:epilist/widgets/common/app_states.dart';
import 'package:epilist/widgets/common/drawer_menu_button.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/services/screen_cache.dart';
import 'package:epilist/services/space_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/widgets/common/app_card.dart';

class PreShoppingScreen extends StatefulWidget {
  const PreShoppingScreen({super.key});

  @override
  State<PreShoppingScreen> createState() => _PreShoppingScreenState();
}

class _PreShoppingScreenState extends State<PreShoppingScreen> {
  /// Les cinq etapes de la planche, cochees ou non. Elles vivent dans
  /// l'etat de l'ecran : la coquille le garde en vie tant que
  /// l'application tourne, et une liste de preparation n'a pas de sens
  /// a survivre a la sortie de courses qu'elle preparait.
  final List<bool> _steps = List<bool>.filled(5, false);

  Map<String, dynamic>? _brief;
  Map<String, dynamic>? _savings;
  bool _error = false;

  SpaceService get _service => context.read<SpaceService>();

  @override
  void initState() {
    super.initState();
    _brief = ScreenCache.read<Map<String, dynamic>>('pre_shopping_brief');
    _savings = ScreenCache.read<Map<String, dynamic>>('pre_shopping_savings');
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _service.getPreShopping(),
        _service.getSavings(),
      ]);
      if (!mounted) return;
      ScreenCache.write('pre_shopping_brief', results[0]);
      ScreenCache.write('pre_shopping_savings', results[1]);
      setState(() {
        _brief = results[0];
        _savings = results[1];
        _error = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (_brief == null) setState(() => _error = true);
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
      builder:
          (dialogContext) => StatefulBuilder(
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: price,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.priceCheckPrice,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                                      _money(result!['good_price'] as num),
                                    ),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              // Repère communautaire anonymisé (§33)
                              if (result?['community'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    l10n.communityLine(
                                      _money(
                                        (result!['community']
                                                as Map)['median_price']
                                            as num,
                                      ),
                                      ((result!['community']
                                                  as Map)['store_label']
                                              as String?) ??
                                          '—',
                                      (result!['community']
                                                  as Map)['contributors']
                                              as int? ??
                                          0,
                                    ),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary,
                                    ),
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
                        onSubmit:
                            checking
                                ? () {}
                                : () async {
                                  final name = product.text.trim();
                                  final p = double.tryParse(
                                    price.text.trim().replaceAll(',', '.'),
                                  );
                                  if (name.isEmpty || p == null || p <= 0) {
                                    return;
                                  }
                                  setLocal(() => checking = true);
                                  try {
                                    final r = await _service.checkPrice(
                                      name,
                                      p,
                                    );
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
        leading: DrawerMenuButton.leadingOrNull(context),
        title: Text(l10n.preShopping),
        actions: [
          IconButton(
            tooltip: l10n.priceCheckTitle,
            icon: const Icon(Icons.price_check_rounded),
            onPressed: _openPriceCheck,
          ),
        ],
      ),
      body:
          _brief == null && !_error
              ? const Center(child: CircularProgressIndicator())
              : _error
              ? Center(
                child: Text(
                  l10n.anErrorOccurred,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
              : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: _sections(l10n),
                ),
              ),
    );
  }

  /// « Avant de partir » : les cinq etapes de la planche, leur compteur
  /// vivant, et les deux boutons qui suivent.
  ///
  /// L'ecran etait un brief de donnees — budget, ruptures, prix reperes.
  /// Il disait ce que l'espace actif SAIT, jamais ce qu'il reste a
  /// FAIRE avant de sortir. Les deux coexistent : la liste d'abord, le
  /// brief ensuite.
  List<Widget> _checklist(AppLocalizations l10n, int alertes) {
    final prets = _steps.where((e) => e).length;
    final titres = <(String, String)>[
      (l10n.preShoppingStepStock, l10n.preShoppingStepStockHint),
      (l10n.preShoppingStepBags, l10n.preShoppingStepBagsHint),
      (l10n.preShoppingStepCard, l10n.preShoppingStepCardHint),
      (l10n.preShoppingStepAlerts, l10n.preShoppingStepAlertsHint(alertes)),
      (l10n.preShoppingStepBattery, l10n.preShoppingStepBatteryHint),
    ];

    return [
      Text(
        l10n.preShoppingChecklist,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        l10n.preShoppingChecklistIntro,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: AppSpacing.md),
      AppCounterCard(
        count: l10n.preShoppingStepsCount(prets, _steps.length),
        sentence: l10n.preShoppingStepsLeft(_steps.length - prets),
        ratio: prets / _steps.length,
      ),
      const SizedBox(height: AppSpacing.md),
      for (var i = 0; i < titres.length; i++)
        AppCheckRow(
          checked: _steps[i],
          title: titres[i].$1,
          subtitle: titres[i].$2,
          doneLabel: l10n.stepDone,
          onChanged: (v) => setState(() => _steps[i] = v),
        ),
      const SizedBox(height: AppSpacing.sm),
      FilledButton.icon(
        onPressed: () => openShoppingMode(context),
        icon: const Icon(Icons.shopping_cart_checkout_rounded),
        label: Text(l10n.preShoppingReady),
      ),
      const SizedBox(height: AppSpacing.sm + 4),
      OutlinedButton.icon(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InventoryScreen()),
            ),
        icon: const Icon(Icons.kitchen_outlined),
        label: Text(l10n.preShoppingCheckStock),
      ),
    ];
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
      ..._checklist(l10n, priceWatch.length),
      const SizedBox(height: AppSpacing.lg),

      // Budget du mois
      if (budget != null)
        _card(
          icon: Icons.savings_outlined,
          title: l10n.preShoppingBudget,
          child: Text(
            l10n.preShoppingBudgetRemaining(
              _money(budget['remaining'] as num? ?? 0),
              budget['days_left'] as int? ?? 0,
            ),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),

      // Demandes d'achat en attente (espaces pro)
      if (pending != null && pending > 0)
        _card(
          icon: Icons.assignment_outlined,
          title: l10n.purchaseRequests,
          child: Text(
            l10n.preShoppingRequests(pending),
            style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
        ),

      // À racheter probablement
      _card(
        icon: Icons.replay_rounded,
        title: l10n.preShoppingRestock,
        child:
            restock.isEmpty
                ? Text(
                  l10n.preShoppingRestockEmpty,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                )
                : Column(
                  children: [
                    for (final r in restock.cast<Map<String, dynamic>>())
                      _line(
                        (r['product_name'] as String?) ?? '',
                        trailing: _statusChip(
                          r['status'] as String? ?? '',
                          (r['below_min'] as bool?) ?? false,
                          l10n,
                        ),
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
                  sub:
                      i['quantity'] != null && i['min_quantity'] != null
                          ? '${_money(i['quantity'] as num)}${i['unit'] ?? ''} / ${_money(i['min_quantity'] as num)}${i['unit'] ?? ''}'
                          : null,
                  trailing: Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: AppColors.error,
                  ),
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
                  sub:
                      a['last_notified_price'] != null
                          ? l10n.priceAlertLastSeen(
                            _money(a['last_notified_price'] as num),
                            '',
                          )
                          : null,
                  trailing: Text(
                    l10n.priceAlertTargetChip(
                      _money(a['target_price'] as num? ?? 0),
                    ),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
            ],
          ),
        ),

      // Économies estimées documentées (§30)
      _card(
        icon: Icons.celebration_outlined,
        title: l10n.savingsTitle,
        child:
            savingsTotal <= 0
                ? Text(
                  l10n.savingsEmpty,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.savingsTotal(_money(savingsTotal)),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    for (final s
                        in savingsItems.take(5).cast<Map<String, dynamic>>())
                      _line(
                        (s['product_name'] as String?) ?? '',
                        sub: l10n.savingsLine(
                          _money(s['paid'] as num? ?? 0),
                          _money(s['usual_price'] as num? ?? 0),
                        ),
                        trailing: Text(
                          '+${_money(s['saving'] as num? ?? 0)} \$',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
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
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
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
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (sub != null && sub.isNotEmpty)
                  Text(
                    sub,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return AppCard(
      radius: 14,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryDark),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
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
