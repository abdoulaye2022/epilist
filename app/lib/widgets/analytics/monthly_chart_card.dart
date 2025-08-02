// widgets/analytics/monthly_chart_card.dart - VERSION CORRIGÉE COMPLÈTE SANS ERREURS DE TYPE
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

            // Graphique avec contraintes strictes
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

            // ✅ CORRIGÉ: Calcul basé uniquement sur les données mensuelles
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    l10n.totalSpent,
                    _calculateTotalFromMonthlyData(monthlyData),
                    Colors.green,
                    isAmount: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryItem(
                    l10n.monthlyAverage,
                    _calculateAverageFromMonthlyData(monthlyData),
                    Colors.blue,
                    isAmount: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Informations sur les données
            _buildDataInfo(monthlyData, l10n),
          ],
        ),
      ),
    );
  }

  // ✅ CORRIGÉ: Méthode utilitaire pour conversion sécurisée vers double
  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? 0.0;
    }
    return 0.0;
  }

  // ✅ CORRIGÉ: Calcul direct depuis les données mensuelles avec gestion sécurisée des types
  double _calculateTotalFromMonthlyData(List<dynamic> monthlyData) {
    double total = 0.0;
    for (var month in monthlyData) {
      if (month is Map<String, dynamic>) {
        final monthTotal = month['total_spent'];
        total += _safeToDouble(monthTotal);
      }
    }
    return total;
  }

  // ✅ CORRIGÉ: Calcul de la moyenne depuis les données mensuelles
  double _calculateAverageFromMonthlyData(List<dynamic> monthlyData) {
    final total = _calculateTotalFromMonthlyData(monthlyData);

    // Compter les mois avec des données > 0
    int monthsWithData = 0;
    for (var month in monthlyData) {
      if (month is Map<String, dynamic>) {
        final monthTotal = month['total_spent'];
        final value = _safeToDouble(monthTotal);
        if (value > 0) {
          monthsWithData++;
        }
      }
    }

    if (monthsWithData > 0) {
      return total / monthsWithData;
    }

    // Fallback: moyenne sur tous les mois
    return total / (monthlyData.length > 0 ? monthlyData.length : 12);
  }

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
      final value = _getMonthValue(month);
      if (value > maxValue) maxValue = value;
    }

    if (maxValue == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              l10n.noSpendingRecorded ?? 'Aucune dépense enregistrée',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children:
              monthlyData.asMap().entries.map((entry) {
                final month = entry.value;
                final value = _getMonthValue(month);
                final monthShort =
                    _getStringValue(month, 'month_short') ??
                    'M${entry.key + 1}';
                final dataQuality =
                    _getStringValue(month, 'data_quality') ?? 'none';
                final height = maxValue > 0 ? (value / maxValue) * 120 : 5.0;

                return Container(
                  width: 45,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Barre du graphique
                      Tooltip(
                        message: _buildTooltipMessage(month),
                        child: Container(
                          width: 24,
                          height: height < 5 ? 5 : height,
                          decoration: BoxDecoration(
                            color: _getBarColor(dataQuality, value),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Label du mois
                      SizedBox(
                        height: 16,
                        child: Text(
                          monthShort,
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[600],
                            fontWeight:
                                value > 0 ? FontWeight.w600 : FontWeight.normal,
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

  // ✅ CORRIGÉ: Extraction robuste de la valeur du mois
  double _getMonthValue(dynamic month) {
    if (month is! Map<String, dynamic>) return 0.0;
    final monthTotal = month['total_spent'];
    return _safeToDouble(monthTotal);
  }

  // ✅ NOUVEAU: Méthode utilitaire pour extraire des chaînes de caractères
  String? _getStringValue(dynamic month, String key) {
    if (month is! Map<String, dynamic>) return null;
    final value = month[key];
    if (value == null) return null;
    return value.toString();
  }

  String _buildTooltipMessage(dynamic month) {
    if (month is! Map<String, dynamic>) return 'Données invalides';

    final monthName =
        _getStringValue(month, 'month_name') ??
        'Mois ${_getStringValue(month, 'month') ?? '?'}';
    final totalSpent = _getMonthValue(month);
    final receiptsTotal = _safeToDouble(month['receipts_total']);
    final itemsTotal = _safeToDouble(month['items_total']);
    final dataQuality = _getStringValue(month, 'data_quality') ?? 'none';

    String message = '$monthName\n';
    message += 'Total: ${totalSpent.toStringAsFixed(2)} XOF\n';

    if (receiptsTotal > 0) {
      message += 'Factures: ${receiptsTotal.toStringAsFixed(2)} XOF\n';
    }
    if (itemsTotal > 0) {
      message += 'Items: ${itemsTotal.toStringAsFixed(2)} XOF\n';
    }

    message += 'Qualité: $dataQuality';
    return message;
  }

  Color _getBarColor(String dataQuality, double value) {
    if (value == 0) return Colors.grey[300]!;

    switch (dataQuality) {
      case 'high':
        return Colors.blue[600]!;
      case 'medium':
        return Colors.blue[400]!;
      case 'low':
        return Colors.blue[300]!;
      case 'none':
      default:
        return Colors.blue[200]!;
    }
  }

  // ✅ CORRIGÉ: Informations simplifiées sur les données
  Widget _buildDataInfo(List<dynamic> monthlyData, AppLocalizations l10n) {
    final totalSpent = _calculateTotalFromMonthlyData(monthlyData);

    if (totalSpent == 0) {
      return const SizedBox.shrink();
    }

    int monthsWithData = 0;
    for (var month in monthlyData) {
      if (_getMonthValue(month) > 0) {
        monthsWithData++;
      }
    }

    String period = '';
    if (monthlyData.isNotEmpty) {
      final firstMonth = monthlyData.first;
      final lastMonth = monthlyData.last;
      final firstYear =
          _getStringValue(firstMonth, 'month_name')?.split(' ').last ?? '';
      final lastYear =
          _getStringValue(lastMonth, 'month_name')?.split(' ').last ?? '';
      if (firstYear.isNotEmpty && lastYear.isNotEmpty) {
        period = '$firstYear - $lastYear';
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
              const SizedBox(width: 6),
              Text(
                'Informations sur la période',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (period.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.calendar_month, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text('Période: $period', style: const TextStyle(fontSize: 11)),
              ],
            ),
            const SizedBox(height: 4),
          ],

          Row(
            children: [
              Icon(Icons.timeline, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Mois avec données: $monthsWithData/${monthlyData.length}',
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
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
