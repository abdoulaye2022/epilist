// widgets/home/action_tile.dart - Les quatre actions de l'accueil.
//
// Elles remplacent le bouton + central, qui cachait six actions derrière
// un geste et un libellé muet. Ici, chacune se voit : son dessin, son
// nom écrit en entier, sa famille de couleur, et 104 dp de hauteur à
// toucher.
//
// La teinte sert deux fois — fond translucide et bordure pleine — donc
// elle suit le mode sombre sans que la tuile en sache rien. Le texte,
// lui, reste [AppColors.textPrimary] : une encre dérivée de la teinte
// serait illisible sur quatre familles différentes.
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;

  /// Écrit en entier sous l'icône, sur deux lignes au besoin. Jamais
  /// abrégé : c'est le libellé qui dit ce que fait la tuile.
  final String label;

  /// La couleur de la famille : orange pour le budget et les magasins,
  /// vert pour la voix, bleu pour le scan, or pour les repas.
  final Color tint;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: AppTint.fill(tint),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm + 4),
            side: BorderSide(color: tint, width: 3),
          ),
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 104),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 2,
                  vertical: AppSpacing.md - 2,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 32, color: AppTint.ink(tint)),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
