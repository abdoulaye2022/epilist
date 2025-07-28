// widgets/analytics/monthly_chart_card.dart - VERSION AVEC TRADUCTIONS COMPLÈTES
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';

class MonthlyChartCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const MonthlyChartCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final monthlyData = data['monthly_data'] as List<dynamic>? ?? [];
    final summary = data['summary'] ?? {};

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: Colors.green[600], size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.monthlyTrends,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Graphique simple avec hauteur flexible
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRect(
                child: _buildSimpleChart(monthlyData, context, l10n),
              ),
            ),

            const SizedBox(height: 20),

            // Résumé
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    l10n.totalSpent,
                    summary['formatted_total'] ?? '0',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryItem(
                    l10n.monthlyAverage,
                    summary['formatted_average_monthly'] ?? '0',
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleChart(
    List<dynamic> monthlyData,
    BuildContext context,
    AppLocalizations l10n,
  ) {
    if (monthlyData.isEmpty) {
      return Center(
        child: Text(
          l10n.noDataAvailable, // ✅ Traduit
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    // Trouver la valeur maximale pour normaliser
    double maxValue = 0;
    for (var month in monthlyData) {
      final value = month['total_spent']?.toDouble() ?? 0;
      if (value > maxValue) maxValue = value;
    }

    if (maxValue == 0) {
      return Center(
        child: Text(
          l10n.noSpendingRecorded, // ✅ Traduit
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    // Utiliser LayoutBuilder pour s'adapter à l'espace disponible
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final chartHeight =
            availableHeight - 40; // Espace pour les labels (30px) + padding
        final barMaxHeight = chartHeight - 20; // Hauteur max des barres

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            height: availableHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children:
                  monthlyData.map<Widget>((month) {
                    final value = month['total_spent']?.toDouble() ?? 0;
                    final height =
                        maxValue > 0 ? (value / maxValue) * barMaxHeight : 0;
                    final monthName = month['month_name'] ?? '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height:
                                height < 5
                                    ? 5
                                    : height, // Hauteur minimum réduite
                            decoration: BoxDecoration(
                              color: Colors.green[600],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 28,
                            height: 20, // Hauteur fixe pour les labels
                            child: Text(
                              monthName.isNotEmpty
                                  ? _getShortMonthName(monthName)
                                  : '',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        );
      },
    );
  }

  String _getShortMonthName(String monthName) {
    try {
      final parts = monthName.split(' ');
      if (parts.isNotEmpty) {
        final month = parts[0];
        return month.length >= 3 ? month.substring(0, 3) : month;
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
