// services/deep_link_handler.dart - VERSION AVEC LIENS DIRECTS
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
      'https://apps.apple.com/ca/app/epilist/id6748285596';

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
          print('🔗 Deep link reçu: ${uri.toString()}');
          _handleDeepLink(uri.toString());
        },
        onError: (err) {
          print('❌ Erreur deep link: $err');
        },
        onDone: () {
          print('✅ Écoute deep link terminée');
        },
      );

      _getInitialLink();
    } catch (e) {
      print('❌ Erreur initialisation deep links: $e');
    }
  }

  static void _navigateToShareInvitation(String shareToken) {
    if (_context == null) {
      print('❌ Context non disponible pour navigation');
      return;
    }

    try {
      print('🎯 Navigation vers ShareInvitationScreen avec token: $shareToken');

      // Vérifier que le context est encore valide
      if (!_context!.mounted) {
        print('❌ Context non monté, navigation annulée');
        return;
      }

      // Navigation sécurisée avec gestion d'erreur
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_context != null && _context!.mounted) {
          try {
            Navigator.of(_context!)
                .pushNamed('/share', arguments: {'token': shareToken})
                .then((_) {
                  if (_context != null) {
                    updateContext(_context!);
                  }
                })
                .catchError((error) {
                  print('❌ Erreur navigation pushNamed: $error');
                  // Fallback: navigation directe
                  _fallbackNavigation(shareToken);
                });

            // Message de succès différé
            Future.delayed(const Duration(milliseconds: 1000), () {
              if (_context != null && _context!.mounted) {
                SmartSnackBarManager.showSuccessSnackBar(
                  _context!,
                  'Invitation reçue !',
                  duration: const Duration(seconds: 2),
                );
              }
            });
          } catch (e) {
            print('❌ Erreur lors de la navigation: $e');
            _fallbackNavigation(shareToken);
          }
        }
      });
    } catch (e) {
      print('❌ Erreur navigation générale: $e');
      _showError('Erreur lors de l\'ouverture de l\'invitation');
    }
  }

  /// Navigation de fallback en cas d'échec de la route nommée
  static void _fallbackNavigation(String shareToken) {
    if (_context == null || !_context!.mounted) return;

    try {
      print('🔄 Tentative navigation fallback');

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
          .catchError((error) {
            print('❌ Erreur navigation fallback: $error');
            _showError('Impossible d\'ouvrir l\'invitation');
          });
    } catch (e) {
      print('❌ Erreur navigation fallback: $e');
      _showError('Erreur lors de l\'ouverture de l\'invitation');
    }
  }

  static void updateContext(BuildContext context) {
    print('🔄 Mise à jour du contexte');
    _context = context;

    // Traiter les liens en attente seulement si le contexte est valide
    if (context.mounted) {
      _processPendingLink();
    }

    // Réinitialiser les liens si nécessaire
    if (_linkSubscription == null) {
      print('🔄 Réinitialisation des liens');
      _initializeDeepLinks();
    }
  }

  static void _handleDeepLink(String link) {
    print('🔄 Traitement du lien: $link');

    // Éviter les traitements multiples du même lien
    if (_isProcessing) {
      print('⏳ Traitement en cours, lien ignoré');
      return;
    }

    _isProcessing = true;

    try {
      final uri = Uri.parse(link);

      if (_isShareLink(uri)) {
        print('✅ Lien de partage détecté');
        _handleShareLink(uri);
      } else {
        print('⚠️ Lien non reconnu: ${uri.toString()}');
      }
    } catch (e) {
      print('❌ Erreur parsing lien: $e');
    } finally {
      // Réinitialiser le flag après un délai
      Future.delayed(const Duration(seconds: 2), () {
        _isProcessing = false;
      });
    }
  }

  static bool _isProcessing = false;

  static bool _isShareLink(Uri uri) {
    bool isValidScheme = false;
    bool isValidPath = false;

    // ✅ GESTION DES LIENS DIRECTS epilist://share/token
    if (uri.scheme == appScheme) {
      isValidScheme = true;
      if (uri.host == 'share' && uri.pathSegments.isNotEmpty) {
        isValidPath = true;
        print('📱 Lien direct app détecté: ${uri.toString()}');
      }
    }
    // ✅ GESTION DES LIENS HTTPS https://epilist.app/share/token
    else if (uri.scheme == 'https' && uri.host == customDomain) {
      isValidScheme = true;
      if (uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'share') {
        isValidPath = true;
        print('🌐 Lien web détecté: ${uri.toString()}');
      }
    }

    final isValid = isValidScheme && isValidPath;
    print(
      '🔍 Validation lien: scheme=$isValidScheme, path=$isValidPath, result=$isValid',
    );

    return isValid;
  }

  static Future<void> _getInitialLink() async {
    try {
      final Uri? initialUri = await _appLinks!.getInitialLink();
      if (initialUri != null) {
        print('🚀 Lien initial détecté: ${initialUri.toString()}');
        _handleDeepLink(initialUri.toString());
      } else {
        print('ℹ️ Aucun lien initial');
      }
    } catch (e) {
      print('❌ Erreur récupération lien initial: $e');
    }
  }

  static void _handleShareLink(Uri uri) {
    try {
      String? shareToken;

      // Extraction du token selon le format du lien
      if (uri.scheme == appScheme) {
        // Format: epilist://share/TOKEN
        if (uri.host == 'share' && uri.pathSegments.isNotEmpty) {
          shareToken = uri.pathSegments[0];
          print('📱 Token extrait du lien direct: $shareToken');
        }
      } else if (uri.scheme == 'https' && uri.host == customDomain) {
        // Format: https://epilist.app/share/TOKEN
        if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'share') {
          shareToken = uri.pathSegments[1];
          print('🌐 Token extrait du lien web: $shareToken');
        }
      }

      // Fallback: chercher dans les query parameters
      if ((shareToken == null || shareToken.isEmpty) &&
          uri.queryParameters.containsKey('token')) {
        shareToken = uri.queryParameters['token'];
        print('🔍 Token extrait des paramètres: $shareToken');
      }

      if (shareToken == null || shareToken.isEmpty) {
        print('❌ Token manquant dans le lien');
        _showError('Lien de partage invalide');
        return;
      }

      if (_context == null) {
        print('⏳ Contexte non disponible, token en attente: $shareToken');
        _pendingShareToken = shareToken;
        return;
      }

      print('✅ Token validé: $shareToken');
      _checkAuthAndNavigate(shareToken);
    } catch (e) {
      print('❌ Erreur traitement lien de partage: $e');
      _showError('Erreur lors du traitement du lien de partage');
    }
  }

  static void _processPendingLink() {
    if (_pendingShareToken != null && _context != null) {
      print('🔄 Traitement token en attente: $_pendingShareToken');
      final token = _pendingShareToken!;
      _pendingShareToken = null;

      Future.delayed(const Duration(milliseconds: 500), () {
        _checkAuthAndNavigate(token);
      });
    }
  }

  static Future<void> _checkAuthAndNavigate(String shareToken) async {
    if (_context == null) {
      print('❌ Contexte non disponible pour vérification auth');
      return;
    }

    try {
      print('🔐 Vérification authentification...');
      final authService = _context!.read<AuthService>();
      final isAuthenticated = await authService.isAuthenticated();

      if (isAuthenticated) {
        print('✅ Utilisateur authentifié, navigation directe');
        _navigateToShareInvitation(shareToken);
      } else {
        print('🔒 Utilisateur non authentifié, redirection login');
        _redirectToLoginWithToken(shareToken);
      }
    } catch (e) {
      print('❌ Erreur vérification auth: $e');
      _redirectToLoginWithToken(shareToken);
    }
  }

  static void _redirectToLoginWithToken(String shareToken) {
    if (_context == null) return;

    _pendingShareToken = shareToken;
    print('🔄 Redirection vers login avec token: $shareToken');

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
        print('✅ Authentification réussie, navigation vers invitation');
        final token = _pendingShareToken!;
        _pendingShareToken = null;

        Future.delayed(const Duration(milliseconds: 1000), () {
          _navigateToShareInvitation(token);
        });

        authSubscription.cancel();
      }
    });

    Future.delayed(const Duration(minutes: 5), () {
      print('⏰ Timeout écoute auth, nettoyage');
      authSubscription.cancel();
      _pendingShareToken = null;
    });
  }

  static void forceReinitialize() {
    print('🔄 Réinitialisation forcée des deep links');
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
      print('🎯 Traitement token après login: $_pendingShareToken');
      final token = _pendingShareToken!;
      _pendingShareToken = null;

      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateToShareInvitation(token);
      });
    }
  }

  // ✅ MÉTHODES POUR LIENS DIRECTS (SOLUTION 1)

  /// Génère un lien DIRECT qui ouvre automatiquement l'app
  static String generateDirectAppUrl(String token) {
    final directUrl = '$appScheme://share/$token';
    print('📱 Lien direct généré: $directUrl');
    return directUrl;
  }

  /// Génère un lien web (avec demande Safari)
  static String generateWebShareUrl(String token) {
    final webUrl = 'https://$customDomain/share/$token';
    print('🌐 Lien web généré: $webUrl');
    return webUrl;
  }

  /// DEPRECATED: Utilisez generateDirectAppUrl() à la place
  @deprecated
  static String generateAppShareUrl(String token) {
    return generateDirectAppUrl(token);
  }

  /// COMPATIBILITÉ: Méthode pour backward compatibility
  static Map<String, String> generateShareData(
    String token,
    String listName,
    String ownerName,
  ) {
    return generateDirectShareData(token, listName, ownerName);
  }

  /// Génère les données de partage OPTIMISÉES pour ouverture directe
  static Map<String, String> generateDirectShareData(
    String token,
    String listName,
    String ownerName,
  ) {
    final directUrl = generateDirectAppUrl(token);
    final webUrl = generateWebShareUrl(token);

    return {
      'directUrl': directUrl, // Lien principal (direct)
      'webUrl': webUrl, // Lien de fallback
      'title': 'Invitation EpiList - $listName',
      'text': '''🛒 $ownerName vous invite sur "$listName"

📱 Lien direct EpiList (recommandé) :
$directUrl

🌐 Ou via navigateur :
$webUrl

Le lien direct ouvrira automatiquement l'app !''',
      'subject': 'Invitation à partager une liste d\'épicerie - EpiList',
    };
  }

  /// Méthode de partage optimisée (utilise le lien direct)
  static String createOptimizedShareMessage(
    String token,
    String listName,
    String ownerName,
  ) {
    final directUrl = generateDirectAppUrl(token);

    return '''🛒 $ownerName vous invite sur "$listName"

📱 Cliquez pour ouvrir EpiList :
$directUrl

L'app s'ouvrira automatiquement !''';
  }

  /// Ouvre directement l'app ou redirige vers le store
  static Future<void> openAppOrStore(String shareToken) async {
    final appUrl = generateDirectAppUrl(shareToken);
    print('🚀 Tentative ouverture app: $appUrl');

    try {
      final bool launched = await launchUrl(
        Uri.parse(appUrl),
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        print('✅ App ouverte avec succès');
      } else {
        print('⚠️ App non ouverte, redirection store');
        await _openStore();
      }
    } catch (e) {
      print('❌ Erreur ouverture app: $e');
      await _openStore();
    }
  }

  static Future<void> _openStore() async {
    try {
      // Détection de la plateforme et ouverture du bon store
      await launchUrl(
        Uri.parse(playStoreUrl), // Adaptez selon la plateforme
        mode: LaunchMode.externalApplication,
      );
      print('✅ Store ouvert');
    } catch (e) {
      print('❌ Erreur ouverture store: $e');
    }
  }

  // MÉTHODES UTILITAIRES DE VALIDATION

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

  // MÉTHODES DE DEBUG

  static void debugPrintStatus() {
    print('\n=== DEBUG DEEP LINK HANDLER ===');
    print('Context available: ${_context != null}');
    print('Pending token: $_pendingShareToken');
    print('Subscription active: ${_linkSubscription != null}');
    print('AppLinks initialized: ${_appLinks != null}');
    print('================================\n');
  }

  static void testDirectLink(String token) {
    final directUrl = generateDirectAppUrl(token);
    print('🧪 Test lien direct: $directUrl');
    _handleDeepLink(directUrl);
  }
}
