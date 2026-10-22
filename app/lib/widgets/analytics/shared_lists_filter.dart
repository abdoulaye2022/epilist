// widgets/analytics/shared_lists_filter.dart
import 'package:epilist/theme/app_theme.dart';
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
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // ✅ Toggle principal
          Row(
            children: [
              Icon(
                includeShared ? Icons.group : Icons.person,
                color: includeShared ? AppColors.info : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.includeSharedLists,
                  style: TextStyle(
                    fontSize: 16,
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
                activeThumbColor: AppColors.info,
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.showingOnlyOwnLists,
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
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
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.spendingBreakdown,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          // Barre de progression
          if (ownTotal > 0 || sharedTotal > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ownPercentage / 100,
                backgroundColor: AppColors.info.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
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
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${l10n.myLists}: ${ownPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 14.5),
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
                        color: AppColors.info.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${l10n.sharedLists}: ${sharedPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 14.5),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          includeShared ? Icons.group : Icons.person,
          size: 18,
          color: includeShared ? AppColors.info : AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Switch.adaptive(
          value: includeShared,
          onChanged: onChanged,
          activeThumbColor: AppColors.info,
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
        color: AppColors.warningTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_alt, size: 14, color: AppColors.warningInk),
          const SizedBox(width: 4),
          Text(
            l10n.ownListsOnly,
            style: TextStyle(
              fontSize: 14.5,
              color: AppColors.warning,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
