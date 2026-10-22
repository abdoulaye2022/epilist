// screens/sections_screen.dart - « Toutes les sections ».
//
// L'écran qui MONTRE l'architecture, parce qu'une architecture à plat ne
// se devine pas : dix destinations égales, numérotées, chacune avec sa
// page. Budgets, Analyses, Alertes de prix et Listes récurrentes sont
// ici au même rang que Mes listes — elles n'en sont pas des
// sous-sections, et ne se trouvent plus seulement au fond d'un menu.
//
// Chaque tuile porte la teinte et la bordure de sa famille : la couleur
// dit de quoi on parle, le numéro et le titre le disent aussi. Jamais la
// couleur seule.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/screens/analytics_screen.dart';
import 'package:epilist/screens/budget_screen.dart';
import 'package:epilist/screens/inventory_screen.dart';
import 'package:epilist/screens/meal_planner_screen.dart';
import 'package:epilist/screens/recurring_lists_screen.dart';
import 'package:epilist/screens/stores_screen.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/drawer_menu_button.dart';
import 'package:epilist/widgets/common/main_shell_scope.dart';
import 'package:flutter/material.dart';

class SectionsScreen extends StatelessWidget {
  const SectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scope = MainShellScope.maybeOf(context);

    final sections = <_Section>[
      _Section(
        rang: 1,
        titre: l10n.dashboardTitle,
        icone: Icons.space_dashboard_outlined,
        teinte: AppColors.primary,
        ouvrir: () => scope?.goToTab(MainTab.home),
      ),
      _Section(
        rang: 2,
        titre: l10n.myShoppingLists,
        icone: Icons.checklist_rounded,
        teinte: AppColors.primaryVivid,
        ouvrir: () => scope?.goToTab(MainTab.lists),
      ),
      _Section(
        rang: 3,
        titre: l10n.budgets,
        icone: Icons.savings_outlined,
        teinte: AppColors.warning,
        ouvrir: () => _push(context, const BudgetScreen()),
      ),
      _Section(
        rang: 4,
        titre: l10n.analytics,
        icone: Icons.insights_outlined,
        teinte: AppColors.accent,
        ouvrir: () => _push(context, const AnalyticsScreen()),
      ),
      _Section(
        rang: 5,
        titre: l10n.preShopping,
        icone: Icons.assistant_outlined,
        teinte: AppColors.gold,
        ouvrir: () => scope?.goToTab(MainTab.preShopping),
      ),
      _Section(
        rang: 6,
        titre: l10n.priceAlerts,
        icone: Icons.notifications_active_outlined,
        teinte: AppColors.error,
        ouvrir: () => scope?.goToTab(MainTab.alerts),
      ),
      _Section(
        rang: 7,
        titre: l10n.inventoryTitle,
        icone: Icons.kitchen_outlined,
        teinte: AppColors.primaryDark,
        ouvrir: () => _push(context, const InventoryScreen()),
      ),
      _Section(
        rang: 8,
        titre: l10n.recurringListsTitle,
        icone: Icons.event_repeat_outlined,
        teinte: AppColors.accent,
        ouvrir: () => _push(context, const RecurringListsScreen()),
      ),
      _Section(
        rang: 9,
        titre: l10n.mealPlannerTitle,
        icone: Icons.restaurant_menu_outlined,
        teinte: AppColors.gold,
        ouvrir: () => _push(context, const MealPlannerScreen()),
      ),
      _Section(
        rang: 10,
        titre: l10n.myStores,
        icone: Icons.storefront_outlined,
        teinte: AppColors.warning,
        ouvrir: () => _push(context, const StoresScreen()),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: DrawerMenuButton.leadingOrNull(context),
        title: Text(l10n.allSections),
      ),
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
            childAspectRatio: 1.45,
            children: sections.map(_tuile).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.allSectionsMenuHint,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          if (scope != null)
            FilledButton.icon(
              onPressed: scope.openDrawer,
              icon: const Icon(Icons.menu_rounded),
              label: Text(l10n.openSideMenu),
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
                '${s.rang}. ${s.titre}',
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
    required this.rang,
    required this.titre,
    required this.icone,
    required this.teinte,
    required this.ouvrir,
  });

  final int rang;
  final String titre;
  final IconData icone;

  /// La couleur de la famille : elle teinte le fond et dessine la
  /// bordure, et son encre porte l'icône.
  final Color teinte;

  final VoidCallback ouvrir;
}
