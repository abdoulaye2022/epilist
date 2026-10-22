// widgets/common/app_top_bar.dart - L'en-tête de TOUTES les pages.
//
// La planche « Version B » ne laisse pas le choix :
//
//   « Le menu latéral est joignable de PARTOUT : bouton menu en haut à
//     gauche du téléphone sur les autres écrans. »
//
// Dans la planche, les pages ne s'empilent pas : il n'y a pas de flèche
// retour, donc le coin haut-gauche est libre pour le menu. L'application
// a une pile de navigation bien réelle, et retirer la flèche retour
// enfermerait l'écran. Les deux tiennent donc côte à côte, dans le même
// coin : retour puis menu.
//
// L'en-tête pose aussi le titre en Sora — la fonte d'affichage de la
// planche — sans que chaque écran ait à le redire, et laisse le thème
// décider des couleurs : les fonds et élévations écrits à la main écran
// par écran étaient la première cause de dérive du thème.
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/main_shell_scope.dart';
import 'package:flutter/material.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.bottom,
    this.titleWidget,
  });

  /// Écrit en toutes lettres, en Sora. Jamais abrégé.
  final String title;

  /// Une seconde ligne, plus petite : le nom de la liste dont on lit les
  /// reçus, le magasin dont on range les rayons. Elle dit DE QUOI parle
  /// la page, quand le titre seul ne le dit pas.
  final String? subtitle;

  /// Pour les rares en-têtes qui portent plus qu'un titre (un sous-titre
  /// d'espace, un champ de recherche). Remplace [title] à l'affichage,
  /// qui reste le nom parlé de la page.
  final Widget? titleWidget;

  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final peutRevenir = Navigator.of(context).canPop();
    final aUnMenu = _AppBarLeading.menuJoignable(context);

    return AppBar(
      leadingWidth: peutRevenir && aUnMenu ? 96 : null,
      leading:
          peutRevenir || aUnMenu
              ? _AppBarLeading(peutRevenir: peutRevenir, aUnMenu: aUnMenu)
              : null,
      title:
          titleWidget ??
          Semantics(
            header: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppFonts.displayStyle(
                    size: subtitle == null ? 20 : 18,
                    color: AppColors.textPrimary,
                    weight: 700,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
      actions: actions,
      bottom: bottom,
    );
  }
}

/// Le coin haut-gauche : retour, puis menu.
class _AppBarLeading extends StatelessWidget {
  const _AppBarLeading({required this.peutRevenir, required this.aUnMenu});

  final bool peutRevenir;
  final bool aUnMenu;

  /// Vrai quand un tiroir existe reellement — dans la coquille, ou sur
  /// une page qui declare le sien. Les ecrans d'avant la connexion n'en
  /// ont pas : leur en-tete n'affiche donc pas de bouton menu, plutot
  /// que d'en montrer un qui leverait une exception.
  static bool menuJoignable(BuildContext context) =>
      MainShellScope.maybeOf(context) != null ||
      (Scaffold.maybeOf(context)?.hasDrawer ?? false);

  @override
  Widget build(BuildContext context) {
    final scope = MainShellScope.maybeOf(context);

    void ouvrirLeMenu() {
      if (scope != null) {
        scope.openDrawer();
      } else {
        Scaffold.of(context).openDrawer();
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (peutRevenir)
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        if (aUnMenu)
          IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            onPressed: ouvrirLeMenu,
          ),
      ],
    );
  }
}
