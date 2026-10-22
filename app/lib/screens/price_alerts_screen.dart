// screens/price_alerts_screen.dart - Alertes de prix (§25-§27, Phase 4).
// « Préviens-moi quand {produit} passe sous {prix cible} ». Les alertes
// appartiennent à l'espace actif ; le seuil peut être SUGGÉRÉ à partir
// de l'historique (§26 : prix habituel = médiane, bon prix = 25e
// percentile) mais c'est toujours l'utilisateur qui confirme. Les
// droits (créateur ou manage_lists) sont tranchés par le serveur.
import 'package:epilist/utils/add_product_to_list.dart';
import 'package:epilist/widgets/common/app_states.dart';
import 'package:epilist/widgets/common/drawer_menu_button.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/space.dart';
import 'package:epilist/services/screen_cache.dart';
import 'package:epilist/services/space_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/widgets/common/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PriceAlertsScreen extends StatefulWidget {
  const PriceAlertsScreen({super.key});

  @override
  State<PriceAlertsScreen> createState() => _PriceAlertsScreenState();
}

class _PriceAlertsScreenState extends State<PriceAlertsScreen> {
  List<PriceAlertInfo>? _alerts;
  bool _error = false;

  SpaceService get _service => context.read<SpaceService>();

  @override
  void initState() {
    super.initState();
    // Afficher d'abord la derniere version connue (pas de spinner
    // si on est deja venu), puis rafraichir en silence.
    _alerts = ScreenCache.read<List<PriceAlertInfo>>('price_alerts');
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _service.getPriceAlerts();
      ScreenCache.write('price_alerts', list);
      if (!mounted) return;
      setState(() {
        _alerts = list;
        _error = false;
      });
    } catch (_) {
      if (!mounted) return;
      // Un rafraichissement rate n'efface pas les donnees affichees.
      if (_alerts == null) setState(() => _error = true);
    }
  }

  String _money(double v) => v.toStringAsFixed(2);

  Future<void> _edit([PriceAlertInfo? existing]) async {
    final l10n = AppLocalizations.of(context)!;
    final product = TextEditingController(text: existing?.productName ?? '');
    final target = TextEditingController(
      text: existing != null ? _money(existing.targetPrice) : '',
    );
    String? suggestion;
    bool suggesting = false;

    final saved = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (dialogContext, setLocal) => Dialog(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppDialogHeader(
                          icon: Icons.notifications_active_outlined,
                          title:
                              existing == null
                                  ? l10n.priceAlertNew
                                  : existing.productName,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (existing == null) ...[
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
                        ],
                        TextField(
                          controller: target,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.priceAlertTarget,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // §26 : seuil suggéré depuis l'historique de l'espace
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed:
                                suggesting
                                    ? null
                                    : () async {
                                      final name =
                                          existing?.productName ??
                                          product.text.trim();
                                      if (name.isEmpty) return;
                                      setLocal(() => suggesting = true);
                                      try {
                                        final s = await _service
                                            .suggestPriceTarget(name);
                                        if (!dialogContext.mounted) return;
                                        setLocal(() {
                                          suggesting = false;
                                          if (s.suggestedTarget != null) {
                                            target.text = _money(
                                              s.suggestedTarget!,
                                            );
                                            suggestion = l10n
                                                .priceAlertSuggestion(
                                                  _money(s.usualPrice ?? 0),
                                                  _money(s.goodPrice ?? 0),
                                                  s.observations,
                                                );
                                          } else {
                                            suggestion =
                                                l10n.priceAlertNoHistory;
                                          }
                                        });
                                      } catch (_) {
                                        if (!dialogContext.mounted) return;
                                        setLocal(() {
                                          suggesting = false;
                                          suggestion = l10n.priceAlertNoHistory;
                                        });
                                      }
                                    },
                            icon:
                                suggesting
                                    ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(
                                      Icons.auto_awesome_outlined,
                                      size: 18,
                                    ),
                            label: Text(l10n.priceAlertSuggest),
                          ),
                        ),
                        if (suggestion != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Text(
                              suggestion!,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.sm),
                        AppDialogActions(
                          cancelLabel: l10n.cancel,
                          submitLabel: l10n.save,
                          onCancel: () => Navigator.pop(dialogContext, false),
                          onSubmit: () async {
                            final name =
                                existing?.productName ?? product.text.trim();
                            final price = double.tryParse(
                              target.text.trim().replaceAll(',', '.'),
                            );
                            if (name.isEmpty || price == null || price <= 0) {
                              return;
                            }
                            try {
                              if (existing == null) {
                                await _service.createPriceAlert(
                                  productName: name,
                                  targetPrice: price,
                                );
                              } else {
                                await _service.updatePriceAlert(
                                  existing.id,
                                  targetPrice: price,
                                );
                              }
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext, true);
                              }
                            } catch (_) {
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext, false);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );

    if (!mounted) return;
    if (saved == true) {
      SmartSnackBarManager.showSuccessSnackBar(
        context,
        existing == null ? l10n.priceAlertCreated : l10n.priceAlertUpdated,
      );
      _load();
    }
  }

  Future<void> _toggleActive(PriceAlertInfo a, bool active) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _service.updatePriceAlert(a.id, isActive: active);
      _load();
    } catch (_) {
      if (!mounted) return;
      SmartSnackBarManager.showErrorSnackBar(context, l10n.anErrorOccurred);
    }
  }

  Future<void> _delete(PriceAlertInfo a) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppDialogHeader(
                    icon: Icons.delete_outline_rounded,
                    title: l10n.priceAlertDelete,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    a.productName,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppDialogActions(
                    cancelLabel: l10n.cancel,
                    submitLabel: l10n.delete,
                    destructive: true,
                    onCancel: () => Navigator.pop(dialogContext, false),
                    onSubmit: () => Navigator.pop(dialogContext, true),
                  ),
                ],
              ),
            ),
          ),
    );
    if (ok != true || !mounted) return;
    try {
      await _service.deletePriceAlert(a.id);
      if (!mounted) return;
      SmartSnackBarManager.showSuccessSnackBar(context, l10n.priceAlertDeleted);
      _load();
    } catch (_) {
      if (!mounted) return;
      SmartSnackBarManager.showErrorSnackBar(context, l10n.anErrorOccurred);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: DrawerMenuButton.leadingOrNull(context),
        title: Text(l10n.priceAlerts),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: Text(l10n.priceAlertNew),
      ),
      body:
          _alerts == null && !_error
              ? const Center(child: CircularProgressIndicator())
              : _error
              ? Center(
                child: Text(
                  l10n.anErrorOccurred,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
              : _alerts!.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    l10n.priceAlertEmpty,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
              : RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    96,
                  ),
                  itemCount: _alerts!.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Text(
                          l10n.priceAlertsIntro,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }
                    return _alertCard(_alerts![i - 1], l10n);
                  },
                ),
              ),
    );
  }

  /// La carte d'une alerte, comme sur la planche.
  ///
  /// Avant : une `ListTile` ou tout tenait en « Vu a 4.99 $ · IGA · Par
  /// Sara » en 12 points, avec une puce « Cible 5.00 $ » en 11. Aucune
  /// baisse n'etait annoncee, et il fallait comparer deux nombres de
  /// taille differente pour savoir s'il fallait acheter.
  ///
  /// Maintenant : la baisse en toutes lettres avec sa fleche, l'ancien
  /// et le nouveau prix, l'economie, et le bouton qui met le produit
  /// dans une liste.
  Widget _alertCard(PriceAlertInfo a, AppLocalizations l10n) {
    final vu = a.lastObservedPrice;
    final notifie = a.lastNotifiedPrice;

    // La baisse n'est annoncee que si DEUX prix la prouvent. Comparer
    // un prix vu a un prix VISE ne dit rien d'une baisse : le prix vise
    // est un souhait, pas un historique.
    double? baisse;
    if (vu != null && notifie != null && notifie > 0 && vu != notifie) {
      baisse = (notifie - vu) / notifie * 100;
    }
    final atteint = vu != null && vu <= a.targetPrice;
    final economie = atteint ? a.targetPrice - vu : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(
            color:
                a.isActive
                    ? (atteint ? AppColors.primaryVivid : AppColors.border)
                    : AppColors.border,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md + 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      a.productName,
                      style: AppFonts.displayStyle(
                        size: 23,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.edit,
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _edit(a),
                  ),
                  IconButton(
                    tooltip: l10n.delete,
                    icon: Icon(Icons.delete_outline, color: AppColors.errorInk),
                    onPressed: () => _delete(a),
                  ),
                ],
              ),
              if (a.lastObservedStore != null &&
                  a.lastObservedStore!.isNotEmpty)
                Text(
                  a.lastObservedStore!,
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              if (baisse != null) ...[
                const SizedBox(height: AppSpacing.sm + 4),
                _baisseBadge(l10n, baisse),
              ],
              const SizedBox(height: AppSpacing.sm + 4),
              if (vu == null)
                Text(
                  '${l10n.priceAlertTargetLine(_money(a.targetPrice))} '
                  '${l10n.priceAlertNoPriceYet}',
                  style: TextStyle(
                    fontSize: 19,
                    height: 1.55,
                    color: AppColors.textPrimary,
                  ),
                )
              else ...[
                if (notifie != null && baisse != null && baisse > 0)
                  Text(
                    l10n.priceAlertOldPrice(_money(notifie)),
                    style: TextStyle(
                      fontSize: 19,
                      height: 1.55,
                      color: AppColors.textPrimary,
                    ),
                  ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${l10n.priceAlertNewPriceLabel} ',
                        style: TextStyle(
                          fontSize: 19,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: '${_money(vu)} \$',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  l10n.priceAlertTargetLine(_money(a.targetPrice)),
                  style: TextStyle(
                    fontSize: 19,
                    height: 1.55,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs + 2),
                Text(
                  atteint
                      ? (economie != null && economie > 0
                          ? '${l10n.priceAlertReached} '
                              '${l10n.priceAlertSaving(_money(economie))}'
                          : l10n.priceAlertReached)
                      : l10n.priceAlertWaiting,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                    color:
                        atteint
                            ? AppColors.successInk
                            : AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm + 4),
              AppStateSwitch(
                value: a.isActive,
                stateLabel:
                    a.isActive
                        ? l10n.priceAlertStateOn
                        : l10n.priceAlertStateOff,
                semanticLabel: a.productName,
                onChanged: (v) => _toggleActive(a, v),
              ),
              const SizedBox(height: AppSpacing.sm + 4),
              OutlinedButton.icon(
                onPressed: () => addProductToList(context, a.productName),
                icon: const Icon(Icons.add_shopping_cart_outlined),
                label: Text(l10n.addToMyList),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// « ↓ Baisse de 14 pour cent ». La fleche ET le mot : une pastille
  /// verte seule laisse deviner le sens de la variation.
  Widget _baisseBadge(AppLocalizations l10n, double variation) {
    final baisse = variation > 0;
    final pourcent = variation.abs().round().toString();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: baisse ? AppColors.primary : AppColors.error,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            baisse ? Icons.south_rounded : Icons.north_rounded,
            size: 24,
            color: AppColors.onPrimary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            baisse
                ? l10n.priceAlertDrop(pourcent)
                : l10n.priceAlertRise(pourcent),
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
