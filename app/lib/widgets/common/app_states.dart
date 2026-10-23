// widgets/common/app_states.dart - Les contrôles dont l'état est ÉCRIT.
//
// « Chaque contrôle répond tout de suite, avec son état écrit en
// texte. » C'est la règle de la planche « Version B », et elle règle un
// vrai problème : un interrupteur, une étoile ou une case cochée ne
// disent leur état que par une position et une couleur. Qui distingue
// mal les couleurs, ou lit à la loupe, doit deviner.
//
// Ici, « État : Activée », « Favori : Oui, magasin favori », « Pris dans
// le panier » sont écrits à côté du contrôle, et changent avec lui.
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Une ligne cochable de 64 dp, avec une case de 34 dp.
///
/// Material donne 18 dp de case et 48 dp de ligne : à la main qui
/// tremble, cocher le bon article d'une liste de dix-sept devient un
/// exercice d'adresse.
class AppCheckRow extends StatelessWidget {
  const AppCheckRow({
    super.key,
    required this.checked,
    required this.title,
    required this.onChanged,
    this.subtitle,
    this.doneLabel,
  });

  final bool checked;
  final String title;

  /// La quantité, le prix, le repas auquel l'article sert.
  final String? subtitle;

  /// Ce qui s'écrit quand c'est fait — « Dans le panier ». `null` :
  /// rien ne s'écrit, et c'est alors la case cochée seule qui le dit.
  final String? doneLabel;

  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      child: Material(
        color:
            checked ? AppTint.fill(AppColors.primaryVivid) : AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm + 2),
          side: BorderSide(
            color: checked ? AppColors.primaryVivid : AppColors.border,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: () => onChanged(!checked),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.row),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md - 2,
                vertical: AppSpacing.sm + 4,
              ),
              child: Row(
                children: [
                  // La case est agrandie plutôt que redessinée : elle
                  // garde l'animation, le focus et la sémantique de
                  // Material.
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: Transform.scale(
                      scale: 1.4,
                      child: Checkbox(
                        value: checked,
                        onChanged: (v) => onChanged(v ?? false),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md - 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                            // Fait : le nom s'atténue, il ne se rature
                            // pas. Une rature traverse les lettres et
                            // devient illisible au soleil, sur l'écran
                            // baissé d'un téléphone en fin de batterie
                            // — exactement la situation des courses.
                            color:
                                checked
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 16.5,
                              height: 1.35,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        if (checked && doneLabel != null)
                          Text(
                            doneLabel!,
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.successInk,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Les quatre états d'une provision à la maison.
///
/// Il n'y en avait qu'un de dessiné — un triangle orange « stock bas » —
/// et rien pour « disponible » ni « rupture » : l'absence de triangle
/// devait vouloir dire « tout va bien », ce qui demande de savoir qu'un
/// triangle existe ailleurs.
enum StockState {
  disponible,
  stockBas,
  rupture,

  /// À terminer dans deux jours. Seul état qui vient d'une DATE et non
  /// d'une quantité.
  peremption,
}

/// Le badge d'état : une pastille PLEINE, qui garde son propre fond.
///
/// Les zones de « À la maison » ont des fonds colorés (lilas, menthe,
/// miel, crème). Une icône de contour mince y disparaît — c'est le
/// problème qu'avait le triangle orange sur fond miel. Ici, un disque
/// ou un triangle rempli, un glyphe par-dessus, un contour de la
/// couleur de la surface et un fin liseré sombre : le badge est lisible
/// sur n'importe quel fond, en clair comme en sombre.
///
/// Les FORMES diffèrent — disque, triangle — et pas seulement les
/// couleurs : qui distingue mal le vert et le rouge lit la forme. Et le
/// texte reste écrit à côté, parce que même une forme ne suffit pas.
class AppStateBadge extends StatelessWidget {
  const AppStateBadge({super.key, required this.state, this.size = 24});

  final StockState state;

  /// Diamètre de la pastille. Le contour et le liseré s'ajoutent
  /// autour : la boîte mesure `size + 4`.
  final double size;

  /// La couleur de l'état. Publique : la zone et la ligne s'en teintent
  /// aussi, et deux teintes différentes pour le même état seraient pire
  /// que pas de couleur du tout.
  static Color couleurDe(StockState state) => switch (state) {
    StockState.disponible => AppColors.stockOk,
    StockState.stockBas => AppColors.stockLow,
    StockState.rupture => AppColors.stockOut,
    StockState.peremption => AppColors.stockExpiring,
  };

  static IconData _formeDe(StockState state) => switch (state) {
    // Disque et coche.
    StockState.disponible => Icons.check_circle,
    // Triangle et point d'exclamation.
    StockState.stockBas => Icons.warning_rounded,
    // Disque et croix.
    StockState.rupture => Icons.cancel,
    // Disque et horloge.
    StockState.peremption => Icons.watch_later,
  };

  @override
  Widget build(BuildContext context) {
    final couleur = couleurDe(state);
    final forme = _formeDe(state);

    return SizedBox(
      width: size + 4,
      height: size + 4,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Le liseré sombre, puis le contour : le badge se détache
            // même d'un fond de la même famille de couleur.
            Icon(
              forme,
              size: size + 4,
              color: AppColors.onVivid.withValues(alpha: 0.28),
            ),
            Icon(forme, size: size + 2.5, color: AppColors.surface),
            // Le glyphe de ces icônes pleines est un TROU : sans ce
            // disque dessous, c'est le fond de la zone qu'on voit
            // dedans, et la coche disparaît sur fond menthe.
            Container(
              width: size * 0.45,
              height: size * 0.45,
              decoration: BoxDecoration(
                color: AppTint.onFilled(couleur),
                shape: BoxShape.circle,
              ),
            ),
            Icon(forme, size: size, color: couleur),
          ],
        ),
      ),
    );
  }
}

/// Le badge, et l'état ÉCRIT à côté.
class AppStateChip extends StatelessWidget {
  const AppStateChip({
    super.key,
    required this.state,
    required this.label,
    this.size = 24,
  });

  final StockState state;

  /// « Disponible », « Stock bas », « Rupture », « À terminer dans 2
  /// jours ». Jamais vide : la couleur ne porte pas seule le sens.
  final String label;

  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppStateBadge(state: state, size: size),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 17.5,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: AppTint.ink(AppStateBadge.couleurDe(state)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Un interrupteur, et son état écrit à côté.
class AppStateSwitch extends StatelessWidget {
  const AppStateSwitch({
    super.key,
    required this.value,
    required this.stateLabel,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;

  /// « État : Activée » ou « État : En pause ». La phrase complète,
  /// pas seulement le mot.
  final String stateLabel;

  final ValueChanged<bool> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          label: semanticLabel,
          child: Transform.scale(
            scale: 1.35,
            alignment: Alignment.centerLeft,
            child: Switch(value: value, onChanged: onChanged),
          ),
        ),
        const SizedBox(width: AppSpacing.md + 4),
        Expanded(
          child: Text(
            stateLabel,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// L'étoile « favori », et son état écrit à côté d'elle.
class AppFavoriteButton extends StatelessWidget {
  const AppFavoriteButton({
    super.key,
    required this.favorite,
    required this.label,
    required this.onPressed,
  });

  final bool favorite;

  /// « Favori : Oui, magasin favori » / « Favori : Non, pas encore
  /// favori ». Jamais l'étoile seule.
  final String label;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        toggled: favorite,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, AppSizes.buttonSmall),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
          ),
          icon: Icon(
            favorite ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 26,
            color: favorite ? AppColors.goldInk : AppColors.textSecondary,
          ),
          label: Text(
            label,
            style: TextStyle(
              fontSize: 17.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Une carte à en-tête teinté : une zone de rangement, un jour de la
/// semaine. Le titre est porté par la couleur de la famille, le contenu
/// reste sur la surface.
class AppZoneCard extends StatelessWidget {
  const AppZoneCard({
    super.key,
    required this.title,
    required this.tint,
    required this.children,
    this.icon,
    this.header,
  });

  final String title;

  /// Teinte de l'en-tête. Elle est posée en version translucide, donc
  /// elle suit le mode sombre.
  final Color tint;

  final IconData? icon;

  /// Posé en haut du corps, avant [children] : la photo du plat.
  final Widget? header;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border, width: 2),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: AppTint.fill(tint),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md + 2,
                vertical: AppSpacing.sm + 5,
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 26, color: AppTint.ink(tint)),
                    const SizedBox(width: AppSpacing.sm + 2),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: AppFonts.displayStyle(
                        size: 21,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (header != null) header!,
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md + 2,
                AppSpacing.md - 2,
                AppSpacing.md + 2,
                AppSpacing.sm - 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une alerte écrite en phrase complète, dans une zone.
///
/// « Alerte péremption : Lait, à terminer dans 2 jours. » Le rouge ne
/// porte pas le sens tout seul : l'icône et la phrase le portent.
class AppWarningLine extends StatelessWidget {
  const AppWarningLine({super.key, required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? Icons.warning_amber_rounded,
            size: 22,
            color: AppColors.errorInk,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.w700,
                height: 1.4,
                color: AppColors.errorInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Un réglage : son nom, ce qu'il fait, et son état ÉCRIT.
///
/// Remplace `SwitchListTile`, dont l'état ne se lit que dans la
/// position d'un curseur et sa couleur. La planche l'interdit :
///
///   « Chaque contrôle répond tout de suite, avec son état écrit en
///     texte. »
///
/// Les réglages d'intelligence, les préférences de courriel et les
/// fournisseurs portaient tous le même défaut, chacun avec sa propre
/// typographie en prime.
class AppSwitchTile extends StatelessWidget {
  const AppSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.stateLabel,
    this.subtitle,
    this.icon,
  });

  final String title;

  /// Ce que fait le réglage, en une phrase.
  final String? subtitle;

  /// « Activé » / « Désactivé », déjà traduit. Écrit sous le nom, en
  /// gras : c'est la réponse à « est-ce en marche ? ».
  final String stateLabel;

  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.row),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm + 2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 26, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm + 4),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.35,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        stateLabel,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color:
                              value
                                  ? AppColors.successInk
                                  : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ExcludeSemantics(
                  child: Transform.scale(
                    scale: 1.25,
                    child: Switch(value: value, onChanged: onChanged),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
