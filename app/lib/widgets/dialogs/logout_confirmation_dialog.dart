import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/app_dialog.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

class LogoutConfirmationDialog extends StatefulWidget {
  const LogoutConfirmationDialog({super.key});

  @override
  State<LogoutConfirmationDialog> createState() =>
      _LogoutConfirmationDialogState();
}

class _LogoutConfirmationDialogState extends State<LogoutConfirmationDialog> {
  Timer? _timeoutTimer;
  bool _hasLoggedOut = false;
  bool _logoutStarted = false; // ✅ NOUVEAU: Track si le logout a commencé

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startLogoutTimeout() {
    // ✅ SÉCURITÉ: Timer de 3 secondes pour forcer la navigation si blocage
    _timeoutTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_hasLoggedOut) {
        debugPrint('⚠️ Timeout de logout - Navigation forcée vers /login');
        _navigateToLogin();
      }
    });
  }

  void _navigateToLogin() {
    if (!_hasLoggedOut && mounted) {
      _hasLoggedOut = true;
      _timeoutTimer?.cancel();

      debugPrint('🚀 Navigation forcée vers /login depuis le dialog');

      // ✅ Fermer le dialog d'abord
      Navigator.pop(context);

      // ✅ Puis naviguer vers login avec un délai
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            debugPrint('🔄 LogoutDialog - State changé: ${state.runtimeType}');

            // ✅ CORRECTION: Gérer le processus de logout de manière plus robuste
            if (state is AuthLoading && _logoutStarted) {
              debugPrint('🔄 Logout en cours...');
              // Ne rien faire, attendre Unauthenticated
            } else if (state is Unauthenticated && _logoutStarted) {
              if (!_hasLoggedOut) {
                debugPrint('✅ Déconnexion confirmée - Navigation vers /login');
                _navigateToLogin();
              }
            } else if (state is AuthFailure && _logoutStarted) {
              // En cas d'erreur, forcer quand même la navigation
              if (!_hasLoggedOut) {
                debugPrint(
                  '❌ Erreur de logout - Navigation forcée vers /login',
                );
                _navigateToLogin();
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppDialogHeader(
                  icon: Icons.logout_rounded,
                  title: l10n.logout,
                  color: AppColors.warning,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.confirmLogoutMessage,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                _buildButtons(context, l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context, AppLocalizations l10n) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = _logoutStarted;
        return AppDialogActions(
          cancelLabel: l10n.cancel,
          submitLabel: l10n.logout,
          destructive: true,
          loading: isLoading,
          onSubmit: () {
            setState(() => _logoutStarted = true);
            _startLogoutTimeout();
            context.read<AuthBloc>().add(LogoutRequested());
          },
        );
      },
    );
  }
}
