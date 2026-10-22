// screens/main_shell.dart - Coquille principale, planche « Version B ».
//
// Accueil | Mes listes | Avant les courses | Alertes de prix | Sections.
//
// Trois choses que la planche impose, et leurs raisons :
//
//  — ARCHITECTURE À PLAT. Les dix sections sont égales. Alertes de prix
//    et Avant les courses montent donc dans la barre : ce sont les deux
//    pages qu'on ouvre AVANT de partir, et elles étaient enterrées dans
//    le menu latéral, derrière un défilement.
//
//  — LA BARRE NE CHANGE JAMAIS. Mêmes cinq icônes, même ordre, mêmes
//    destinations, sur toutes les pages. Une pastille teintée claire
//    marque la section ouverte — la forme, pas seulement la couleur.
//
//  — PLUS DE BOUTON + AU CENTRE. Les six actions qu'il cachait sont
//    devenues quatre tuiles visibles sur l'accueil (dicter, scanner,
//    repas, magasins). Un geste de moins pour la même chose.
//
// Factures et « Plus » cessent d'être des onglets : les reçus se lisent
// sur la page Budgets, et les réglages dans le menu latéral.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/screens/home_screen.dart';
import 'package:epilist/screens/pre_shopping_screen.dart';
import 'package:epilist/screens/price_alerts_screen.dart';
import 'package:epilist/screens/sections_screen.dart';
import 'package:epilist/screens/shopping_list_screen.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/app_drawer.dart';
import 'package:epilist/widgets/common/main_shell_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  MainTab _tab = MainTab.home;

  /// Onglets déjà visités : seuls ceux-là sont réellement construits, pour
  /// ne pas déclencher cinq chargements API à l'ouverture de l'app.
  final Set<MainTab> _visited = {MainTab.home};

  @override
  void initState() {
    super.initState();
    MainShellRoute.goToTab = _select;
  }

  @override
  void dispose() {
    if (MainShellRoute.goToTab == _select) MainShellRoute.goToTab = null;
    super.dispose();
  }

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
      MainTab.preShopping => const PreShoppingScreen(),
      MainTab.alerts => const PriceAlertsScreen(),
      MainTab.sections => const SectionsScreen(),
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

  /// La barre de la planche : fond blanc, cinq icônes dessinées en
  /// couleur (ce ne sont pas des glyphes teintés par l'état), et une
  /// pastille ronde teintée derrière celle de la section ouverte.
  Widget _buildBottomBar(AppLocalizations l10n) {
    final destinations = <_Destination>[
      _Destination(
        tab: MainTab.home,
        actif: 'accueil',
        label: l10n.tabHome,
        pastille: AppColors.primaryLight,
        montreLeLabel: true,
      ),
      _Destination(
        tab: MainTab.lists,
        actif: 'listes',
        label: l10n.myShoppingLists,
        pastille: AppColors.warningTint,
      ),
      _Destination(
        tab: MainTab.preShopping,
        actif: 'avant',
        label: l10n.preShopping,
        pastille: AppColors.goldTint,
      ),
      _Destination(
        tab: MainTab.alerts,
        actif: 'alertes',
        label: l10n.priceAlerts,
        pastille: AppColors.errorTint,
      ),
      _Destination(
        tab: MainTab.sections,
        actif: 'sections',
        label: l10n.allSections,
        pastille: AppColors.warningTint,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.sm,
            bottom: AppSpacing.sm + 2,
          ),
          child: Row(children: destinations.map(_navItem).toList()),
        ),
      ),
    );
  }

  Widget _navItem(_Destination d) {
    final selected = _tab == d.tab;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: d.label,
        child: InkWell(
          onTap: () => _select(d.tab),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 62),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: selected ? d.pastille : null,
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    'assets/images/nav/${d.actif}.svg',
                    width: 30,
                    height: 30,
                  ),
                ),
                if (d.montreLeLabel) ...[
                  const SizedBox(height: 3),
                  // #16A34A, le vert de la planche, ne donne que 2,8 de
                  // contraste sur blanc : illisible pour un libellé.
                  // C'est le vert foncé qui le porte, à 5,0.
                  Text(
                    d.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Une destination de la barre : l'onglet, son dessin, son libellé parlé
/// et la teinte de sa pastille active.
@immutable
class _Destination {
  const _Destination({
    required this.tab,
    required this.actif,
    required this.label,
    required this.pastille,
    this.montreLeLabel = false,
  });

  final MainTab tab;

  /// Nom du fichier SVG, sans son chemin ni son extension.
  final String actif;

  /// Lu par les lecteurs d'écran, et affiché sous l'icône quand
  /// [montreLeLabel] — la planche ne l'écrit que sous Accueil.
  final String label;

  final Color pastille;
  final bool montreLeLabel;
}
