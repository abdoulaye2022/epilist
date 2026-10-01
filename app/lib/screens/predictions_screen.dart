// screens/predictions_screen.dart - « Toutes les suggestions » :
// prédictions d'achat avec les quatre actions de feedback (§8).
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/intelligence.dart';
import 'package:epilist/services/screen_cache.dart';
import 'package:epilist/services/intelligence_service.dart';
import 'package:epilist/services/list_item_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PredictionsScreen extends StatefulWidget {
  const PredictionsScreen({super.key});

  @override
  State<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends State<PredictionsScreen> {
  List<ProductPrediction> _predictions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final cached = ScreenCache.read<List<ProductPrediction>>('predictions');
    if (cached != null) {
      _predictions = cached;
      _loading = false;
    }
    _load();
  }

  Future<void> _load() async {
    try {
      final predictions = await context
          .read<IntelligenceService>()
          .getPredictions(limit: 50);
      if (!mounted) return;
      ScreenCache.write('predictions', predictions);
      setState(() {
        _predictions = predictions;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _feedback(ProductPrediction p, String action) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      if (action == 'added') {
        final state = context.read<ShoppingListBloc>().state;
        final lists = state is ShoppingListLoaded ? state.lists : [];
        if (lists.isNotEmpty) {
          await context.read<ListItemService>().forceAddListItem(
                listId: lists.first.id,
                productName: p.productName,
                quantity: p.avgQuantity.round().clamp(1, 99),
              );
          if (mounted) {
            SmartSnackBarManager.showSuccessSnackBar(
                context, l10n.predictionAdded(p.productName));
          }
        }
      }
      if (!mounted) return;
      await context
          .read<IntelligenceService>()
          .sendPredictionFeedback(p.productName, action);
      setState(() => _predictions.remove(p));
    } catch (_) {
      if (!mounted) return;
      SmartSnackBarManager.showErrorSnackBar(context, l10n.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.allPredictions)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _predictions.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        Icon(Icons.auto_awesome_outlined,
                            size: 56, color: Colors.grey[400]),
                        const SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl),
                          child: Text(
                            l10n.noPredictionsYet,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 13.5,
                                color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: _predictions.length,
                      itemBuilder: (context, index) => PredictionCard(
                        prediction: _predictions[index],
                        onAction: (action) =>
                            _feedback(_predictions[index], action),
                      ),
                    ),
            ),
    );
  }
}

/// Carte d'une prédiction, réutilisée par le dashboard.
class PredictionCard extends StatelessWidget {
  final ProductPrediction prediction;
  final void Function(String action) onAction;
  final bool compact;

  const PredictionCard({
    super.key,
    required this.prediction,
    required this.onAction,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = prediction;

    final (statusLabel, statusColor) = switch (p.status) {
      'overdue' => (l10n.statusOverdue, AppColors.error),
      'likely_needed' => (l10n.statusLikelyNeeded, AppColors.warning),
      _ => (l10n.statusSoon, AppColors.primary),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm + 2, AppSpacing.sm, AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    p.productName,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${l10n.usuallyEveryDays(p.frequencyDays)} · '
              '${l10n.lastBoughtDaysAgo(p.daysSinceLast)}'
              '${p.confidence == 'low' ? ' · ${l10n.confidenceLow}' : ''}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onPressed: () => onAction('added'),
                  child: Text(l10n.predictionAdd),
                ),
                const SizedBox(width: AppSpacing.xs),
                if (!compact) ...[
                  TextButton(
                    style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                    onPressed: () => onAction('still_have'),
                    child: Text(l10n.predictionStillHave,
                        style: const TextStyle(fontSize: 12.5)),
                  ),
                ],
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz,
                      size: 20, color: AppColors.textDisabled),
                  onSelected: onAction,
                  itemBuilder: (_) => [
                    PopupMenuItem(
                        value: 'not_now',
                        child: Text(l10n.predictionNotNow)),
                    if (compact)
                      PopupMenuItem(
                          value: 'still_have',
                          child: Text(l10n.predictionStillHave)),
                    PopupMenuItem(
                        value: 'never', child: Text(l10n.predictionNever)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
