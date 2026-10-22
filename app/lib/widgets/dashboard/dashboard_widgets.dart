// widgets/dashboard/dashboard_widgets.dart
// Briques visuelles du tableau de bord d'accueil : carte budget du mois,
// cartes de listes horizontales, actions rapides, tuiles de navigation.
import 'package:epilist/widgets/common/app_meters.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/budget.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Carte sombre « Budget du mois » (inspirée de la maquette) : dépensé /
/// alloué, barre de progression, reste du mois.
class BudgetMonthCard extends StatelessWidget {
  final Budget budget;
  final VoidCallback onSeeDetail;

  /// Mois affiché dans la puce ; un appui ouvre le sélecteur de mois.
  final DateTime selectedMonth;
  final VoidCallback? onPickMonth;

  const BudgetMonthCard({
    super.key,
    required this.budget,
    required this.onSeeDetail,
    required this.selectedMonth,
    this.onPickMonth,
  });

  /// Puce « 📅 mai 2025 ▾ » : appui = sélecteur de mois.
  Widget _monthChip(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    var month = DateFormat('MMM yyyy', locale).format(selectedMonth);
    month = month[0].toUpperCase() + month.substring(1);
    return GestureDetector(
      onTap: onPickMonth,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.onBrandBand.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 11,
              color: AppColors.onBrandBand,
            ),
            const SizedBox(width: 5),
            Text(
              month,
              style: TextStyle(
                color: AppColors.onBrandBand,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onPickMonth != null) ...[
              const SizedBox(width: 2),
              Icon(Icons.expand_more, size: 13, color: AppColors.onBrandBand),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ratio =
        budget.budgetAmount > 0
            ? (budget.spentAmount / budget.budgetAmount).clamp(0.0, 1.0)
            : 0.0;
    final over = budget.spentAmount > budget.budgetAmount;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: AppColors.brandBand,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.onBrandBand.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.onBrandBand,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        l10n.budgetOfMonth,
                        style: TextStyle(
                          color: AppColors.onBrandBand,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _monthChip(context),
                  ],
                ),
              ),
              TextButton(
                onPressed: onSeeDetail,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.onBrandBand,
                  backgroundColor: AppColors.onBrandBand.withValues(
                    alpha: 0.14,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text('${l10n.seeDetail} →'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                budget.formattedSpentAmount,
                style: TextStyle(
                  color: AppColors.onBrandBand,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ ${budget.formattedBudgetAmount}',
                style: TextStyle(
                  color: AppColors.onBrandBand.withValues(alpha: 0.7),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          Row(
            children: [
              Expanded(
                // Les deux couleurs etaient ecrites en dur (#FFB4A9,
                // #9BE7A0) : hors des sept couleurs de la planche, et
                // figees en mode sombre.
                child: AppGauge(
                  ratio: ratio,
                  color: over ? AppColors.error : AppColors.primaryVivid,
                  label: l10n.budgetGaugePercent(
                    (ratio * 100).toStringAsFixed(0),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Text(
                '${(ratio * 100).round()} %',
                style: TextStyle(
                  color: AppColors.onBrandBand,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Row(
            children: [
              Icon(
                over ? Icons.error_outline : Icons.eco_outlined,
                size: 14,
                color: AppColors.onBrandBand.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  over ? l10n.budgetExceededShort : l10n.withinBudget,
                  style: TextStyle(
                    color: AppColors.onBrandBand.withValues(alpha: 0.85),
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                l10n.remainingThisMonth(budget.formattedRemainingAmount),
                style: TextStyle(
                  color: AppColors.onBrandBand.withValues(alpha: 0.85),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Carte affichée quand AUCUN budget n'est en cours : invite à en créer
/// un plutôt que de laisser un trou dans le tableau de bord.
class BudgetCtaCard extends StatelessWidget {
  final VoidCallback onCreate;

  /// Si fourni : « Aucun budget pour {mois} » + puce cliquable, au lieu du
  /// message générique.
  final DateTime? selectedMonth;
  final VoidCallback? onPickMonth;

  const BudgetCtaCard({
    super.key,
    required this.onCreate,
    this.selectedMonth,
    this.onPickMonth,
  });

  String _monthLabel(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final m = DateFormat('MMMM yyyy', locale).format(selectedMonth!);
    return m[0].toUpperCase() + m.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.brandBand,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.onBrandBand.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.onBrandBand,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.budgetOfMonth,
                  style: TextStyle(
                    color: AppColors.onBrandBand,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  selectedMonth == null
                      ? l10n.createBudgetCta
                      : l10n.noBudgetForMonth(_monthLabel(context)),
                  style: TextStyle(
                    color: AppColors.onBrandBand.withValues(alpha: 0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          if (onPickMonth != null) ...[
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: onPickMonth,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.onBrandBand.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Icon(
                  Icons.expand_more,
                  size: 15,
                  color: AppColors.onBrandBand,
                ),
              ),
            ),
          ],
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: onCreate,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              backgroundColor: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('+'),
          ),
        ],
      ),
    );
  }
}

/// Carte de liste compacte pour le carrousel horizontal du dashboard.
class DashboardListCard extends StatelessWidget {
  final ShoppingList list;
  final VoidCallback onTap;

  const DashboardListCard({super.key, required this.list, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = list.itemsCount;
    final done = list.purchasedItemsCount;

    return SizedBox(
      width: 190,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        list.isShared
                            ? Icons.people_alt_rounded
                            : Icons.shopping_basket_outlined,
                        size: 16,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.textDisabled,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  list.name,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '$done / $total ${l10n.articles.toLowerCase()}',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                AppGauge(
                  ratio: list.progress,
                  label: l10n.listCheckedSentence(done, total),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
