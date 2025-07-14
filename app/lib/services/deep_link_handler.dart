// services/deep_link_handler.dart - VERSION AVEC SNACKBARS MINIMAUX
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart';
import 'package:epilist/screens/share_invitation_screen.dart';
import 'package:epilist/screens/login_screen.dart';
import 'package:epilist/services/shared_list_service.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:epilist/services/connectivity_service.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/connectivity/connectivity_wrapper.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';

class DeepLinkHandler {
  static StreamSubscription<Uri>? _linkSubscription;
  static BuildContext? _context;
  static AppLinks? _appLinks;
  static String? _pendingShareToken;

  // Système de protection contre les redirections multiples
  static bool _isProcessing = false;
  static bool _isNavigating = false;
  static String? _lastProcessedToken;
  static DateTime? _lastProcessTime;
  static StreamSubscription? _authSubscription;

  static const String customDomain = 'epilist.app';
  static const String appScheme = 'epilist';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.m2atech.epilist';
  static const String appStoreUrl =
      'https://apps.apple.com/ca/app/epilist/id6748285596';

  // Vérifier la connectivité avant toute action réseau
  static Future<bool> _checkConnectivity() async {
    try {
      return await ConnectivityService().checkConnectivity();
    } catch (e) {
      print('❌ Erreur vérification connectivité: $e');
      return false;
    }
  }

  // Gérer les actions nécessitant une connexion
  static Future<void> _requireConnection(VoidCallback onConnected) async {
    if (_context == null) {
      print('❌ Context non disponible pour vérification connectivité');
      return;
    }

    final isConnected = await _checkConnectivity();
    if (isConnected) {
      onConnected();
    } else {
      print('❌ Aucune connexion - Invitation en attente');
      // Pas de SnackBar - gestion silencieuse ou via l'UI de connectivité
    }
  }

  static bool _shouldIgnoreToken(String token) {
    if (_lastProcessedToken == token && _lastProcessTime != null) {
      final timeDiff = DateTime.now().difference(_lastProcessTime!);
      if (timeDiff.inSeconds < 5) {
        print('⏭️ Token ignoré (traité récemment): $token');
        return true;
      }
    }
    return false;
  }

  static void _markTokenAsProcessed(String token) {
    _lastProcessedToken = token;
    _lastProcessTime = DateTime.now();
  }

  static String _getTranslatedMessage(String key) {
    if (_context == null) {
      const Map<String, String> fallbacks = {
        'auth_success_navigation':
            'Authentification réussie, navigation vers invitation',
      };
      return fallbacks[key] ?? 'Message non disponible';
    }

    final l10n = AppLocalizations.of(_context!)!;
    switch (key) {
      case 'auth_success_navigation':
        return l10n.authSuccessNavigation ??
            'Authentification réussie, navigation vers invitation';
      default:
        return 'Message non disponible';
    }
  }

  static void dispose() {
    print('🧹 Nettoyage complet du DeepLinkHandler');
    _linkSubscription?.cancel();
    _authSubscription?.cancel();
    _linkSubscription = null;
    _authSubscription = null;
    _context = null;
    _appLinks = null;
    _pendingShareToken = null;
    _isProcessing = false;
    _isNavigating = false;
    _lastProcessedToken = null;
    _lastProcessTime = null;
  }

  static void initialize(BuildContext context) {
    if (_isProcessing) {
      print('⏳ Initialisation déjà en cours, ignorée');
      return;
    }

    print('🚀 Initialisation DeepLinkHandler');
    _context = context;

    if (_appLinks == null) {
      _appLinks = AppLinks();
    }

    _initializeDeepLinks();
    _processPendingLink();
  }

