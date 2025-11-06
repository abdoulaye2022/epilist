// widgets/budget/budget_filters.dart - VERSION CORRIGÉE AVEC ÉTAT VISUEL
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
    final hasActiveFilters = _hasActiveFilters();
    // ✅ Utiliser la couleur du thème
    final themeColor = Theme.of(context).primaryColor;

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
                    color: hasActiveFilters ? themeColor : Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.filtersAndSort,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: hasActiveFilters ? themeColor : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  // ✅ CORRECTION: Affichage conditionnel amélioré
                  if (hasActiveFilters) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getActiveFiltersCount().toString(),
                        style: TextStyle(
                          color: themeColor,
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
            // ✅ CORRECTION OVERFLOW: Contraindre la hauteur max
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ DEBUG: Affichage des valeurs actives pour test
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
                            if (widget.activeStatusFilter != null)
                              Text(
                                'Statut: ${widget.activeStatusFilter}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            if (widget.activePeriodFilter != null)
                              Text(
                                'Période: ${widget.activePeriodFilter}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            if (widget.activeScopeFilter != null)
                              Text(
                                'Portée: ${widget.activeScopeFilter}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            if (widget.activeSortBy != null)
                              Text(
                                'Tri: ${widget.activeSortBy} (${widget.activeSortAscending == true ? 'ASC' : 'DESC'})',
                                style: const TextStyle(fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                    ],

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

  Widget _buildStatusFilters(AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          l10n.all,
          null, // ✅ IMPORTANT: null pour "Tous"
          widget.activeStatusFilter,
          widget.onStatusFilterChanged,
        ),
        _buildFilterChip(
          l10n.active,
          'active',
          widget.activeStatusFilter,
          widget.onStatusFilterChanged,
          icon: Icons.play_circle,
          // ✅ Utiliser le thème pour "active" (pas de couleur sémantique)
        ),
        _buildFilterChip(
          l10n.exceeded,
          'exceeded',
          widget.activeStatusFilter,
          widget.onStatusFilterChanged,
          icon: Icons.warning,
          color: Colors.red[600],
        ),
        _buildFilterChip(
          l10n.warning,
          'warning',
          widget.activeStatusFilter,
          widget.onStatusFilterChanged,
          icon: Icons.info,
          color: Colors.orange[600],
        ),
        _buildFilterChip(
          l10n.expired,
          'expired',
          widget.activeStatusFilter,
          widget.onStatusFilterChanged,
          icon: Icons.schedule,
          color: Colors.grey[600],
        ),
        _buildFilterChip(
          l10n.upcoming,
          'upcoming',
          widget.activeStatusFilter,
          widget.onStatusFilterChanged,
          icon: Icons.upcoming,
          color: Colors.blue[600],
        ),
      ],
    );
  }

  Widget _buildPeriodFilters(AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          l10n.all,
          null, // ✅ IMPORTANT: null pour "Tous"
          widget.activePeriodFilter,
          widget.onPeriodFilterChanged,
        ),
        _buildFilterChip(
          l10n.weekly,
          'weekly',
          widget.activePeriodFilter,
          widget.onPeriodFilterChanged,
          icon: Icons.view_week,
          // ✅ Utiliser le thème
        ),
        _buildFilterChip(
          l10n.monthly,
          'monthly',
          widget.activePeriodFilter,
          widget.onPeriodFilterChanged,
          icon: Icons.calendar_month,
          // ✅ Utiliser le thème
        ),
        _buildFilterChip(
          l10n.yearly,
          'yearly',
          widget.activePeriodFilter,
          widget.onPeriodFilterChanged,
          icon: Icons.calendar_today,
          // ✅ Utiliser le thème
        ),
        _buildFilterChip(
          l10n.custom,
          'custom',
          widget.activePeriodFilter,
          widget.onPeriodFilterChanged,
          icon: Icons.tune,
          // ✅ Utiliser le thème
        ),
      ],
    );
  }

  Widget _buildScopeFilters(AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip(
          l10n.all,
          null, // ✅ IMPORTANT: null pour "Tous"
          widget.activeScopeFilter,
          widget.onScopeFilterChanged,
        ),
        _buildFilterChip(
          l10n.general,
          'general',
          widget.activeScopeFilter,
          widget.onScopeFilterChanged,
          icon: Icons.public,
          // ✅ Utiliser le thème pour "general"
        ),
        _buildFilterChip(
          l10n.specificList,
          'specific',
          widget.activeScopeFilter,
          widget.onScopeFilterChanged,
          icon: Icons.list,
          color: Colors.orange[600], // ✅ Garder orange pour distinction
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

    // ✅ Utiliser la couleur du thème
    final themeColor = Theme.of(context).primaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children:
          sortOptions.map((option) {
            final isActive = widget.activeSortBy == option['key'];
            final isAscending = widget.activeSortAscending ?? true;

            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // ✅ DEBUG: Print pour vérifier les clics
                    print(
                      '🔧 Sort option clicked: ${option['key']}, current: ${widget.activeSortBy}, isActive: $isActive',
                    );

                    if (isActive) {
                      widget.onSortChanged(
                        option['key'] as String,
                        !isAscending,
                      );
                    } else {
                      widget.onSortChanged(option['key'] as String, true);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isActive
                              ? themeColor.withValues(alpha: 0.1)
                              : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border:
                          isActive
                              ? Border.all(
                                color: themeColor,
                                width: 2,
                              )
                              : Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          option['icon'] as IconData,
                          size: 20,
                          color: isActive ? themeColor : Colors.grey[600],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option['label'] as String,
                            style: TextStyle(
                              color: isActive ? themeColor : Colors.black87,
                              fontWeight:
                                  isActive
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: themeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isAscending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 16,
                              color: themeColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  // ✅ CORRECTION MAJEURE: Logique de comparaison des filtres
  Widget _buildFilterChip(
    String label,
    String? value,
    String? activeValue,
    Function(String?) onChanged, {
    IconData? icon,
    Color? color,
  }) {
    // ✅ CORRECTION: Logique de comparaison plus robuste
    final isActive =
        (value == null && activeValue == null) ||
        (value != null && value == activeValue);

    return Builder(
      builder: (context) {
        // ✅ Utiliser la couleur du thème de l'application
        final themeColor = Theme.of(context).primaryColor;
        final chipColor = color ?? themeColor;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              print(
                '🔧 Filter chip clicked: "$label", value=$value, current activeValue=$activeValue',
              );
              // ✅ CORRECTION: Logique simplifiée - toujours activer la valeur cliquée
              // Si on clique sur le filtre déjà actif, on le désactive (retour à null)
              if (isActive) {
                onChanged(null);
              } else {
                onChanged(value);
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                // ✅ CORRECTION: Utiliser la couleur du thème
                color: isActive ? chipColor : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? chipColor : Colors.grey[300]!,
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
                      color: isActive ? Colors.white : chipColor,
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
      },
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
    print('🔧 Clearing all filters');
    widget.onStatusFilterChanged(null);
    widget.onPeriodFilterChanged(null);
    widget.onScopeFilterChanged(null);
    if (widget.onClearFilters != null) {
      widget.onClearFilters!();
    }
  }
}
