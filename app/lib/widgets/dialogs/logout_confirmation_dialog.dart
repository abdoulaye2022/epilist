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
        print('⚠️ Timeout de logout - Navigation forcée vers /login');
        _navigateToLogin();
      }
    });
  }

  void _navigateToLogin() {
    if (!_hasLoggedOut && mounted) {
      _hasLoggedOut = true;
      _timeoutTimer?.cancel();

      print('🚀 Navigation forcée vers /login depuis le dialog');

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
            print('🔄 LogoutDialog - State changé: ${state.runtimeType}');

            // ✅ CORRECTION: Gérer le processus de logout de manière plus robuste
            if (state is AuthLoading && _logoutStarted) {
              print('🔄 Logout en cours...');
              // Ne rien faire, attendre Unauthenticated
            } else if (state is Unauthenticated && _logoutStarted) {
              if (!_hasLoggedOut) {
                print('✅ Déconnexion confirmée - Navigation vers /login');
                _navigateToLogin();
              }
            } else if (state is AuthFailure && _logoutStarted) {
              // En cas d'erreur, forcer quand même la navigation
              if (!_hasLoggedOut) {
                print('❌ Erreur de logout - Navigation forcée vers /login');
                _navigateToLogin();
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIcon(),
                const SizedBox(height: 20),
                _buildTitle(l10n),
                const SizedBox(height: 12),
                _buildMessage(l10n),
                const SizedBox(height: 24),
                _buildButtons(context, l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(40),
      ),
      child: Icon(Icons.logout_rounded, size: 40, color: Colors.orange[600]),
    );
  }

  Widget _buildTitle(AppLocalizations l10n) {
    return Text(
      l10n.logout,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildMessage(AppLocalizations l10n) {
    return Text(
      l10n.confirmLogoutMessage,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
    );
  }

  Widget _buildButtons(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        // Bouton Annuler
        Expanded(
          child: TextButton(
            onPressed: _logoutStarted ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Text(
              l10n.cancel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _logoutStarted ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Bouton Déconnexion
        Expanded(
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final isLoading = state is AuthLoading && _logoutStarted;

              return ElevatedButton(
                onPressed:
                    (_logoutStarted || isLoading)
                        ? null
                        : () {
                          print('🚀 Déclenchement de LogoutRequested');

                          // ✅ Marquer le début du logout
                          setState(() {
                            _logoutStarted = true;
                          });

                          // ✅ Démarrer le timer de sécurité
                          _startLogoutTimeout();

                          // Déclencher le logout
                          context.read<AuthBloc>().add(LogoutRequested());
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.orange[300],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child:
                    isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              l10n.logout,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
              );
            },
          ),
        ),
      ],
    );
  }
}
