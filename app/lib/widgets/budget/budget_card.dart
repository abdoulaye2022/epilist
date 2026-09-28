// widgets/budget/budget_card.dart - VERSION AVEC BACKGROUND BLANC
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:epilist/models/budget.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart';

class BudgetCard extends StatelessWidget {
  final Budget budget;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStatus;

  const BudgetCard({
    super.key,
    required this.budget,
    this.compact = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleStatus,
  });

  Color get _statusColor => switch (budget.status) {
        BudgetStatus.exceeded => AppColors.error,
        BudgetStatus.warning => AppColors.warning,
        BudgetStatus.ok => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final ratio = (budget.spentPercentage / 100).clamp(0.0, 1.0);
    final expired = budget.isExpired;

    final df = DateFormat('d MMM', locale);
    final period =
        '${df.format(budget.startDate)} – ${df.format(budget.endDate)}';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm + 4, AppSpacing.xs, AppSpacing.sm + 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Pourcentage dans une pastille couleur statut
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      '${budget.spentPercentage.round()}%',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: _statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                budget.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: expired
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (expired) ...[
                              const SizedBox(width: 6),
                              Text(
                                l10n.expired,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textDisabled,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          period,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        budget.formattedSpentAmount,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _statusColor,
                        ),
                      ),
                      Text(
                        '/ ${budget.formattedBudgetAmount}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (!compact) _buildMenu(context, l10n),
                ],
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm + 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 5,
                    backgroundColor: AppColors.background,
                    valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context, AppLocalizations l10n) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert,
          size: 20, color: AppColors.textSecondary),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit?.call();
            break;
          case 'toggle':
            onToggleStatus?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        if (onEdit != null)
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(l10n.edit),
              ],
            ),
          ),
        if (onToggleStatus != null)
          PopupMenuItem(
            value: 'toggle',
            child: Row(
              children: [
                Icon(
                  budget.isActive
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(budget.isActive ? l10n.deactivate : l10n.activate),
              ],
            ),
          ),
        if (onDelete != null) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.error),
                const SizedBox(width: 8),
                Text(l10n.delete,
                    style: const TextStyle(color: AppColors.error)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class BudgetAlertsWidget extends StatelessWidget {
  final Budget budget;
  final VoidCallback? onDismiss;

  const BudgetAlertsWidget({super.key, required this.budget, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 3,
      color: Colors.white, // ✅ BACKGROUND BLANC
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, // ✅ BACKGROUND BLANC
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getAlertColor().withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with alert icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getAlertColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getAlertIcon(),
                    color: _getAlertColor(),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getAlertTitle(l10n),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getAlertColor(),
                        ),
                      ),
                      Text(
                        budget.name,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                    onPressed: onDismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Budget details avec FormattedAmount
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background, // ✅ BACKGROUND GRIS TRÈS CLAIR
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.budgeted,
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      FormattedAmount(
                        amount: budget.budgetAmount,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.spent,
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      FormattedAmount(
                        amount: budget.spentAmount,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getAlertColor(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (budget.spentPercentage / 100).clamp(0.0, 1.0),
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(_getAlertColor()),
                    minHeight: 6,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${budget.spentPercentage.toStringAsFixed(1)}% ${l10n.spent.toLowerCase()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _getAlertColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (budget.daysRemaining > 0)
                        Text(
                          '${budget.daysRemaining} ${_getDaysText(l10n)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Alert message
            if (budget.alertMessage != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getAlertColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getAlertColor().withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: _getAlertColor()),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        budget.alertMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          color: _getAlertColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // List name (if applicable)
            if (budget.listName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.list_alt, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    budget.listName!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],

            // Action button (only suggestions for exceeded budgets)
            if (budget.isExceeded) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showSuggestions(context),
                  icon: const Icon(Icons.lightbulb_outline, size: 16),
                  label: Text(l10n.suggestions),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getAlertColor(),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getAlertColor() {
    if (budget.isExceeded) {
      return AppColors.error;
    } else if (budget.isNearLimit) {
      return AppColors.warning;
    } else {
      return AppColors.accent;
    }
  }

  IconData _getAlertIcon() {
    if (budget.isExceeded) {
      return Icons.error;
    } else if (budget.isNearLimit) {
      return Icons.warning;
    } else {
      return Icons.info;
    }
  }

  String _getAlertTitle(AppLocalizations l10n) {
    if (budget.isExceeded) {
      return '🚨 ${l10n.exceeded}';
    } else if (budget.isNearLimit) {
      return '⚠️ ${l10n.warning}';
    } else {
      return '📊 ${l10n.information}';
    }
  }

  String _getDaysText(AppLocalizations l10n) {
    if (budget.daysRemaining == 1) {
      return l10n.day;
    } else {
      return '${l10n.day}s';
    }
  }

  void _showSuggestions(BuildContext context) {
    // Implementation des suggestions...
  }
}

// widgets/budget/budget_summary_card.dart - VERSION AVEC BACKGROUND BLANC
class BudgetSummaryCard extends StatelessWidget {
  final int totalBudgets;
  final int activeBudgets;
  final int exceededBudgets;
  final int warningBudgets;
  final double? totalBudgeted;
  final double? totalSpent;

  const BudgetSummaryCard({
    super.key,
    required this.totalBudgets,
    required this.activeBudgets,
    required this.exceededBudgets,
    required this.warningBudgets,
    this.totalBudgeted,
    this.totalSpent,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 4,
      color: Colors.white, // ✅ BACKGROUND BLANC
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, // ✅ BACKGROUND BLANC
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.budgetSummary,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        l10n.overviewOfYourBudgets,
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    l10n.totalBudgets,
                    totalBudgets.toString(),
                    Icons.widgets,
                    AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    l10n.active,
                    activeBudgets.toString(),
                    Icons.play_circle_outline,
                    AppColors.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    l10n.warnings,
                    warningBudgets.toString(),
                    Icons.warning_amber,
                    AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    l10n.exceeded,
                    exceededBudgets.toString(),
                    Icons.error_outline,
                    AppColors.error,
                  ),
                ),
              ],
            ),

            // Amounts avec FormattedAmount
            if (totalBudgeted != null && totalSpent != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background, // ✅ BACKGROUND GRIS TRÈS CLAIR
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.budgeted,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        FormattedAmount(
                          amount: totalBudgeted!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.spent,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        FormattedAmount(
                          amount: totalSpent!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _getSpentColor(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value:
                          totalBudgeted! > 0
                              ? (totalSpent! / totalBudgeted!).clamp(0.0, 1.0)
                              : 0.0,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getSpentColor(),
                      ),
                      minHeight: 8,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background, // ✅ BACKGROUND GRIS TRÈS CLAIR
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getSpentColor() {
    if (totalBudgeted == null || totalSpent == null || totalBudgeted == 0) {
      return AppColors.primary;
    }

    final percentage = (totalSpent! / totalBudgeted!) * 100;

    if (percentage >= 100) {
      return AppColors.error;
    } else if (percentage >= 80) {
      return AppColors.warning;
    } else {
      return AppColors.primary;
    }
  }
}
