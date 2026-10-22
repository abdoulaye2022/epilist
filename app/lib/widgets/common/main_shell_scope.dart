// widgets/common/main_shell_scope.dart - Accès au MainShell depuis
// n'importe quel écran de l'arbre.
//
// Deux manques que cette portée comble :
//   1. le tiroir n'était déclaré QUE sur l'accueil (`drawer:` apparaissait
//      une seule fois dans tout lib/) — depuis l'onglet Listes, changer
//      d'espace imposait de revenir en arrière ;
//   2. « Voir toutes les listes » EMPILAIT une copie de l'écran Listes
//      au lieu de basculer sur son onglet, laissant une flèche retour qui
//      ne correspond à rien.
import 'package:flutter/material.dart';

/// Onglets de la barre du bas, dans l'ordre d'affichage.
///
/// Ce sont les cinq destinations de la planche Version B, et la barre
/// est la MÊME sur toutes les pages : Accueil, Mes listes, Avant les
/// courses, Alertes de prix, Toutes les sections. Plus de bouton + au
/// centre — les actions du quotidien sont devenues quatre tuiles
/// visibles sur l'accueil, au lieu d'être cachées derrière un geste.
///
/// Factures et Réglages ne sont plus des onglets : les reçus se lisent
/// dans Budgets, et les réglages tiennent dans le menu latéral.
enum MainTab { home, lists, preShopping, alerts, sections }

class MainShellScope extends InheritedWidget {
  const MainShellScope({
    super.key,
    required this.currentTab,
    required this.openDrawer,
    required this.goToTab,
    required super.child,
  });

  final MainTab currentTab;

  /// Ouvre le tiroir de la coquille, quel que soit l'onglet affiché.
  final VoidCallback openDrawer;

  /// Bascule sur un onglet au lieu d'empiler un écran.
  final void Function(MainTab tab) goToTab;

  /// `null` hors de la coquille : un écran poussé (Navigator) n'a pas
  /// cette portée pour ancêtre, et doit garder sa flèche retour.
  static MainShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MainShellScope>();

  @override
  bool updateShouldNotify(MainShellScope oldWidget) =>
      currentTab != oldWidget.currentTab;
}
