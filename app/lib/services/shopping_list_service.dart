// services/shopping_list_service.dart - VERSION AVEC LEAVE SHARED LIST
import 'package:dio/dio.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:flutter/foundation.dart';

class ShoppingListService {
  final Dio _dio;
  final AuthService _authService;

  ShoppingListService({required Dio dio, required AuthService authService})
    : _dio = dio,
      _authService = authService;

  Future<List<ShoppingList>> getShoppingLists() async {
    final token = await _authService.getToken();

    // Ajouter le paramètre pour inclure les items
    final response = await _dio.get(
      '/shopping-lists',
      queryParameters: {
        'include': 'items', // Demander l'inclusion des items
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return (response.data['data'] as List).map((json) {
      return ShoppingList.fromJson(json);
    }).toList();
  }

  Future<ShoppingList> createShoppingList(String name) async {
    final token = await _authService.getToken();
    final response = await _dio.post(
      '/shopping-lists',
      data: {'name': name},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return ShoppingList.fromJson(response.data['data']);
  }

  Future<ShoppingList> updateShoppingList(int id, String name) async {
    final token = await _authService.getToken();
    final response = await _dio.put(
      '/shopping-lists/$id',
      data: {'name': name},
      queryParameters: {
        'include': 'items', // Inclure les items dans la réponse
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return ShoppingList.fromJson(response.data['data']);
  }

  Future<void> deleteShoppingList(int id) async {
    final token = await _authService.getToken();
    await _dio.delete(
      '/shopping-lists/$id',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  Future<ShoppingList> duplicateShoppingList(int id) async {
    final token = await _authService.getToken();
    final response = await _dio.post(
      '/shopping-lists/$id/duplicate',
      queryParameters: {
        'include': 'items', // Inclure les items dans la réponse
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return ShoppingList.fromJson(response.data['data']);
  }

  // Méthode pour obtenir une liste spécifique avec ses items
  Future<ShoppingList> getShoppingListById(int id) async {
    final token = await _authService.getToken();
    final response = await _dio.get(
      '/shopping-lists/$id',
      queryParameters: {'include': 'items'},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return ShoppingList.fromJson(response.data['data']);
  }

  // ✅ NOUVELLE MÉTHODE: Quitter une liste partagée
  Future<void> leaveSharedList(int listId) async {
    try {
      final token = await _authService.getToken();

      debugPrint('🔄 Quitter la liste partagée: $listId');

      final response = await _dio.post(
        '/shopping-lists/$listId/leave',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint(
        '✅ Liste quittée avec succès - Status: ${response.statusCode}',
      );

      // Vérifier la réponse
      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] != true) {
        final message =
            responseData['message'] ?? 'Erreur lors de la sortie de la liste';
        throw Exception(message);
      }
    } on DioException catch (e) {
      debugPrint('❌ Erreur lors de la sortie de la liste:');
      debugPrint('   - Status Code: ${e.response?.statusCode}');
      debugPrint('   - Message: ${e.message}');
      debugPrint('   - Response Data: ${e.response?.data}');

      if (e.response?.statusCode == 404) {
        throw Exception('Liste non trouvée ou vous n\'y avez pas accès');
      } else if (e.response?.statusCode == 400) {
        final responseData = e.response?.data;
        final errorMessage =
            responseData is Map<String, dynamic>
                ? responseData['message'] ??
                    'Vous ne pouvez pas quitter cette liste'
                : 'Vous ne pouvez pas quitter cette liste';
        throw Exception(errorMessage);
      } else if (e.response?.statusCode == 403) {
        throw Exception('Vous n\'êtes pas autorisé à quitter cette liste');
      } else {
        final responseData = e.response?.data;
        final errorMessage =
            responseData is Map<String, dynamic>
                ? responseData['message'] ?? e.message
                : e.message;
        throw Exception('Erreur lors de la sortie: $errorMessage');
      }
    } catch (e) {
      debugPrint('❌ Erreur inattendue lors de la sortie de la liste: $e');
      throw Exception('Erreur lors de la sortie de la liste partagée');
    }
  }
}
