// snackbar_manager.dart - VERSION CORRIGÉE : Suppression de AuthErrorMessages
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

// ✅ SUPPRIMÉ : Classe AuthErrorMessages qui causait les doublons
// Toute la logique de traduction des erreurs est maintenant dans main.dart
// dans la fonction _getLocalizedError()
