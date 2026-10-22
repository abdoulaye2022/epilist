// widgets/common/main_bottom_bar.dart - La barre du bas, planche « Version B ».
//
// Mêmes cinq icônes, même ordre, mêmes destinations, sur toutes les
// pages. Une pastille ronde teintée marque la section ouverte — la
// forme, pas seulement la couleur.
//
// Elle vit dans son propre fichier parce qu'elle a une HAUTEUR, et
// qu'une hauteur se teste. Voir [MainBottomBar.build] : le Scaffold lui
// offre tout l'écran, et c'est à elle de n'en prendre que ce qu'il lui
// faut.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/common/app_nav.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/main_shell_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MainBottomBar extends StatelessWidget {
  const MainBottomBar({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final MainTab current;
  final void Function(MainTab tab) onSelect;

  /// Hauteur d'un bouton, pastille et libellé compris. La planche
  /// demande une cible généreuse ; Material se contenterait de 48.
  static const double itemHeight = 62;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
          child: Row(children: [for (final d in destinations) _navItem(d)]),
        ),
      ),
    );
  }

  Widget _navItem(_Destination d) {
    final selected = current == d.tab;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: d.label,
        child: InkWell(
          onTap: () => onSelect(d.tab),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: itemHeight),
            child: Column(
              // mainAxisSize.min, et c'est tout le sujet de ce fichier.
              //
              // Le Scaffold mesure sa barre AVANT son corps, en lui
              // offrant la hauteur entière de l'écran. Un Column en
              // MainAxisSize.max accepte tout ce qu'on lui offre : la
              // barre faisait 832 dp de haut, les icônes se centraient
              // au milieu de l'écran, et le corps de la page recevait
              // une contrainte de hauteur ZÉRO — plus rien ne s'y
              // dessinait. En min, le Column ne prend que ses enfants,
              // et le ConstrainedBox lui impose ses 62 dp de cible.
              mainAxisSize: MainAxisSize.min,
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

/// La même barre, pour une page EMPILÉE par le Navigator.
///
/// La planche l'exige partout, pas seulement sur les cinq onglets :
/// « La barre du bas est strictement la même sur toutes les pages. »
/// Toucher une destination referme la pile et bascule sur l'onglet, au
/// lieu d'empiler un écran de plus.
///
/// [tab] est la section à laquelle cette page appartient : le détail
/// d'une liste éclaire « Mes listes », les budgets et les analyses
/// éclairent « Toutes les sections ».
class AppPageBottomBar extends StatelessWidget {
  const AppPageBottomBar({super.key, required this.tab});

  final MainTab tab;

  @override
  Widget build(BuildContext context) {
    return MainBottomBar(
      current: tab,
      onSelect: (t) => AppNav.goTo(context, t),
    );
  }
}
