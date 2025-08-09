// widgets/analytics/shared_lists_filter.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/analytics/analytics_bloc.dart';
import 'package:epilist/blocs/analytics/analytics_event.dart';
import 'package:epilist/blocs/analytics/analytics_state.dart';
import 'package:epilist/l10n/app_localizations.dart';

class SharedListsFilter extends StatelessWidget {
  final bool includeShared;
  final Function(bool)? onChanged;
  final bool showBreakdown;

  const SharedListsFilter({
    super.key,
    required this.includeShared,
    this.onChanged,
    this.showBreakdown = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              includeShared
                  ? Colors.blue.withOpacity(0.3)
                  : theme.colorScheme.outline.withOpacity(0.2),
          width: includeShared ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec icône et titre
            _buildHeader(context, l10n),
            const SizedBox(height: 16),

            // Toggle principal avec design moderne
            _buildMainToggle(context, l10n),

            // Description explicative
            if (!includeShared) ...[
              const SizedBox(height: 12),
              _buildInfoBanner(context, l10n),
            ],

            // Breakdown optionnel
            if (showBreakdown && includeShared) ...[
              const SizedBox(height: 20),
              _buildBreakdownSection(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: includeShared ? Colors.blue[50] : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            includeShared ? Icons.groups_rounded : Icons.person_rounded,
            color: includeShared ? Colors.blue[600] : Colors.grey[600],
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.includeSharedLists ?? 'Inclure les listes partagées',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                includeShared
                    ? 'Toutes les listes sont incluses'
                    : 'Seules vos listes personnelles',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainToggle(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:
            includeShared
                ? Colors.blue[50]?.withOpacity(0.5)
                : theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              includeShared
                  ? Colors.blue.withOpacity(0.2)
                  : theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            includeShared
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: includeShared ? Colors.blue[600] : Colors.grey[500],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              includeShared
                  ? 'Analyse complète (mes listes + partagées)'
                  : 'Analyse personnelle uniquement',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Transform.scale(
            scale: 0.9,
            child: Switch.adaptive(
              value: includeShared,
              onChanged: (value) {
                if (onChanged != null) {
                  onChanged!(value);
                } else {
                  context.read<AnalyticsBloc>().add(
                    ToggleSharedListsFilter(includeShared: value),
                  );
                }
              },
              activeColor: Colors.blue[600],
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.showingOnlyOwnLists ??
                  'Affichage uniquement de vos propres listes',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection(BuildContext context) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        if (state is DashboardLoaded) {
          final breakdown = state.dashboardData['data_breakdown'];
          if (breakdown != null) {
            return _buildBreakdownContent(context, breakdown);
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildBreakdownContent(
    BuildContext context,
    Map<String, dynamic> breakdown,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final ownTotal = breakdown['own_lists_total']?.toDouble() ?? 0.0;
    final sharedTotal = breakdown['shared_lists_total']?.toDouble() ?? 0.0;
    final ownPercentage = breakdown['own_lists_percentage']?.toDouble() ?? 0.0;
    final sharedPercentage =
        breakdown['shared_lists_percentage']?.toDouble() ?? 0.0;

    if (ownTotal == 0 && sharedTotal == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du breakdown
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.pie_chart_outline_rounded,
                  size: 18,
                  color: Colors.blue[600],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.spendingBreakdown ?? 'Répartition des dépenses',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Barre de progression moderne
          if (ownTotal > 0 || sharedTotal > 0) ...[
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ownPercentage / 100,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green[500]!),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Statistiques détaillées
          Row(
            children: [
              // Mes listes
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.person_rounded,
                  color: Colors.green,
                  label: l10n.myLists ?? "Mes listes",
                  percentage: ownPercentage,
                ),
              ),

              const SizedBox(width: 12),

              // Listes partagées
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.group_rounded,
                  color: Colors.blue,
                  label: l10n.sharedLists ?? "Partagées",
                  percentage: sharedPercentage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required MaterialColor color,
    required String label,
    required double percentage,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color[500],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icon, size: 12, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: color[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color[700],
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Widget simplifié pour un toggle rapide - Design moderne
class QuickSharedListsToggle extends StatelessWidget {
  final bool includeShared;
  final Function(bool) onChanged;

  const QuickSharedListsToggle({
    super.key,
    required this.includeShared,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: includeShared ? Colors.blue[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              includeShared
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            includeShared ? Icons.groups_rounded : Icons.person_rounded,
            size: 16,
            color: includeShared ? Colors.blue[600] : Colors.grey[600],
          ),
          const SizedBox(width: 6),
          Transform.scale(
            scale: 0.8,
            child: Switch.adaptive(
              value: includeShared,
              onChanged: onChanged,
              activeColor: Colors.blue[600],
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Widget de statut du filtre pour la barre d'app - Design moderne
class FilterStatusIndicator extends StatelessWidget {
  final bool includeShared;

  const FilterStatusIndicator({super.key, required this.includeShared});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (includeShared) {
      return const SizedBox.shrink(); // Pas d'indication si tout est inclus
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.filter_alt_rounded,
              size: 10,
              color: Colors.orange[700],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            l10n.ownListsOnly ?? 'Mes listes uniquement',
            style: TextStyle(
              fontSize: 11,
              color: Colors.orange[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
