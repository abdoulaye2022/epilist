// widgets/analytics/comparison_card.dart - VERSION CORRIGÉE AVEC FormattedAmount
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart';

class ComparisonCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const ComparisonCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final changePercentage =
        data['spending_change_percentage']?.toDouble() ?? 0.0;
    final trend = data['spending_trend'] ?? 'stable';
    final absoluteChange = data['absolute_change']?.toDouble() ?? 0.0;

    Color trendColor = Colors.grey;
    IconData trendIcon = Icons.remove;

    switch (trend) {
      case 'increased':
        trendColor = Colors.red[600]!;
        trendIcon = Icons.trending_up;
        break;
      case 'decreased':
        trendColor = Colors.green[600]!;
        trendIcon = Icons.trending_down;
        break;
      default:
        trendColor = Colors.blue[600]!;
        trendIcon = Icons.trending_flat;
    }

    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.compare_arrows, color: Colors.orange[600], size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.comparisonWithLastMonth,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // ✅ AJOUT: Indicateur de devise dans le header
                const CurrencyIndicator(),
              ],
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: trendColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: trendColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(trendIcon, color: trendColor, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTrendText(trend, l10n),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: trendColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${changePercentage > 0 ? '+' : ''}${changePercentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: trendColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (absoluteChange != 0) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                '${absoluteChange > 0 ? '+' : ''}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              // ✅ UTILISATION CORRECTE: Votre FormattedAmount sans paramètres inconnus
                              Flexible(
                                child: FormattedAmount(
                                  amount: absoluteChange.abs(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  showCode: false,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ✅ AMÉLIORATION: Section supplémentaire si on a plus de données de comparaison
            if (data.containsKey('current_period') &&
                data.containsKey('previous_period')) ...[
              const SizedBox(height: 16),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildPeriodComparison(
                      l10n.currentPeriod ?? 'Période actuelle',
                      data['current_period']?.toDouble() ?? 0.0,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPeriodComparison(
                      l10n.previousPeriod ?? 'Période précédente',
                      data['previous_period']?.toDouble() ?? 0.0,
                      Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ NOUVELLE MÉTHODE: Comparaison visuelle des périodes
  Widget _buildPeriodComparison(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FormattedAmount(
            amount: amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            showCode: false,
          ),
        ],
      ),
    );
  }

  String _getTrendText(String trend, AppLocalizations l10n) {
    switch (trend) {
      case 'increased':
        return l10n.spendingIncreased;
      case 'decreased':
        return l10n.spendingDecreased;
      default:
        return l10n.spendingStable;
    }
  }
}
