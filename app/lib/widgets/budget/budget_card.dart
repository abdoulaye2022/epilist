// widgets/budget/budget_card.dart
import 'package:flutter/material.dart';
import 'package:epilist/models/budget.dart';
import 'package:epilist/l10n/app_localizations.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: compact ? 1 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, l10n),
              if (!compact) ...[
                const SizedBox(height: 12),
                _buildAmountInfo(context, l10n),
                const SizedBox(height: 12),
                _buildProgressBar(context, l10n), // ✅ AJOUT l10n
                const SizedBox(height: 8),
                _buildFooter(context, l10n),
              ] else ...[
                const SizedBox(height: 8),
                _buildCompactInfo(context, l10n),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        // Icône de statut
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getStatusIcon(),
            color: _getStatusColor(),
            size: compact ? 16 : 20,
          ),
        ),
        const SizedBox(width: 12),

        // Nom et type
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                budget.name,
                style: TextStyle(
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    budget.periodDisplayName,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (budget.isListSpecific) ...[
                    Text(
                      ' • ',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Icon(Icons.list_alt, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 2),
                    Flexible(
                      // ✅ CORRECTION OVERFLOW
                      child: Text(
                        budget.listName ?? l10n.unknownList, // ✅ LOCALISATION
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else ...[
                    Text(
                      ' • ',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Icon(Icons.public, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 2),
                    Text(
                      l10n.general,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ), // ✅ LOCALISATION
                  ],
                ],
              ),
            ],
          ),
        ),

        // Menu actions
        if (!compact)
          PopupMenuButton<String>(
            onSelected: (value) => _handleAction(value),
            itemBuilder:
                (context) => [
                  if (onEdit != null)
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 18),
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
                            budget.isActive ? Icons.pause : Icons.play_arrow,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(budget.isActive ? l10n.pause : l10n.activate),
                        ],
                      ),
                    ),
                  if (onDelete != null) ...[
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red[600]),
                          const SizedBox(width: 8),
                          Text(
                            l10n.delete,
                            style: TextStyle(color: Colors.red[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
            child: Icon(Icons.more_vert, color: Colors.grey[600]),
          ),
      ],
    );
  }

  Widget _buildAmountInfo(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          // ✅ CORRECTION OVERFLOW
          child: _buildAmountColumn(
            l10n.budgeted,
            budget.formattedBudgetAmount,
            Colors.blue[600]!,
          ),
        ),
        Flexible(
          // ✅ CORRECTION OVERFLOW
          child: _buildAmountColumn(
            l10n.spent,
            budget.formattedSpentAmount,
            _getSpentColor(),
          ),
        ),
        Flexible(
          // ✅ CORRECTION OVERFLOW
          child: _buildAmountColumn(
            l10n.remaining,
            budget.formattedRemainingAmount,
            Colors.green[600]!,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountColumn(String label, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis, // ✅ CORRECTION OVERFLOW
          maxLines: 1,
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
          overflow: TextOverflow.ellipsis, // ✅ CORRECTION OVERFLOW
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.spendingProgress, // ✅ LOCALISATION
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${budget.spentPercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getProgressColor(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: (budget.spentPercentage / 100).clamp(0.0, 1.0),
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Période
        Flexible(
          // ✅ CORRECTION OVERFLOW
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Flexible(
                // ✅ CORRECTION OVERFLOW
                child: Text(
                  _formatDateRange(),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),

        // Statut/Message d'alerte
        if (budget.shouldShowAlert && budget.alertMessage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getShortAlertMessage(l10n), // ✅ LOCALISATION
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _getStatusColor(),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              budget.daysRemaining > 0
                  ? '${budget.daysRemaining}${l10n.day}${budget.daysRemaining > 1 ? l10n.days.substring(l10n.day.length) : ""} ${l10n.remaining.toLowerCase()}' // ✅ LOCALISATION
                  : l10n.expired, // ✅ LOCALISATION
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color:
                    budget.daysRemaining > 0
                        ? Colors.green[600]
                        : Colors.red[600],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompactInfo(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Montants
        Expanded(
          child: Text(
            '${budget.formattedSpentAmount} / ${budget.formattedBudgetAmount}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis, // ✅ CORRECTION OVERFLOW
          ),
        ),

        // Statut
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${budget.spentPercentage.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    if (budget.isExceeded) return Colors.red[600]!;
    if (budget.isNearLimit) return Colors.orange[600]!;
    return Colors.green[600]!;
  }

  Color _getSpentColor() {
    if (budget.isExceeded) return Colors.red[600]!;
    if (budget.isNearLimit) return Colors.orange[600]!;
    return Colors.blue[600]!;
  }

  Color _getProgressColor() {
    if (budget.isExceeded) return Colors.red[600]!;
    if (budget.isNearLimit) return Colors.orange[600]!;
    return Colors.green[600]!;
  }

  IconData _getStatusIcon() {
    if (budget.isExceeded) return Icons.warning;
    if (budget.isNearLimit) return Icons.info;
    if (budget.isListSpecific) return Icons.list_alt;
    return Icons.account_balance_wallet;
  }

  String _formatDateRange() {
    final start = budget.startDate;
    final end = budget.endDate;

    if (start.year == end.year && start.month == end.month) {
      return '${start.day}-${end.day}/${start.month}/${start.year}';
    }
    return '${start.day}/${start.month} - ${end.day}/${end.month}';
  }

  String _getShortAlertMessage(AppLocalizations l10n) {
    if (budget.isExceeded) return l10n.exceeded;
    if (budget.isNearLimit) return l10n.warning;
    return 'OK'; // Garder 'OK' car c'est universel
  }

  void _handleAction(String action) {
    switch (action) {
      case 'edit':
        onEdit?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
      case 'toggle':
        onToggleStatus?.call();
        break;
    }
  }
}

// widgets/budget/budget_summary_card.dart
class BudgetSummaryCard extends StatelessWidget {
  final int totalBudgets;
  final int activeBudgets;
  final int exceededBudgets;
  final int warningBudgets;

  const BudgetSummaryCard({
    super.key,
    required this.totalBudgets,
    required this.activeBudgets,
    required this.exceededBudgets,
    required this.warningBudgets,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.dashboard,
                    color: Colors.green[600],
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
                          color: Colors.black87,
                        ),
                        overflow:
                            TextOverflow.ellipsis, // ✅ CORRECTION OVERFLOW
                        maxLines: 1,
                      ),
                      Text(
                        l10n.overviewOfYourBudgets,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        overflow:
                            TextOverflow.ellipsis, // ✅ CORRECTION OVERFLOW
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    l10n.total,
                    totalBudgets.toString(),
                    Colors.blue[600]!,
                    Icons.account_balance_wallet,
                  ),
                ),
                const SizedBox(width: 12), // ✅ ESPACEMENT ENTRE COLONNES
                Expanded(
                  child: _buildStatItem(
                    l10n.active,
                    activeBudgets.toString(),
                    Colors.green[600]!,
                    Icons.play_circle,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    l10n.warnings,
                    warningBudgets.toString(),
                    Colors.orange[600]!,
                    Icons.warning,
                  ),
                ),
                const SizedBox(width: 12), // ✅ ESPACEMENT ENTRE COLONNES
                Expanded(
                  child: _buildStatItem(
                    l10n.exceeded,
                    exceededBudgets.toString(),
                    Colors.red[600]!,
                    Icons.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center, // ✅ CENTRER LE TEXTE
            overflow: TextOverflow.ellipsis, // ✅ CORRECTION OVERFLOW
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

// widgets/budget/budget_alerts_widget.dart
class BudgetAlertsWidget extends StatelessWidget {
  final Budget budget;
  final VoidCallback? onTap;

  const BudgetAlertsWidget({super.key, required this.budget, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getAlertColor().withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getAlertColor().withOpacity(0.1),
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
                          budget.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          overflow:
                              TextOverflow.ellipsis, // ✅ CORRECTION OVERFLOW
                          maxLines: 1,
                        ),
                        if (budget.listName != null)
                          Text(
                            budget.listName!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow:
                                TextOverflow.ellipsis, // ✅ CORRECTION OVERFLOW
                            maxLines: 1,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getAlertColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${budget.spentPercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getAlertColor(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (budget.alertMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getAlertColor().withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: _getAlertColor(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          budget.alertMessage!,
                          style: TextStyle(
                            fontSize: 13,
                            color: _getAlertColor(),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow:
                              TextOverflow.ellipsis, // ✅ CORRECTION OVERFLOW
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              LinearProgressIndicator(
                value: (budget.spentPercentage / 100).clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(_getAlertColor()),
                minHeight: 4,
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    // ✅ CORRECTION OVERFLOW
                    child: Text(
                      '${budget.formattedSpentAmount} / ${budget.formattedBudgetAmount}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  Text(
                    budget.daysRemaining > 0
                        ? '${budget.daysRemaining} ${l10n.days} ${l10n.remaining.toLowerCase()}' // ✅ LOCALISATION
                        : l10n.expired, // ✅ LOCALISATION
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis, // ✅ CORRECTION OVERFLOW
                    maxLines: 1,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAlertColor() {
    if (budget.isExceeded) return Colors.red[600]!;
    if (budget.isNearLimit) return Colors.orange[600]!;
    return Colors.blue[600]!;
  }

  IconData _getAlertIcon() {
    if (budget.isExceeded) return Icons.error;
    if (budget.isNearLimit) return Icons.warning;
    return Icons.info;
  }
}
