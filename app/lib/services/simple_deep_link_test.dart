// services/simple_deep_link_test.dart - TEST SIMPLE
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

class SimpleDeepLinkTest {
  static StreamSubscription<Uri>? _linkSubscription;
  static AppLinks? _appLinks;

  static void startTest(BuildContext context) {
    debugPrint('🧪 SIMPLE TEST: Démarrage du test simple');

    _appLinks = AppLinks();

    // Test du lien initial
    _getInitialLink(context);

    // Test des liens en temps réel
    _linkSubscription = _appLinks!.uriLinkStream.listen(
      (Uri uri) {
        debugPrint('🧪 SIMPLE TEST: Lien reçu: ${uri.toString()}');
        _showTestResult(context, 'Lien reçu: ${uri.toString()}');
      },
      onError: (err) {
        debugPrint('🧪 SIMPLE TEST: Erreur: $err');
        _showTestResult(context, 'ERREUR: $err');
      },
    );
  }

  static Future<void> _getInitialLink(BuildContext context) async {
    try {
      final Uri? initialUri = await _appLinks!.getInitialLink();
      if (initialUri != null) {
        debugPrint('🧪 SIMPLE TEST: Lien initial: ${initialUri.toString()}');
        _showTestResult(context, 'Lien initial: ${initialUri.toString()}');
      } else {
        debugPrint('🧪 SIMPLE TEST: Aucun lien initial');
        _showTestResult(context, 'Aucun lien initial trouvé');
      }
    } catch (e) {
      debugPrint('🧪 SIMPLE TEST: Erreur lien initial: $e');
      _showTestResult(context, 'ERREUR lien initial: $e');
    }
  }

  static void _showTestResult(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.purple,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  static void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _appLinks = null;
  }
}
