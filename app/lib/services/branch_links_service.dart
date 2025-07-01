// services/branch_links_service.dart - VERSION CORRIGÉE
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:epilist/models/shared_list.dart';
import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_event.dart';
import 'package:epilist/screens/share_invitation_screen.dart';
import 'package:epilist/services/shared_list_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

class BranchLinksService {
  static StreamSubscription<Map>? _streamSubscription;
  static bool _isInitialized = false;
  static BuildContext? _context;

  // Configuration Branch.io
  static const String branchKey = 'key_test_mvAhCSmc58VZkQWdEu9WEgojFDdd2f4k';

  // Domaines Branch.io
  static const String branchDomain = '9g24t.app.link';
  static const String testBranchDomain = '9g24t.test-app.link';

  // Fallback vers les stores
  static const String androidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.m2atech.epilist';
  static const String iosStoreUrl =
      'https://apps.apple.com/app/epilist/id123456789';

  /// Initialiser Branch.io
  static Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;

    _context = context;

    try {
      // ✅ FlutterBranchSdk.init retourne void
      FlutterBranchSdk.init(enableLogging: true, disableTracking: false);

      // ✅ Écouter les sessions Branch.io
      _streamSubscription = FlutterBranchSdk.listSession().listen(
        (data) => _handleBranchLink(data),
        onError: (error) {
          debugPrint('❌ Erreur Branch.io: $error');
        },
      );

      _isInitialized = true;
      debugPrint('✅ Branch.io initialisé avec succès');

      // Vérifier le lien initial après un court délai
      await Future.delayed(const Duration(milliseconds: 500));
      await _checkInitialLink();
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation de Branch.io: $e');
    }
  }

  /// Créer un lien de partage Branch.io
  static Future<String> createShareLink({
    required String shareToken,
    required String listName,
    required String ownerName,
  }) async {
    try {
      // ✅ Créer le BranchUniversalObject
      final buo = BranchUniversalObject(
        canonicalIdentifier: 'share_$shareToken',
        canonicalUrl: 'https://$testBranchDomain/share/$shareToken',
        title: 'Invitation EpiList - $listName',
        contentDescription:
            '$ownerName vous invite à collaborer sur la liste "$listName"',
        contentMetadata:
            BranchContentMetaData()
              ..addCustomMetadata('share_token', shareToken)
              ..addCustomMetadata('list_name', listName)
              ..addCustomMetadata('owner_name', ownerName)
              ..addCustomMetadata('type', 'list_share'),
        publiclyIndex: false,
        locallyIndex: true,
      );

      // ✅ Créer les propriétés du lien
      final lp = BranchLinkProperties(
        channel: 'sharing',
        feature: 'list_share',
        campaign: 'user_sharing',
        stage: 'invitation',
        tags: ['list_share', 'invitation'],
      );

      // ✅ Configuration des fallbacks
      lp.addControlParam('\$fallback_url', androidStoreUrl);
      lp.addControlParam(
        '\$desktop_url',
        _generateWebFallbackUrl(shareToken, listName, ownerName),
      );
      lp.addControlParam('\$android_url', androidStoreUrl);
      lp.addControlParam('\$ios_url', iosStoreUrl);

      // Données personnalisées
      lp.addControlParam('share_token', shareToken);
      lp.addControlParam('list_name', listName);
      lp.addControlParam('owner_name', ownerName);

      // ✅ Générer le lien court
      final response = await FlutterBranchSdk.getShortUrl(
        buo: buo,
        linkProperties: lp,
      );

      if (response.success) {
        debugPrint('✅ Lien Branch.io créé: ${response.result}');
        return response.result;
      } else {
        debugPrint('❌ Erreur Branch.io: ${response.errorMessage}');
        throw Exception(
          'Erreur lors de la création du lien: ${response.errorMessage}',
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la création du lien Branch.io: $e');
      // Fallback vers un lien simple
      return _generateSimpleFallbackUrl(shareToken);
    }
  }

  /// Générer une URL de fallback web
  static String _generateWebFallbackUrl(
    String shareToken,
    String listName,
    String ownerName,
  ) {
    final encodedListName = Uri.encodeComponent(listName);
    final encodedOwnerName = Uri.encodeComponent(ownerName);

    // Pour l'instant, utiliser le domaine Branch.io comme fallback
    return 'https://$testBranchDomain/share/$shareToken?list=$encodedListName&owner=$encodedOwnerName';
  }

  /// Fallback simple
  static String _generateSimpleFallbackUrl(String shareToken) {
    return 'https://$testBranchDomain/share/$shareToken';
  }

  /// Gérer les liens Branch.io entrants
  static void _handleBranchLink(Map data) {
    if (_context == null) {
      debugPrint('❌ Contexte non disponible pour gérer le lien Branch.io');
      return;
    }

    debugPrint('🔗 Données Branch.io reçues: $data');

    // Vérifier si c'est un lien de partage
    String? shareToken;

    // Chercher le token dans différents endroits
    if (data.containsKey('share_token') && data['share_token'] != null) {
      shareToken = data['share_token'] as String;
    } else if (data.containsKey('\$custom_data') &&
        data['\$custom_data'] != null) {
      final customData = data['\$custom_data'] as Map?;
      if (customData != null && customData.containsKey('share_token')) {
        shareToken = customData['share_token'] as String?;
      }
    } else if (data.containsKey('\$og_title') && data['\$og_title'] != null) {
      // Essayer d'extraire depuis l'URL canonique
      final canonicalUrl = data['\$canonical_url'] as String?;
      if (canonicalUrl != null && canonicalUrl.contains('/share/')) {
        shareToken = canonicalUrl.split('/share/').last.split('?').first;
      }
    }

    if (shareToken != null && shareToken.isNotEmpty) {
      debugPrint('🎯 Token de partage détecté: $shareToken');

      // Tracker l'événement
      trackCustomEvent(
        eventName: 'deep_link_opened',
        customData: {
          'share_token': shareToken,
          'source': data['~referring_link']?.toString() ?? 'unknown',
        },
      );

      _navigateToShareInvitation(shareToken);
    } else {
      debugPrint('⚠️ Lien Branch.io non reconnu: $data');
    }
  }

  /// Vérifier le lien initial
  static Future<void> _checkInitialLink() async {
    try {
      final data = await FlutterBranchSdk.getFirstReferringParams();
      if (data.isNotEmpty) {
        debugPrint('🔗 Lien initial Branch.io détecté: $data');

        // Vérifier si c'est vraiment un lien Branch.io
        if (data.containsKey('+clicked_branch_link') &&
            data['+clicked_branch_link'] == true) {
          _handleBranchLink(data);
        } else if (data.containsKey('share_token')) {
          // Fallback si +clicked_branch_link n'est pas présent
          _handleBranchLink(data);
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification du lien initial: $e');
    }
  }

  /// Naviguer vers l'écran d'invitation
  static void _navigateToShareInvitation(String shareToken) {
    if (_context == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_context != null && _context!.mounted) {
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
    });
  }

  /// Tracker un événement personnalisé
  static Future<void> trackCustomEvent({
    required String eventName,
    Map<String, String>? customData,
  }) async {
    try {
      final event = BranchEvent.customEvent(eventName);

      if (customData != null) {
        for (final entry in customData.entries) {
          event.addCustomData(entry.key, entry.value);
        }
      }

      // ✅ trackContent retourne void
      FlutterBranchSdk.trackContent(buo: [], branchEvent: event);
      debugPrint('📊 Événement Branch.io tracké: $eventName');
    } catch (e) {
      debugPrint('❌ Erreur lors du tracking: $e');
    }
  }

  /// Tracker l'événement de partage
  static Future<void> trackShareEvent({
    required String shareToken,
    required String listName,
    required String shareMethod,
  }) async {
    await trackCustomEvent(
      eventName: 'share_initiated',
      customData: {
        'share_token': shareToken,
        'list_name': listName,
        'share_method': shareMethod,
      },
    );
  }

  /// Définir l'identité de l'utilisateur
  static Future<void> setUserIdentity(String userId) async {
    try {
      // ✅ setIdentity retourne void
      FlutterBranchSdk.setIdentity(userId);
      debugPrint('👤 Identité utilisateur définie: $userId');
    } catch (e) {
      debugPrint('❌ Erreur lors de la définition de l\'identité: $e');
    }
  }

  /// Effacer l'identité de l'utilisateur
  static Future<void> clearUserIdentity() async {
    try {
      // ✅ logout retourne void
      FlutterBranchSdk.logout();
      debugPrint('👤 Identité utilisateur effacée');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'effacement de l\'identité: $e');
    }
  }

  /// Obtenir les paramètres de référence actuels
  static Future<Map> getReferringParams() async {
    try {
      return await FlutterBranchSdk.getLatestReferringParams();
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des paramètres: $e');
      return {};
    }
  }

  /// Obtenir les paramètres de la première référence
  static Future<Map> getFirstReferringParams() async {
    try {
      return await FlutterBranchSdk.getFirstReferringParams();
    } catch (e) {
      debugPrint(
        '❌ Erreur lors de la récupération des premiers paramètres: $e',
      );
      return {};
    }
  }

  /// Nettoyer les ressources
  static void dispose() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _isInitialized = false;
    _context = null;
    debugPrint('🧹 Branch.io nettoyé');
  }

  /// Créer des données de partage pour les réseaux sociaux
  static Map<String, dynamic> createShareData({
    required String shareToken,
    required String listName,
    required String ownerName,
    required String branchUrl,
  }) {
    return {
      'title': 'Invitation EpiList - $listName',
      'message':
          '$ownerName vous invite à collaborer sur la liste "$listName". Téléchargez EpiList pour commencer !',
      'url': branchUrl,
      'subject': 'Invitation à partager une liste d\'épicerie',
    };
  }

  /// Vérifier si Branch.io est initialisé
  static bool get isInitialized => _isInitialized;

  /// Valider un token de partage
  static bool isValidShareToken(String? token) {
    if (token == null || token.isEmpty) return false;
    return token.length >= 10;
  }

  /// Méthode utilitaire pour extraire le token d'un lien
  static String? extractTokenFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.isNotEmpty) {
        final lastSegment = uri.pathSegments.last;
        if (lastSegment.contains('share')) {
          final parts = uri.pathSegments;
          final shareIndex = parts.indexOf('share');
          if (shareIndex != -1 && shareIndex + 1 < parts.length) {
            return parts[shareIndex + 1];
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'extraction du token: $e');
      return null;
    }
  }

  /// Méthode pour forcer la vérification des liens
  static Future<void> validatePendingLinks() async {
    try {
      final params = await FlutterBranchSdk.getFirstReferringParams();
      if (params.isNotEmpty) {
        _handleBranchLink(params);
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la validation des liens: $e');
    }
  }
}
