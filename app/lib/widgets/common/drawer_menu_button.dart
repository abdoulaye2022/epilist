// widgets/common/drawer_menu_button.dart - Bouton « menu » des onglets.
//
// Les onglets sont des Scaffold IMBRIQUÉS dans celui du MainShell : leur
// AppBar ne peut pas deviner qu'un tiroir existe plus haut, et n'affiche
// donc aucun bouton. Celui-ci passe par la portée du shell.
import 'package:epilist/widgets/common/main_shell_scope.dart';
import 'package:flutter/material.dart';

class DrawerMenuButton extends StatelessWidget {
  const DrawerMenuButton({super.key});

  /// À passer tel quel à `AppBar.leading` : le bouton menu dans la
  /// coquille, et `null` — donc la flèche retour habituelle — sur un
  /// écran poussé.
  static Widget? leadingOrNull(BuildContext context) =>
      MainShellScope.maybeOf(context) == null
          ? null
          : const DrawerMenuButton();

  @override
  Widget build(BuildContext context) {
    final scope = MainShellScope.maybeOf(context);
    if (scope == null) return const SizedBox.shrink();
    return IconButton(
      icon: const Icon(Icons.menu_rounded),
      tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      onPressed: scope.openDrawer,
    );
  }
}
