// services/shared_list_service.dart - VERSION CORRIGÉE AVEC BONNES URLS
import 'package:dio/dio.dart';
import 'package:epilist/models/share_invitation.dart';
import 'package:epilist/models/shared_enums.dart';
import 'package:epilist/models/shared_list.dart' hide SharePermission;
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:epilist/services/deep_link_handler.dart';
import 'package:flutter/foundation.dart';

class SharedListService {
  final Dio _dio;
  final AuthService _authService;

  SharedListService({required Dio dio, required AuthService authService})
    : _dio = dio,
      _authService = authService;

  // ✅ Obtenir les informations d'une invitation via le token - URL CORRIGÉE
  Future<ShareInvitation> getShareInvitation(String shareToken) async {
    try {
      debugPrint('🔄 Récupération de l\'invitation pour le token: $shareToken');
      debugPrint('🌐 URL appelée: /share/invitation/$shareToken');

      // ✅ CORRECTION: Utiliser la bonne URL selon votre contrôleur PHP
      final response = await _dio.get('/share/invitation/$shareToken');

      debugPrint('✅ Réponse API reçue - Status: ${response.statusCode}');
      debugPrint('✅ Données reçues: ${response.data}');

      // Vérifier la structure de la réponse
      if (response.data == null) {
        throw Exception('Réponse API vide');
      }

      final responseData = response.data as Map<String, dynamic>;

      // Vérifier le succès de la réponse
      if (responseData['success'] != true) {
        final message = responseData['message'] ?? 'Erreur inconnue';
        throw Exception(message);
      }

      final data = responseData['data'];
      if (data == null) {
        throw Exception('Données d\'invitation manquantes');
      }

      // Créer l'invitation avec gestion d'erreur robuste
      final invitation = ShareInvitation.fromJson(data as Map<String, dynamic>);

      debugPrint(
        '✅ Invitation parsée: ${invitation.listName} (${invitation.status})',
      );

      return invitation;
    } on DioException catch (e) {
      debugPrint('❌ Erreur Dio lors de la récupération de l\'invitation:');
      debugPrint('   - Status Code: ${e.response?.statusCode}');
      debugPrint('   - Message: ${e.message}');
      debugPrint('   - Response Data: ${e.response?.data}');

      if (e.response?.statusCode == 404) {
        throw Exception('Invitation non trouvée ou expirée');
      } else if (e.response?.statusCode == 410) {
        throw Exception('Invitation expirée');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Token d\'invitation invalide');
      } else {
        final responseData = e.response?.data;
        final errorMessage =
            responseData is Map<String, dynamic>
                ? responseData['message'] ?? e.message
                : e.message;
        throw Exception('Erreur réseau: $errorMessage');
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du parsing de l\'invitation: $e');
      throw Exception('Erreur lors de la validation de l\'invitation: $e');
    }
  }

  // ✅ Accepter une invitation de partage - URL CORRIGÉE
  Future<ShoppingList> acceptShareInvitation(String shareToken) async {
    try {
      final token = await _authService.getToken();

      debugPrint('🔄 Acceptation de l\'invitation: $shareToken');
      debugPrint('🌐 URL appelée: /share/accept/$shareToken');

      final response = await _dio.post(
        '/share/accept/$shareToken',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('✅ Invitation acceptée - Status: ${response.statusCode}');
      debugPrint('✅ Réponse: ${response.data}');

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] != true) {
        final message =
            responseData['message'] ?? 'Erreur lors de l\'acceptation';
        throw Exception(message);
      }

      final data = responseData['data'];
      if (data == null) {
        throw Exception('Données de liste manquantes après acceptation');
      }

      // ✅ CORRECTION: Utiliser la factory spécifique et gérer les champs manquants
      try {
        final shoppingListData = data as Map<String, dynamic>;

        // S'assurer que les champs requis sont présents avec des valeurs par défaut
        final correctedData = {
          'id': shoppingListData['id'],
          'name': shoppingListData['name'],
          'description':
              shoppingListData['description'] ?? '', // ✅ Valeur par défaut
          'created_at': shoppingListData['created_at'],
          'updated_at':
              shoppingListData['updated_at'] ??
              DateTime.now().toIso8601String(), // ✅ Valeur par défaut
          'user_id': shoppingListData['user_id'] ?? 0, // ✅ Valeur par défaut
          'items': shoppingListData['items'] ?? [], // ✅ Valeur par défaut
        };

        return ShoppingList.fromShareApiJson(correctedData);
      } catch (parseError) {
        debugPrint('❌ Erreur de parsing détaillée: $parseError');
        debugPrint('❌ Données reçues: $data');
        throw Exception(
          'Erreur lors du parsing des données de la liste: $parseError',
        );
      }
    } on DioException catch (e) {
      debugPrint('❌ Erreur lors de l\'acceptation:');
      debugPrint('   - Status Code: ${e.response?.statusCode}');
      debugPrint('   - Message: ${e.message}');
      debugPrint('   - Response Data: ${e.response?.data}');

      if (e.response?.statusCode == 404) {
        throw Exception('Invitation non trouvée ou expirée');
      } else if (e.response?.statusCode == 409) {
        throw Exception('Invitation déjà traitée');
      } else if (e.response?.statusCode == 400) {
        final responseData = e.response?.data;
        final errorMessage =
            responseData is Map<String, dynamic>
                ? responseData['message'] ??
                    'Invitation ne peut plus être acceptée'
                : 'Invitation ne peut plus être acceptée';
        throw Exception(errorMessage);
      } else if (e.response?.statusCode == 403) {
        throw Exception(
          'Vous n\'êtes pas autorisé à accepter cette invitation',
        );
      } else {
        final responseData = e.response?.data;
        final errorMessage =
            responseData is Map<String, dynamic>
                ? responseData['message'] ?? e.message
                : e.message;
        throw Exception('Erreur lors de l\'acceptation: $errorMessage');
      }
    } catch (e) {
      debugPrint('❌ Erreur inattendue lors de l\'acceptation: $e');
      throw Exception('Erreur lors de l\'acceptation de l\'invitation');
    }
  }

  // ✅ Refuser une invitation de partage - URL CORRIGÉE
  Future<void> declineShareInvitation(String shareToken) async {
    try {
      final token = await _authService.getToken();

      debugPrint('🔄 Refus de l\'invitation: $shareToken');
      debugPrint('🌐 URL appelée: /share/decline/$shareToken');

      // ✅ CORRECTION: Utiliser la bonne URL selon votre contrôleur PHP
      final response = await _dio.post(
        '/share/decline/$shareToken',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint(
        '✅ Invitation refusée avec succès - Status: ${response.statusCode}',
      );

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] != true) {
        final message = responseData['message'] ?? 'Erreur lors du refus';
        throw Exception(message);
      }
    } on DioException catch (e) {
      debugPrint('❌ Erreur lors du refus:');
      debugPrint('   - Status Code: ${e.response?.statusCode}');
      debugPrint('   - Message: ${e.message}');
      debugPrint('   - Response Data: ${e.response?.data}');

      if (e.response?.statusCode == 404) {
        throw Exception('Invitation non trouvée');
      } else if (e.response?.statusCode == 409) {
        throw Exception('Invitation déjà traitée');
      } else if (e.response?.statusCode == 400) {
        final responseData = e.response?.data;
        final errorMessage =
            responseData is Map<String, dynamic>
                ? responseData['message'] ??
                    'Invitation ne peut plus être refusée'
                : 'Invitation ne peut plus être refusée';
        throw Exception(errorMessage);
      } else {
        final responseData = e.response?.data;
        final errorMessage =
            responseData is Map<String, dynamic>
                ? responseData['message'] ?? e.message
                : e.message;
        throw Exception('Erreur lors du refus: $errorMessage');
      }
    } catch (e) {
      debugPrint('❌ Erreur inattendue lors du refus: $e');
      throw Exception('Erreur lors du refus de l\'invitation');
    }
  }

  // ✅ Créer un lien de partage - VERSION AVEC DOMAINE
  Future<Map<String, dynamic>> createShareLink({
    required int listId,
    required SharePermission permission,
    int? expirationDays,
  }) async {
    try {
      final token = await _authService.getToken();

      debugPrint('🔄 Création du lien de partage pour la liste $listId');

      final response = await _dio.post(
        '/shopping-lists/$listId/share',
        data: {
          'permission': permission.name,
          'expiration_days': expirationDays ?? 30,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final responseData = response.data['data'];
      final shareToken = responseData['share_token'];

      debugPrint('✅ Lien de partage créé avec le token: $shareToken');

      // ✅ Gérer les URLs de partage
      final shareUrls = responseData['share_urls'];
      final shareUrl =
          shareUrls?['web'] ??
          responseData['share_url'] ??
          DeepLinkHandler.generateWebShareUrl(shareToken);

      return {
        'share_token': shareToken,
        'share_url': shareUrl,
        'list_name': responseData['list_name'],
        'owner_name': responseData['owner_name'],
        'expiration_date':
            responseData['expiration_date'] ?? responseData['expires_at'],
        'share_message':
            responseData['share_message'] ??
            _createWebShareMessage(
              shareToken,
              responseData['list_name'],
              responseData['owner_name'],
              shareUrl,
            ),
        'store_urls':
            responseData['store_urls'] ?? shareUrls ?? _getDefaultStoreUrls(),
        'app_url':
            shareUrls?['app'] ??
            DeepLinkHandler.generateAppShareUrl(shareToken),
      };
    } on DioException catch (e) {
      debugPrint('❌ Erreur lors de la création du lien: ${e.message}');

      if (e.response?.statusCode == 404) {
        throw Exception('Liste non trouvée');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Vous n\'êtes pas autorisé à partager cette liste');
      } else {
        throw Exception('Erreur lors de la création du lien: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Erreur inattendue lors de la création du lien: $e');
      throw Exception('Erreur lors de la création du lien de partage');
    }
  }

  // ✅ Obtenir toutes les listes partagées avec l'utilisateur
  Future<List<SharedList>> getSharedLists() async {
    try {
      final token = await _authService.getToken();

      final response = await _dio.get(
        '/shared-lists',
        queryParameters: {'include': 'shopping_list,owner'},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data['data'] as List?;
      if (data == null) return [];

      return data.map((json) => SharedList.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement des listes partagées: $e');
      throw Exception('Erreur lors du chargement des listes partagées');
    }
  }

  // ✅ Obtenir les personnes avec qui une liste est partagée
  Future<List<SharedList>> getListShares(int listId) async {
    try {
      final token = await _authService.getToken();

      final response = await _dio.get(
        '/shopping-lists/$listId/shares',
        queryParameters: {'include': 'shared_with_user'},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data['data'] as List?;
      if (data == null) return [];

      return data.map((json) => SharedList.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement des partages: $e');
      throw Exception('Erreur lors du chargement des partages de la liste');
    }
  }

  // Modifier les permissions d'un partage
  Future<SharedList> updateSharePermission({
    required int shareId,
    required SharePermission permission,
  }) async {
    final token = await _authService.getToken();

    final response = await _dio.put(
      '/shared-lists/$shareId',
      data: {'permission': permission.name},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return SharedList.fromJson(response.data['data']);
  }

  // Révoquer un partage
  Future<void> revokeShare(int shareId) async {
    final token = await _authService.getToken();

    await _dio.delete(
      '/shared-lists/$shareId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // Quitter une liste partagée
  Future<void> leaveSharedList(int listId) async {
    final token = await _authService.getToken();

    await _dio.post(
      '/shopping-lists/$listId/leave',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // Vérifier si un lien de partage est valide
  Future<bool> validateShareLink(String shareToken) async {
    try {
      await getShareInvitation(shareToken);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Révoquer tous les liens de partage d'une liste
  Future<void> revokeAllShareLinks(int listId) async {
    final token = await _authService.getToken();

    await _dio.delete(
      '/shopping-lists/$listId/share-links',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // ✅ MÉTHODES UTILITAIRES

  Map<String, dynamic> _getDefaultStoreUrls() {
    return {
      'android':
          'https://play.google.com/store/apps/details?id=com.m2atech.epilist',
      'ios': 'https://apps.apple.com/app/epilist/id123456789',
    };
  }

  String _createWebShareMessage(
    String shareToken,
    String listName,
    String ownerName,
    String webUrl,
  ) {
    return '$ownerName vous invite à collaborer sur la liste d\'épicerie "$listName".\n\n'
        '🔗 Cliquez sur ce lien pour ouvrir l\'app ou la télécharger :\n$webUrl\n\n'
        '📱 EpiList - Vos listes de courses partagées';
  }

  // Générer les données de partage
  Map<String, String> generateShareData(
    String shareToken,
    String listName,
    String ownerName,
  ) {
    return DeepLinkHandler.generateShareData(shareToken, listName, ownerName);
  }

  String generateWebShareUrl(String shareToken) {
    return DeepLinkHandler.generateWebShareUrl(shareToken);
  }

  String generateAppShareUrl(String shareToken) {
    return DeepLinkHandler.generateAppShareUrl(shareToken);
  }

  String createShareMessage(
    String shareToken,
    String listName,
    String ownerName,
  ) {
    final webUrl = generateWebShareUrl(shareToken);
    return _createWebShareMessage(shareToken, listName, ownerName, webUrl);
  }

  bool isValidShareUrl(String url) {
    return DeepLinkHandler.isValidShareLink(url);
  }

  String? extractTokenFromUrl(String url) {
    return DeepLinkHandler.extractTokenFromLink(url);
  }

  Future<void> openAppOrStore(String shareToken) async {
    await DeepLinkHandler.openAppOrStore(shareToken);
  }
}
