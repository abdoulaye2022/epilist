// widgets/analytics/monthly_chart_card.dart - VERSION CORRIGÉE TRADUCTION MOIS
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

            // Résumé
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

  // ==================== TRADUCTIONS CORRIGÉES ====================

  /// ✅ CORRIGÉ: Traduit un nom de mois complet avec les clés de localisation
  String _translateMonthName(String monthName, AppLocalizations l10n) {
    final parts = monthName.toLowerCase().split(' ');
    final monthPart = parts.isNotEmpty ? parts[0] : monthName.toLowerCase();

    // Mapping utilisant les clés de localisation (français ET anglais)
    String translatedMonth;
    switch (monthPart) {
      // ==================== JANVIER ====================
      case 'janvier':
      case 'january':
        translatedMonth = l10n.january;
        break;

      // ==================== FÉVRIER ====================
      case 'février':
      case 'fevrier':
      case 'february':
        translatedMonth = l10n.february;
        break;

      // ==================== MARS ====================
      case 'mars':
      case 'march':
        translatedMonth = l10n.march;
        break;

      // ==================== AVRIL ====================
      case 'avril':
      case 'april':
        translatedMonth = l10n.april;
        break;

      // ==================== MAI ====================
      case 'mai':
      case 'may':
        translatedMonth = l10n.may;
        break;

      // ==================== JUIN ====================
      case 'juin':
      case 'june':
        translatedMonth = l10n.june;
        break;

      // ==================== JUILLET ====================
      case 'juillet':
      case 'july':
        translatedMonth = l10n.july;
        break;

      // ==================== AOÛT ====================
      case 'août':
      case 'aout':
      case 'august':
        translatedMonth = l10n.august;
        break;

      // ==================== SEPTEMBRE ====================
      case 'septembre':
      case 'september':
        translatedMonth = l10n.september;
        break;

      // ==================== OCTOBRE ====================
      case 'octobre':
      case 'october':
        translatedMonth = l10n.october;
        break;

      // ==================== NOVEMBRE ====================
      case 'novembre':
      case 'november':
        translatedMonth = l10n.november;
        break;

      // ==================== DÉCEMBRE ====================
      case 'décembre':
      case 'decembre':
      case 'december':
        translatedMonth = l10n.december;
        break;

      default:
        return monthName; // Retourner tel quel si pas de correspondance
    }

    // Reconstituer avec l'année si elle existe
    if (parts.length > 1) {
      return '$translatedMonth ${parts[1]}';
    }
    return translatedMonth;
  }

  /// ✅ CORRIGÉ: Traduit une abréviation de mois avec gestion complète
  /// ✅ CORRIGÉ COMPLET: Traduit une abréviation de mois (français ET anglais)
  String _translateMonthShort(String monthShort, AppLocalizations l10n) {
    if (monthShort.isEmpty) return monthShort;

    final originalShort = monthShort;
    final lowerShort = monthShort.toLowerCase().trim();

    // 🔧 CORRECTION: Gérer tous les formats possibles d'abréviation
    // Format avec point (jan., fév., etc.)
    final cleanShort = lowerShort.replaceAll('.', '').replaceAll(',', '');

    // 🐛 DEBUG: Log pour voir la chaîne nettoyée
    print('🔍 Translating month: "$originalShort" → cleaned: "$cleanShort"');

    // Mapping complet avec TOUTES les variantes (français ET anglais)
    String result;
    switch (cleanShort) {
      // ==================== JANVIER ====================
      case 'jan':
      case 'janv':
      case 'janvier':
      case 'january':
        result = l10n.jan;
        break;

      // ==================== FÉVRIER ====================
      case 'fév':
      case 'fev':
      case 'févr':
      case 'fevr':
      case 'février':
      case 'fevrier':
      case 'feb':
      case 'february':
        result = l10n.feb;
        break;

      // ==================== MARS ====================
      case 'mar':
      case 'mars':
      case 'march':
        result = l10n.mar;
        break;

      // ==================== AVRIL ====================
      case 'avr':
      case 'avril':
      case 'apr':
      case 'april':
        result = l10n.apr;
        break;

      // ==================== MAI ====================
      case 'mai':
      case 'may':
        result = l10n.mayShort;
        break;

      // ==================== JUIN ====================
      case 'jun':
      case 'juin':
      case 'june':
        result = l10n.jun;
        break;

      // ==================== JUILLET ====================
      case 'jul':
      case 'juil':
      case 'juillet':
      case 'july':
        result = l10n.jul;
        break;

      // ==================== AOÛT ====================
      case 'aoû':
      case 'aou':
      case 'août':
      case 'aout':
      case 'aug':
      case 'august':
        result = l10n.aug;
        break;

      // ==================== SEPTEMBRE ====================
      case 'sep':
      case 'sept':
      case 'septembre':
      case 'september':
        result = l10n.sep;
        break;

      // ==================== OCTOBRE ====================
      case 'oct':
      case 'octobre':
      case 'october':
        result = l10n.oct;
        break;

      // ==================== NOVEMBRE ====================
      case 'nov':
      case 'novembre':
      case 'november':
        result = l10n.nov;
        break;

      // ==================== DÉCEMBRE ====================
      case 'déc':
      case 'dec':
      case 'décembre':
      case 'decembre':
      case 'december':
        result = l10n.dec;
        break;

      default:
        // 🔧 FALLBACK AMÉLIORÉ: Détection par préfixe (français ET anglais)
        if (cleanShort.startsWith('jan')) {
          result = l10n.jan;
        } else if (cleanShort.startsWith('fév') ||
            cleanShort.startsWith('fev') ||
            cleanShort.startsWith('feb')) {
          result = l10n.feb;
        } else if (cleanShort.startsWith('mar')) {
          result = l10n.mar;
        } else if (cleanShort.startsWith('avr') ||
            cleanShort.startsWith('apr')) {
          result = l10n.apr;
        } else if (cleanShort.startsWith('mai') ||
            cleanShort.startsWith('may')) {
          result = l10n.mayShort;
        } else if (cleanShort.startsWith('jun')) {
          result = l10n.jun;
        } else if (cleanShort.startsWith('jul') ||
            cleanShort.startsWith('juil')) {
          result = l10n.jul;
        } else if (cleanShort.startsWith('aoû') ||
            cleanShort.startsWith('aou') ||
            cleanShort.startsWith('aug')) {
          result = l10n.aug;
        } else if (cleanShort.startsWith('sep')) {
          result = l10n.sep;
        } else if (cleanShort.startsWith('oct')) {
          result = l10n.oct;
        } else if (cleanShort.startsWith('nov')) {
          result = l10n.nov;
        } else if (cleanShort.startsWith('déc') ||
            cleanShort.startsWith('dec')) {
          result = l10n.dec;
        } else if (cleanShort.contains('déc') || cleanShort.contains('dec')) {
          // 🆕 Fallback spécial pour décembre
          result = l10n.dec;
        } else if (RegExp(r'^(12|décembre|december)').hasMatch(cleanShort)) {
          // 🆕 Gestion des formats numériques
          result = l10n.dec;
        } else {
          // Si vraiment rien ne correspond, retourner tel quel
          print('⚠️ No translation found for: "$cleanShort"');
          result = monthShort;
        }
        break;
    }

    // 🐛 DEBUG: Log le résultat
    print('✅ Translation result: "$originalShort" → "$result"');
    return result;
  }

  // ==================== UTILITAIRES ====================

  /// Méthode utilitaire pour conversion sécurisée vers double
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

  /// Calcul direct depuis les données mensuelles avec gestion sécurisée des types
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

  /// Calcul de la moyenne depuis les données mensuelles
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

                // ✅ CORRECTION: Appliquer la traduction avec debug
                final translatedMonthShort = _translateMonthShort(
                  monthShort,
                  l10n,
                );

                // 🐛 DEBUG: Ajouter un log pour voir ce qui se passe
                if (monthShort != translatedMonthShort) {
                  print(
                    '🔄 Month translation: "$monthShort" → "$translatedMonthShort"',
                  );
                } else {
                  print('⚠️ No translation for: "$monthShort"');
                }

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
                        message: _buildTooltipMessage(month, l10n),
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
                      // ✅ CORRECTION: Label du mois traduit
                      SizedBox(
                        height: 16,
                        child: Text(
                          translatedMonthShort,
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

  /// Extraction robuste de la valeur du mois
  double _getMonthValue(dynamic month) {
    if (month is! Map<String, dynamic>) return 0.0;
    final monthTotal = month['total_spent'];
    return _safeToDouble(monthTotal);
  }

  /// Méthode utilitaire pour extraire des chaînes de caractères
  String? _getStringValue(dynamic month, String key) {
    if (month is! Map<String, dynamic>) return null;
    final value = month[key];
    if (value == null) return null;
    return value.toString();
  }

  /// ✅ MODIFIÉ: Tooltip avec traduction du nom de mois
  String _buildTooltipMessage(dynamic month, AppLocalizations l10n) {
    if (month is! Map<String, dynamic>) return 'Données invalides';

    final monthName =
        _getStringValue(month, 'month_name') ??
        'Mois ${_getStringValue(month, 'month') ?? '?'}';

    // ✅ CORRECTION: Traduire le nom complet du mois
    final translatedMonthName = _translateMonthName(monthName, l10n);

    final totalSpent = _getMonthValue(month);
    final receiptsTotal = _safeToDouble(month['receipts_total']);
    final itemsTotal = _safeToDouble(month['items_total']);
    final dataQuality = _getStringValue(month, 'data_quality') ?? 'none';

    String message = '$translatedMonthName\n';
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

  /// ✅ MODIFIÉ: Informations avec traduction de période
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

      final firstMonthName = _getStringValue(firstMonth, 'month_name') ?? '';
      final lastMonthName = _getStringValue(lastMonth, 'month_name') ?? '';

      // ✅ CORRECTION: Traduire les noms de mois dans la période
      if (firstMonthName.isNotEmpty && lastMonthName.isNotEmpty) {
        final translatedFirst = _translateMonthName(firstMonthName, l10n);
        final translatedLast = _translateMonthName(lastMonthName, l10n);

        // Extraire les années
        final firstYear = translatedFirst.split(' ').last;
        final lastYear = translatedLast.split(' ').last;

        if (firstYear == lastYear) {
          period = firstYear;
        } else {
          period = '$firstYear - $lastYear';
        }
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
