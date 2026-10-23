// screens/sections_screen.dart - « Toutes les sections ».
//
// Dix tuiles, dix pages. Budgets, Analyses, Alertes de prix et Listes
// récurrentes sont ici au même rang que Mes listes — aucune n'est une
// sous-section d'une autre, et aucune ne se trouve seulement au fond
// d'un menu.
//
// Les tuiles étaient numérotées « 1. » à « 10. ». Un numéro n'aide pas
// à naviguer : personne ne cherche la section 7. Chaque tuile porte la
// teinte et la bordure de sa famille, et son nom écrit — jamais la
// couleur seule.
import 'package:epilist/widgets/common/app_top_bar.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/screens/analytics_screen.dart';
import 'package:epilist/screens/budget_screen.dart';
import 'package:epilist/screens/inventory_screen.dart';
import 'package:epilist/screens/meal_planner_screen.dart';
import 'package:epilist/screens/recurring_lists_screen.dart';
import 'package:epilist/screens/stores_screen.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/main_shell_scope.dart';
import 'package:epilist/theme/app_icons.dart';
import 'package:flutter/material.dart';

class SectionsScreen extends StatelessWidget {
  const SectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scope = MainShellScope.maybeOf(context);

    final sections = <_Section>[
      _Section(
        titre: l10n.dashboardTitle,
        icone: AppIcons.dashboard,
        teinte: AppColors.primary,
        ouvrir: () => scope?.goToTab(MainTab.home),
      ),
      _Section(
        titre: l10n.myShoppingLists,
        icone: AppIcons.lists,
        teinte: AppColors.primaryVivid,
        ouvrir: () => scope?.goToTab(MainTab.lists),
      ),
      _Section(
        titre: l10n.budgets,
        icone: AppIcons.budgets,
        teinte: AppColors.warning,
        ouvrir: () => _push(context, const BudgetScreen()),
      ),
      _Section(
        titre: l10n.analytics,
        icone: AppIcons.analytics,
        teinte: AppColors.accent,
        ouvrir: () => _push(context, const AnalyticsScreen()),
      ),
      _Section(
        titre: l10n.preShopping,
        icone: AppIcons.preShopping,
        teinte: AppColors.gold,
        ouvrir: () => scope?.goToTab(MainTab.preShopping),
      ),
      _Section(
        titre: l10n.priceAlerts,
        icone: AppIcons.priceAlerts,
        teinte: AppColors.error,
        ouvrir: () => scope?.goToTab(MainTab.alerts),
      ),
      _Section(
        titre: l10n.inventoryTitle,
        icone: AppIcons.inventory,
        teinte: AppColors.primaryDark,
        ouvrir: () => _push(context, const InventoryScreen()),
      ),
      _Section(
        titre: l10n.recurringListsTitle,
        icone: AppIcons.recurring,
        teinte: AppColors.accent,
        ouvrir: () => _push(context, const RecurringListsScreen()),
      ),
      _Section(
        titre: l10n.mealPlannerTitle,
        icone: AppIcons.mealPlanner,
        teinte: AppColors.gold,
        ouvrir: () => _push(context, const MealPlannerScreen()),
      ),
      _Section(
        titre: l10n.myStores,
        icone: AppIcons.stores,
        teinte: AppColors.warning,
        ouvrir: () => _push(context, const StoresScreen()),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(title: l10n.allSections),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md + 2,
          AppSpacing.md,
          AppSpacing.md + 2,
          AppSpacing.xl,
        ),
        children: [
          Text(
            l10n.allSectionsIntro,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm + 2,
            crossAxisSpacing: AppSpacing.sm + 2,
            // La tuile s'allonge quand le texte grossit : a deux fois,
            // « Mes magasins » sur deux lignes ne tenait plus dans un
            // rapport fixe.
            childAspectRatio: 1.45 / appTextScale(context),
            children: sections.map(_tuile).toList(),
          ),
        ],
      ),
    );
  }

  Widget _tuile(_Section s) {
    return Material(
      color: AppTint.fill(s.teinte),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: s.teinte, width: 2),
      ),
      child: InkWell(
        onTap: s.ouvrir,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm + 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(s.icone, size: 30, color: AppTint.ink(s.teinte)),
              Text(
                s.titre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget ecran) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => ecran));
}

@immutable
class _Section {
  const _Section({
    required this.titre,
    required this.icone,
    required this.teinte,
    required this.ouvrir,
  });

  final String titre;
  final IconData icone;

  /// La couleur de la famille : elle teinte le fond et dessine la
  /// bordure, et son encre porte l'icône.
  final Color teinte;

  final VoidCallback ouvrir;
}
