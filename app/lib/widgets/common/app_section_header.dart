// widgets/common/app_section_header.dart - Le titre d'un groupe.
//
// Chaque écran écrivait son propre en-tête : tailles de 14 à 20, gras
// ou demi-gras, parfois une icône, un « Voir tout » tantôt à gauche
// tantôt à droite. Le lecteur ne pouvait pas apprendre une seule fois
// à quoi ressemble un début de section.
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailingLabel,
    this.onTrailing,
    this.count,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.sm,
      AppSpacing.sm,
      0,
      AppSpacing.xs,
    ),
  });

  final String title;
  final IconData? icon;

  /// Compte affiché juste après le titre (« Factures · 12 »).
  final String? count;

  /// Action de droite — « Voir tout », « Tout cocher ».
  final String? trailingLabel;
  final VoidCallback? onTrailing;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              count == null ? title : '$title · $count',
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailingLabel != null && onTrailing != null)
            TextButton(
              onPressed: onTrailing,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              child: Text(trailingLabel!),
            ),
        ],
      ),
    );
  }
}
