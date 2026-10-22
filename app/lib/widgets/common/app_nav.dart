// widgets/common/app_nav.dart - Rejoindre un onglet depuis n'importe où.
//
// La barre du bas est la même sur toutes les pages, y compris sur les
// pages EMPILÉES par le Navigator. Toucher « Mes listes » depuis le
// détail d'une liste ne doit pas empiler une liste de plus : il faut
// refermer la pile, puis demander l'onglet à la coquille.
import 'package:epilist/widgets/common/main_shell_scope.dart';
import 'package:flutter/material.dart';

abstract final class AppNav {
  /// Referme toute la pile, puis bascule sur [tab].
  ///
  /// Dans la coquille, la portée suffit. Au-dessus d'elle, un écran
  /// poussé ne la voit pas : on passe par la référence statique, posée
  /// par la coquille à sa construction.
  static void goTo(BuildContext context, MainTab tab) {
    final scope = MainShellScope.maybeOf(context);
    if (scope != null && !Navigator.of(context).canPop()) {
      scope.goToTab(tab);
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
    MainShellRoute.goToTab?.call(tab);
  }
}
