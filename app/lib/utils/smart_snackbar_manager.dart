// utils/smart_snackbar_manager.dart - Gestionnaire intelligent pour les états Bloc
import 'package:flutter/material.dart';

class SmartSnackBarManager {
  static bool _isSnackBarVisible = false;
  static ScaffoldMessengerState? _currentMessenger;

  /// Affiche automatiquement le bon type de SnackBar selon l'état
  static void showForState(
    BuildContext context,
    dynamic state, {
    Duration? duration,
    bool forceShow = false,
  }) {
    final String message = _extractMessage(state);
    if (message.isEmpty) return;

    final SnackBarType type = _determineType(state);

    _showSnackBar(
      context,
      message: message,
      type: type,
      duration: duration ?? _getDefaultDuration(type),
      forceShow: forceShow,
    );
  }

  /// Méthode pour afficher un SnackBar avec un message personnalisé
  static void showMessage(
    BuildContext context,
    String message, {
    SnackBarType type = SnackBarType.info,
    Duration? duration,
    bool forceShow = false,
  }) {
    _showSnackBar(
      context,
      message: message,
      type: type,
      duration: duration ?? _getDefaultDuration(type),
      forceShow: forceShow,
    );
  }

  // ✅ NOUVELLES MÉTHODES AJOUTÉES

  /// Affiche un SnackBar de succès
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration? duration,
    bool forceShow = false,
  }) {
    _showSnackBar(
      context,
      message: message,
      type: SnackBarType.success,
      duration: duration ?? const Duration(seconds: 3),
      forceShow: forceShow,
    );
  }

  /// Affiche un SnackBar d'erreur
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    Duration? duration,
    bool forceShow = false,
  }) {
    _showSnackBar(
      context,
      message: message,
      type: SnackBarType.error,
      duration: duration ?? const Duration(seconds: 4),
      forceShow: forceShow,
    );
  }

  /// Affiche un SnackBar d'avertissement
  static void showWarningSnackBar(
    BuildContext context,
    String message, {
    Duration? duration,
    bool forceShow = false,
  }) {
    _showSnackBar(
      context,
      message: message,
      type: SnackBarType.warning,
      duration: duration ?? const Duration(seconds: 4),
      forceShow: forceShow,
    );
  }

  /// Affiche un SnackBar d'information
  static void showInfoSnackBar(
    BuildContext context,
    String message, {
    Duration? duration,
    bool forceShow = false,
  }) {
    _showSnackBar(
      context,
      message: message,
      type: SnackBarType.info,
      duration: duration ?? const Duration(seconds: 3),
      forceShow: forceShow,
    );
  }

  /// Détermine le type de SnackBar selon l'état
  static SnackBarType _determineType(dynamic state) {
    final stateType = state.runtimeType.toString().toLowerCase();

    // États d'erreur
    if (stateType.contains('error') ||
        stateType.contains('failure') ||
        stateType.contains('failed')) {
      return SnackBarType.error;
    }

    // États de succès
    if (stateType.contains('success') ||
        stateType.contains('completed') ||
        stateType.contains('created') ||
        stateType.contains('updated') ||
        stateType.contains('deleted')) {
      return SnackBarType.success;
    }

    // États d'avertissement
    if (stateType.contains('warning') || stateType.contains('caution')) {
      return SnackBarType.warning;
    }

    // États de chargement ou d'information
    if (stateType.contains('loading') || stateType.contains('info')) {
      return SnackBarType.info;
    }

    // Par défaut, info
    return SnackBarType.info;
  }

  /// Extrait le message de l'état
  static String _extractMessage(dynamic state) {
    try {
      // Essayer d'accéder à la propriété 'message'
      if (state is StateWithMessage) {
        return state.message;
      }

      // Utiliser la réflexion pour accéder à 'message'
      final mirror = state as dynamic;
      if (mirror.message != null) {
        return mirror.message.toString();
      }
    } catch (e) {
      // Si pas de propriété message, retourner vide
    }

    return '';
  }

  /// Durée par défaut selon le type
  static Duration _getDefaultDuration(SnackBarType type) {
    switch (type) {
      case SnackBarType.error:
        return const Duration(seconds: 4);
      case SnackBarType.warning:
        return const Duration(seconds: 4);
      case SnackBarType.success:
        return const Duration(seconds: 3);
      case SnackBarType.info:
        return const Duration(seconds: 3);
    }
  }

  /// Méthode privée pour afficher le SnackBar
  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required SnackBarType type,
    required Duration duration,
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

    final config = _getConfigForType(type);
    final messenger = ScaffoldMessenger.of(context);
    _currentMessenger = messenger;
    _isSnackBarVisible = true;

    messenger
        .showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(config.icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: config.backgroundColor,
            duration: duration,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 20, right: 20, left: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 6,
            action:
                config.showCloseAction
                    ? SnackBarAction(
                      label: 'Fermer',
                      textColor: Colors.white70,
                      onPressed: () {
                        messenger.hideCurrentSnackBar();
                      },
                    )
                    : null,
          ),
        )
        .closed
        .then((_) {
          _isSnackBarVisible = false;
          _currentMessenger = null;
        });
  }

  /// Configuration pour chaque type de SnackBar
  static _SnackBarConfig _getConfigForType(SnackBarType type) {
    switch (type) {
      case SnackBarType.error:
        return _SnackBarConfig(
          icon: Icons.error_outline,
          backgroundColor: Colors.red[600]!,
          showCloseAction: true,
        );
      case SnackBarType.success:
        return _SnackBarConfig(
          icon: Icons.check_circle_outline,
          backgroundColor: Colors.green[600]!,
          showCloseAction: false,
        );
      case SnackBarType.warning:
        return _SnackBarConfig(
          icon: Icons.warning_outlined,
          backgroundColor: Colors.orange[600]!,
          showCloseAction: true,
        );
      case SnackBarType.info:
        return _SnackBarConfig(
          icon: Icons.info_outline,
          backgroundColor: Colors.blue[600]!,
          showCloseAction: false,
        );
    }
  }

  /// Force la fermeture de tous les SnackBars
  static void clearAll(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    _isSnackBarVisible = false;
    _currentMessenger = null;
  }
}

/// Types de SnackBar disponibles
enum SnackBarType { error, success, warning, info }

/// Configuration pour un type de SnackBar
class _SnackBarConfig {
  final IconData icon;
  final Color backgroundColor;
  final bool showCloseAction;

  _SnackBarConfig({
    required this.icon,
    required this.backgroundColor,
    required this.showCloseAction,
  });
}

/// Interface pour les états qui ont un message
abstract class StateWithMessage {
  String get message;
}
