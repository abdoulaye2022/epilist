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

  /// Ce qui s'écrit quand c'est fait. `null` : rien ne s'écrit, la
  /// rature et la couleur suffisent (une liste de courses en magasin,
  /// où chaque ligne porterait sinon le même mot).
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
                            color: AppColors.textPrimary,
                            decoration:
                                checked ? TextDecoration.lineThrough : null,
                            decorationColor: AppColors.textSecondary,
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
