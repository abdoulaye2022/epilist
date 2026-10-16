// screens/appearance_screen.dart - Le choix clair / sombre.
//
// L'application n'avait qu'un thème. Les jetons de couleur étant
// désormais lus dans une palette (voir theme/app_theme.dart), le mode
// sombre est devenu un choix et non un chantier : cet écran l'expose,
// et `ThemeModeController` l'enregistre.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/theme/theme_mode_controller.dart';
import 'package:epilist/widgets/common/app_card.dart';
import 'package:epilist/widgets/common/app_section_header.dart';
import 'package:flutter/material.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appearance)),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: appThemeMode,
        builder: (context, mode, _) => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            AppCard.tight(
              child: Column(
                children: [
                  _Choice(
                    mode: ThemeMode.system,
                    current: mode,
                    icon: Icons.brightness_auto_outlined,
                    label: l10n.appearanceSystem,
                    hint: l10n.appearanceSystemHint,
                  ),
                  const Divider(height: 1, indent: AppSpacing.md),
                  _Choice(
                    mode: ThemeMode.light,
                    current: mode,
                    icon: Icons.light_mode_outlined,
                    label: l10n.appearanceLight,
                  ),
                  const Divider(height: 1, indent: AppSpacing.md),
                  _Choice(
                    mode: ThemeMode.dark,
                    current: mode,
                    icon: Icons.dark_mode_outlined,
                    label: l10n.appearanceDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppSectionHeader(title: l10n.appearancePreview),
            const _Preview(),
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.mode,
    required this.current,
    required this.icon,
    required this.label,
    this.hint,
  });

  final ThemeMode mode;
  final ThemeMode current;
  final IconData icon;
  final String label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final selected = mode == current;
    return ListTile(
      onTap: () => appThemeMode.select(mode),
      leading: Icon(
        icon,
        color: selected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(label, style: Theme.of(context).textTheme.titleSmall),
      subtitle: hint == null
          ? null
          : Text(hint!, style: Theme.of(context).textTheme.bodySmall),
      trailing: selected
          ? Icon(Icons.check_rounded, color: AppColors.primary)
          : null,
    );
  }
}

/// Un échantillon de chaque rôle : c'est ce qui permet de voir, avant de
/// parcourir l'application, que le texte secondaire et les fonds teintés
/// restent lisibles dans le mode choisi.
class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.appTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.appearancePreviewLine, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _Swatch(AppColors.successTint, AppColors.successInk, 'OK'),
              _Swatch(AppColors.warningTint, AppColors.warningInk, '!'),
              _Swatch(AppColors.errorTint, AppColors.errorInk, '×'),
              _Swatch(AppColors.infoTint, AppColors.infoInk, 'i'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(onPressed: () {}, child: Text(l10n.save)),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.fill, this.ink, this.label);

  final Color fill;
  final Color ink;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(color: ink, fontWeight: FontWeight.w600),
      ),
    );
  }
}
