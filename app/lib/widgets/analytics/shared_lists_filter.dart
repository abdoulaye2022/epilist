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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // ✅ Toggle principal
          Row(
            children: [
              Icon(
                includeShared ? Icons.group : Icons.person,
                color: includeShared ? Colors.blue : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.includeSharedLists ?? 'Inclure les listes partagées',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Switch.adaptive(
                value: includeShared,
                onChanged: (value) {
                  if (onChanged != null) {
                    onChanged!(value);
                  } else {
                    // ✅ CORRECTION: Utiliser le bloc existant du contexte
                    context.read<AnalyticsBloc>().add(
                      ToggleSharedListsFilter(includeShared: value),
                    );
                  }
                },
                activeColor: Colors.blue,
              ),
            ],
          ),

          // ✅ Description explicative
          if (!includeShared)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.showingOnlyOwnLists ??
                          'Affichage uniquement de vos propres listes',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ✅ Breakdown optionnel (si activé) - CORRIGÉ pour utiliser le bloc existant
          if (showBreakdown && includeShared)
            BlocBuilder<AnalyticsBloc, AnalyticsState>(
              builder: (context, state) {
                if (state is DashboardLoaded) {
                  final breakdown = state.dashboardData['data_breakdown'];
                  if (breakdown != null) {
                    return _buildBreakdownSection(context, breakdown);
                  }
                }
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection(
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
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.spendingBreakdown ?? 'Répartition des dépenses',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          // Barre de progression
          if (ownTotal > 0 || sharedTotal > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ownPercentage / 100,
                backgroundColor: Colors.blue.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Détails
          Row(
            children: [
              // Mes listes
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${l10n.myLists ?? "Mes listes"}: ${ownPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Listes partagées
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${l10n.sharedLists ?? "Partagées"}: ${sharedPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ✅ Widget simplifié pour un toggle rapide
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
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          includeShared ? Icons.group : Icons.person,
          size: 18,
          color: includeShared ? Colors.blue : Colors.grey,
        ),
        const SizedBox(width: 4),
        Switch.adaptive(
          value: includeShared,
          onChanged: onChanged,
          activeColor: Colors.blue,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}

// ✅ Widget de statut du filtre pour la barre d'app
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_alt, size: 14, color: Colors.orange[700]),
          const SizedBox(width: 4),
          Text(
            l10n.ownListsOnly ?? 'Mes listes uniquement',
            style: TextStyle(
              fontSize: 11,
              color: Colors.orange[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
