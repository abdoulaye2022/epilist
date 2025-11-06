// widgets/connectivity/connectivity_wrapper.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/services/connectivity_service.dart';
import 'package:epilist/widgets/dialogs/no_internet_dialog.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  final bool showOfflineBanner;
  final bool blockActionsWhenOffline;
  final VoidCallback? onConnectivityRestored;
  final VoidCallback? onConnectivityLost;

  const ConnectivityWrapper({
    super.key,
    required this.child,
    this.showOfflineBanner = true,
    this.blockActionsWhenOffline = false, // 🔓 Par défaut: permettre le fonctionnement hors ligne
    this.onConnectivityRestored,
    this.onConnectivityLost,
  });

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _periodicCheckTimer;
  bool _isConnected = true;
  bool _dialogShown = false;
  bool _hasShownOfflineMessage = false;

  @override
  void initState() {
    super.initState();
    _initializeConnectivity();
    _startPeriodicCheck();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicCheckTimer?.cancel();
    super.dispose();
  }

  /// Démarre une vérification périodique de la connectivité
  void _startPeriodicCheck() {
    // Vérifier toutes les 30 secondes si on est hors ligne
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!_isConnected && mounted) {
        print('🔄 [ConnectivityWrapper] Vérification périodique de la connectivité');
        final isConnected = await ConnectivityService().checkConnectivity();

        if (isConnected && mounted) {
          print('✅ [ConnectivityWrapper] Connexion restaurée (vérification périodique)');
          setState(() {
            _isConnected = true;
          });
          widget.onConnectivityRestored?.call();
          _showOnlineSnackBar();
        }
      }
    });
  }

  Future<void> _initializeConnectivity() async {
    // Vérifier la connectivité initiale
    final isConnected = await ConnectivityService().checkConnectivity();
    print('🌐 [ConnectivityWrapper] Connectivité initiale: $isConnected');

    if (mounted) {
      setState(() {
        _isConnected = isConnected;
      });

      // 🔓 Ne jamais afficher le popup au démarrage, seulement la bannière
      // Le popup bloquant est désactivé par défaut (blockActionsWhenOffline = false)
    }

    // Écouter les changements de connectivité
    _connectivitySubscription = ConnectivityService().connectivityStream.listen(
      (connected) {
        print('🌐 [ConnectivityWrapper] Changement de connectivité: $connected');

        if (mounted) {
          final wasConnected = _isConnected;
          setState(() {
            _isConnected = connected;
          });

          if (!connected && wasConnected) {
            // Connexion perdue
            print('❌ [ConnectivityWrapper] Connexion perdue');
            widget.onConnectivityLost?.call();
            _hasShownOfflineMessage = false;

            if (widget.blockActionsWhenOffline && !_dialogShown) {
              _showNoInternetDialog();
            } else if (widget.showOfflineBanner && !_hasShownOfflineMessage) {
              _showOfflineSnackBar();
              _hasShownOfflineMessage = true;
            }
          } else if (connected && !wasConnected) {
            // Connexion rétablie
            print('✅ [ConnectivityWrapper] Connexion rétablie');
            widget.onConnectivityRestored?.call();
            _hasShownOfflineMessage = false;

            if (_dialogShown) {
              Navigator.of(context, rootNavigator: true).pop();
              _dialogShown = false;
            }

            _showOnlineSnackBar();
          }
        }
      },
    );
  }

  void _showNoInternetDialog() {
    if (!_dialogShown && mounted) {
      _dialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => NoInternetDialog(
              onRetry: () {
                _dialogShown = false;
                widget.onConnectivityRestored?.call();
              },
            ),
      ).then((_) {
        _dialogShown = false;
      });
    }
  }

  void _showOfflineSnackBar() {
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      SmartSnackBarManager.showWarningSnackBar(
        context,
        l10n.offlineMode ?? 'Mode hors ligne - Fonctionnalités limitées',
        duration: const Duration(seconds: 4),
        showCloseIcon: true,
      );
    }
  }

  void _showOnlineSnackBar() {
    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      SmartSnackBarManager.showSuccessSnackBar(
        context,
        l10n.backOnline ?? 'Connexion rétablie !',
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Bannière hors ligne
        if (!_isConnected && widget.showOfflineBanner)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_off, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.offlineMode ?? 'Mode hors ligne - Connexion requise',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    print('🔄 [ConnectivityWrapper] Bouton réessayer cliqué');

                    // Forcer une vérification de connectivité
                    final isConnected =
                        await ConnectivityService().checkConnectivity();
                    print('🌐 [ConnectivityWrapper] Résultat de la vérification manuelle: $isConnected');

                    if (mounted) {
                      if (isConnected) {
                        setState(() {
                          _isConnected = true;
                        });
                        widget.onConnectivityRestored?.call();
                        _showOnlineSnackBar();
                      } else {
                        // Afficher un message si toujours hors ligne
                        SmartSnackBarManager.showWarningSnackBar(
                          context,
                          'Toujours hors ligne',
                          duration: const Duration(seconds: 2),
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      l10n.retry ?? 'Réessayer',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Contenu principal
        Expanded(
          child: ConnectivityProvider(
            isConnected: _isConnected,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

// Provider pour accéder au statut de connectivité dans les widgets enfants
class ConnectivityProvider extends InheritedWidget {
  final bool isConnected;

  const ConnectivityProvider({
    super.key,
    required this.isConnected,
    required super.child,
  });

  static ConnectivityProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ConnectivityProvider>();
  }

  @override
  bool updateShouldNotify(ConnectivityProvider oldWidget) {
    return isConnected != oldWidget.isConnected;
  }
}

// Extension pour faciliter l'accès au statut de connectivité
extension ConnectivityContext on BuildContext {
  bool get isConnected {
    return ConnectivityProvider.of(this)?.isConnected ?? true;
  }

  void requireConnection({
    VoidCallback? onConnected,
    VoidCallback? onDisconnected,
  }) {
    if (isConnected) {
      onConnected?.call();
    } else {
      onDisconnected?.call();
      // Afficher le dialog de connexion requise
      showDialog(
        context: this,
        barrierDismissible: false,
        builder: (context) => NoInternetDialog(onRetry: onConnected),
      );
    }
  }
}
