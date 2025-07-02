// services/shared_list_service.dart - VERSION CORRIGÉE
import 'package:dio/dio.dart';
import 'package:epilist/models/shared_list.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:epilist/services/deep_link_handler.dart';

class SharedListService {
  final Dio _dio;
  final AuthService _authService;

  SharedListService({required Dio dio, required AuthService authService})
    : _dio = dio,
      _authService = authService;

  // ✅ Créer un lien de partage - VERSION AVEC DOMAINE
  Future<Map<String, dynamic>> createShareLink({
    required int listId,
    required SharePermission permission,
    int? expirationDays,
  }) async {
    final token = await _authService.getToken();

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

    // ✅ CORRECTION : Utiliser l'URL web comme lien principal
    final shareUrl =
        responseData['share_url'] ??
        DeepLinkHandler.generateWebShareUrl(shareToken);

    return {
      'share_token': shareToken,
      'share_url': shareUrl, // https://epilist.app/share/token
      'list_name': responseData['list_name'],
      'owner_name': responseData['owner_name'],
      'expiration_date':
          responseData['expiration_date'] ?? responseData['expires_at'],
      // ✅ Message de partage optimisé pour le web
      'share_message':
          responseData['share_message'] ??
          _createWebShareMessage(
            shareToken,
            responseData['list_name'],
            responseData['owner_name'],
            shareUrl,
          ),
      // ✅ URLs des stores pour fallback
      'store_urls':
          responseData['store_urls'] ??
          {
            'android':
                'https://play.google.com/store/apps/details?id=com.m2atech.epilist',
            'ios': 'https://apps.apple.com/app/epilist/id123456789',
          },
      // ✅ URL alternative avec schéma app
      'app_url': DeepLinkHandler.generateAppShareUrl(shareToken),
    };
  }

  // Obtenir les informations d'une invitation via le token
  Future<ShareInvitation> getShareInvitation(String shareToken) async {
    final response = await _dio.get('/share/invitation/$shareToken');
    return ShareInvitation.fromJson(response.data['data']);
  }

  // Accepter une invitation de partage
  Future<ShoppingList> acceptShareInvitation(String shareToken) async {
    final token = await _authService.getToken();

    final response = await _dio.post(
      '/share/accept/$shareToken',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return ShoppingList.fromJson(response.data['data']);
  }

  // Refuser une invitation de partage
  Future<void> declineShareInvitation(String shareToken) async {
    final token = await _authService.getToken();

    await _dio.post(
      '/share/decline/$shareToken',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // Obtenir toutes les listes partagées avec l'utilisateur
  Future<List<SharedList>> getSharedLists() async {
    final token = await _authService.getToken();

    final response = await _dio.get(
      '/shared-lists',
      queryParameters: {'include': 'shopping_list,owner'},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return (response.data['data'] as List)
        .map((json) => SharedList.fromJson(json))
        .toList();
  }

  // Obtenir les personnes avec qui une liste est partagée
  Future<List<SharedList>> getListShares(int listId) async {
    final token = await _authService.getToken();

    final response = await _dio.get(
      '/shopping-lists/$listId/shares',
      queryParameters: {'include': 'shared_with_user'},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return (response.data['data'] as List)
        .map((json) => SharedList.fromJson(json))
        .toList();
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

  // Quitter une liste partagée (pour l'utilisateur qui reçoit le partage)
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

  // Obtenir les statistiques de partage pour une liste
  Future<Map<String, dynamic>> getShareStats(int listId) async {
    final token = await _authService.getToken();

    final response = await _dio.get(
      '/shopping-lists/$listId/share-stats',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data['data'];
  }

  // Obtenir les liens de partage actifs pour une liste
  Future<List<Map<String, dynamic>>> getActiveShareLinks(int listId) async {
    final token = await _authService.getToken();

    final response = await _dio.get(
      '/shopping-lists/$listId/share-links',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  // Révoquer un lien de partage spécifique
  Future<void> revokeShareLink(String shareToken) async {
    final token = await _authService.getToken();

    await _dio.delete(
      '/share/links/$shareToken',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // Obtenir les détails d'un partage par token
  Future<Map<String, dynamic>> getShareDetails(String shareToken) async {
    final token = await _authService.getToken();

    final response = await _dio.get(
      '/share/details/$shareToken',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data['data'];
  }

  // Mettre à jour les paramètres d'un lien de partage
  Future<void> updateShareLink({
    required String shareToken,
    SharePermission? permission,
    int? expirationDays,
  }) async {
    final token = await _authService.getToken();

    final data = <String, dynamic>{};
    if (permission != null) data['permission'] = permission.name;
    if (expirationDays != null) data['expiration_days'] = expirationDays;

    await _dio.put(
      '/share/links/$shareToken',
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // Obtenir l'historique des accès à un lien de partage
  Future<List<Map<String, dynamic>>> getShareLinkHistory(
    String shareToken,
  ) async {
    final token = await _authService.getToken();

    final response = await _dio.get(
      '/share/links/$shareToken/history',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  // ✅ MÉTHODES UTILITAIRES AVEC DOMAINE

  // Méthode utilitaire pour générer les données de partage
  Map<String, String> generateShareData(
    String shareToken,
    String listName,
    String ownerName,
  ) {
    return DeepLinkHandler.generateShareData(shareToken, listName, ownerName);
  }

  // ✅ Générer un lien web avec votre domaine (principal)
  String generateWebShareUrl(String shareToken) {
    return DeepLinkHandler.generateWebShareUrl(shareToken);
  }

  // ✅ Générer un lien avec schéma app (fallback)
  String generateAppShareUrl(String shareToken) {
    return DeepLinkHandler.generateAppShareUrl(shareToken);
  }

  // ✅ Créer un message de partage optimisé pour le web
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

  // ✅ Créer un message de partage complet avec instructions
  String createShareMessage(
    String shareToken,
    String listName,
    String ownerName,
  ) {
    final webUrl = generateWebShareUrl(shareToken);
    return _createWebShareMessage(shareToken, listName, ownerName, webUrl);
  }

  // Méthode pour valider un lien de partage
  bool isValidShareUrl(String url) {
    return DeepLinkHandler.isValidShareLink(url);
  }

  // Extraire le token d'un lien de partage
  String? extractTokenFromUrl(String url) {
    return DeepLinkHandler.extractTokenFromLink(url);
  }

  // ✅ Méthode pour ouvrir l'app ou rediriger vers le store (maintenant disponible)
  Future<void> openAppOrStore(String shareToken) async {
    await DeepLinkHandler.openAppOrStore(shareToken);
  }
}
