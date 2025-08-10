// widgets/analytics/period_chart_card.dart - VERSION AVEC CLÉS DE LOCALISATION
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/blocs/analytics/analytics_bloc.dart';
import 'package:epilist/blocs/analytics/analytics_event.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart';

class PeriodChartCard extends StatefulWidget {
  final Map<String, dynamic> data;

  const PeriodChartCard({super.key, required this.data});

  @override
  State<PeriodChartCard> createState() => _PeriodChartCardState();
}

class _PeriodChartCardState extends State<PeriodChartCard> {
  String _selectedPeriod = 'month';

  // ==================== CONFIGURATION ====================

  Map<String, String> _getPeriodLabels(AppLocalizations l10n) {
    return {
      'day': l10n.day,
      'week': l10n.week,
      'month': l10n.month,
      'year': l10n.year,
    };
  }

  final Map<String, IconData> _periodIcons = {
    'day': Icons.today,
    'week': Icons.view_week,
    'month': Icons.calendar_month,
    'year': Icons.calendar_today,
  };

  final Map<String, MaterialColor> _periodColors = {
    'day': Colors.green,
    'week': Colors.blue,
    'month': Colors.purple,
    'year': Colors.orange,
  };

  // ==================== BUILD PRINCIPAL ====================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final periodData = _extractPeriodData();
    final summary = widget.data['summary'] ?? {};
    final currentPeriod = widget.data['period'] ?? 'month';

