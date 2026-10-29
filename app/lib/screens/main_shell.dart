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
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/screens/onboarding_screen.dart';
import 'package:epilist/services/onboarding_service.dart';
import 'package:epilist/widgets/auth/verification_banner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/screens/home_screen.dart';
import 'package:epilist/screens/pre_shopping_screen.dart';
import 'package:epilist/screens/price_alerts_screen.dart';
import 'package:epilist/screens/sections_screen.dart';
import 'package:epilist/screens/shopping_list_screen.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/app_drawer.dart';
import 'package:epilist/widgets/common/main_bottom_bar.dart';
import 'package:epilist/widgets/common/main_shell_scope.dart';
import 'package:flutter/material.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  MainTab _tab = MainTab.home;

  /// Le parcours de depart ne se lance qu'une fois par montage, meme si
  /// l'etat d'authentification est reconstruit plusieurs fois.
  bool _parcoursLance = false;

  /// Onglets déjà visités : seuls ceux-là sont réellement construits, pour
  /// ne pas déclencher cinq chargements API à l'ouverture de l'app.
  final Set<MainTab> _visited = {MainTab.home};

  @override
  void initState() {
    super.initState();
    MainShellRoute.goToTab = _select;

    // Apres la premiere image : pousser un ecran pendant que l'arbre
    // se construit ferait exploser Navigator.
    WidgetsBinding.instance.addPostFrameCallback((_) => _peutEtreParcours());
  }

  /// Le parcours de depart, s'il n'a jamais ete vu.
  ///
  /// La reponse vient du serveur (`onboarding_done`) : changer de
  /// telephone ne doit pas le faire revenir. En cas de doute — serveur
  /// plus ancien, champ absent — on ne montre rien.
  Future<void> _peutEtreParcours() async {
    if (_parcoursLance || !mounted) return;

    final etat = context.read<AuthBloc>().state;
    if (etat is! AuthSuccess) return;

    final service = context.read<OnboardingService>();
    final montrer = await service.doitMontrer(
      dejaFaitSelonServeur: etat.user.onboardingDone,
    );

    if (!montrer || !mounted || _parcoursLance) return;

    _parcoursLance = true;

    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const OnboardingScreen(),
      ),
    );
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
    return MainShellScope(
      currentTab: _tab,
      openDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      goToTab: _select,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.background,
        drawer: const AppDrawer(),
        body: Column(
          children: [
            // Le rappel de verification, au-dessus de tous les onglets.
            // La verification ne bloque plus l'entree : ce bandeau est
            // ce qui reste pour la demander, et il doit donc dire a quoi
            // elle sert, pas seulement qu'elle manque.
            const BandeauVerificationCourriel(),
            Expanded(
              child: IndexedStack(
                index: MainTab.values.indexOf(_tab),
                children: MainTab.values.map(_tabBody).toList(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: MainBottomBar(current: _tab, onSelect: _select),
      ),
    );
  }
}
