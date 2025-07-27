// services/analytics_service.dart
import 'package:dio/dio.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  final Dio _dio;
  final AuthService _authService;

  AnalyticsService({required Dio dio, required AuthService authService})
    : _dio = dio,
      _authService = authService;

  Future<Map<String, dynamic>> getDashboard([String? currencyCode]) async {
    final token = await _authService.getToken();

    final queryParams = <String, dynamic>{};
    if (currencyCode != null) {
      queryParams['currency'] = currencyCode;
    }

    final response = await _dio.get(
      '/analytics/dashboard',
      queryParameters: queryParams,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.data['success'] == true) {
      return response.data['data'] as Map<String, dynamic>;
    } else {
      throw Exception(response.data['error']['message'] ?? 'Erreur dashboard');
    }
  }

  Future<Map<String, dynamic>> getMonthlySpending({
    int months = 12,
    String? currencyCode,
  }) async {
    final token = await _authService.getToken();

    final queryParams = <String, dynamic>{'months': months};
    if (currencyCode != null) {
      queryParams['currency'] = currencyCode;
    }

    final response = await _dio.get(
      '/analytics/spending/monthly',
      queryParameters: queryParams,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.data['success'] == true) {
      return response.data['data'] as Map<String, dynamic>;
    } else {
      throw Exception(
        response.data['error']['message'] ?? 'Erreur données mensuelles',
      );
    }
  }

  Future<Map<String, dynamic>> getSpendingTrends({
    String period = 'month',
    String? currencyCode,
  }) async {
    final token = await _authService.getToken();

    final queryParams = <String, dynamic>{'period': period};
    if (currencyCode != null) {
      queryParams['currency'] = currencyCode;
    }

    final response = await _dio.get(
      '/analytics/spending/trends',
      queryParameters: queryParams,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.data['success'] == true) {
      return response.data['data'] as Map<String, dynamic>;
    } else {
      throw Exception(response.data['error']['message'] ?? 'Erreur tendances');
    }
  }

  Future<Map<String, dynamic>> getSpendingCategories({
    String period = 'month',
    int limit = 10,
    String? currencyCode,
  }) async {
    final token = await _authService.getToken();

    final queryParams = <String, dynamic>{'period': period, 'limit': limit};
    if (currencyCode != null) {
      queryParams['currency'] = currencyCode;
    }

    final response = await _dio.get(
      '/analytics/spending/categories',
      queryParameters: queryParams,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.data['success'] == true) {
      return response.data['data'] as Map<String, dynamic>;
    } else {
      throw Exception(response.data['error']['message'] ?? 'Erreur catégories');
    }
  }

  Future<Map<String, dynamic>> getTopProducts({
    String period = 'month',
    String sortBy = 'total_spent',
    int limit = 10,
    String? currencyCode,
  }) async {
    final token = await _authService.getToken();

    final queryParams = <String, dynamic>{
      'period': period,
      'sort_by': sortBy,
      'limit': limit,
    };
    if (currencyCode != null) {
      queryParams['currency'] = currencyCode;
    }

    final response = await _dio.get(
      '/analytics/products/top',
      queryParameters: queryParams,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.data['success'] == true) {
      return response.data['data'] as Map<String, dynamic>;
    } else {
      throw Exception(
        response.data['error']['message'] ?? 'Erreur top produits',
      );
    }
  }

  Future<Map<String, dynamic>> getPeriodComparison({
    String periodType = 'month',
    String? currencyCode,
  }) async {
    final token = await _authService.getToken();

    final queryParams = <String, dynamic>{'period_type': periodType};
    if (currencyCode != null) {
      queryParams['currency'] = currencyCode;
    }

    final response = await _dio.get(
      '/analytics/spending/comparison',
      queryParameters: queryParams,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.data['success'] == true) {
      return response.data['data'] as Map<String, dynamic>;
    } else {
      throw Exception(
        response.data['error']['message'] ?? 'Erreur comparaison',
      );
    }
  }
}
