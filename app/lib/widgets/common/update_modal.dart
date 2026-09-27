// widgets/common/update_modal.dart - Fenêtre de mise à jour.
//
// Le blocage repose sur TROIS verrous simultanés, aucun n'est redondant :
//  1. barrierDismissible: false  — toucher à côté ne ferme pas ;
//  2. pas de bouton « Pas maintenant » quand la mise à jour est requise ;
//  3. PopScope(canPop: !force)   — le bouton retour Android non plus.
// Le corps du message vient du serveur (fr/en selon la langue de
// l'appareil) : modifiable sans publier de version.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/services/app_version_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Affiche la fenêtre si nécessaire. À appeler une fois par lancement.
Future<void> showUpdateModalIfNeeded(
  BuildContext context,
  AppVersionService service,
) async {
  final result = await service.check();
  if (!result.updateAvailable && !result.updateRequired) return;
  if (!context.mounted) return;

  await showDialog(
    context: context,
    barrierDismissible: false, // verrou 1
    builder: (ctx) => UpdateModal(result: result, service: service),
  );
}

class UpdateModal extends StatelessWidget {
  final AppVersionResult result;
  final AppVersionService service;

  const UpdateModal({super.key, required this.result, required this.service});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final force = result.updateRequired;
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final message = (isEn ? result.messageEn : result.messageFr) ??
        (isEn ? result.messageFr : result.messageEn);

    return PopScope(
      canPop: !force, // verrou 3 : bouton retour Android
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppDialogHeader(
                icon: Icons.system_update_alt,
                title: force
                    ? l10n.updateRequiredTitle
                    : l10n.updateAvailableTitle,
                color: force ? AppColors.warning : AppColors.primary,
              ),
              if (message != null && message.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // verrou 2 : pas d'échappatoire quand c'est requis
                  if (!force)
                    TextButton(
                      onPressed: () {
                        service.sendStat('dismissed');
                        Navigator.of(context).pop();
                      },
                      child: Text(l10n.predictionNotNow),
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: () async {
                      // La stat part AVANT l'ouverture du magasin (le
                      // compteur « updated » du doc d'origine restait à
                      // zéro faute de cet appel).
                      service.sendStat('updated');
                      final url =
                          result.storeUrl ?? AppVersionService.fallbackStoreUrl;
                      await launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    child: Text(l10n.updateNow),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
