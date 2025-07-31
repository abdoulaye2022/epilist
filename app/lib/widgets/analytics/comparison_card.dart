// widgets/analytics/comparison_card.dart
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';

class ComparisonCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String currency;

  const ComparisonCard({super.key, required this.data, required this.currency});

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

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ CORRECTION: Row avec Expanded pour éviter l'overflow
            Row(
              children: [
                Icon(Icons.compare_arrows, color: Colors.blue[600], size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.comparisonWithLastMonth,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2, // ✅ Maximum 2 lignes
                    overflow: TextOverflow.ellipsis, // ✅ Ellipsis si trop long
                  ),
                ),
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
                        // ✅ CORRECTION: Gestion de l'overflow pour le texte de tendance
                        Text(
                          _getTrendText(trend, l10n),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: trendColor,
                          ),
                          maxLines: 1, // ✅ Une seule ligne
                          overflow:
                              TextOverflow.ellipsis, // ✅ Ellipsis si nécessaire
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${changePercentage > 0 ? '+' : ''}${changePercentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: trendColor,
                          ),
                        ),
                        if (absoluteChange != 0)
                          // ✅ CORRECTION: Gestion de l'overflow pour le montant
                          Text(
                            '${absoluteChange > 0 ? '+' : ''}${absoluteChange.toStringAsFixed(2)} $currency',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1, // ✅ Une seule ligne
                            overflow:
                                TextOverflow
                                    .ellipsis, // ✅ Ellipsis si nécessaire
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
