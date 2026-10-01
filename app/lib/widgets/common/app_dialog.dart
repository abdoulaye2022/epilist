// widgets/common/app_dialog.dart - Blocs partagés des dialogues.
//
// Règle du design system : un dialogue est sobre — un en-tête compact
// (petite icône teintée + titre), les champs stylés par le thème global,
// deux boutons. Fini les icônes de 80 px, les titres de 24 et les
// paragraphes d'explication : le titre suffit, l'aide va dans les champs.
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// En-tête compact : icône 20 px dans un carré teinté de 36 px + titre.
class AppDialogHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;

  const AppDialogHeader({
    super.key,
    required this.icon,
    required this.title,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm + 2),
          ),
          child: Icon(icon, size: 20, color: c),
        ),
        const SizedBox(width: AppSpacing.sm + 4),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Rangée d'actions standard : Annuler (texte) + action principale
/// (pleine), avec état de chargement et variante destructive.
class AppDialogActions extends StatelessWidget {
  final String cancelLabel;
  final String submitLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onSubmit;
  final bool loading;
  final bool destructive;

  const AppDialogActions({
    super.key,
    required this.cancelLabel,
    required this.submitLabel,
    this.onCancel,
    this.onSubmit,
    this.loading = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap plutôt que Row : sur un écran étroit, ou avec des libellés
    // longs (traduction, grande taille de police système), les deux
    // boutons passent sur deux lignes au lieu de déborder.
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        TextButton(
          onPressed: loading
              ? null
              : (onCancel ?? () => Navigator.of(context).pop()),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: loading ? null : onSubmit,
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: AppColors.error)
              : null,
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(submitLabel),
        ),
      ],
    );
  }
}
