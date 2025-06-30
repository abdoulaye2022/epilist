// services/shared_list_service.dart
import 'package:dio/dio.dart';
import 'package:epilist/models/shared_list.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/services/auth_service.dart';

class SharedListService {
  final Dio _dio;
  final AuthService _authService;

  SharedListService({required Dio dio, required AuthService authService})
    : _dio = dio,
      _authService = authService;

  // Créer un lien de partage pour une liste
  Future<String> createShareLink({
    required int listId,
    required SharePermission permission,
    int? expirationDays,
  }) async {
    final token = await _authService.getToken();

    final response = await _dio.post(
      '/shopping-lists/$listId/share',
      data: {
        'permission': permission.name,
        'expiration_days': expirationDays ?? 30, // Par défaut 30 jours
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data['data']['share_url'];
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
}
