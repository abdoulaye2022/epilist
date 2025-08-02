// widgets/analytics/monthly_chart_card.dart - SOLUTION FINALE
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart';

class MonthlyChartCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const MonthlyChartCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final monthlyData = data['monthly_data'] as List<dynamic>? ?? [];
    final summary = data['summary'] ?? {};

    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: Colors.blue[600], size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.monthlyTrends,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const CurrencyIndicator(),
              ],
            ),
            const SizedBox(height: 20),

            // ✅ SOLUTION: Graphique avec contraintes strictes
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: _buildSimpleChart(monthlyData, l10n),
            ),

            const SizedBox(height: 20),

            // Résumé avec FormattedAmount
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    l10n.totalSpent,
                    summary['total']?.toDouble() ?? 0.0,
                    Colors.green,
                    isAmount: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryItem(
                    l10n.monthlyAverage,
                    summary['average_monthly']?.toDouble() ?? 0.0,
                    Colors.blue,
                    isAmount: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ SOLUTION: Chart simplifié sans LayoutBuilder ni ScrollView complexe
  Widget _buildSimpleChart(List<dynamic> monthlyData, AppLocalizations l10n) {
    if (monthlyData.isEmpty) {
      return Center(
        child: Text(
          l10n.noDataAvailable,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Trouver la valeur maximale
    double maxValue = 0;
    for (var month in monthlyData) {
      final value = month['total_spent']?.toDouble() ?? 0;
      if (value > maxValue) maxValue = value;
    }

    if (maxValue == 0) {
      return Center(
        child: Text(
          l10n.noSpendingRecorded,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    // ✅ SOLUTION: Chart simple avec contraintes fixes
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children:
              monthlyData.asMap().entries.map((entry) {
                final month = entry.value;
                final value = month['total_spent']?.toDouble() ?? 0;
                final monthName = month['month_name'] ?? '';
                final height =
                    maxValue > 0
                        ? (value / maxValue) * 120
                        : 5; // ✅ CORRECTION: 120px max au lieu de 140px

                return Container(
                  width: 45, // Largeur fixe par barre
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Barre du graphique
                      Tooltip(
                        message: '${value.toStringAsFixed(2)}',
                        child: Container(
                          width: 24,
                          height: height < 5 ? 5 : height,
                          decoration: BoxDecoration(
                            color: Colors.blue[600],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 6,
                      ), // ✅ CORRECTION: 6px au lieu de 8px
                      // Label du mois
                      SizedBox(
                        height: 16, // ✅ CORRECTION: Hauteur fixe pour le label
                        child: Text(
                          _getShortMonthName(monthName),
                          style: TextStyle(
                            fontSize: 9, // ✅ CORRECTION: Police plus petite
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  String _getShortMonthName(String monthName) {
    if (monthName.isEmpty) return '';
    try {
      final parts = monthName.split(' ');
      if (parts.isNotEmpty) {
        final month = parts[0];
        return month.length >= 3 ? month.substring(0, 3) : month;
      }
      return monthName.length > 4 ? monthName.substring(0, 4) : monthName;
    } catch (e) {
      return monthName.length > 4 ? monthName.substring(0, 4) : monthName;
    }
  }

  Widget _buildSummaryItem(
    String label,
    double value,
    Color color, {
    bool isAmount = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          const SizedBox(height: 4),
          if (isAmount)
            FormattedAmount(
              amount: value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              showCode: false,
            )
          else
            Text(
              value.toInt().toString(),
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
