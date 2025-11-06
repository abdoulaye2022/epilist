// widgets/shopping/list_filter_chips.dart - Filtres pour les listes de courses
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';

enum ListFilter {
  all,
  active,
  completed,
  shared,
}

class ListFilterChips extends StatelessWidget {
  final ListFilter selectedFilter;
  final ValueChanged<ListFilter> onFilterChanged;

  const ListFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip(
            context,
            label: l10n.all,
            icon: Icons.list,
            filter: ListFilter.all,
            count: null,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            label: l10n.active,
            icon: Icons.schedule,
            filter: ListFilter.active,
            count: null,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            label: l10n.completed,
            icon: Icons.check_circle,
            filter: ListFilter.completed,
            count: null,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            label: l10n.shared,
            icon: Icons.people,
            filter: ListFilter.shared,
            count: null,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required ListFilter filter,
    int? count,
  }) {
    final isSelected = selectedFilter == filter;
    // ✅ Utiliser la couleur du thème de l'application (même style que budget_filters)
    final Color primaryColor = Theme.of(context).primaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onFilterChanged(filter),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            // ✅ Style identique aux filtres de budget
            color: isSelected ? primaryColor : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
              if (count != null && count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.3)
                        : primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
