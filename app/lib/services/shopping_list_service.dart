// services/shopping_list_service.dart
import 'package:dio/dio.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/services/auth_service.dart';

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

    print("API Response: ${response.data}"); // Debug

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
}
