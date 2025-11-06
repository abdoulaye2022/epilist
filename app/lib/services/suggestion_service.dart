// services/suggestion_service.dart
import 'package:dio/dio.dart';
import 'package:epilist/models/smart_suggestion.dart';
import 'package:epilist/config/app_config.dart';

class SuggestionService {
  final Dio dio;

  SuggestionService({required this.dio});

  /// Get personalized suggestions
  Future<List<SmartSuggestion>> getSuggestions({
    int limit = 10,
    bool includeAssociations = true,
    List<String> currentListItems = const [],
  }) async {
    try {
      final queryParams = {
        'limit': limit,
        'include_associations': includeAssociations,
      };

      if (currentListItems.isNotEmpty) {
        queryParams['current_items'] = currentListItems.join(',');
      }

      final response = await dio.get(
        '${AppConfig.baseUrl}/api/suggestions',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final suggestions = (response.data['data']['suggestions'] as List)
            .map((json) => SmartSuggestion.fromJson(json))
            .toList();

        return suggestions;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load suggestions');
      }
    } on DioException catch (e) {
      throw Exception('Failed to load suggestions: ${e.message}');
    }
  }

  /// Get suggestion for a specific product (quantity and price)
  Future<SmartSuggestion?> getProductSuggestion(String productName) async {
    try {
      final response = await dio.get(
        '${AppConfig.baseUrl}/api/suggestions/product',
        queryParameters: {'product_name': productName},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        return SmartSuggestion(
          productName: data['product_name'],
          suggestedQuantity: data['suggested_quantity'] ?? 1,
          avgPrice: data['suggested_price'] != null
              ? double.tryParse(data['suggested_price'].toString())
              : null,
          confidenceScore: 50.0, // Default medium confidence
          reason: 'Based on your purchase history',
        );
      }

      return null;
    } on DioException catch (e) {
      print('Failed to get product suggestion: ${e.message}');
      return null;
    }
  }

  /// Record feedback on a suggestion
  Future<void> recordFeedback({
    required String productName,
    required String action, // 'accepted', 'rejected', 'modified'
    int? suggestedQuantity,
    int? actualQuantity,
  }) async {
    try {
      final response = await dio.post(
        '${AppConfig.baseUrl}/api/suggestions/feedback',
        data: {
          'product_name': productName,
          'action': action,
          if (suggestedQuantity != null) 'suggested_quantity': suggestedQuantity,
          if (actualQuantity != null) 'actual_quantity': actualQuantity,
        },
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to record feedback');
      }
    } on DioException catch (e) {
      print('Failed to record feedback: ${e.message}');
      // Silently fail - not critical
    }
  }

  /// Recalculate purchase patterns
  Future<void> recalculatePatterns() async {
    try {
      final response = await dio.post(
        '${AppConfig.baseUrl}/api/suggestions/recalculate',
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to recalculate patterns');
      }
    } on DioException catch (e) {
      throw Exception('Failed to recalculate patterns: ${e.message}');
    }
  }

  /// Get suggestion statistics
  Future<SuggestionStatistics> getStatistics() async {
    try {
      final response = await dio.get(
        '${AppConfig.baseUrl}/api/suggestions/stats',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return SuggestionStatistics.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load statistics');
      }
    } on DioException catch (e) {
      throw Exception('Failed to load statistics: ${e.message}');
    }
  }

  /// Get trending products
  Future<List<SmartSuggestion>> getTrendingProducts({int limit = 10}) async {
    try {
      final response = await dio.get(
        '${AppConfig.baseUrl}/api/suggestions/trending',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final trending = (response.data['data']['trending'] as List)
            .map((json) => SmartSuggestion(
                  productName: json['product_name'],
                  suggestedQuantity: 1,
                  confidenceScore: 60.0,
                  reason: 'Trending now (${json['purchase_count']} recent purchases)',
                  type: SuggestionType.trending,
                ))
            .toList();

        return trending;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load trending');
      }
    } on DioException catch (e) {
      throw Exception('Failed to load trending: ${e.message}');
    }
  }
}
