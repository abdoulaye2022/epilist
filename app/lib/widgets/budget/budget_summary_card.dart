// widgets/budget/budget_summary_card.dart - VERSION COMPLETE AVEC FormattedAmount
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart'; // ✅ IMPORT AJOUTÉ

class BudgetSummaryCard extends StatelessWidget {
  final int totalBudgets;
  final int activeBudgets;
  final int exceededBudgets;
  final int warningBudgets;
  final double? totalBudgeted;
  final double? totalSpent;
  // ✅ SUPPRESSION DES PROPRIÉTÉS formattedTotalBudgeted ET formattedTotalSpent
  // Elles ne sont plus nécessaires car FormattedAmount gère le formatage

  const BudgetSummaryCard({
    super.key,
    required this.totalBudgets,
    required this.activeBudgets,
    required this.exceededBudgets,
    required this.warningBudgets,
    this.totalBudgeted,
    this.totalSpent,
    // ✅ SUPPRESSION DES PARAMÈTRES DE FORMATAGE
    // this.formattedTotalBudgeted,
    // this.formattedTotalSpent,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryLight, AppColors.primaryLight],
          ),
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

            // ✅ SECTION MONTANTS AVEC FormattedAmount
            if (totalBudgeted != null && totalSpent != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
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
                          // ✅ UTILISATION DE FormattedAmount
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
                          // ✅ UTILISATION DE FormattedAmount
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
                    // ✅ BARRE DE PROGRESSION AVEC CALCUL DE POURCENTAGE
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.spendingProgress,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${_getSpentPercentage().toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getSpentColor(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value:
                              totalBudgeted! > 0
                                  ? (totalSpent! / totalBudgeted!).clamp(
                                    0.0,
                                    1.0,
                                  )
                                  : 0.0,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getSpentColor(),
                          ),
                          minHeight: 8,
                        ),
                      ],
                    ),

                    // ✅ AJOUT DU MONTANT RESTANT
                    if (totalBudgeted! > totalSpent!) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.savings,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.remaining,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            FormattedAmount(
                              // ✅ MONTANT RESTANT AVEC FormattedAmount
                              amount: totalBudgeted! - totalSpent!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (totalSpent! > totalBudgeted!) ...[
                      // ✅ AFFICHAGE DU DÉPASSEMENT
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.warning,
                                  size: 16,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.overBudget,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            FormattedAmount(
                              // ✅ MONTANT DE DÉPASSEMENT
                              amount: totalSpent! - totalBudgeted!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
        color: Colors.white.withValues(alpha: 0.7),
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

  // ✅ MÉTHODE POUR CALCULER LE POURCENTAGE DÉPENSÉ
  double _getSpentPercentage() {
    if (totalBudgeted == null || totalSpent == null || totalBudgeted == 0) {
      return 0.0;
    }
    return (totalSpent! / totalBudgeted!) * 100;
  }

  Color _getSpentColor() {
    if (totalBudgeted == null || totalSpent == null || totalBudgeted == 0) {
      return AppColors.primary;
    }

    final percentage = _getSpentPercentage();

    if (percentage >= 100) {
      return AppColors.error;
    } else if (percentage >= 80) {
      return AppColors.warning;
    } else {
      return AppColors.primary;
    }
  }
}
