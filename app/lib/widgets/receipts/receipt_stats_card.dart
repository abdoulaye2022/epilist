// widgets/receipts/receipt_stats_card.dart
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.analytics,
                    color: Colors.blue[600],
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.totalExpensesSummary,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
              color: Colors.green,
              isHighlighted: stats.hasReceiptData,
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              icon: Icons.shopping_cart,
              label: l10n.totalFromItems,
              amount: stats.itemsTotal, // Utiliser le montant brut
              color: Colors.orange,
              isHighlighted: stats.hasItemData,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildStatRow(
              icon: Icons.star,
              label: l10n.bestEstimate,
              amount: stats.bestTotal, // Utiliser le montant brut
              color: Colors.purple,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                            ? Colors.orange[50]
                            : Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hasSignificantVariance ? Icons.warning : Icons.check_circle,
                    color:
                        hasSignificantVariance
                            ? Colors.orange[600]
                            : Colors.green[600],
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
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildComparisonStat(
                    label: l10n.items,
                    count: stats.itemsWithPrices,
                    amount: stats.itemsTotal, // Utiliser le montant brut
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            if (hasSignificantVariance) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.significantVarianceDetected(
                          variance.toStringAsFixed(1),
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    color: qualityColor[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(qualityIcon, color: qualityColor[600], size: 28),
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
                          fontSize: 14,
                          color: qualityColor[600],
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
    required MaterialColor color,
    bool isHighlighted = false,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isHighlighted ? color[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isHighlighted ? color[600] : Colors.grey[600],
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
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
            color: isHighlighted ? color[600] : Colors.grey[700],
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
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color[700],
            ),
          ),
          const SizedBox(height: 4),
          // CORRECTION: Utilisation de FormattedAmount
          FormattedAmount(
            amount: amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color[600],
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
                    color: isPositive ? Colors.green[600] : Colors.blue[600],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  MaterialColor _getQualityColor(String quality) {
    switch (quality.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.blue;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
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
