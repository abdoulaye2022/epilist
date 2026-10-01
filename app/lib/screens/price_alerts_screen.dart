// screens/price_alerts_screen.dart - Alertes de prix (§25-§27, Phase 4).
// « Préviens-moi quand {produit} passe sous {prix cible} ». Les alertes
// appartiennent à l'espace actif ; le seuil peut être SUGGÉRÉ à partir
// de l'historique (§26 : prix habituel = médiane, bon prix = 25e
// percentile) mais c'est toujours l'utilisateur qui confirme. Les
// droits (créateur ou manage_lists) sont tranchés par le serveur.
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
        text: existing != null ? _money(existing.targetPrice) : '');
    String? suggestion;
    bool suggesting = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocal) => Dialog(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppDialogHeader(
                  icon: Icons.notifications_active_outlined,
                  title: existing == null
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
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                TextField(
                  controller: target,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.priceAlertTarget,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // §26 : seuil suggéré depuis l'historique de l'espace
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: suggesting
                        ? null
                        : () async {
                            final name = existing?.productName ??
                                product.text.trim();
                            if (name.isEmpty) return;
                            setLocal(() => suggesting = true);
                            try {
                              final s =
                                  await _service.suggestPriceTarget(name);
                              if (!dialogContext.mounted) return;
                              setLocal(() {
                                suggesting = false;
                                if (s.suggestedTarget != null) {
                                  target.text = _money(s.suggestedTarget!);
                                  suggestion = l10n.priceAlertSuggestion(
                                      _money(s.usualPrice ?? 0),
                                      _money(s.goodPrice ?? 0),
                                      s.observations);
                                } else {
                                  suggestion = l10n.priceAlertNoHistory;
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
                    icon: suggesting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.auto_awesome_outlined, size: 18),
                    label: Text(l10n.priceAlertSuggest),
                  ),
                ),
                if (suggestion != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      suggestion!,
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textSecondary),
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
                        target.text.trim().replaceAll(',', '.'));
                    if (name.isEmpty || price == null || price <= 0) return;
                    try {
                      if (existing == null) {
                        await _service.createPriceAlert(
                            productName: name, targetPrice: price);
                      } else {
                        await _service.updatePriceAlert(existing.id,
                            targetPrice: price);
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
          existing == null ? l10n.priceAlertCreated : l10n.priceAlertUpdated);
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
      builder: (dialogContext) => Dialog(
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
                style: const TextStyle(color: AppColors.textSecondary),
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
      appBar: AppBar(title: Text(l10n.priceAlerts)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.priceAlertNew),
      ),
      body: _alerts == null && !_error
          ? const Center(child: CircularProgressIndicator())
          : _error
              ? Center(
                  child: Text(l10n.anErrorOccurred,
                      style: const TextStyle(color: AppColors.textSecondary)))
              : _alerts!.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          l10n.priceAlertEmpty,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                            AppSpacing.md, AppSpacing.md, 96),
                        itemCount: _alerts!.length,
                        itemBuilder: (context, i) =>
                            _alertCard(_alerts![i], l10n),
                      ),
                    ),
    );
  }

  Widget _alertCard(PriceAlertInfo a, AppLocalizations l10n) {
    final subtitle = <String>[
      if (a.lastObservedPrice != null)
        l10n.priceAlertLastSeen(_money(a.lastObservedPrice!),
            a.lastObservedStore ?? '—'),
      if (a.createdByName != null && a.createdByName!.isNotEmpty)
        l10n.priceAlertBy(a.createdByName!),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: () => _edit(a),
        onLongPress: () => _delete(a),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: a.isActive
                ? AppColors.primaryLight
                : AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            a.isActive
                ? Icons.notifications_active_outlined
                : Icons.notifications_paused_outlined,
            size: 20,
            color: a.isActive
                ? AppColors.primaryDark
                : AppColors.textDisabled,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                a.productName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: a.isActive
                      ? AppColors.textPrimary
                      : AppColors.textDisabled,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l10n.priceAlertTargetChip(_money(a.targetPrice)),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
        subtitle: subtitle.isEmpty
            ? null
            : Text(
                subtitle.join(' · '),
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
        trailing: Switch(
          value: a.isActive,
          activeThumbColor: AppColors.primary,
          onChanged: (v) => _toggleActive(a, v),
        ),
      ),
    );
  }
}
