// widgets/analytics/period_chart_card.dart - VERSION CORRIGÉE SÉPARÉE
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

            // ✅ SOLUTION: Graphique avec contraintes strictes
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

            // Résumé avec FormattedAmount
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    l10n.totalSpent,
                    summary['total']?.toDouble() ?? 0.0,
                    currentColor,
                    isAmount: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryItem(
                    _getAverageLabel(l10n),
                    _getAverageValue(summary),
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

  double _getAverageValue(Map<String, dynamic> summary) {
    switch (_selectedPeriod) {
      case 'day':
        return summary['average_daily']?.toDouble() ??
            summary['average']?.toDouble() ??
            0.0;
      case 'week':
        return summary['average_weekly']?.toDouble() ??
            summary['average']?.toDouble() ??
            0.0;
      case 'year':
        return summary['average_yearly']?.toDouble() ??
            summary['average']?.toDouble() ??
            0.0;
      case 'month':
      default:
        return summary['average_monthly']?.toDouble() ??
            summary['average']?.toDouble() ??
            0.0;
    }
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

  // ✅ SOLUTION: Chart simplifié sans LayoutBuilder complexe
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
      final value = item['total_spent']?.toDouble() ?? 0;
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
              periodData.asMap().entries.map((entry) {
                final item = entry.value;
                final value = item['total_spent']?.toDouble() ?? 0;
                final label = _getItemLabel(item, l10n);
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
                            color: chartColor[600],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 6,
                      ), // ✅ CORRECTION: 6px au lieu de 8px
                      // Label
                      SizedBox(
                        height: 16, // ✅ CORRECTION: Hauteur fixe pour le label
                        child: Text(
                          label,
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
