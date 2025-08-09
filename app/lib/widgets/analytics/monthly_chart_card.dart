// widgets/analytics/monthly_chart_card.dart - VERSION CORRIGÉE AVEC CONTEXT
import 'package:epilist/utils/month_localization_helper.dart';
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart';
import 'package:epilist/utils/tooltip_currency_formatter.dart';

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
                // Décommentez si vous avez ce widget
                // const CurrencyIndicator(),
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
              // ✅ CORRECTION: Passer le context à la méthode
              child: _buildSimpleChart(context, monthlyData, l10n),
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

  // ✅ CORRECTION: Ajouter le context en paramètre
  Widget _buildSimpleChart(
    BuildContext context,
    List<dynamic> monthlyData,
    AppLocalizations l10n,
  ) {
    if (monthlyData.isEmpty) {
      return Center(
        child: Text(
          l10n.noDataAvailable,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    // ✅ CORRECTION: Calcul de la valeur maximale
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

                // ✅ CORRECTION: Le context est maintenant disponible
                final rawMonthShort =
                    _getStringValue(month, 'month_short') ??
                    'M${entry.key + 1}';
                final monthShort =
                    MonthLocalizationHelper.localizeShortMonthName(
                      context, // ← Maintenant accessible
                      rawMonthShort,
                    );

                final dataQuality =
                    _getStringValue(month, 'data_quality') ?? 'none';
                final height = maxValue > 0 ? (value / maxValue) * 120 : 5.0;

                return Container(
                  width: 45,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTooltipBar(month, height, dataQuality, value),
                      const SizedBox(height: 6),
                      // Label du mois (maintenant localisé)
                      SizedBox(
                        height: 16,
                        child: Text(
                          monthShort, // ← Maintenant localisé
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

  // ✅ NOUVEAU: Widget de barre avec tooltip formaté correctement
  Widget _buildTooltipBar(
    dynamic month,
    double height,
    String dataQuality,
    double value,
  ) {
    return Builder(
      builder: (context) {
        return Tooltip(
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          richMessage: _buildTooltipContent(context, month),
          child: Container(
            width: 24,
            height: height < 5 ? 5 : height,
            decoration: BoxDecoration(
              color: _getBarColor(dataQuality, value),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }

  // ✅ CORRIGÉ: Contenu du tooltip avec localisation complète
  InlineSpan _buildTooltipContent(BuildContext context, dynamic month) {
    if (month is! Map<String, dynamic>) {
      return const TextSpan(
        text: 'Données invalides',
        style: TextStyle(color: Colors.white, fontSize: 12),
      );
    }

    final l10n = AppLocalizations.of(context)!;

    // ✅ CORRECTION: Localiser le nom du mois
    final rawMonthName =
        _getStringValue(month, 'month_name') ??
        'Mois ${_getStringValue(month, 'month') ?? '?'}';
    final monthName = MonthLocalizationHelper.extractAndLocalizeMonth(
      context,
      rawMonthName,
    );

    final totalSpent = _getMonthValue(month);
    final receiptsTotal = _safeToDouble(month['receipts_total']);
    final itemsTotal = _safeToDouble(month['items_total']);
    final dataQuality = _getStringValue(month, 'data_quality') ?? 'none';

    final List<InlineSpan> spans = [];

    // Titre du mois (maintenant localisé)
    spans.add(
      TextSpan(
        text: '$monthName\n',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    // Total avec localisation
    spans.add(
      TextSpan(
        text: '${l10n.total}: ',
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
    spans.add(_buildFormattedAmountSpan(context, totalSpent));
    spans.add(
      const TextSpan(
        text: '\n',
        style: TextStyle(color: Colors.white, fontSize: 11),
      ),
    );

    // Factures avec localisation
    if (receiptsTotal > 0) {
      spans.add(
        TextSpan(
          text: '${l10n.receipts}: ',
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      );
      spans.add(_buildFormattedAmountSpan(context, receiptsTotal));
      spans.add(
        const TextSpan(
          text: '\n',
          style: TextStyle(color: Colors.white, fontSize: 11),
        ),
      );
    }

    // Items avec localisation
    if (itemsTotal > 0) {
      spans.add(
        TextSpan(
          text: '${l10n.items}: ',
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      );
      spans.add(_buildFormattedAmountSpan(context, itemsTotal));
      spans.add(
        const TextSpan(
          text: '\n',
          style: TextStyle(color: Colors.white, fontSize: 11),
        ),
      );
    }

    // Qualité des données avec localisation
    spans.add(
      TextSpan(
        text: '${l10n.dataQuality}: $dataQuality',
        style: const TextStyle(color: Colors.white70, fontSize: 10),
      ),
    );

    return TextSpan(children: spans);
  }

  // ✅ CORRECTION: Informations sur les données avec localisation
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
                l10n.periodInformation,
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
                Text(
                  '${l10n.period}: $period',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],

          Row(
            children: [
              Icon(Icons.timeline, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                '${l10n.monthsWithData}: $monthsWithData/${monthlyData.length}',
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ NOUVEAU: Créer un span avec montant formaté (en utilisant le helper)
  InlineSpan _buildFormattedAmountSpan(BuildContext context, double amount) {
    final formattedAmount = TooltipCurrencyFormatter.formatAmount(
      context,
      amount,
    );
    return TextSpan(
      text: formattedAmount,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w600,
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
