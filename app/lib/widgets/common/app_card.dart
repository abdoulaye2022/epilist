// widgets/common/app_card.dart - La carte commune.
//
// Cinquante-quatre endroits peignaient la même chose à la main : un
// Container, un BoxDecoration, AppColors.surface, un rayon choisi au
// hasard entre 8 et 16, parfois une ombre, parfois une bordure. D'où
// des cartes qui ne se ressemblaient pas d'un écran à l'autre, et un
// mode sombre impossible à vérifier.
//
// Le thème a tranché : bordure fine, pas d'ombre portée. Cette carte
// est l'endroit unique où ce choix s'applique.
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
    this.onTap,
    this.color,
    this.bordered = true,
    this.borderColor,
    this.borderWidth = 1,
    this.radius = AppRadius.md,
  });

  /// Carte sans marge intérieure : pour une colonne de lignes qui ont
  /// déjà la leur (des ListTile, par exemple).
  const AppCard.tight({
    super.key,
    required this.child,
    this.margin,
    this.onTap,
    this.color,
    this.bordered = true,
    this.borderColor,
    this.borderWidth = 1,
    this.radius = AppRadius.md,
  }) : padding = EdgeInsets.zero;

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  /// Fond teinté plutôt que la surface : un état (succès, alerte) ou un
  /// accent de catégorie. Toujours un jeton `*Tint`, jamais une couleur
  /// écrite à la main.
  final Color? color;

  final bool bordered;

  /// Bordure teintée au lieu de la bordure neutre : elle signale un état
  /// (article coché, liste en lecture seule) sans fond coloré.
  final Color? borderColor;
  final double borderWidth;

  final double radius;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side:
          bordered || borderColor != null
              ? BorderSide(
                color: borderColor ?? AppColors.border,
                width: borderWidth,
              )
              : BorderSide.none,
    );
    // Material, et non un Container décoré : un fond posé par un
    // DecoratedBox intermédiaire masque le fond et l'onde d'appui des
    // ListTile qu'il contient (Flutter le signale en assertion).
    final card = Material(
      color: color ?? AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: shape,
      child:
          onTap == null
              ? Padding(padding: padding, child: child)
              : InkWell(
                onTap: onTap,
                child: Padding(padding: padding, child: child),
              ),
    );
    return margin == null ? card : Padding(padding: margin!, child: card);
  }
}
