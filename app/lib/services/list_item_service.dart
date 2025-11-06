// services/list_item_service.dart - VERSION CORRIGÉE POUR DIO EXCEPTION
import 'package:dio/dio.dart';
import 'package:epilist/models/list_item.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:epilist/blocs/list_item/list_item_bloc.dart';

class ListItemService {
  final Dio _dio;
  final AuthService _authService;

  ListItemService({required Dio dio, required AuthService authService})
    : _dio = dio,
      _authService = authService;

  Future<List<ListItem>> getListItems(int listId) async {
    final token = await _authService.getToken();
    final response = await _dio.get(
      '/shopping-lists/$listId/items',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return (response.data['data'] as List)
        .map((json) => ListItem.fromJson(json))
        .toList();
  }

  /// ✅ MÉTHODE CORRIGÉE: Gestion correcte des exceptions Dio
  Future<AddItemResult> addListItem({
    required int listId,
    required String productName,
    int quantity = 1,
    double? price,
    String? storeName,
    int? categoryId,
  }) async {
    final token = await _authService.getToken();

    try {
      final response = await _dio.post(
        '/shopping-lists/$listId/items',
        data: {
          'product_name': productName,
          'quantity': quantity,
          'price': price,
          'store_name': storeName,
          'category_id': categoryId,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          // ✅ CRITIQUE: Ne pas valider le status 409 comme erreur
          validateStatus: (status) {
            return status != null &&
                status < 500; // Accepter tous les codes < 500
          },
        ),
      );

      // ✅ VÉRIFIER MANUELLEMENT LE STATUS CODE
      if (response.statusCode == 201) {
        // Succès - pas de doublon détecté
        return AddItemResult.success(ListItem.fromJson(response.data['data']));
      } else if (response.statusCode == 409) {
        // Doublon détecté
        print('🔍 Doublon détecté: ${response.data}');

        final errorData = response.data;
        final duplicates =
            (errorData['error']['duplicates'] as List)
                .map((json) => DuplicateItem.fromJson(json))
                .toList();

        return AddItemResult.duplicateDetected(
          message: errorData['error']['message'] as String,
          duplicates: duplicates,
        );
      } else if (response.statusCode == 422) {
        // Erreur de validation
        final errorData = response.data;
        return AddItemResult.validationError(
          message: errorData['error']['message'] as String,
          validationErrors: Map<String, List<String>>.from(
            (errorData['error']['validation_errors'] as Map<String, dynamic>? ??
                    {})
                .map((key, value) => MapEntry(key, List<String>.from(value))),
          ),
        );
      } else {
        // Autre erreur
        throw DioException(
          requestOptions: RequestOptions(path: '/shopping-lists/$listId/items'),
          response: response,
          message: 'Unexpected status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      // ✅ GESTION D'ERREUR AMÉLIORÉE
      print('❌ Erreur Dio: ${e.message}');
      print('❌ Status: ${e.response?.statusCode}');
      print('❌ Data: ${e.response?.data}');

      // Si c'est encore une erreur 409 qui a échappé au validateStatus
      if (e.response?.statusCode == 409) {
        final errorData = e.response!.data;
        final duplicates =
            (errorData['error']['duplicates'] as List)
                .map((json) => DuplicateItem.fromJson(json))
                .toList();

        return AddItemResult.duplicateDetected(
          message: errorData['error']['message'] as String,
          duplicates: duplicates,
        );
      }

      // Relancer l'exception pour les autres cas
      rethrow;
    } catch (e) {
      print('❌ Erreur inattendue: $e');
      rethrow;
    }
  }

  /// ✅ MÉTHODE CORRIGÉE: Force add avec gestion d'erreur
  Future<ListItem> forceAddListItem({
    required int listId,
    required String productName,
    int quantity = 1,
    double? price,
    String? storeName,
  }) async {
    final token = await _authService.getToken();

    try {
      final response = await _dio.post(
        '/shopping-lists/$listId/items/force',
        data: {
          'product_name': productName,
          'quantity': quantity,
          'price': price,
          'store_name': storeName,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 201) {
        return ListItem.fromJson(response.data['data']);
      } else {
        throw DioException(
          requestOptions: RequestOptions(
            path: '/shopping-lists/$listId/items/force',
          ),
          response: response,
          message: 'Force add failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Erreur force add: $e');
      rethrow;
    }
  }

  // ✅ Méthodes existantes restent inchangées
  Future<void> togglePurchasedStatus({
    required int listId,
    required int itemId,
    required bool isPurchased,
  }) async {
    final token = await _authService.getToken();
    await _dio.patch(
      '/shopping-lists/$listId/items/$itemId/toggle',
      data: {'is_purchased': isPurchased},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<void> deleteListItem({
    required int listId,
    required int itemId,
  }) async {
    final token = await _authService.getToken();
    await _dio.delete(
      '/shopping-lists/$listId/items/$itemId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<ListItem> updateListItem({
    required int listId,
    required int itemId,
    required String productName,
    int quantity = 1,
    double? price,
    String? storeName,
    int? categoryId,
  }) async {
    final token = await _authService.getToken();
    final response = await _dio.put(
      '/shopping-lists/$listId/items/$itemId',
      data: {
        'product_name': productName,
        'quantity': quantity,
        'price': price,
        'store_name': storeName,
        'category_id': categoryId,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return ListItem.fromJson(response.data['data']);
  }

  Future<void> restoreListItem({
    required int listId,
    required int itemId,
  }) async {
    final token = await _authService.getToken();
    await _dio.post(
      '/shopping-lists/$listId/items/$itemId/restore',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  /// ✅ Méthodes bonus (optionnelles)
  Future<int> markAllItemsAs({
    required int listId,
    required bool isPurchased,
  }) async {
    final token = await _authService.getToken();
    final response = await _dio.patch(
      '/shopping-lists/$listId/items/mark-all',
      data: {'purchased': isPurchased},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data['data']['updated_count'] as int;
  }

  Future<int> clearPurchasedItems(int listId) async {
    final token = await _authService.getToken();
    final response = await _dio.delete(
      '/shopping-lists/$listId/items/clear-purchased',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return response.data['data']['deleted_count'] as int;
  }

  Future<ListStats> getListStats(int listId) async {
    final token = await _authService.getToken();
    final response = await _dio.get(
      '/shopping-lists/$listId/stats',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return ListStats.fromJson(response.data['data']);
  }

  Future<List<ListItem>> getSimilarItems({
    required int listId,
    required String productName,
    int limit = 5,
  }) async {
    final token = await _authService.getToken();
    final response = await _dio.get(
      '/shopping-lists/$listId/items/suggestions',
      queryParameters: {'product_name': productName, 'limit': limit},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return (response.data['data'] as List)
        .map((json) => ListItem.fromJson(json))
        .toList();
  }

  /// ✅ MÉTHODE CORRIGÉE: Fusionner avec un item existant
  Future<ListItem> mergeWithExistingItem({
    required int listId,
    required int existingItemId,
    int additionalQuantity = 1,
    double? newPrice,
  }) async {
    final token = await _authService.getToken();

    try {
      // ✅ CORRECTION: Utiliser PUT au lieu de POST et ne pas récupérer l'item d'abord
      final response = await _dio.put(
        '/shopping-lists/$listId/items/$existingItemId/merge',
        data: {
          'additional_quantity': additionalQuantity,
          'new_price': newPrice,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        return ListItem.fromJson(response.data['data']);
      } else {
        throw DioException(
          requestOptions: RequestOptions(
            path: '/shopping-lists/$listId/items/$existingItemId/merge',
          ),
          response: response,
          message: 'Merge failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Erreur merge: $e');
      rethrow;
    }
  }

  /// ✅ MÉTHODE CORRIGÉE: Obtenir un item spécifique
  Future<ListItem> getListItem(int listId, int itemId) async {
    final token = await _authService.getToken();

    try {
      final response = await _dio.get(
        '/shopping-lists/$listId/items/$itemId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        return ListItem.fromJson(response.data['data']);
      } else {
        throw DioException(
          requestOptions: RequestOptions(
            path: '/shopping-lists/$listId/items/$itemId',
          ),
          response: response,
          message: 'Get item failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Erreur get item: $e');
      rethrow;
    }
  }
}

/// ✅ CLASSE RÉSULTAT INCHANGÉE
class AddItemResult {
  final bool isSuccess;
  final bool isDuplicateDetected;
  final bool isValidationError;
  final ListItem? item;
  final String? message;
  final List<DuplicateItem>? duplicates;
  final Map<String, List<String>>? validationErrors;

  const AddItemResult._({
    required this.isSuccess,
    required this.isDuplicateDetected,
    required this.isValidationError,
    this.item,
    this.message,
    this.duplicates,
    this.validationErrors,
  });

  factory AddItemResult.success(ListItem item) {
    return AddItemResult._(
      isSuccess: true,
      isDuplicateDetected: false,
      isValidationError: false,
      item: item,
    );
  }

  factory AddItemResult.duplicateDetected({
    required String message,
    required List<DuplicateItem> duplicates,
  }) {
    return AddItemResult._(
      isSuccess: false,
      isDuplicateDetected: true,
      isValidationError: false,
      message: message,
      duplicates: duplicates,
    );
  }

  factory AddItemResult.validationError({
    required String message,
    required Map<String, List<String>> validationErrors,
  }) {
    return AddItemResult._(
      isSuccess: false,
      isDuplicateDetected: false,
      isValidationError: true,
      message: message,
      validationErrors: validationErrors,
    );
  }
}