  static void _initializeDeepLinks() {
    // Protection: Ne pas réinitialiser si déjà actif
    if (_linkSubscription != null) {
      print('🔄 Subscription déjà active');
      return;
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

  // Navigation avec wrapper de connectivité
  static void _navigateToShareInvitation(String shareToken) {
    // Protection contre les navigations multiples
    if (_isNavigating) {
      print('🚫 Navigation déjà en cours, ignorée');
      return;
    }

    if (_context == null || !_context!.mounted) {
      print('❌ Context non disponible pour navigation');
      return;
    }

    _isNavigating = true;

    try {
      print('🎯 Navigation vers ShareInvitationScreen avec token: $shareToken');

      // Navigation avec ConnectivityWrapper pour éviter les conflits
      Navigator.of(_context!).pushAndRemoveUntil(
        MaterialPageRoute(
          builder:
              (context) => ConnectivityWrapper(
                showOfflineBanner: true,
                blockActionsWhenOffline: true,
                onConnectivityLost: () {
                  print('❌ Connexion perdue durant l\'invitation');
                  // Gestion silencieuse via le wrapper
                },
                onConnectivityRestored: () {
                  print('✅ Connexion rétablie durant l\'invitation');
                },
                child: BlocProvider(
                  create:
                      (context) => SharedListBloc(
                        sharedListService: context.read<SharedListService>(),
                        localizationBloc: context.read<LocalizationBloc>(),
                      ),
                  child: ShareInvitationScreen(shareToken: shareToken),
                ),
              ),
        ),
        (route) => route.settings.name == '/' || route.isFirst,
      );

      // Pas de message de succès - l'écran d'invitation se charge de l'affichage
    } catch (e) {
      print('❌ Erreur navigation: $e');
      // Pas de SnackBar - erreur loggée seulement
    } finally {
      // Réinitialiser le flag avec délai
      Future.delayed(const Duration(seconds: 3), () {
        _isNavigating = false;
      });
    }
  }

  static void updateContext(BuildContext context) {
    // Protection: Éviter les mises à jour trop fréquentes
    if (_isProcessing || _isNavigating) {
      print('⏳ Update context ignoré (traitement en cours)');
      return;
    }

    print('🔄 Mise à jour du contexte');
    _context = context;

    // Traiter les liens en attente seulement si le contexte est valide et stable
    if (context.mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isProcessing && !_isNavigating) {
          _processPendingLink();
        }
      });
    }

