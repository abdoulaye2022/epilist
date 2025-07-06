// services/deep_link_handler.dart - VERSION COMPLÈTE CORRIGÉE
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/screens/share_invitation_screen.dart';
import 'package:epilist/screens/login_screen.dart';
import 'package:epilist/services/shared_list_service.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';

class DeepLinkHandler {
  static StreamSubscription<Uri>? _linkSubscription;
  static BuildContext? _context;
  static AppLinks? _appLinks;
  static String? _pendingShareToken;

  static const String customDomain = 'epilist.app';
  static const String appScheme = 'epilist';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.m2atech.epilist';
  static const String appStoreUrl =
      'https://apps.apple.com/app/epilist/id123456789';

  static void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _context = null;
    _appLinks = null;
    _pendingShareToken = null;
  }

  static void initialize(BuildContext context) {
    _context = context;

    if (_appLinks == null) {
      _appLinks = AppLinks();
    }

    _initializeDeepLinks();
    _processPendingLink();
  }

  static void _initializeDeepLinks() {
    if (_linkSubscription != null) {
      _linkSubscription?.cancel();
      _linkSubscription = null;
    }

    try {
      _appLinks = AppLinks();

      _linkSubscription = _appLinks!.uriLinkStream.listen(
        (Uri uri) {
          _handleDeepLink(uri.toString());
        },
        onError: (err) {
          // Gestion d'erreur silencieuse
        },
        onDone: () {
          // Écoute terminée
        },
      );

      _getInitialLink();
    } catch (e) {
      // Erreur silencieuse
    }
  }

  static void _navigateToShareInvitation(String shareToken) {
    if (_context == null) return;

    try {
      Navigator.of(_context!)
          .push(
            MaterialPageRoute(
              builder:
                  (context) => BlocProvider(
                    create:
                        (context) => SharedListBloc(
                          sharedListService: context.read<SharedListService>(),
                        ),
                    child: ShareInvitationScreen(shareToken: shareToken),
                  ),
            ),
          )
          .then((_) {
            if (_context != null) {
              updateContext(_context!);
            }
          });

      Future.delayed(const Duration(milliseconds: 800), () {
        if (_context != null) {
          SmartSnackBarManager.showSuccessSnackBar(
            _context!,
            'Invitation reçue !',
            duration: const Duration(seconds: 2),
          );
        }
      });
    } catch (e) {
      _showError('Erreur lors de l\'ouverture de l\'invitation');
    }
  }

  static void updateContext(BuildContext context) {
    _context = context;
    _processPendingLink();

    if (_linkSubscription == null) {
      _initializeDeepLinks();
    }
  }

  static void _handleDeepLink(String link) {
    final uri = Uri.parse(link);

    if (_isShareLink(uri)) {
      _handleShareLink(uri);
    }
  }

  static bool _isShareLink(Uri uri) {
    bool isValidScheme = false;
    bool isValidPath = false;

    if (uri.scheme == appScheme) {
      isValidScheme = true;
      bool hostValid = uri.host == 'share';
      bool pathNotEmpty = uri.pathSegments.isNotEmpty;
      isValidPath = hostValid && pathNotEmpty;
    } else if (uri.scheme == 'https' && uri.host == customDomain) {
      isValidScheme = true;
      isValidPath =
          uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'share';
    }

    return isValidScheme && isValidPath;
  }

  static Future<void> _getInitialLink() async {
    try {
      final Uri? initialUri = await _appLinks!.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri.toString());
      }
    } catch (e) {
      // Erreur silencieuse
    }
  }

  static void ensureListening() {
    if (_linkSubscription == null || _linkSubscription!.isPaused) {
      forceReinitialize();
    } else {
      _testListening();
    }
  }

  static void _handleShareLink(Uri uri) {
    try {
      String? shareToken;

      if (uri.scheme == appScheme) {
        if (uri.host == 'share' && uri.pathSegments.isNotEmpty) {
          shareToken = uri.pathSegments[0];
        }
      } else if (uri.scheme == 'https' && uri.host == customDomain) {
        if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'share') {
          shareToken = uri.pathSegments[1];
        }
      }

      if ((shareToken == null || shareToken.isEmpty) &&
          uri.queryParameters.containsKey('token')) {
        shareToken = uri.queryParameters['token'];
      }

      if (shareToken == null || shareToken.isEmpty) {
        _showError('Lien de partage invalide');
        return;
      }

      if (_context == null) {
        _pendingShareToken = shareToken;
        return;
      }

      _checkAuthAndNavigate(shareToken);
    } catch (e) {
      _showError('Erreur lors du traitement du lien de partage');
    }
  }

  static void _processPendingLink() {
    if (_pendingShareToken != null && _context != null) {
      final token = _pendingShareToken!;
      _pendingShareToken = null;

      Future.delayed(const Duration(milliseconds: 500), () {
        _checkAuthAndNavigate(token);
      });
    }
  }

  static Future<void> _checkAuthAndNavigate(String shareToken) async {
    if (_context == null) {
      return;
    }

    try {
      final authService = _context!.read<AuthService>();
      final isAuthenticated = await authService.isAuthenticated();

      if (isAuthenticated) {
        _navigateToShareInvitation(shareToken);
      } else {
        _redirectToLoginWithToken(shareToken);
      }
    } catch (e) {
      _redirectToLoginWithToken(shareToken);
    }
  }

  static void _redirectToLoginWithToken(String shareToken) {
    if (_context == null) return;

    _pendingShareToken = shareToken;

    SmartSnackBarManager.showInfoSnackBar(
      _context!,
      'Connexion requise pour accéder à l\'invitation',
      duration: const Duration(seconds: 3),
    );

    Navigator.of(_context!).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );

    _listenForAuthChanges();
  }

  static void _listenForAuthChanges() {
    if (_context == null) return;

    final authBloc = _context!.read<AuthBloc>();
    late StreamSubscription authSubscription;

    authSubscription = authBloc.stream.listen((state) {
      if (state is AuthSuccess && _pendingShareToken != null) {
        final token = _pendingShareToken!;
        _pendingShareToken = null;

        Future.delayed(const Duration(milliseconds: 1000), () {
          _navigateToShareInvitation(token);
        });

        authSubscription.cancel();
      }
    });

    Future.delayed(const Duration(minutes: 5), () {
      authSubscription.cancel();
      _pendingShareToken = null;
    });
  }

  static void _testListening() {
    Timer(const Duration(seconds: 2), () {
      if (_linkSubscription == null || _linkSubscription!.isPaused) {
        forceReinitialize();
      }
    });
  }

  static void forceReinitialize() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _appLinks = null;

    if (_context != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _appLinks = AppLinks();
        _initializeDeepLinks();
      });
    }
  }

  static void _showError(String message) {
    if (_context == null) return;

    SmartSnackBarManager.showErrorSnackBar(
      _context!,
      message,
      duration: const Duration(seconds: 4),
    );
  }

  static void processPendingTokenAfterLogin() {
    if (_pendingShareToken != null && _context != null) {
      final token = _pendingShareToken!;
      _pendingShareToken = null;

      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateToShareInvitation(token);
      });
    }
  }

  // MÉTHODES UTILITAIRES
  static String generateWebShareUrl(String token) {
    return 'https://$customDomain/share/$token';
  }

  static String generateAppShareUrl(String token) {
    return '$appScheme://share/$token';
  }

  static Map<String, String> generateShareData(
    String token,
    String listName,
    String ownerName,
  ) {
    final shareUrl = generateWebShareUrl(token);

    return {
      'url': shareUrl,
      'title': 'Invitation EpiList - $listName',
      'text':
          '$ownerName vous invite à collaborer sur la liste "$listName".\n\n'
          '🔗 Cliquez pour ouvrir dans EpiList :\n$shareUrl\n\n'
          '📱 L\'app s\'ouvrira automatiquement ou vous pourrez la télécharger.',
      'subject': 'Invitation à partager une liste d\'épicerie - EpiList',
    };
  }

  static bool isValidShareLink(String link) {
    try {
      final uri = Uri.parse(link);
      return _isShareLink(uri);
    } catch (e) {
      return false;
    }
  }

  static String? extractTokenFromLink(String link) {
    try {
      final uri = Uri.parse(link);
      if (!_isShareLink(uri)) return null;

      if (uri.scheme == appScheme) {
        if (uri.host == 'share' && uri.pathSegments.isNotEmpty) {
          return uri.pathSegments[0];
        }
      } else if (uri.scheme == 'https' && uri.host == customDomain) {
        if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'share') {
          return uri.pathSegments[1];
        }
      }

      if (uri.queryParameters.containsKey('token')) {
        return uri.queryParameters['token'];
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static String createOptimizedShareMessage(
    String token,
    String listName,
    String ownerName,
  ) {
    final webUrl = generateWebShareUrl(token);

    return '🛒 $ownerName vous invite sur "$listName"\n\n'
        '📱 Cliquez pour ouvrir EpiList :\n$webUrl\n\n'
        'L\'app s\'ouvrira automatiquement ou vous pourrez la télécharger gratuitement !';
  }

  static Future<void> openAppOrStore(String shareToken) async {
    final appUrl = generateAppShareUrl(shareToken);

    try {
      final bool launched = await launchUrl(
        Uri.parse(appUrl),
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        await _openStore();
      }
    } catch (e) {
      await _openStore();
    }
  }

  static Future<void> _openStore() async {
    try {
      await launchUrl(
        Uri.parse(playStoreUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      // Erreur silencieuse
    }
  }
}
