// services/list_item_service.dart
import 'package:dio/dio.dart';
import 'package:epilist/models/list_item.dart';
import 'package:epilist/services/auth_service.dart';

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

  Future<ListItem> addListItem({
    required int listId,
    required String productName,
    int quantity = 1,
    double? price,
    String? storeName,
  }) async {
    final token = await _authService.getToken();
    final response = await _dio.post(
      '/shopping-lists/$listId/items',
      data: {
        'product_name': productName,
        'quantity': quantity,
        'price': price,
        'store_name': storeName,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return ListItem.fromJson(response.data['data']);
  }

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
  }) async {
    final token = await _authService.getToken();
    final response = await _dio.put(
      '/shopping-lists/$listId/items/$itemId',
      data: {
        'product_name': productName,
        'quantity': quantity,
        'price': price,
        'store_name': storeName,
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
}
