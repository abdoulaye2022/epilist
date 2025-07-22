// services/product_suggestion_service.dart
import 'package:dio/dio.dart';
import 'package:epilist/models/product_suggestion.dart';
import 'package:epilist/services/auth_service.dart';

class ProductSuggestionService {
  final Dio _dio;
  final AuthService _authService;

  ProductSuggestionService({required Dio dio, required AuthService authService})
    : _dio = dio,
      _authService = authService;

  /// Recherche des suggestions par nom de produit
  Future<List<ProductSuggestion>> searchSuggestions({
    required String query,
    int limit = 10,
  }) async {
    try {
      final token = await _authService.getToken();
      final response = await _dio.get(
        '/product-suggestions/search',
        queryParameters: {'q': query, 'limit': limit},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data['success'] == true) {
        return (response.data['data'] as List)
            .map((json) => ProductSuggestion.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Erreur lors de la recherche de suggestions: $e');
      return [];
    }
  }

  /// Obtient les suggestions les plus populaires
  Future<List<ProductSuggestion>> getPopularSuggestions({
    int limit = 20,
  }) async {
    try {
      final token = await _authService.getToken();
      final response = await _dio.get(
        '/product-suggestions/popular',
        queryParameters: {'limit': limit},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data['success'] == true) {
        return (response.data['data'] as List)
            .map((json) => ProductSuggestion.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Erreur lors de la récupération des suggestions populaires: $e');
      return [];
    }
  }

  /// Supprime une suggestion spécifique
  Future<bool> deleteSuggestion(int suggestionId) async {
    try {
      final token = await _authService.getToken();
      final response = await _dio.delete(
        '/product-suggestions/$suggestionId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.data['success'] == true;
    } catch (e) {
      print('Erreur lors de la suppression de la suggestion: $e');
      return false;
    }
  }

  /// Supprime toutes les suggestions
  Future<bool> clearAllSuggestions() async {
    try {
      final token = await _authService.getToken();
      final response = await _dio.delete(
        '/product-suggestions',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.data['success'] == true;
    } catch (e) {
      print('Erreur lors de la suppression de toutes les suggestions: $e');
      return false;
    }
  }

  /// Met à jour une suggestion
  Future<ProductSuggestion?> updateSuggestion({
    required int suggestionId,
    String? productName,
    double? price,
    String? storeName,
  }) async {
    try {
      final token = await _authService.getToken();
      final Map<String, dynamic> data = {};

      if (productName != null) data['product_name'] = productName;
      if (price != null) data['price'] = price;
      if (storeName != null) data['store_name'] = storeName;

      final response = await _dio.put(
        '/product-suggestions/$suggestionId',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data['success'] == true) {
        return ProductSuggestion.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la mise à jour de la suggestion: $e');
      return null;
    }
  }

  /// Obtient les statistiques des suggestions
  Future<Map<String, dynamic>?> getSuggestionStats() async {
    try {
      final token = await _authService.getToken();
      final response = await _dio.get(
        '/product-suggestions/stats',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération des statistiques: $e');
      return null;
    }
  }
}
