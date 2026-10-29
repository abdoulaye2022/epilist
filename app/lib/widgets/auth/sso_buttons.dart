// widgets/auth/sso_buttons.dart — Google et Apple, au même endroit.
//
// Ces deux boutons existaient déjà, mais seulement DERRIÈRE l'écran de
// connexion : il fallait toucher « Commencer », arriver sur la
// connexion, et les trouver là. Ils sont maintenant proposés dès
// l'écran de bienvenue, en premier — c'est le chemin le plus court
// vers une première liste, et le seul qui ne demande ni mot de passe à
// inventer ni boîte de courriel à ouvrir.
//
// Le widget ne garde aucun état : il lit celui du bloc. Deux écrans
// affichant ces boutons ne peuvent donc pas se contredire.
import 'dart:io';

import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BoutonsSSO extends StatelessWidget {
  const BoutonsSSO({super.key, this.onDemarrage});

  /// Appelé juste avant d'envoyer l'événement, pour que l'écran puisse
  /// fermer un clavier ou effacer un message d'erreur.
  final VoidCallback? onDemarrage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final occupe = state is AuthLoading || state is SSOLoading;
        final googleEnCours =
            state is SSOLoading && state.provider == 'google';
        final appleEnCours = state is SSOLoading && state.provider == 'apple';

        void lancer(AuthEvent evenement) {
          onDemarrage?.call();
          context.read<AuthBloc>().add(evenement);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed:
                  occupe ? null : () => lancer(const GoogleSignInRequested()),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.surface,
              ),
              icon:
                  googleEnCours
                      ? _attente(AppColors.textSecondary)
                      : const Icon(
                        Icons.g_mobiledata,
                        size: 26,
                        color: Color(0xFF4285F4),
                      ),
              label: Text(
                l10n.continueWithGoogle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // Apple seulement sur iOS : le bouton n'a rien à faire sur
            // Android, et Apple exige qu'il soit là dès qu'un autre
            // fournisseur l'est.
            if (Platform.isIOS) ...[
              const SizedBox(height: AppSpacing.sm + 4),
              ElevatedButton.icon(
                onPressed:
                    occupe ? null : () => lancer(const AppleSignInRequested()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: AppColors.surface,
                ),
                icon:
                    appleEnCours
                        ? _attente(AppColors.onPrimary)
                        : const Icon(Icons.apple, size: 20),
                label: Text(
                  l10n.continueWithApple,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _attente(Color couleur) => SizedBox(
    width: 18,
    height: 18,
    child: CircularProgressIndicator(strokeWidth: 2, color: couleur),
  );
}
