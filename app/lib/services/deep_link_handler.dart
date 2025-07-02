// services/deep_link_handler.dart - VERSION AVEC VOTRE DOMAINE
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:epilist/screens/share_invitation_screen.dart';
import 'package:epilist/services/shared_list_service.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';

class DeepLinkHandler {
  static StreamSubscription<Uri>? _linkSubscription;
  static BuildContext? _context;
  static AppLinks? _appLinks;

  // ✅ VOTRE DOMAINE RÉEL
  static const String customDomain = 'epilist.app'; // ✅ Votre domaine Vercel
  static const String appScheme = 'epilist';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.m2atech.epilist';
  static const String appStoreUrl =
      'https://apps.apple.com/app/epilist/id123456789';

  // Initialiser le gestionnaire de liens profonds
  static void initialize(BuildContext context) {
    _context = context;
    _appLinks = AppLinks();
    _initializeDeepLinks();
  }

  // Nettoyer les ressources
  static void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _context = null;
    _appLinks = null;
  }

  static void _initializeDeepLinks() {
    // Écouter les liens entrants quand l'app est déjà ouverte
    _linkSubscription = _appLinks!.uriLinkStream.listen(
      (Uri uri) {
        debugPrint('🔗 Lien reçu: ${uri.toString()}');
        _handleDeepLink(uri.toString());
      },
      onError: (err) {
        debugPrint('❌ Erreur de lien profond: $err');
      },
    );

    // Gérer le lien initial (quand l'app s'ouvre via un lien)
    _getInitialLink();
  }

  static Future<void> _getInitialLink() async {
    try {
      final Uri? initialUri = await _appLinks!.getInitialLink();
      if (initialUri != null) {
        debugPrint('🔗 Lien initial: ${initialUri.toString()}');
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleDeepLink(initialUri.toString());
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération du lien initial: $e');
    }
  }

  static void _handleDeepLink(String link) {
    if (_context == null) {
      debugPrint('❌ Contexte non disponible pour gérer le lien');
      return;
    }

    final uri = Uri.parse(link);
    debugPrint('🔍 URI parsée: ${uri.toString()}');
    debugPrint('🔍 Scheme: ${uri.scheme}');
    debugPrint('🔍 Host: ${uri.host}');
    debugPrint('🔍 Path: ${uri.path}');

    // ✅ Gérer les liens avec schéma personnalisé ET domaine web
    if (_isShareLink(uri)) {
      _handleShareLink(uri);
    } else {
      debugPrint('⚠️ Type de lien non reconnu: $link');
    }
  }

  static bool _isShareLink(Uri uri) {
    debugPrint('🔍 Vérification du lien de partage...');
    debugPrint('🔍 Scheme: ${uri.scheme}, Host: ${uri.host}');
    debugPrint('🔍 Path segments: ${uri.pathSegments}');

    // ✅ Accepter les deux formats :
    // 1. epilist://share/token (schéma personnalisé)
    // 2. https://epilist.app/share/token (domaine web)
    bool isValidScheme =
        uri.scheme == appScheme ||
        (uri.scheme == 'https' && uri.host == customDomain);

    bool isValidPath =
        uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'share';

    debugPrint('🔍 Scheme valide: $isValidScheme');
    debugPrint('🔍 Path valide: $isValidPath');

    return isValidScheme && isValidPath;
  }

  static void _handleShareLink(Uri uri) {
    try {
      String? shareToken;

      // ✅ Extraction du token pour les deux formats
      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'share') {
        shareToken = uri.pathSegments[1];
      } else if (uri.queryParameters.containsKey('token')) {
        shareToken = uri.queryParameters['token'];
      }

      if (shareToken == null || shareToken.isEmpty) {
        _showError('Lien de partage invalide');
        return;
      }

      debugPrint('🎯 Token de partage extrait: $shareToken');
      _navigateToShareInvitation(shareToken);
    } catch (e) {
      debugPrint('❌ Erreur lors du traitement du lien de partage: $e');
      _showError('Erreur lors du traitement du lien de partage');
    }
  }

  static void _navigateToShareInvitation(String shareToken) {
    if (_context == null) return;

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

  // ✅ MÉTHODES POUR GÉNÉRER LES LIENS

  /// Génère un lien web avec votre domaine (utilisé pour le partage)
  static String generateWebShareUrl(String token) {
    return 'https://$customDomain/share/$token';
  }

  /// Génère un lien de partage avec schéma personnalisé (fallback)
  static String generateAppShareUrl(String token) {
    return '$appScheme://share/$token';
  }

  /// Génère les données de partage pour réseaux sociaux
  static Map<String, String> generateShareData(
    String token,
    String listName,
    String ownerName,
  ) {
    final shareUrl = generateWebShareUrl(token); // ✅ Utilise le domaine web

    return {
      'url': shareUrl,
      'title': 'Invitation EpiList - $listName',
      'text':
          '$ownerName vous invite à collaborer sur la liste "$listName".\n\n'
          'Cliquez sur le lien pour ouvrir l\'app ou la télécharger :\n$shareUrl',
      'subject': 'Invitation à partager une liste d\'épicerie',
    };
  }

  // Méthode pour tester si un lien est valide
  static bool isValidShareLink(String link) {
    try {
      final uri = Uri.parse(link);
      return _isShareLink(uri);
    } catch (e) {
      return false;
    }
  }

  // Méthode pour extraire le token d'un lien
  static String? extractTokenFromLink(String link) {
    try {
      final uri = Uri.parse(link);
      if (!_isShareLink(uri)) return null;

      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'share') {
        return uri.pathSegments[1];
      } else if (uri.queryParameters.containsKey('token')) {
        return uri.queryParameters['token'];
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Méthode pour ouvrir l'app ou rediriger vers le store
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