    // Réinitialiser les liens seulement si nécessaire
    if (_linkSubscription == null && _appLinks == null) {
      print('🔄 Réinitialisation des liens');
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!_isProcessing) {
          _initializeDeepLinks();
        }
      });
    }
  }

  static void _handleDeepLink(String link) {
    print('🔄 Traitement du lien: $link');

    // Protection contre les traitements multiples
    if (_isProcessing || _isNavigating) {
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
      // Réinitialiser le flag avec délai
      Future.delayed(const Duration(seconds: 2), () {
        _isProcessing = false;
      });
    }
  }

  static bool _isShareLink(Uri uri) {
    bool isValidScheme = false;
    bool isValidPath = false;

    if (uri.scheme == appScheme) {
      isValidScheme = true;
      if (uri.host == 'share' && uri.pathSegments.isNotEmpty) {
        isValidPath = true;
        print('📱 Lien direct app détecté: ${uri.toString()}');
      }
    } else if (uri.scheme == 'https' && uri.host == customDomain) {
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
        // Délai pour éviter les conflits avec l'initialisation
        Future.delayed(const Duration(milliseconds: 1000), () {
          _handleDeepLink(initialUri.toString());
        });
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

      if (uri.scheme == appScheme) {
        if (uri.host == 'share' && uri.pathSegments.isNotEmpty) {
          shareToken = uri.pathSegments[0];
          print('📱 Token extrait du lien direct: $shareToken');
        }
      } else if (uri.scheme == 'https' && uri.host == customDomain) {
        if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'share') {
          shareToken = uri.pathSegments[1];
          print('🌐 Token extrait du lien web: $shareToken');
        }
      }

      if ((shareToken == null || shareToken.isEmpty) &&
          uri.queryParameters.containsKey('token')) {
        shareToken = uri.queryParameters['token'];
        print('🔍 Token extrait des paramètres: $shareToken');
      }

      if (shareToken == null || shareToken.isEmpty) {
        print('❌ Token manquant dans le lien');
        // Pas de SnackBar - erreur loggée seulement
        return;
      }

      // Protection: Vérifier si ce token a été traité récemment
      if (_shouldIgnoreToken(shareToken)) {
        return;
      }

      // Marquer comme traité
      _markTokenAsProcessed(shareToken);

      if (_context == null) {
        print('⏳ Contexte non disponible, token en attente: $shareToken');
        _pendingShareToken = shareToken;
        return;
      }

      print('✅ Token validé: $shareToken');

      // Vérifier connectivité avant de procéder
      _requireConnection(() {
        _checkAuthAndNavigate(shareToken!);
      });
    } catch (e) {
      print('❌ Erreur traitement lien de partage: $e');
      // Pas de SnackBar - erreur loggée seulement
    }
  }

  static void _processPendingLink() {
    if (_pendingShareToken != null &&
        _context != null &&
        !_isProcessing &&
        !_isNavigating) {
      print('🔄 Traitement token en attente: $_pendingShareToken');
      final token = _pendingShareToken!;
      _pendingShareToken = null;

      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isProcessing && !_isNavigating) {
          // Vérifier connectivité pour les tokens en attente
          _requireConnection(() {
            _checkAuthAndNavigate(token);
          });
        }
      });
    }
  }

  static Future<void> _checkAuthAndNavigate(String shareToken) async {
    if (_context == null || _isNavigating) {
      print('❌ Contexte non disponible ou navigation en cours');
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

  // Redirection login avec wrapper de connectivité
  static void _redirectToLoginWithToken(String shareToken) {
    if (_context == null || _isNavigating) return;

    _pendingShareToken = shareToken;
    print('🔄 Redirection vers login avec token: $shareToken');

    // Pas de SnackBar - redirection silencieuse
    Navigator.of(_context!).pushAndRemoveUntil(
      MaterialPageRoute(
        builder:
            (context) => ConnectivityWrapper(
              showOfflineBanner: true,
              blockActionsWhenOffline: true,
              child: const LoginScreen(),
            ),
      ),
      (route) => false,
    );

    _listenForAuthChanges();
  }

  static void _listenForAuthChanges() {
    if (_context == null || _authSubscription != null) return;

    final authBloc = _context!.read<AuthBloc>();

    _authSubscription = authBloc.stream.listen((state) {
      if (state is AuthSuccess &&
          _pendingShareToken != null &&
          !_isNavigating) {
        print('✅ ${_getTranslatedMessage('auth_success_navigation')}');
        final token = _pendingShareToken!;
        _pendingShareToken = null;

        // Vérifier connectivité après authentification
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!_isNavigating) {
            _requireConnection(() {
              _navigateToShareInvitation(token);
            });
          }
        });

        // Nettoyer la subscription
        _authSubscription?.cancel();
        _authSubscription = null;
      }
    });

    // Timeout pour la subscription
    Future.delayed(const Duration(minutes: 10), () {
      print('⏰ Timeout écoute auth, nettoyage');
      _authSubscription?.cancel();
      _authSubscription = null;
      _pendingShareToken = null;
    });
  }

  static void forceReinitialize() {
    print('🔄 Réinitialisation forcée des deep links');

    // Nettoyer complètement avant de réinitialiser
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _appLinks = null;
    _isProcessing = false;
    _isNavigating = false;

    if (_context != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isProcessing) {
          _appLinks = AppLinks();
          _initializeDeepLinks();
        }
      });
    }
  }

  static void processPendingTokenAfterLogin() {
    if (_pendingShareToken != null && _context != null && !_isNavigating) {
      print('🎯 Traitement token après login: $_pendingShareToken');
      final token = _pendingShareToken!;
      _pendingShareToken = null;

      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!_isNavigating) {
          // Vérifier connectivité après login
          _requireConnection(() {
            _navigateToShareInvitation(token);
          });
        }
      });
    }
  }

  // MÉTHODES POUR LIENS DIRECTS (inchangées)

  static String generateDirectAppUrl(String token) {
    final directUrl = '$appScheme://share/$token';
    print('📱 Lien direct généré: $directUrl');
    return directUrl;
  }

  static String generateWebShareUrl(String token) {
    final webUrl = 'https://$customDomain/share/$token';
    print('🌐 Lien web généré: $webUrl');
    return webUrl;
  }

  @deprecated
  static String generateAppShareUrl(String token) {
    return generateDirectAppUrl(token);
  }

  static Map<String, String> generateShareData(
    String token,
    String listName,
    String ownerName,
  ) {
    return generateDirectShareData(token, listName, ownerName);
  }

  static Map<String, String> generateDirectShareData(
    String token,
    String listName,
    String ownerName,
  ) {
    final directUrl = generateDirectAppUrl(token);
    final webUrl = generateWebShareUrl(token);

    final invitationTitle =
        _context != null
            ? '${AppLocalizations.of(_context!)!.invitationEpiList ?? 'Invitation EpiList'} - $listName'
            : 'Invitation EpiList - $listName';

    final invitationText =
        _context != null && AppLocalizations.of(_context!) != null
            ? _getLocalizedInvitationText(
              ownerName,
              listName,
              directUrl,
              webUrl,
            )
            : _getFallbackInvitationText(
              ownerName,
              listName,
              directUrl,
              webUrl,
            );

    final invitationSubject =
        _context != null
            ? AppLocalizations.of(_context!)!.invitationSubject ??
                'Invitation à partager une liste d\'épicerie - EpiList'
            : 'Invitation à partager une liste d\'épicerie - EpiList';

    return {
      'directUrl': directUrl,
      'webUrl': webUrl,
      'title': invitationTitle,
      'text': invitationText,
      'subject': invitationSubject,
    };
  }

  static String _getLocalizedInvitationText(
    String ownerName,
    String listName,
    String directUrl,
    String webUrl,
  ) {
    final l10n = AppLocalizations.of(_context!)!;
    final message =
        l10n.invitationMessage?.call(ownerName, listName) ??
        l10n.invitationMessage ??
        '$ownerName vous invite sur "$listName"';

    return '''🛒 $message

📱 ${l10n.directLinkRecommended ?? 'Lien direct EpiList (recommandé)'} :
$directUrl

🌐 ${l10n.orViaBrowser ?? 'Ou via navigateur'} :
$webUrl

${l10n.directLinkAutoOpen ?? 'Le lien direct ouvrira automatiquement l\'app !'}''';
  }

  static String _getFallbackInvitationText(
    String ownerName,
    String listName,
    String directUrl,
    String webUrl,
  ) {
    return '''🛒 $ownerName vous invite sur "$listName"

📱 Lien direct EpiList (recommandé) :
$directUrl

🌐 Ou via navigateur :
$webUrl

Le lien direct ouvrira automatiquement l'app !''';
  }

  static String createOptimizedShareMessage(
    String token,
    String listName,
    String ownerName,
  ) {
    final directUrl = generateDirectAppUrl(token);

    if (_context != null && AppLocalizations.of(_context!) != null) {
      final l10n = AppLocalizations.of(_context!)!;
      return '''🛒 ${l10n.invitationMessage(ownerName, listName)}

📱 ${l10n.clickToOpenEpiList ?? 'Cliquez pour ouvrir EpiList'} :
$directUrl

${l10n.appWillOpenAutomatically ?? 'L\'app s\'ouvrira automatiquement !'}''';
    }

    return '''🛒 $ownerName vous invite sur "$listName"

📱 Cliquez pour ouvrir EpiList :
$directUrl

L'app s'ouvrira automatiquement !''';
  }

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
      await launchUrl(
        Uri.parse(playStoreUrl),
        mode: LaunchMode.externalApplication,
      );
      print('✅ Store ouvert');
    } catch (e) {
      print('❌ Erreur ouverture store: $e');
    }
  }

  // MÉTHODES UTILITAIRES DE VALIDATION (inchangées)

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
    print('Is processing: $_isProcessing');
    print('Is navigating: $_isNavigating');
    print('Last processed token: $_lastProcessedToken');
    print('Last process time: $_lastProcessTime');
    print('================================\n');
  }

  static void testDirectLink(String token) {
    final directUrl = generateDirectAppUrl(token);
    print('🧪 Test lien direct: $directUrl');
    _handleDeepLink(directUrl);
  }
}
