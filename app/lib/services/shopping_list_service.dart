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
    final response = await _dio.get(
      '/shopping-lists',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return (response.data['data'] as List)
        .map((json) => ShoppingList.fromJson(json))
        .toList();
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
}
