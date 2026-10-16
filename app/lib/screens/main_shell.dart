// screens/main_shell.dart - Coquille principale : Accueil | Listes | (+)
// | Factures | Plus.
//
// Trois changements de structure, et leurs raisons :
//
//  — « Factures » devient une destination. Les dépenses étaient
//    enfermées dans le menu ⋮ d'une liste, et l'écran existant exige
//    encore un `shoppingList` : voir ses factures demandait de se
//    rappeler à quelle liste on avait rattaché un reçu.
//
//  — Statistiques et Budget descendent dans « Plus ». Ce sont des
//    écrans de consultation mensuelle ; ils occupaient deux des quatre
//    places permanentes de l'écran, et le budget reste résumé sur
//    l'accueil, d'où on l'ouvre en un appui.
//
//  — le tiroir appartient maintenant à la coquille. Il n'était déclaré
//    que sur l'accueil (un seul `drawer:` dans tout lib/) : depuis
//    l'onglet Listes, changer d'espace imposait de revenir en arrière.
//
// Le bouton central n'ouvre plus la création de liste — geste fait une
// fois par semaine — mais les six actions du quotidien.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/screens/all_receipts_screen.dart';
import 'package:epilist/screens/home_screen.dart';
import 'package:epilist/screens/more_screen.dart';
import 'package:epilist/screens/shopping_list_screen.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/app_drawer.dart';
import 'package:epilist/widgets/common/main_shell_scope.dart';
import 'package:epilist/widgets/common/quick_actions_sheet.dart';
import 'package:flutter/material.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  MainTab _tab = MainTab.home;

  /// Onglets déjà visités : seuls ceux-là sont réellement construits, pour
  /// ne pas déclencher quatre chargements API à l'ouverture de l'app.
  final Set<MainTab> _visited = {MainTab.home};

  void _select(MainTab tab) {
    if (tab == _tab) return;
    setState(() {
      _tab = tab;
      _visited.add(tab);
    });
  }

  Widget _tabBody(MainTab tab) {
    if (!_visited.contains(tab)) return const SizedBox.shrink();
    return switch (tab) {
      MainTab.home => const HomeScreen(),
      MainTab.lists => const ShoppingListScreen(),
      MainTab.receipts => const AllReceiptsScreen(),
      MainTab.more => const MoreScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MainShellScope(
      currentTab: _tab,
      openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      goToTab: _select,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        drawer: const AppDrawer(),
        body: IndexedStack(
          index: MainTab.values.indexOf(_tab),
          children: MainTab.values.map(_tabBody).toList(),
        ),
        bottomNavigationBar: _buildBottomBar(l10n),
      ),
    );
  }

  Widget _buildBottomBar(AppLocalizations l10n) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _tabItem(MainTab.home, Icons.home_outlined, Icons.home_rounded,
                  l10n.tabHome),
              _tabItem(MainTab.lists, Icons.list_alt_outlined,
                  Icons.list_alt_rounded, l10n.tabLists),
              _centerButton(l10n),
              _tabItem(MainTab.receipts, Icons.receipt_long_outlined,
                  Icons.receipt_long_rounded, l10n.receipts),
              _tabItem(MainTab.more, Icons.widgets_outlined,
                  Icons.widgets_rounded, l10n.tabMore),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabItem(
      MainTab tab, IconData icon, IconData activeIcon, String label) {
    final selected = _tab == tab;
    final color = selected ? AppColors.primary : AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: () => _select(tab),
        child: Semantics(
          selected: selected,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? activeIcon : icon, size: 24, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bouton central vert : la feuille des six actions du quotidien.
  Widget _centerButton(AppLocalizations l10n) {
    return Expanded(
      child: Center(
        child: Semantics(
          button: true,
          label: l10n.quickActionsTitle,
          child: Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            elevation: 3,
            shadowColor: AppColors.primary.withValues(alpha: 0.4),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => QuickActionsSheet.show(context),
              child: const SizedBox(
                width: 52,
                height: 52,
                child: Icon(Icons.add, color: AppColors.onPrimary, size: 28),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
