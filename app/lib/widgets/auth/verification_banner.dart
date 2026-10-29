// widgets/auth/verification_banner.dart — le rappel de vérification.
//
// La vérification du courriel ne bloque plus l'entrée : on entre, on
// crée sa première liste, et on vérifie son adresse quand on veut. Ce
// bandeau est tout ce qui reste pour la demander — il doit donc dire à
// quoi elle sert, et pas seulement qu'elle manque.
//
// Il disparaît de lui-même dès que l'adresse est vérifiée : il lit
// l'état du compte, il n'a pas de mémoire propre.
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/screens/email_verification_screen.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BandeauVerificationCourriel extends StatelessWidget {
  const BandeauVerificationCourriel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (avant, apres) => avant != apres,
      builder: (context, state) {
        if (state is! AuthSuccess || state.user.emailVerified) {
          return const SizedBox.shrink();
        }

        return Material(
          color: AppColors.warningTint,
          child: InkWell(
            onTap: () => _ouvrirVerification(context, state.user.email),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.mark_email_unread_outlined,
                    size: 20,
                    color: AppColors.warningInk,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.verifyEmailBannerTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.warningInk,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.verifyEmailBannerBody,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.3,
                            color: AppColors.warningInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n.verifyEmailBannerAction,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.warningInk,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _ouvrirVerification(BuildContext context, String courriel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmailVerificationScreen(email: courriel),
      ),
    );
  }
}
