// widgets/common/app_action_tile.dart - Ligne « icône + titre + sous-
// titre » utilisée par la feuille du bouton + et par l'écran « Plus ».
// Même pastille, même densité, même onde d'appui partout.
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AppActionTile extends StatelessWidget {
  const AppActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  /// Compteur discret à droite (nombre de factures, de membres…).
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, size: 21, color: AppColors.primaryDark),
      ),
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle:
          subtitle == null
              ? null
              : Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
      trailing:
          badge == null
              ? Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textDisabled,
              )
              : Text(badge!, style: theme.textTheme.bodySmall),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      visualDensity: const VisualDensity(vertical: -1),
    );
  }
}
