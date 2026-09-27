// widgets/dashboard/dashboard_widgets.dart
// Briques visuelles du tableau de bord d'accueil : carte budget du mois,
// cartes de listes horizontales, actions rapides, tuiles de navigation.
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
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 11, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              month,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onPickMonth != null) ...[
              const SizedBox(width: 2),
              const Icon(Icons.expand_more, size: 13, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ratio = budget.budgetAmount > 0
        ? (budget.spentAmount / budget.budgetAmount).clamp(0.0, 1.0)
        : 0.0;
    final over = budget.spentAmount > budget.budgetAmount;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
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
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        l10n.budgetOfMonth,
                        style: const TextStyle(
                          color: Colors.white,
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
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  textStyle: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ ${budget.formattedBudgetAmount}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      over ? const Color(0xFFFFB4A9) : const Color(0xFF9BE7A0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Text(
                '${(ratio * 100).round()} %',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
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
                color: Colors.white.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  over ? l10n.budgetExceededShort : l10n.withinBudget,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                  ),
                ),
              ),
              Text(
                l10n.remainingThisMonth(budget.formattedRemainingAmount),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12.5,
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
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.account_balance_wallet_outlined,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.budgetOfMonth,
                  style: const TextStyle(
                    color: Colors.white,
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
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12.5,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(Icons.expand_more,
                    size: 15, color: Colors.white),
              ),
            ),
          ],
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: onCreate,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              backgroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w700),
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
                        borderRadius: BorderRadius.circular(10),
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
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.textDisabled),
                  ],
                ),
                const Spacer(),
                Text(
                  list.name,
                  style: const TextStyle(
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
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: list.progress,
                    minHeight: 5,
                    backgroundColor: AppColors.background,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton d'action rapide rond (ajouter, voix, scanner...).
class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: AppColors.primaryDark),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              sublabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textDisabled,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Petite tuile de navigation (dépenses du mois, magasins...).
class DashboardTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const DashboardTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.primaryDark),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.textDisabled),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
