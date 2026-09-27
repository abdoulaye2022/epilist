// services/store_service.dart - Magasins et ordre des rayons.
// Utilise le Dio partagé : Bearer injecté et refresh token automatiques
// (TokenRefreshInterceptor), contrairement aux anciens services en http.
import 'package:dio/dio.dart';
import 'package:epilist/models/store.dart';
import 'package:epilist/services/offline_storage_service.dart';

class StoreService {
  final Dio _dio;

  StoreService({required Dio dio}) : _dio = dio;

  /// Charge les magasins depuis l'API et met le cache à jour ;
  /// en cas d'échec (hors ligne), sert le dernier cache connu.
  Future<List<Store>> getStores() async {
    try {
      final response = await _dio.get('/stores');
      final data = response.data['data'] as List?;
      final stores = (data ?? [])
          .map((json) => Store.fromJson(json as Map<String, dynamic>))
          .toList();
      await OfflineStorageService.saveStores(
        stores.map((s) => s.toJson()).toList(),
      );
      return stores;
    } catch (e) {
      final cached = await OfflineStorageService.getStores();
      if (cached != null) {
        return cached.map(Store.fromJson).toList();
      }
      rethrow;
    }
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

  /// Fusionne [sourceStoreId] dans [targetStoreId] (la cible est conservée ;
  /// elle hérite de l'ordre des rayons de la source si elle n'en a pas).
  Future<Store> mergeStores(int sourceStoreId, int targetStoreId) async {
    final response = await _dio.post(
      '/stores/$sourceStoreId/merge',
      data: {'target_store_id': targetStoreId},
    );
    return Store.fromJson(response.data['data'] as Map<String, dynamic>);
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
