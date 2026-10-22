// widgets/receipts/receipt_stats_card.dart
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/receipt.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart'; // Import ajouté
import 'package:flutter/material.dart';

class ReceiptStatsCard extends StatelessWidget {
  final ReceiptStats stats;

  const ReceiptStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _buildSummaryCard(context, l10n),
        const SizedBox(height: 16),
        _buildComparisonCard(context, l10n),
        const SizedBox(height: 16),
        _buildDataQualityCard(context, l10n),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, AppLocalizations l10n) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.analytics,
                    color: AppColors.infoInk,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.spendingSummary,
                        style: const TextStyle(
                          fontFamily: AppFonts.display,
                          fontVariations: [FontVariation('wght', 800)],
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.totalExpensesSummary,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildStatRow(
              icon: Icons.receipt_long,
              label: l10n.totalFromReceipts,
              amount: stats.receiptsTotal, // Utiliser le montant brut
              color: AppColors.success,
              isHighlighted: stats.hasReceiptData,
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              icon: Icons.shopping_cart,
              label: l10n.totalFromItems,
              amount: stats.itemsTotal, // Utiliser le montant brut
              color: AppColors.warning,
              isHighlighted: stats.hasItemData,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildStatRow(
              icon: Icons.star,
              label: l10n.bestEstimate,
              amount: stats.bestTotal, // Utiliser le montant brut
              color: AppColors.violet,
              isHighlighted: true,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard(BuildContext context, AppLocalizations l10n) {
    if (!stats.hasReceiptData || !stats.hasItemData) {
      return const SizedBox.shrink();
    }

    final variance = stats.variance;
    final hasSignificantVariance = variance > 20.0; // 20% de différence

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        hasSignificantVariance
                            ? AppColors.warningTint
                            : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    hasSignificantVariance ? Icons.warning : Icons.check_circle,
                    color:
                        hasSignificantVariance
                            ? AppColors.warning
                            : AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.dataComparison,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.receiptVsItemComparison,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildComparisonStat(
                    label: l10n.receipts,
                    count: stats.totalReceipts,
                    amount: stats.receiptsTotal, // Utiliser le montant brut
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildComparisonStat(
                    label: l10n.items,
                    count: stats.itemsWithPrices,
                    amount: stats.itemsTotal, // Utiliser le montant brut
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            if (hasSignificantVariance) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningTint,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.warningBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: AppColors.warningInk, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.significantVarianceDetected(
                          variance.toStringAsFixed(1),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataQualityCard(BuildContext context, AppLocalizations l10n) {
    final qualityColor = _getQualityColor(stats.dataQuality);
    final qualityIcon = _getQualityIcon(stats.dataQuality);
    final qualityText = _getQualityText(stats.dataQuality, l10n);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTint.fill(qualityColor),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(qualityIcon, color: qualityColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.dataQuality,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        qualityText,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTint.ink(qualityColor),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildQualityRecommendations(context, l10n),
          ],
        ),
      ),
    );
  }

  // CORRECTION: Modification pour utiliser FormattedAmount au lieu de String
  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required double amount, // Changé de String à double
    required Color color,
    bool isHighlighted = false,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isHighlighted ? AppTint.fill(color) : AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            icon,
            color: isHighlighted ? color : AppColors.textSecondary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        // CORRECTION: Utilisation de FormattedAmount
        FormattedAmount(
          amount: amount,
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isHighlighted ? AppTint.ink(color) : AppColors.textSecondary,
          ),
          showCode: false,
          fallbackCurrencyCode: 'CAD',
        ),
      ],
    );
  }

  // CORRECTION: Modification pour utiliser FormattedAmount
  Widget _buildComparisonStat({
    required String label,
    required int count,
    required double amount, // Changé de String à double
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTint.fill(color),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppTint.line(color)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: AppTint.ink(color),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontVariations: [FontVariation('wght', 800)],
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTint.ink(color),
            ),
          ),
          const SizedBox(height: 4),
          // CORRECTION: Utilisation de FormattedAmount
          FormattedAmount(
            amount: amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTint.ink(color),
            ),
            showCode: false,
            fallbackCurrencyCode: 'CAD',
          ),
        ],
      ),
    );
  }

  Widget _buildQualityRecommendations(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    List<String> recommendations = [];

    if (!stats.hasReceiptData) {
      recommendations.add(l10n.addReceiptsRecommendation);
    }

    if (!stats.hasItemData) {
      recommendations.add(l10n.addItemPricesRecommendation);
    }

    if (stats.hasGoodDataQuality) {
      recommendations.add(l10n.dataQualityGood);
    }

    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children:
          recommendations.map((recommendation) {
            final isPositive = recommendation == l10n.dataQualityGood;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isPositive ? Icons.check_circle : Icons.lightbulb_outline,
                    color: isPositive ? AppColors.primary : AppColors.accent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Color _getQualityColor(String quality) {
    switch (quality.toLowerCase()) {
      case 'excellent':
        return AppColors.success;
      case 'good':
        return AppColors.info;
      case 'fair':
        return AppColors.warning;
      case 'poor':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getQualityIcon(String quality) {
    switch (quality.toLowerCase()) {
      case 'excellent':
        return Icons.star;
      case 'good':
        return Icons.check_circle;
      case 'fair':
        return Icons.warning;
      case 'poor':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _getQualityText(String quality, AppLocalizations l10n) {
    switch (quality.toLowerCase()) {
      case 'excellent':
        return l10n.dataQualityExcellent;
      case 'good':
        return l10n.dataQualityGood;
      case 'fair':
        return l10n.dataQualityFair;
      case 'poor':
        return l10n.dataQualityPoor;
      default:
        return l10n.dataQualityUnknown;
    }
  }
}
