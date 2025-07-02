// snackbar_manager.dart - Gestionnaire pour éviter les doublons de SnackBar
import 'package:flutter/material.dart';

class SnackBarManager {
  static bool _isSnackBarVisible = false;
  static ScaffoldMessengerState? _currentMessenger;

  /// Affiche un SnackBar d'erreur avec gestion des doublons
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    bool forceShow = false,
  }) {
    // Si un SnackBar est déjà visible et qu'on ne force pas l'affichage
    if (_isSnackBarVisible && !forceShow) {
      return;
    }

    // Fermer le SnackBar précédent s'il existe
    if (_isSnackBarVisible && _currentMessenger != null) {
      _currentMessenger!.clearSnackBars();
    }

    final messenger = ScaffoldMessenger.of(context);
    _currentMessenger = messenger;
    _isSnackBarVisible = true;

    messenger
        .showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            duration: duration,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 20, right: 20, left: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 6,
            action: SnackBarAction(
              label: 'Fermer',
              textColor: Colors.white70,
              onPressed: () {
                messenger.hideCurrentSnackBar();
              },
            ),
          ),
        )
        .closed
        .then((_) {
          // Marquer comme non visible quand le SnackBar se ferme
          _isSnackBarVisible = false;
          _currentMessenger = null;
        });
  }

  /// Affiche un SnackBar de succès
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (_isSnackBarVisible) {
      ScaffoldMessenger.of(context).clearSnackBars();
    }

    _isSnackBarVisible = true;

    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            duration: duration,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 20, right: 20, left: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 6,
          ),
        )
        .closed
        .then((_) {
          _isSnackBarVisible = false;
        });
  }

  /// Force la fermeture de tous les SnackBars
  static void clearAll(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    _isSnackBarVisible = false;
    _currentMessenger = null;
  }
}

/// Classe utilitaire pour les messages d'erreur en français
class AuthErrorMessages {
  static String getLocalizedError(String error) {
    final lowerError = error.toLowerCase();

    // Erreurs de connexion
    if (lowerError.contains('invalid_credentials') ||
        lowerError.contains('invalid credentials') ||
        lowerError.contains('wrong password') ||
        lowerError.contains('incorrect password') ||
        lowerError.contains('bad credentials') ||
        lowerError.contains('authentication failed')) {
      return 'Email ou mot de passe incorrect. Veuillez vérifier vos informations.';
    }

    if (lowerError.contains('user_not_found') ||
        lowerError.contains('user not found') ||
        lowerError.contains('account not found') ||
        lowerError.contains('email not found')) {
      return 'Aucun compte associé à cette adresse email. Créez un compte ou vérifiez votre email.';
    }

    if (lowerError.contains('email_not_verified') ||
        lowerError.contains('email not verified') ||
        lowerError.contains('account not verified')) {
      return 'Votre email n\'est pas encore vérifié. Consultez votre boîte de réception.';
    }

    // Erreurs de réseau
    if (lowerError.contains('network') ||
        lowerError.contains('connection') ||
        lowerError.contains('timeout') ||
        lowerError.contains('no internet') ||
        lowerError.contains('host lookup failed')) {
      return 'Problème de connexion internet. Vérifiez votre réseau et réessayez.';
    }

    // Erreurs de serveur
    if (lowerError.contains('server error') ||
        lowerError.contains('internal server') ||
        lowerError.contains('500') ||
        lowerError.contains('503')) {
      return 'Problème temporaire du serveur. Veuillez réessayer dans quelques instants.';
    }

    // Erreurs de validation
    if (lowerError.contains('validation') ||
        lowerError.contains('invalid format') ||
        lowerError.contains('malformed')) {
      return 'Format de données invalide. Vérifiez vos informations.';
    }

    // Erreurs de session
    if (lowerError.contains('session expired') ||
        lowerError.contains('token expired') ||
        lowerError.contains('unauthorized')) {
      return 'Votre session a expiré. Veuillez vous reconnecter.';
    }

    // Erreurs de limite
    if (lowerError.contains('too many attempts') ||
        lowerError.contains('rate limit') ||
        lowerError.contains('too many requests')) {
      return 'Trop de tentatives. Attendez quelques minutes avant de réessayer.';
    }

    // Erreurs de compte
    if (lowerError.contains('account disabled') ||
        lowerError.contains('account suspended') ||
        lowerError.contains('account locked')) {
      return 'Votre compte est temporairement désactivé. Contactez le support.';
    }

    // Message générique si aucune correspondance
    if (error.length > 100) {
      return 'Une erreur est survenue lors de la connexion. Veuillez réessayer.';
    }

    return error.isNotEmpty ? error : 'Une erreur inattendue est survenue.';
  }
}
