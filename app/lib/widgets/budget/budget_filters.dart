// widgets/budget/budget_filters.dart
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';

class BudgetFilters extends StatefulWidget {
  final String? activeStatusFilter;
  final String? activePeriodFilter;
  final String? activeScopeFilter;
  final String? activeSortBy;
  final bool? activeSortAscending;
  final Function(String?) onStatusFilterChanged;
  final Function(String?) onPeriodFilterChanged;
  final Function(String?) onScopeFilterChanged;
  final Function(String, bool) onSortChanged;
  final VoidCallback? onClearFilters;

  const BudgetFilters({
    super.key,
    this.activeStatusFilter,
    this.activePeriodFilter,
    this.activeScopeFilter,
    this.activeSortBy,
    this.activeSortAscending,
    required this.onStatusFilterChanged,
    required this.onPeriodFilterChanged,
    required this.onScopeFilterChanged,
    required this.onSortChanged,
    this.onClearFilters,
  });

  @override
  State<BudgetFilters> createState() => _BudgetFiltersState();
}

class _BudgetFiltersState extends State<BudgetFilters> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final hasActiveFilters = _hasActiveFilters();

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
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
                        hasActiveFilters
                            ? theme.primaryColor
                            : Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.filtersAndSort,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: hasActiveFilters ? theme.primaryColor : null,
                      ),
                      overflow: TextOverflow.ellipsis, // ✅ CORRECTION OVERFLOW
                    ),
                  ),
                  if (hasActiveFilters) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getActiveFiltersCount().toString(),
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _clearAllFilters,
                      icon: const Icon(Icons.clear, size: 20),
                      tooltip: l10n.clearFilters,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),

          // Contenu des filtres (expansible)
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtres par statut
                  _buildFilterSection(l10n.status, _buildStatusFilters(l10n)),
                  const SizedBox(height: 16),

                  // Filtres par période
                  _buildFilterSection(l10n.period, _buildPeriodFilters(l10n)),
                  const SizedBox(height: 16),

                  // Filtres par portée
                  _buildFilterSection(l10n.scope, _buildScopeFilters(l10n)),
                  const SizedBox(height: 16),

                  // Tri
                  _buildFilterSection(l10n.sortBy, _buildSortOptions(l10n)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
          overflow: TextOverflow.ellipsis, // ✅ CORRECTION OVERFLOW
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildStatusFilters(AppLocalizations l10n) {
    return Wrap(
      // ✅ CORRECTION OVERFLOW - Remplacer SingleChildScrollView par Wrap
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          l10n.all,
          null,
          widget.activeStatusFilter,
          widget.onStatusFilterChanged,
        ),
        _buildFilterChip(
          l10n.active,
          'active',
          widget.activeStatusFilter,
          widget.onStatusFilterChanged,
          icon: Icons.play_circle,
          color: Colors.green,
        ),
        _buildFilterChip(
          l10n.exceeded,
          'exceeded',
          widget.activeStatusFilter,
          widget.onStatusFilterChanged,
          icon: Icons.warning,
          color: Colors.red,
        ),
        _buildFilterChip(
          l10n.warning,
          'warning',
          widget.activeStatusFilter,
          widget.onStatusFilterChanged,
          icon: Icons.info,
          color: Colors.orange,
        ),
        _buildFilterChip(
          l10n.expired,
          'expired',
          widget.activeStatusFilter,
          widget.onStatusFilterChanged,
          icon: Icons.schedule,
          color: Colors.grey,
        ),
        _buildFilterChip(
          l10n.upcoming,
          'upcoming',
          widget.activeStatusFilter,
          widget.onStatusFilterChanged,
          icon: Icons.upcoming,
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildPeriodFilters(AppLocalizations l10n) {
    return Wrap(
      // ✅ CORRECTION OVERFLOW - Remplacer SingleChildScrollView par Wrap
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          l10n.all,
          null,
          widget.activePeriodFilter,
          widget.onPeriodFilterChanged,
        ),
        _buildFilterChip(
          l10n.weekly,
          'weekly',
          widget.activePeriodFilter,
          widget.onPeriodFilterChanged,
          icon: Icons.view_week,
        ),
        _buildFilterChip(
          l10n.monthly,
          'monthly',
          widget.activePeriodFilter,
          widget.onPeriodFilterChanged,
          icon: Icons.calendar_month,
        ),
        _buildFilterChip(
          l10n.yearly,
          'yearly',
          widget.activePeriodFilter,
          widget.onPeriodFilterChanged,
          icon: Icons.calendar_today,
        ),
        _buildFilterChip(
          l10n.custom,
          'custom',
          widget.activePeriodFilter,
          widget.onPeriodFilterChanged,
          icon: Icons.tune,
        ),
      ],
    );
  }

  Widget _buildScopeFilters(AppLocalizations l10n) {
    return Wrap(
      // ✅ CORRECTION OVERFLOW - Remplacer SingleChildScrollView par Wrap
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          l10n.all,
          null,
          widget.activeScopeFilter,
          widget.onScopeFilterChanged,
        ),
        _buildFilterChip(
          l10n.general,
          'general',
          widget.activeScopeFilter,
          widget.onScopeFilterChanged,
          icon: Icons.public,
        ),
        _buildFilterChip(
          l10n.specificList,
          'specific',
          widget.activeScopeFilter,
          widget.onScopeFilterChanged,
          icon: Icons.list,
        ),
      ],
    );
  }

  Widget _buildSortOptions(AppLocalizations l10n) {
    final sortOptions = [
      {'key': 'name', 'label': l10n.name, 'icon': Icons.sort_by_alpha},
      {'key': 'amount', 'label': l10n.amount, 'icon': Icons.attach_money},
      {'key': 'spent', 'label': l10n.spent, 'icon': Icons.payments},
      {
        'key': 'remaining',
        'label': l10n.remaining,
        'icon': Icons.account_balance_wallet,
      },
      {'key': 'date', 'label': l10n.date, 'icon': Icons.calendar_today},
    ];

    return Column(
      children:
          sortOptions.map((option) {
            final isActive = widget.activeSortBy == option['key'];
            final isAscending = widget.activeSortAscending ?? true;

            return InkWell(
              onTap: () {
                if (isActive) {
                  widget.onSortChanged(option['key'] as String, !isAscending);
                } else {
                  widget.onSortChanged(option['key'] as String, true);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color:
                      isActive
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : null,
                  borderRadius: BorderRadius.circular(8),
                  border:
                      isActive
                          ? Border.all(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.3),
                          )
                          : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      option['icon'] as IconData,
                      size: 20,
                      color:
                          isActive
                              ? Theme.of(context).primaryColor
                              : Colors.grey[600],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option['label'] as String,
                        style: TextStyle(
                          color:
                              isActive ? Theme.of(context).primaryColor : null,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                        overflow:
                            TextOverflow.ellipsis, // ✅ CORRECTION OVERFLOW
                      ),
                    ),
                    if (isActive)
                      Icon(
                        isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
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
    final isActive = activeValue == value;
    final theme = Theme.of(context);

    return FilterChip(
      label: IntrinsicWidth(
        // ✅ CORRECTION OVERFLOW - Contraindre la largeur
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isActive ? Colors.white : (color ?? theme.primaryColor),
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              // ✅ CORRECTION OVERFLOW
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : null,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis, // ✅ CORRECTION OVERFLOW
                maxLines: 1, // ✅ LIMITATION À UNE LIGNE
              ),
            ),
          ],
        ),
      ),
      selected: isActive,
      onSelected: (selected) => onChanged(selected ? value : null),
      selectedColor: color ?? theme.primaryColor,
      checkmarkColor: Colors.white,
      backgroundColor: Colors.grey[100],
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isActive ? (color ?? theme.primaryColor) : Colors.grey[300]!,
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return widget.activeStatusFilter != null ||
        widget.activePeriodFilter != null ||
        widget.activeScopeFilter != null ||
        widget.activeSortBy != null;
  }

  int _getActiveFiltersCount() {
    int count = 0;
    if (widget.activeStatusFilter != null) count++;
    if (widget.activePeriodFilter != null) count++;
    if (widget.activeScopeFilter != null) count++;
    if (widget.activeSortBy != null) count++;
    return count;
  }

  void _clearAllFilters() {
    widget.onStatusFilterChanged(null);
    widget.onPeriodFilterChanged(null);
    widget.onScopeFilterChanged(null);
    if (widget.onClearFilters != null) {
      widget.onClearFilters!();
    }
  }
}