    if (currentPeriod != _selectedPeriod) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedPeriod = currentPeriod;
          });
        }
      });
    }

    final currentColor = _periodColors[_selectedPeriod] ?? Colors.green;

    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec titre et sélecteur de période
            Row(
              children: [
                Icon(
                  _periodIcons[_selectedPeriod] ?? Icons.show_chart,
                  color: currentColor[600],
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getPeriodTitle(l10n),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const CurrencyIndicator(),
                const SizedBox(width: 8),
                _buildPeriodSelector(l10n),
              ],
            ),
            const SizedBox(height: 20),

            // Graphique principal
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: currentColor[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: currentColor[100]!),
              ),
              child: _buildChart(periodData, l10n, currentColor),
            ),

            const SizedBox(height: 20),

            // Résumé statistiques
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    l10n.totalSpent,
                    _calculateTotalFromPeriodData(periodData),
                    currentColor,
                    isAmount: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryItem(
                    _getAverageLabel(l10n),
                    _calculateAverageFromPeriodData(periodData),
                    Colors.blue,
                    isAmount: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Informations sur les données
            _buildDataInfo(periodData, l10n),
          ],
        ),
      ),
    );
  }

  // ==================== TRADUCTIONS ====================

  /// ✅ NOUVELLE VERSION: Traduit une abréviation de mois avec les clés de localisation
  String _translateMonthShort(String monthShort, AppLocalizations l10n) {
    if (monthShort.isEmpty) return monthShort;

    final originalShort = monthShort;
    final lowerShort = monthShort.toLowerCase().trim();

    // 🔧 CORRECTION: Gérer tous les formats possibles d'abréviation
    final cleanShort = lowerShort.replaceAll('.', '').replaceAll(',', '');

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
          result = monthShort;
        }
        break;
    }

    return result;
  }

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

  /// ✅ NOUVEAU: Traduit un nom de jour complet (français ET anglais)
  String _translateDayName(String dayName, AppLocalizations l10n) {
    if (dayName.isEmpty) return dayName;

    final lowerDay = dayName.toLowerCase().trim();

    // Mapping des noms complets (français ET anglais)
    switch (lowerDay) {
      // ==================== LUNDI ====================
      case 'lundi':
      case 'monday':
        return l10n.monday;

      // ==================== MARDI ====================
      case 'mardi':
      case 'tuesday':
        return l10n.tuesday;

      // ==================== MERCREDI ====================
      case 'mercredi':
      case 'wednesday':
        return l10n.wednesday;

      // ==================== JEUDI ====================
      case 'jeudi':
      case 'thursday':
        return l10n.thursday;

      // ==================== VENDREDI ====================
      case 'vendredi':
      case 'friday':
        return l10n.friday;

      // ==================== SAMEDI ====================
      case 'samedi':
      case 'saturday':
        return l10n.saturday;

      // ==================== DIMANCHE ====================
      case 'dimanche':
      case 'sunday':
        return l10n.sunday;

      default:
        // Fallback: essayer de détecter par les premières lettres (français ET anglais)
        if (lowerDay.startsWith('lun') || lowerDay.startsWith('mon'))
          return l10n.monday;
        if (lowerDay.startsWith('mar') || lowerDay.startsWith('tue'))
          return l10n.tuesday;
        if (lowerDay.startsWith('mer') || lowerDay.startsWith('wed'))
          return l10n.wednesday;
        if (lowerDay.startsWith('jeu') || lowerDay.startsWith('thu'))
          return l10n.thursday;
        if (lowerDay.startsWith('ven') || lowerDay.startsWith('fri'))
          return l10n.friday;
        if (lowerDay.startsWith('sam') || lowerDay.startsWith('sat'))
          return l10n.saturday;
        if (lowerDay.startsWith('dim') || lowerDay.startsWith('sun'))
          return l10n.sunday;

        return dayName; // Retourner tel quel si pas de correspondance
    }
  }

  /// ✅ NOUVEAU: Traduit une abréviation de jour (français ET anglais)
  String _translateDayShort(String dayShort, AppLocalizations l10n) {
    if (dayShort.isEmpty) return dayShort;

    final lowerShort = dayShort.toLowerCase().trim();

    // Nettoyage des points et virgules
    final cleanShort = lowerShort.replaceAll('.', '').replaceAll(',', '');

    // Mapping des abréviations (français ET anglais)
    switch (cleanShort) {
      // ==================== LUNDI ====================
      case 'lun':
      case 'lundi':
      case 'mon':
      case 'monday':
        return l10n.mondayShort;

      // ==================== MARDI ====================
      case 'mar':
      case 'mardi':
      case 'tue':
      case 'tues':
      case 'tuesday':
        return l10n.tuesdayShort;

      // ==================== MERCREDI ====================
      case 'mer':
      case 'merc':
      case 'mercredi':
      case 'wed':
      case 'wednesday':
        return l10n.wednesdayShort;

      // ==================== JEUDI ====================
      case 'jeu':
      case 'jeudi':
      case 'thu':
      case 'thurs':
      case 'thursday':
        return l10n.thursdayShort;

      // ==================== VENDREDI ====================
      case 'ven':
      case 'vend':
      case 'vendredi':
      case 'fri':
      case 'friday':
        return l10n.fridayShort;

      // ==================== SAMEDI ====================
      case 'sam':
      case 'samedi':
      case 'sat':
      case 'saturday':
        return l10n.saturdayShort;

      // ==================== DIMANCHE ====================
      case 'dim':
      case 'dimanche':
      case 'sun':
      case 'sunday':
        return l10n.sundayShort;

      default:
        // Fallback: si c'est plus long, prendre les 3 premières lettres et retenter
        if (dayShort.length > 3) {
          return _translateDayShort(dayShort.substring(0, 3), l10n);
        }
        return dayShort;
    }
  }

  // ==================== UTILITAIRES DE DONNÉES ====================

  /// Conversion sécurisée vers double
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

  /// Calcule le total des dépenses sur la période
  double _calculateTotalFromPeriodData(List<dynamic> periodData) {
    double total = 0.0;
    for (var period in periodData) {
      if (period is Map<String, dynamic>) {
        final periodTotal = period['total_spent'];
        total += _safeToDouble(periodTotal);
      }
    }
    return total;
  }

  /// Calcule la moyenne des dépenses sur la période
  double _calculateAverageFromPeriodData(List<dynamic> periodData) {
    final total = _calculateTotalFromPeriodData(periodData);
    int periodsWithData = 0;

    for (var period in periodData) {
      if (period is Map<String, dynamic>) {
        final periodTotal = period['total_spent'];
        final value = _safeToDouble(periodTotal);
        if (value > 0) {
          periodsWithData++;
        }
      }
    }

    if (periodsWithData > 0) {
      return total / periodsWithData;
    }
    return total / (periodData.length > 0 ? periodData.length : 1);
  }

  /// Extrait les données selon la période sélectionnée
  List<dynamic> _extractPeriodData() {
    final period = widget.data['period'] ?? _selectedPeriod;
    switch (period) {
      case 'day':
        return widget.data['daily_data'] as List<dynamic>? ?? [];
      case 'week':
        return widget.data['weekly_data'] as List<dynamic>? ?? [];
      case 'year':
        return widget.data['yearly_data'] as List<dynamic>? ?? [];
      case 'month':
      default:
        return widget.data['monthly_data'] as List<dynamic>? ?? [];
    }
  }

  // ==================== GETTERS DE TEXTE ====================

  String _getPeriodTitle(AppLocalizations l10n) {
    switch (_selectedPeriod) {
      case 'day':
        return l10n.dailyTrends;
      case 'week':
        return l10n.weeklyTrends;
      case 'year':
        return l10n.yearlyTrends;
      case 'month':
      default:
        return l10n.monthlyTrends;
    }
  }

  String _getAverageLabel(AppLocalizations l10n) {
    switch (_selectedPeriod) {
      case 'day':
        return l10n.dailyAverage;
      case 'week':
        return l10n.weeklyAverage;
      case 'year':
        return l10n.yearlyAverage;
      case 'month':
      default:
        return l10n.monthlyAverage;
    }
  }

  // ==================== WIDGETS DE L'INTERFACE ====================

  /// Construit le sélecteur de période (dropdown)
  Widget _buildPeriodSelector(AppLocalizations l10n) {
    final periodLabels = _getPeriodLabels(l10n);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: PopupMenuButton<String>(
        icon: Icon(Icons.date_range, color: Colors.grey[600]),
        tooltip: l10n.selectPeriod,
        onSelected: (period) {
          setState(() {
            _selectedPeriod = period;
          });
          _loadDataForPeriod(period);
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: Colors.white,
        elevation: 8,
        itemBuilder:
            (context) =>
                periodLabels.entries.map((entry) {
                  final period = entry.key;
                  final label = entry.value;
                  final isSelected = period == _selectedPeriod;
                  final color = _periodColors[period] ?? Colors.grey;

                  return PopupMenuItem<String>(
                    value: period,
                    child: Row(
                      children: [
                        Icon(
                          _periodIcons[period]!,
                          size: 20,
                          color: isSelected ? color[600] : Colors.grey[600],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color: isSelected ? color[600] : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check, color: color[600], size: 18),
                      ],
                    ),
                  );
                }).toList(),
      ),
    );
  }

  /// Construit le graphique principal
  Widget _buildChart(
    List<dynamic> periodData,
    AppLocalizations l10n,
    MaterialColor chartColor,
  ) {
    if (periodData.isEmpty) {
      return Center(
        child: Text(
          l10n.noDataAvailable,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Trouver la valeur maximale pour la normalisation
    double maxValue = 0;
    for (var item in periodData) {
      final value = _safeToDouble(item['total_spent']);
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
              periodData.asMap().entries.map((entry) {
                final item = entry.value;
                final value = _safeToDouble(item['total_spent']);
                final label = _getItemLabel(item, l10n);
                final height = maxValue > 0 ? (value / maxValue) * 120 : 5.0;

                return Container(
                  width: 45,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Barre du graphique
                      Tooltip(
                        message: '${value.toStringAsFixed(2)} XOF',
                        child: Container(
                          width: 24,
                          height: height < 5 ? 5 : height,
                          decoration: BoxDecoration(
                            color:
                                value > 0 ? chartColor[600] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Label avec traduction pour les mois
                      SizedBox(
                        height: 16,
                        child: Text(
                          label,
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

  /// Construit les cartes de résumé (total et moyenne)
  Widget _buildSummaryItem(
    String label,
    double value,
    MaterialColor color, {
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

  /// Construit l'encadré d'informations sur les données
  Widget _buildDataInfo(List<dynamic> periodData, AppLocalizations l10n) {
    final totalSpent = _calculateTotalFromPeriodData(periodData);
    if (totalSpent == 0) {
      return const SizedBox.shrink();
    }

    int periodsWithData = 0;
    for (var period in periodData) {
      if (_safeToDouble(period['total_spent']) > 0) {
        periodsWithData++;
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
          Row(
            children: [
              Icon(Icons.timeline, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Périodes avec données: $periodsWithData/${periodData.length}',
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== GESTION DES LABELS ====================

  /// Retourne le label approprié pour chaque élément selon la période
  String _getItemLabel(Map<String, dynamic> item, AppLocalizations l10n) {
    switch (_selectedPeriod) {
      case 'day':
        final date = item['date'] ?? '';
        final dayShort = item['day_short'] ?? '';
        final dayName = item['day_name'] ?? '';

        // ✅ CORRECTION: Traduire les jours
        if (dayShort.isNotEmpty) {
          return _translateDayShort(dayShort, l10n);
        } else if (dayName.isNotEmpty) {
          return _translateDayShort(
            dayName,
            l10n,
          ); // Convertir nom complet en abréviation
        } else {
          return _getShortDateLabel(date);
        }

      case 'week':
        final weekNumber = item['week_number'];
        final weekLabel = item['week_label'] ?? '';
        if (weekNumber != null) {
          return l10n.weekLabel(weekNumber);
        }
        return weekLabel.isNotEmpty ? _getShortWeekLabel(weekLabel) : '';

      case 'year':
        final year = item['year'] ?? item['year_label'] ?? '';
        return year.toString();

      case 'month':
      default:
        final monthShort = item['month_short'] ?? '';
        final monthName = item['month_name'] ?? '';

        // ✅ TRADUCTION DES MOIS: Utiliser les clés de localisation
        if (monthShort.isNotEmpty) {
          return _translateMonthShort(monthShort, l10n);
        } else if (monthName.isNotEmpty) {
          return _getShortMonthName(_translateMonthName(monthName, l10n));
        }
        return '';
    }
  }

  /// Formate une date courte (jour)
  String _getShortDateLabel(String date) {
    try {
      if (date.contains('-')) {
        final parts = date.split('-');
        if (parts.length >= 3) {
          return '${parts[2]}/${parts[1]}';
        }
      }
      return date.length > 5 ? date.substring(0, 5) : date;
    } catch (e) {
      return '';
    }
  }

  /// Formate un label de semaine
  String _getShortWeekLabel(String weekLabel) {
    try {
      final parts = weekLabel.split(' - ');
      if (parts.isNotEmpty) {
        final startPart = parts[0].trim();
        return startPart.length > 6 ? startPart.substring(0, 6) : startPart;
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  /// Extrait l'abréviation d'un nom de mois complet
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

  // ==================== GESTION DES ACTIONS ====================

  /// Charge les données pour la période sélectionnée
  void _loadDataForPeriod(String period) {
    switch (period) {
      case 'day':
        context.read<AnalyticsBloc>().add(const LoadDailySpending());
        break;
      case 'week':
        context.read<AnalyticsBloc>().add(const LoadWeeklySpending());
        break;
      case 'year':
        context.read<AnalyticsBloc>().add(const LoadYearlySpending());
        break;
      case 'month':
      default:
        context.read<AnalyticsBloc>().add(const LoadMonthlySpending());
        break;
    }
  }
}
