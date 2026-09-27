// widgets/price/price_history_sheet.dart - Historique de prix d'un
// produit. Chaque prix affiche sa provenance (« Vu sur votre reçu
// Walmart · 27 sept. 2026 ») : jamais de « prix actuel » inventé.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/price_intelligence.dart';
import 'package:epilist/services/price_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

Future<void> showPriceHistorySheet(BuildContext context, String productName) {
  final service = context.read<PriceService>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _PriceHistorySheet(
      productName: productName,
      future: service.getPriceHistory(productName),
    ),
  );
}

class _PriceHistorySheet extends StatelessWidget {
  final String productName;
  final Future<ProductPriceHistory> future;

  const _PriceHistorySheet({required this.productName, required this.future});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
        child: FutureBuilder<ProductPriceHistory>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final history = snapshot.data;
            final stats = history?.stats;

            return ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(l10n.priceHistoryTitle,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                Text(productName,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: AppSpacing.md),

                if (snapshot.hasError || stats == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xl),
                    child: Text(
                      l10n.noPriceHistory,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13.5, color: AppColors.textSecondary),
                    ),
                  )
                else ...[
                  _statsRow(l10n, stats),
                  if (stats.variationPct != null &&
                      stats.variationPct!.abs() >= 3) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _variationBanner(l10n, stats.variationPct!),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.observationsInWindow(
                        stats.observations, stats.windowDays),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...history!.observations.map((o) => _observationTile(
                      context, l10n, o)),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statsRow(AppLocalizations l10n, PriceStats stats) {
    Widget cell(String label, Widget value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              value,
            ],
          ),
        );
    const valueStyle =
        TextStyle(fontSize: 16, fontWeight: FontWeight.w800);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            cell(l10n.lastPaidPrice,
                FormattedAmount(amount: stats.lastPrice, style: valueStyle)),
            cell(l10n.usualPrice,
                FormattedAmount(amount: stats.usualPrice, style: valueStyle)),
            cell(
              l10n.priceRange,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FormattedAmount(
                      amount: stats.minPrice,
                      style: valueStyle.copyWith(fontSize: 13.5)),
                  const Text(' – ', style: TextStyle(fontSize: 13.5)),
                  FormattedAmount(
                      amount: stats.maxPrice,
                      style: valueStyle.copyWith(fontSize: 13.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _variationBanner(AppLocalizations l10n, double pct) {
    final higher = pct > 0;
    final color = higher ? AppColors.warning : AppColors.primary;
    final text = higher
        ? l10n.aboveUsualPrice(pct.toStringAsFixed(0))
        : l10n.belowUsualPrice(pct.toStringAsFixed(0));
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 4, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(higher ? Icons.trending_up : Icons.trending_down,
              size: 16, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12.5,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _observationTile(
      BuildContext context, AppLocalizations l10n, PriceObservation o) {
    final locale = Localizations.localeOf(context).languageCode;
    final date = DateFormat('d MMM yyyy', locale).format(o.purchasedAt);
    final store = o.storeName ?? '—';
    final provenance = o.source == 'receipt_ocr'
        ? l10n.seenOnReceipt(store, date)
        : l10n.seenOnPurchase(store, date);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      child: Row(
        children: [
          Icon(
            o.source == 'receipt_ocr'
                ? Icons.receipt_long_outlined
                : Icons.shopping_bag_outlined,
            size: 18,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Text(provenance,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textPrimary)),
          ),
          FormattedAmount(
            amount: o.price,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
