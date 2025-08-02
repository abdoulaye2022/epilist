// widgets/analytics/period_chart_card.dart - VERSION CORRIGÉE AVEC CALCUL MANUEL
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

            // Graphique avec contraintes strictes
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

            // ✅ CORRIGÉ: Calcul basé sur les données réelles au lieu du summary
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

            // ✅ NOUVEAU: Informations sur les données
            _buildDataInfo(periodData, l10n),
          ],
        ),
      ),
    );
  }

  // ✅ NOUVEAU: Méthode utilitaire pour conversion sécurisée vers double
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

  // ✅ NOUVEAU: Calcul du total depuis les données de période
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

  // ✅ NOUVEAU: Calcul de la moyenne depuis les données de période
  double _calculateAverageFromPeriodData(List<dynamic> periodData) {
    final total = _calculateTotalFromPeriodData(periodData);

    // Compter les périodes avec des données > 0
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

    // Fallback: moyenne sur toutes les périodes
    return total / (periodData.length > 0 ? periodData.length : 1);
  }

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

  // ✅ MODIFIÉ: Utilise le calcul manuel au lieu du summary
  double _getAverageValue(Map<String, dynamic> summary) {
    final periodData = _extractPeriodData();
    return _calculateAverageFromPeriodData(periodData);
  }

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

    // Trouver la valeur maximale
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
                      // Label
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

  String _getItemLabel(Map<String, dynamic> item, AppLocalizations l10n) {
    switch (_selectedPeriod) {
      case 'day':
        final date = item['date'] ?? '';
        final dayShort = item['day_short'] ?? '';
        return dayShort.isNotEmpty ? dayShort : _getShortDateLabel(date);

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
        return monthShort.isNotEmpty
            ? monthShort
            : _getShortMonthName(monthName);
    }
  }

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

  // ✅ NOUVEAU: Informations sur les données
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
}
