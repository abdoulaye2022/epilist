// screens/budget_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/models/budget.dart';
import 'package:epilist/blocs/budget/budget_bloc.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/budget/create_budget_dialog.dart';
import 'package:intl/intl.dart';

class BudgetDetailsScreen extends StatelessWidget {
  final Budget budget;

  const BudgetDetailsScreen({
    super.key,
    required this.budget,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          budget.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: l10n.edit,
            onPressed: () => _editBudget(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) => _handleMenuAction(value, context),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_status',
                child: Row(
                  children: [
                    Icon(
                      budget.isActive ? Icons.pause : Icons.play_arrow,
                      size: 20,
                      color: budget.isActive ? Colors.orange[600] : Colors.green[600],
                    ),
                    const SizedBox(width: 8),
                    Text(budget.isActive ? l10n.pause : l10n.activate),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Text(l10n.delete),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec montants
            _buildHeaderCard(context, l10n),

            const SizedBox(height: 16),

            // Barre de progression
            _buildProgressCard(context, l10n),

            const SizedBox(height: 16),

            // Informations de la période
            _buildPeriodCard(context, l10n),

            const SizedBox(height: 16),

            // Statut et alertes
            if (budget.shouldShowAlert) _buildAlertCard(context, l10n),

            const SizedBox(height: 16),

            // Informations supplémentaires
            _buildAdditionalInfoCard(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, AppLocalizations l10n) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Budget alloué
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget Alloué', // TODO: Add to l10n
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                FormattedAmount(
                  amount: budget.budgetAmount,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            const Divider(height: 32),

            // Dépensé et Restant
            Row(
              children: [
                Expanded(
                  child: _buildAmountColumn(
                    l10n.spent,
                    budget.spentAmount,
                    _getSpentColor(),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                Expanded(
                  child: _buildAmountColumn(
                    l10n.remaining,
                    budget.remainingAmount,
                    budget.isExceeded ? Colors.red[600]! : Colors.green[600]!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountColumn(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        FormattedAmount(
          amount: amount,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard(BuildContext context, AppLocalizations l10n) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.progress,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                // Afficher le VRAI pourcentage (peut être > 100%)
                Text(
                  '${budget.spentPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getSpentColor(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Barre de progression (plafonnée à 100% visuellement)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (budget.spentPercentage / 100).clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(_getSpentColor()),
              ),
            ),

            if (budget.isExceeded) ...[
              const SizedBox(height: 8),
              Text(
                'Exceeded by: ${(budget.spentAmount - budget.budgetAmount).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodCard(BuildContext context, AppLocalizations l10n) {
    final dateFormat = DateFormat.yMMMd();
    final daysTotal = budget.endDate.difference(budget.startDate).inDays;
    final daysElapsed = DateTime.now().difference(budget.startDate).inDays.clamp(0, daysTotal);
    final progressDays = daysTotal > 0 ? (daysElapsed / daysTotal) : 0.0;

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.period,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildDateInfo(
                    l10n.startDate,
                    dateFormat.format(budget.startDate),
                    Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateInfo(
                    l10n.endDate,
                    dateFormat.format(budget.endDate),
                    Icons.event,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Barre de progression temporelle
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${l10n.daysRemaining}: ${budget.daysRemaining}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${daysElapsed} / ${daysTotal} ${l10n.days}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressDays.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateInfo(String label, String date, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.blue[600]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                date,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlertCard(BuildContext context, AppLocalizations l10n) {
    return Card(
      color: budget.isExceeded ? Colors.red[50] : Colors.orange[50],
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              budget.isExceeded ? Icons.error : Icons.warning,
              color: budget.isExceeded ? Colors.red[600] : Colors.orange[600],
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    budget.isExceeded ? l10n.budgetExceeded : 'Budget Near Limit', // TODO: Add to l10n
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: budget.isExceeded ? Colors.red[800] : Colors.orange[800],
                    ),
                  ),
                  if (budget.alertMessage != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      budget.alertMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: budget.isExceeded ? Colors.red[700] : Colors.orange[700],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoCard(BuildContext context, AppLocalizations l10n) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details', // TODO: Add to l10n
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 16),

            _buildInfoRow(l10n.type, budget.periodDisplayName, Icons.event_repeat),
            const Divider(height: 24),
            _buildInfoRow(l10n.scope, budget.scopeDisplayName, Icons.list_alt),
            const Divider(height: 24),
            _buildInfoRow(
              l10n.alertThreshold,
              '${budget.alertThreshold}%',
              Icons.notifications_active,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              l10n.status,
              budget.isActive ? l10n.active : 'Inactive', // TODO: Add to l10n
              budget.isActive ? Icons.check_circle : Icons.pause_circle,
              valueColor: budget.isActive ? Colors.green[600] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Color _getSpentColor() {
    if (budget.isExceeded) {
      return Colors.red[600]!;
    } else if (budget.isNearLimit) {
      return Colors.orange[600]!;
    }
    return Colors.green[600]!;
  }

  void _editBudget(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<BudgetBloc>(),
        child: BlocListener<BudgetBloc, BudgetState>(
          listener: (context, state) {
            if (state is BudgetOperationSuccess) {
              Navigator.pop(dialogContext);
              Navigator.pop(context); // Retour à l'écran précédent
            }
          },
          child: CreateBudgetDialog(budgetToEdit: budget),
        ),
      ),
    );
  }

  void _handleMenuAction(String action, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    switch (action) {
      case 'toggle_status':
        context.read<BudgetBloc>().add(
          ToggleBudgetStatus(budget.id, !budget.isActive),
        );
        Navigator.pop(context);
        break;

      case 'delete':
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text(l10n.deleteBudget),
            content: Text(l10n.deleteBudgetConfirmation(budget.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.read<BudgetBloc>().add(DeleteBudget(budget.id));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.delete),
              ),
            ],
          ),
        );
        break;
    }
  }
}
