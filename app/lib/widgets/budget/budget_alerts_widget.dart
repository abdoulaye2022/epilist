// widgets/budget/budget_alerts_widget.dart - VERSION COMPLETE AVEC FormattedAmount
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:epilist/models/budget.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart'; // ✅ IMPORT AJOUTÉ

class BudgetAlertsWidget extends StatelessWidget {
  final Budget budget;
  final VoidCallback? onDismiss;

  const BudgetAlertsWidget({super.key, required this.budget, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getAlertColor().withValues(alpha: 0.3),
            width: 1.5,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getAlertColor().withValues(alpha: 0.05),
              _getAlertColor().withValues(alpha: 0.1),
            ],
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
                    color: _getAlertColor().withValues(alpha: 0.2),
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

            // ✅ SECTION BUDGET AVEC FormattedAmount
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
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
                        // ✅ UTILISATION DE FormattedAmount
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
                        // ✅ UTILISATION DE FormattedAmount
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

            // ✅ AJOUT D'UN RÉSUMÉ AVEC MONTANT RESTANT OU DÉPASSEMENT
            const SizedBox(height: 12),
            _buildBudgetSummary(l10n),

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

  // ✅ NOUVEAU WIDGET POUR LE RÉSUMÉ BUDGÉTAIRE
  Widget _buildBudgetSummary(AppLocalizations l10n) {
    final remainingAmount = budget.budgetAmount - budget.spentAmount;
    final isOverBudget = remainingAmount < 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isOverBudget ? Colors.red[50] : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOverBudget ? Colors.red[200]! : Colors.green[200]!,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isOverBudget ? Icons.trending_up : Icons.account_balance_wallet,
                size: 16,
                color: isOverBudget ? AppColors.error : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                isOverBudget
                    ? (l10n.overBudget)
                    : l10n.remaining,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isOverBudget ? AppColors.error : AppColors.primaryDark,
                ),
              ),
            ],
          ),
          FormattedAmount(
            // ✅ UTILISATION DE FormattedAmount POUR LE RÉSUMÉ
            amount: remainingAmount.abs(), // Valeur absolue pour l'affichage
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isOverBudget ? AppColors.error : AppColors.primaryDark,
            ),
          ),
        ],
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
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.amber[600]),
                    const SizedBox(width: 8),
                    Text(
                      l10n.suggestions,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSuggestionItem(
                  Icons.analytics,
                  l10n.analytics,
                  AppLocalizations.of(context)!.baCheckExpenses,
                ),
                _buildSuggestionItem(
                  Icons.tune,
                  l10n.update,
                  AppLocalizations.of(context)!.baIncreaseBudget,
                ),
                _buildSuggestionItem(
                  Icons.trending_down,
                  AppLocalizations.of(context)!.baReduceTitle,
                  AppLocalizations.of(context)!.baReduceDesc,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.understood),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSuggestionItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
