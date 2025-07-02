// services/deep_link_handler.dart - VERSION AVEC VÉRIFICATION D'AUTHENTIFICATION
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/screens/share_invitation_screen.dart';
import 'package:epilist/screens/login_screen.dart';
import 'package:epilist/services/shared_list_service.dart';
import 'package:epilist/services/auth_service.dart';
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

  static void initialize(BuildContext context) {
    _context = context;
    _appLinks = AppLinks();
    _initializeDeepLinks();
    _processPendingLink();
  }

  static void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _context = null;
    _appLinks = null;
    _pendingShareToken = null;
  }

  static void _initializeDeepLinks() {
    _linkSubscription = _appLinks!.uriLinkStream.listen(
      (Uri uri) {
        debugPrint('🔗 Lien reçu: ${uri.toString()}');
        _handleDeepLink(uri.toString());
      },
      onError: (err) {
        debugPrint('❌ Erreur de lien profond: $err');
      },
    );

    _getInitialLink();
  }

  static Future<void> _getInitialLink() async {
    try {
      final Uri? initialUri = await _appLinks!.getInitialLink();
      if (initialUri != null) {
        debugPrint('🔗 Lien initial: ${initialUri.toString()}');
        _handleDeepLink(initialUri.toString());
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération du lien initial: $e');
    }
  }

  static void _handleDeepLink(String link) {
    final uri = Uri.parse(link);

    if (_isShareLink(uri)) {
      _handleShareLink(uri);
    } else {
      debugPrint('⚠️ Type de lien non reconnu: $link');
    }
  }

  static bool _isShareLink(Uri uri) {
    bool isValidScheme = false;
    bool isValidPath = false;

    if (uri.scheme == appScheme) {
      // Pour epilist://share/token -> host="share", path="/token"
      isValidScheme = true;
      isValidPath = uri.host == 'share' && uri.pathSegments.isNotEmpty;
    } else if (uri.scheme == 'https' && uri.host == customDomain) {
      // Pour https://epilist.app/share/token -> pathSegments=["share", "token"]
      isValidScheme = true;
      isValidPath =
          uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'share';
    }

    return isValidScheme && isValidPath;
  }

  static void _handleShareLink(Uri uri) {
    try {
      String? shareToken;

      if (uri.scheme == appScheme) {
        // Pour epilist://share/token -> host="share", pathSegments=["token"]
        if (uri.host == 'share' && uri.pathSegments.isNotEmpty) {
          shareToken = uri.pathSegments[0];
        }
      } else if (uri.scheme == 'https' && uri.host == customDomain) {
        // Pour https://epilist.app/share/token -> pathSegments=["share", "token"]
        if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'share') {
          shareToken = uri.pathSegments[1];
        }
      }

      // Fallback: check query parameters
      if ((shareToken == null || shareToken.isEmpty) &&
          uri.queryParameters.containsKey('token')) {
        shareToken = uri.queryParameters['token'];
      }

      if (shareToken == null || shareToken.isEmpty) {
        _showError('Lien de partage invalide');
        return;
      }

      debugPrint('🎯 Token de partage: $shareToken');

      if (_context == null) {
        _pendingShareToken = shareToken;
        return;
      }

      // ✅ Vérifier l'authentification avant de naviguer
      _checkAuthAndNavigate(shareToken);
    } catch (e) {
      debugPrint('❌ Erreur lors du traitement du lien de partage: $e');
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

  // ✅ NOUVELLE MÉTHODE : Vérifier l'authentification avant la navigation
  static Future<void> _checkAuthAndNavigate(String shareToken) async {
    if (_context == null) return;

    try {
      // Vérifier si l'utilisateur est authentifié
      final authService = _context!.read<AuthService>();
      final isAuthenticated = await authService.isAuthenticated();

      if (isAuthenticated) {
        debugPrint('✅ Utilisateur authentifié, navigation vers l\'invitation');
        _navigateToShareInvitation(shareToken);
      } else {
        debugPrint('❌ Utilisateur non authentifié, redirection vers login');
        _redirectToLoginWithToken(shareToken);
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification d\'authentification: $e');
      // En cas d'erreur, rediriger vers login par sécurité
      _redirectToLoginWithToken(shareToken);
    }
  }

  // ✅ NOUVELLE MÉTHODE : Rediriger vers login avec token sauvegardé
  static void _redirectToLoginWithToken(String shareToken) {
    if (_context == null) return;

    // Sauvegarder le token pour après la connexion
    _pendingShareToken = shareToken;

    // Afficher un message informatif
    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Connexion requise pour accéder à l\'invitation'),
          ],
        ),
        backgroundColor: Colors.blue[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      ),
    );

    // Naviguer vers l'écran de connexion
    Navigator.of(_context!).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );

    // Écouter les changements d'état d'authentification
    _listenForAuthChanges();
  }

  // ✅ NOUVELLE MÉTHODE : Écouter les changements d'authentification
  static void _listenForAuthChanges() {
    if (_context == null) return;

    final authBloc = _context!.read<AuthBloc>();
    late StreamSubscription authSubscription;

    authSubscription = authBloc.stream.listen((state) {
      if (state is AuthSuccess && _pendingShareToken != null) {
        debugPrint('✅ Utilisateur connecté, traitement du token en attente');

        final token = _pendingShareToken!;
        _pendingShareToken = null;

        // Petit délai pour laisser l'interface se stabiliser
        Future.delayed(const Duration(milliseconds: 1000), () {
          _navigateToShareInvitation(token);
        });

        // Annuler l'écoute
        authSubscription.cancel();
      }
    });

    // Annuler l'écoute après 5 minutes pour éviter les fuites mémoire
    Future.delayed(const Duration(minutes: 5), () {
      authSubscription.cancel();
      _pendingShareToken = null;
    });
  }

  static void _navigateToShareInvitation(String shareToken) {
    if (_context == null) return;

    try {
      Navigator.of(_context!).push(
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
      );

      // Message de confirmation
      Future.delayed(const Duration(milliseconds: 800), () {
        if (_context != null) {
          ScaffoldMessenger.of(_context!).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.share, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Invitation reçue !'),
                ],
              ),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('❌ Erreur lors de la navigation: $e');
      _showError('Erreur lors de l\'ouverture de l\'invitation');
    }
  }

  static void _showError(String message) {
    if (_context == null) return;

    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ✅ NOUVELLE MÉTHODE : Traiter un token après connexion réussie
  static void processPendingTokenAfterLogin() {
    if (_pendingShareToken != null && _context != null) {
      debugPrint('🔄 Traitement du token après connexion: $_pendingShareToken');

      final token = _pendingShareToken!;
      _pendingShareToken = null;

      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateToShareInvitation(token);
      });
    }
  }

  // MÉTHODES UTILITAIRES (inchangées)
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
      debugPrint('❌ Erreur lors de l\'ouverture de l\'app: $e');
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
      debugPrint('❌ Erreur lors de l\'ouverture du store: $e');
    }
  }
}
