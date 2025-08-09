// widgets/analytics/analytics_filters.dart - VERSION FINALE SANS DEVISE
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';

class AnalyticsFilters extends StatefulWidget {
  final bool includeShared;
  final String? activePeriodFilter;
  final Function(bool) onIncludeSharedChanged;
  final Function(String?) onPeriodFilterChanged;
  final VoidCallback? onClearFilters;

  const AnalyticsFilters({
    super.key,
    required this.includeShared,
    this.activePeriodFilter,
    required this.onIncludeSharedChanged,
    required this.onPeriodFilterChanged,
    this.onClearFilters,
  });

  @override
  State<AnalyticsFilters> createState() => _AnalyticsFiltersState();
}

class _AnalyticsFiltersState extends State<AnalyticsFilters> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasActiveFilters = _hasActiveFilters();

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // En-tête avec bouton d'expansion
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color:
                        hasActiveFilters ? Colors.green[600] : Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.analyticsFilters ?? 'Filtres d\'analyse',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            hasActiveFilters
                                ? Colors.green[600]
                                : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (hasActiveFilters) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getActiveFiltersCount().toString(),
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _clearAllFilters,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.clear,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),

          if (_isExpanded) ...[
            const Divider(height: 1, color: Colors.grey),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Debug des filtres actifs
                    if (hasActiveFilters) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Filtres actifs:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Listes partagées: ${widget.includeShared ? "Incluses" : "Exclues"}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            if (widget.activePeriodFilter != null)
                              Text(
                                'Période: ${widget.activePeriodFilter}',
                                style: const TextStyle(fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                    ],

                    // Filtre des listes partagées
                    _buildFilterSection(
                      l10n.sharedLists ?? 'Listes partagées',
                      _buildSharedListsFilter(l10n),
                    ),
                    const SizedBox(height: 16),

                    // Filtres par période
                    _buildFilterSection(
                      l10n.period ?? 'Période',
                      _buildPeriodFilters(l10n),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterSection(String title, Widget content) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildSharedListsFilter(AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildToggleChip(
          l10n.includeSharedLists ?? 'Inclure les listes partagées',
          widget.includeShared,
          widget.onIncludeSharedChanged,
          icon: Icons.share,
          color: Colors.blue[600]!,
        ),
        _buildToggleChip(
          l10n.excludeSharedLists ?? 'Exclure les listes partagées',
          !widget.includeShared,
          (value) => widget.onIncludeSharedChanged(!value),
          icon: Icons.lock,
          color: Colors.grey[600]!,
        ),
      ],
    );
  }

  Widget _buildPeriodFilters(AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(l10n.all ?? 'Tous', null, widget.activePeriodFilter, (
          value,
        ) {
          print('🔧 Period filter changed to: $value');
          widget.onPeriodFilterChanged(value);
        }),
        _buildFilterChip(
          l10n.thisWeek ?? 'Cette semaine',
          'week',
          widget.activePeriodFilter,
          (value) {
            print('🔧 Period filter changed to: $value');
            widget.onPeriodFilterChanged(value);
          },
          icon: Icons.view_week,
          color: Colors.purple[600],
        ),
        _buildFilterChip(
          l10n.thisMonth ?? 'Ce mois',
          'month',
          widget.activePeriodFilter,
          (value) {
            print('🔧 Period filter changed to: $value');
            widget.onPeriodFilterChanged(value);
          },
          icon: Icons.calendar_month,
          color: Colors.blue[600],
        ),
        _buildFilterChip(
          l10n.thisYear ?? 'Cette année',
          'year',
          widget.activePeriodFilter,
          (value) {
            print('🔧 Period filter changed to: $value');
            widget.onPeriodFilterChanged(value);
          },
          icon: Icons.calendar_today,
          color: Colors.indigo[600],
        ),
        _buildFilterChip(
          l10n.last30Days ?? 'Derniers 30 jours',
          '30days',
          widget.activePeriodFilter,
          (value) {
            print('🔧 Period filter changed to: $value');
            widget.onPeriodFilterChanged(value);
          },
          icon: Icons.date_range,
          color: Colors.teal[600],
        ),
      ],
    );
  }

  Widget _buildToggleChip(
    String label,
    bool isActive,
    Function(bool) onChanged, {
    IconData? icon,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          print('🔧 Toggle chip clicked: "$label", isActive=$isActive');
          onChanged(!isActive);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? (color ?? Colors.green[600]) : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isActive ? (color ?? Colors.green[600])! : Colors.grey[300]!,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isActive ? Colors.white : (color ?? Colors.green[600]),
                ),
                const SizedBox(width: 6),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.black87,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String? value,
    String? activeValue,
    Function(String?) onChanged, {
    IconData? icon,
    Color? color,
  }) {
    final isActive =
        (value == null && activeValue == null) ||
        (value != null && value == activeValue);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          print(
            '🔧 Filter chip clicked: "$label", value=$value, current activeValue=$activeValue',
          );
          if (isActive && value != null) {
            onChanged(null);
          } else {
            onChanged(value);
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? (color ?? Colors.green[600]) : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isActive ? (color ?? Colors.green[600])! : Colors.grey[300]!,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isActive ? Colors.white : (color ?? Colors.green[600]),
                ),
                const SizedBox(width: 6),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.black87,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return !widget.includeShared || // Si les listes partagées sont exclues
        widget.activePeriodFilter != null;
  }

  int _getActiveFiltersCount() {
    int count = 0;
    if (!widget.includeShared)
      count++; // Compter l'exclusion des listes partagées
    if (widget.activePeriodFilter != null) count++;
    return count;
  }

  void _clearAllFilters() {
    print('🔧 Clearing all analytics filters');
    widget.onIncludeSharedChanged(true); // Reset à "inclure"
    widget.onPeriodFilterChanged(null);
    if (widget.onClearFilters != null) {
      widget.onClearFilters!();
    }
  }
}
