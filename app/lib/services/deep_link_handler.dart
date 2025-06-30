// services/deep_link_handler.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:epilist/screens/share_invitation_screen.dart';
import 'package:epilist/services/shared_list_service.dart';
import 'dart:async';

import 'package:uni_links3/uni_links.dart';

class DeepLinkHandler {
  static StreamSubscription? _linkSubscription;
  static BuildContext? _context;

  // Initialiser le gestionnaire de liens profonds
  static void initialize(BuildContext context) {
    _context = context;
    _initializeDeepLinks();
  }

  // Nettoyer les ressources
  static void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _context = null;
  }

  static void _initializeDeepLinks() {
    // Écouter les liens entrants quand l'app est déjà ouverte
    _linkSubscription = linkStream.listen(
      (String link) {
            debugPrint('🔗 Lien reçu: $link');
            _handleDeepLink(link);
          }
          as void Function(String? event)?,
      onError: (err) {
        debugPrint('❌ Erreur de lien profond: $err');
      },
    );

    // Gérer le lien initial (quand l'app s'ouvre via un lien)
    _getInitialLink();
  }

  static Future<void> _getInitialLink() async {
    try {
      final String? initialLink = await getInitialLink();
      if (initialLink != null) {
        debugPrint('🔗 Lien initial: $initialLink');
        // Attendre que le contexte soit disponible
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleDeepLink(initialLink);
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
    // - https://app.epilist.com/share/{token}
    // - epilist://share/{token}

    return (uri.host == 'epilist.app' ||
            uri.host == 'app.epilist.com' ||
            uri.scheme == 'epilist') &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments[0] == 'share';
  }

  static void _handleShareLink(Uri uri) {
    try {
      // Extraire le token de partage
      String? shareToken;

      if (uri.pathSegments.length >= 2) {
        shareToken = uri.pathSegments[1];
      } else if (uri.queryParameters.containsKey('token')) {
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

  // Méthode utilitaire pour générer des liens de partage
  static String generateShareUrl(String token) {
    return 'https://epilist.app/share/$token';
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

      if (uri.pathSegments.length >= 2) {
        return uri.pathSegments[1];
      } else if (uri.queryParameters.containsKey('token')) {
        return uri.queryParameters['token'];
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}

// Configuration des liens profonds dans Android (android/app/src/main/AndroidManifest.xml)
/*
Ajouter dans <activity android:name=".MainActivity" ...>:

<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https"
          android:host="epilist.app" />
</intent-filter>

<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https"
          android:host="app.epilist.com" />
</intent-filter>

<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="epilist" />
</intent-filter>
*/

// Configuration des liens profonds dans iOS (ios/Runner/Info.plist)
/*
Ajouter dans <dict>:

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>epilist.app</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>https</string>
        </array>
        <key>CFBundleURLTypes</key>
        <string>Editor</string>
    </dict>
    <dict>
        <key>CFBundleURLName</key>
        <string>epilist.custom</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>epilist</string>
        </array>
    </dict>
</array>

<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:epilist.app</string>
    <string>applinks:app.epilist.com</string>
</array>
*/
