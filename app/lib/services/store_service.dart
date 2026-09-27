// services/store_service.dart - Magasins et ordre des rayons.
// Utilise le Dio partagé : Bearer injecté et refresh token automatiques
// (TokenRefreshInterceptor), contrairement aux anciens services en http.
import 'package:dio/dio.dart';
import 'package:epilist/models/store.dart';

class StoreService {
  final Dio _dio;

  StoreService({required Dio dio}) : _dio = dio;

  Future<List<Store>> getStores() async {
    final response = await _dio.get('/stores');
    final data = response.data['data'] as List?;
    if (data == null) return [];
    return data
        .map((json) => Store.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Crée un magasin. Si un magasin du même nom existe déjà (409),
  /// retourne celui-ci au lieu d'échouer.
  Future<Store> createStore(String name) async {
    try {
      final response = await _dio.post('/stores', data: {'name': name});
      return Store.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409 && e.response?.data?['data'] != null) {
        return Store.fromJson(e.response!.data['data'] as Map<String, dynamic>);
      }
      rethrow;
    }
  }

  Future<Store> renameStore(int storeId, String name) async {
    final response = await _dio.put('/stores/$storeId', data: {'name': name});
    return Store.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteStore(int storeId) async {
    await _dio.delete('/stores/$storeId');
  }

  Future<List<String>> getCategoryOrder(int storeId) async {
    final response = await _dio.get('/stores/$storeId/category-order');
    final order = response.data['data']?['category_order'] as List?;
    if (order == null) return [];
    return order.map((e) => e.toString()).toList();
  }

  /// Remplace tout l'ordre des rayons du magasin (bulk transactionnel).
  Future<void> setCategoryOrder(int storeId, List<String> categoryKinds) async {
    await _dio.put(
      '/stores/$storeId/category-order',
      data: {'category_kinds': categoryKinds},
    );
  }
}
