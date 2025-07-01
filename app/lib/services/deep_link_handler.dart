// services/deep_link_handler.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:epilist/screens/share_invitation_screen.dart';
import 'package:epilist/services/shared_list_service.dart';
import 'dart:async';

// 🔄 Remplacé uni_links3 par app_links
import 'package:app_links/app_links.dart';

class DeepLinkHandler {
  static StreamSubscription<Uri>? _linkSubscription;
  static BuildContext? _context;
  static AppLinks? _appLinks;

  // 🌐 Configuration du domaine personnalisé
  static const String customDomain = 'epilist.app';
  static const String appScheme = 'epilist';

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
        // Attendre que le contexte soit disponible
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
    debugPrint('🔍 Query: ${uri.queryParameters}');

    // Gérer les liens de partage de liste
    if (_isShareLink(uri)) {
      _handleShareLink(uri);
    } else {
      debugPrint('⚠️ Type de lien non reconnu: $link');
    }
  }

  static bool _isShareLink(Uri uri) {
    // Vérifier si c'est un lien de partage
    // Formats supportés:
    // - https://epilist.app/share/{token}
    // - https://epilist.app/share?token={token}
    // - epilist://share/{token}
    // - epilist://share?token={token}

    return (
        // Liens HTTPS avec domaine personnalisé
        (uri.scheme == 'https' && uri.host == customDomain) ||
            // Liens avec scheme personnalisé
            uri.scheme == appScheme) &&
        (
        // Path contient 'share'
        (uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'share') ||
            // Ou c'est un lien direct vers share
            uri.path.startsWith('/share') ||
            // Ou c'est un lien avec query parameter
            uri.queryParameters.containsKey('token'));
  }

  static void _handleShareLink(Uri uri) {
    try {
      // Extraire le token de partage
      String? shareToken;

      // Pour https://epilist.app/share/{token} ou epilist://share/{token}
      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'share') {
        shareToken = uri.pathSegments[1];
      }
      // Pour https://epilist.app/share?token={token} ou epilist://share?token={token}
      else if (uri.queryParameters.containsKey('token')) {
        shareToken = uri.queryParameters['token'];
      }
      // Pour https://epilist.app/?token={token} (lien direct)
      else if (uri.path == '/' && uri.queryParameters.containsKey('token')) {
        shareToken = uri.queryParameters['token'];
      }

      if (shareToken == null || shareToken.isEmpty) {
        _showError('Lien de partage invalide');
        return;
      }

      debugPrint('🎯 Token de partage extrait: $shareToken');

      // Naviguer vers l'écran d'invitation
      _navigateToShareInvitation(shareToken);
    } catch (e) {
      debugPrint('❌ Erreur lors du traitement du lien de partage: $e');
      _showError('Erreur lors du traitement du lien de partage');
    }
  }

  static void _navigateToShareInvitation(String shareToken) {
    if (_context == null) return;

    // Vérifier si l'utilisateur est connecté
    // Si ce n'est pas le cas, vous pourriez vouloir rediriger vers l'écran de connexion
    // et stocker le token pour après la connexion

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

  // 🆕 Méthodes pour générer des liens avec le domaine personnalisé

  /// Génère un lien de partage pour le web (avec fallback vers Play Store)
  static String generateWebShareUrl(String token) {
    return 'https://$customDomain/share/$token';
  }

  /// Génère un lien de partage pour l'application (schema personnalisé)
  static String generateAppShareUrl(String token) {
    return '$appScheme://share/$token';
  }

  /// Génère un lien universel qui fonctionne pour les deux
  static String generateUniversalShareUrl(String token) {
    // Utiliser le domaine web avec paramètres pour le fallback
    return 'https://$customDomain/share?token=$token';
  }

  /// Génère un lien de partage complet avec métadonnées
  static Map<String, String> generateShareData(
    String token,
    String listName,
    String ownerName,
  ) {
    final shareUrl = generateUniversalShareUrl(token);

    return {
      'url': shareUrl,
      'title': 'Invitation EpiList',
      'text': '$ownerName vous invite à collaborer sur la liste "$listName"',
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

      // Pour https://epilist.app/share/{token} ou epilist://share/{token}
      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'share') {
        return uri.pathSegments[1];
      }
      // Pour les liens avec query parameter
      else if (uri.queryParameters.containsKey('token')) {
        return uri.queryParameters['token'];
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // 🆕 Méthode pour générer le HTML de la page de fallback
  static String generateFallbackPageHtml(
    String token,
    String listName,
    String ownerName,
  ) {
    return '''
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Invitation EpiList - $listName</title>
    <meta name="description" content="$ownerName vous invite à collaborer sur la liste d'épicerie $listName">
    
    <!-- Open Graph pour le partage social -->
    <meta property="og:title" content="Invitation EpiList - $listName">
    <meta property="og:description" content="$ownerName vous invite à collaborer sur cette liste d'épicerie">
    <meta property="og:type" content="website">
    <meta property="og:url" content="https://$customDomain/share/$token">
    
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 0; 
            padding: 20px; 
            background: #f5f5f5;
            text-align: center;
        }
        .container { 
            max-width: 400px; 
            margin: 50px auto; 
            background: white; 
            padding: 30px; 
            border-radius: 12px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .logo { 
            font-size: 24px; 
            font-weight: bold; 
            color: #4CAF50; 
            margin-bottom: 20px;
        }
        .invite-text { 
            margin: 20px 0; 
            color: #333;
            line-height: 1.5;
        }
        .app-button { 
            display: inline-block; 
            background: #4CAF50; 
            color: white; 
            padding: 12px 24px; 
            text-decoration: none; 
            border-radius: 6px; 
            margin: 10px;
            font-weight: bold;
        }
        .store-button {
            background: #2196F3;
        }
        .fallback-link {
            margin-top: 20px;
            font-size: 14px;
            color: #666;
        }
    </style>
    
    <script>
        // Tentative d'ouverture automatique de l'app
        function tryOpenApp() {
            const appUrl = '$appScheme://share/$token';
            const fallbackUrl = 'https://play.google.com/store/apps/details?id=com.m2atech.epilist';
            
            // Tenter d'ouvrir l'app
            const iframe = document.createElement('iframe');
            iframe.style.display = 'none';
            iframe.src = appUrl;
            document.body.appendChild(iframe);
            
            // Fallback vers le Play Store après 2 secondes
            setTimeout(() => {
                window.location.href = fallbackUrl;
            }, 2000);
        }
        
        // Auto-redirection sur mobile
        if (/Android|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)) {
            setTimeout(tryOpenApp, 1000);
        }
    </script>
</head>
<body>
    <div class="container">
        <div class="logo">📱 EpiList</div>
        <h2>Invitation de partage</h2>
        <div class="invite-text">
            <strong>$ownerName</strong> vous invite à collaborer sur la liste d'épicerie 
            <strong>"$listName"</strong>
        </div>
        
        <a href="$appScheme://share/$token" class="app-button">
            Ouvrir dans EpiList
        </a>
        
        <br>
        
        <a href="https://play.google.com/store/apps/details?id=com.m2atech.epilist" class="app-button store-button">
            Télécharger EpiList
        </a>
        
        <div class="fallback-link">
            <small>
                Si vous avez déjà l'application, elle devrait s'ouvrir automatiquement.
                <br>Sinon, téléchargez l'application et utilisez ce lien.
            </small>
        </div>
    </div>
</body>
</html>
    ''';
  }
}
