// services/analytics_service.dart - VERSION MISE À JOUR AVEC NOUVEAUX ENDPOINTS
import 'package:dio/dio.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AnalyticsService {
  final Dio _dio;
  final AuthService _authService;

  AnalyticsService({required Dio dio, required AuthService authService})
    : _dio = dio,
      _authService = authService;

  /// ✅ MÉTHODE POUR OBTENIR LA LANGUE ACTUELLE
  String _getCurrentLanguage() {
    // Récupérer la langue depuis le contexte global ou les préférences
    // Pour l'instant, on utilise la locale système
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final languageCode = locale.languageCode;

    // Supporter seulement français et anglais
    if (languageCode == 'fr' || languageCode == 'en') {
      return languageCode;
    }

    // Défaut : français
    return 'fr';
  }

  /// ✅ MÉTHODE POUR AJOUTER LES HEADERS DE LANGUE
  Map<String, String> _getHeaders() {
    final language = _getCurrentLanguage();
    return {'Accept-Language': language, 'Content-Type': 'application/json'};
  }

  Future<Map<String, dynamic>> getDashboard([String? currencyCode]) async {
    final token = await _authService.getToken();

    final queryParams = <String, dynamic>{};
    if (currencyCode != null) {
      queryParams['currency'] = currencyCode;
    }
    // ✅ Ajouter la langue aux paramètres
    queryParams['lang'] = _getCurrentLanguage();

    final response = await _dio.get(
      '/analytics/dashboard',
      queryParameters: queryParams,
      options: Options(
        headers: {'Authorization': 'Bearer $token', ..._getHeaders()},
      ),
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
    // ✅ Ajouter la langue
    queryParams['lang'] = _getCurrentLanguage();

    final response = await _dio.get(
      '/analytics/spending/monthly',
      queryParameters: queryParams,
      options: Options(
        headers: {'Authorization': 'Bearer $token', ..._getHeaders()},
      ),
    );

    if (response.data['success'] == true) {
      return response.data['data'] as Map<String, dynamic>;
    } else {
      throw Exception(
        response.data['error']['message'] ?? 'Erreur données mensuelles',
      );
    }
  }

  /// ✅ NOUVEAU: Méthode pour les dépenses quotidiennes
  Future<Map<String, dynamic>> getDailySpending({
    int days = 30,
    String? currencyCode,
  }) async {
    final token = await _authService.getToken();

    final queryParams = <String, dynamic>{'days': days};
    if (currencyCode != null) {
      queryParams['currency'] = currencyCode;
    }
    queryParams['lang'] = _getCurrentLanguage();

    final response = await _dio.get(
      '/analytics/spending/daily',
      queryParameters: queryParams,
      options: Options(
        headers: {'Authorization': 'Bearer $token', ..._getHeaders()},
      ),
    );

    if (response.data['success'] == true) {
      return response.data['data'] as Map<String, dynamic>;
    } else {
      throw Exception(
        response.data['error']['message'] ?? 'Erreur données quotidiennes',
      );
    }
  }

  /// ✅ NOUVEAU: Méthode pour les dépenses hebdomadaires
  Future<Map<String, dynamic>> getWeeklySpending({
    int weeks = 12,
    String? currencyCode,
  }) async {
    final token = await _authService.getToken();

    final queryParams = <String, dynamic>{'weeks': weeks};
    if (currencyCode != null) {
      queryParams['currency'] = currencyCode;
    }
    queryParams['lang'] = _getCurrentLanguage();

    final response = await _dio.get(
      '/analytics/spending/weekly',
      queryParameters: queryParams,
      options: Options(
        headers: {'Authorization': 'Bearer $token', ..._getHeaders()},
      ),
    );

    if (response.data['success'] == true) {
      return response.data['data'] as Map<String, dynamic>;
    } else {
      throw Exception(
        response.data['error']['message'] ?? 'Erreur données hebdomadaires',
      );
    }
  }

  /// ✅ NOUVEAU: Méthode pour les dépenses annuelles
  Future<Map<String, dynamic>> getYearlySpending({
    int years = 5,
    String? currencyCode,
  }) async {
    final token = await _authService.getToken();

    final queryParams = <String, dynamic>{'years': years};
    if (currencyCode != null) {
      queryParams['currency'] = currencyCode;
    }
    queryParams['lang'] = _getCurrentLanguage();

    final response = await _dio.get(
      '/analytics/spending/yearly',
      queryParameters: queryParams,
      options: Options(
        headers: {'Authorization': 'Bearer $token', ..._getHeaders()},
      ),
    );

    if (response.data['success'] == true) {
      return response.data['data'] as Map<String, dynamic>;
    } else {
      throw Exception(
        response.data['error']['message'] ?? 'Erreur données annuelles',
      );
    }
  }

  /// ✅ MODIFIÉ: Méthode getSpendingTrends mise à jour pour utiliser les nouveaux endpoints
  Future<Map<String, dynamic>> getSpendingTrends({
    String period = 'month',
    String? currencyCode,
  }) async {
    // Rediriger vers les bonnes méthodes selon la période
    switch (period) {
      case 'day':
        return await getDailySpending(currencyCode: currencyCode);
      case 'week':
        return await getWeeklySpending(currencyCode: currencyCode);
      case 'year':
        return await getYearlySpending(currencyCode: currencyCode);
      case 'month':
      default:
        return await getMonthlySpending(currencyCode: currencyCode);
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
    // ✅ Ajouter la langue
    queryParams['lang'] = _getCurrentLanguage();

    final response = await _dio.get(
      '/analytics/spending/categories',
      queryParameters: queryParams,
      options: Options(
        headers: {'Authorization': 'Bearer $token', ..._getHeaders()},
      ),
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
    // ✅ Ajouter la langue
    queryParams['lang'] = _getCurrentLanguage();

    final response = await _dio.get(
      '/analytics/products/top',
      queryParameters: queryParams,
      options: Options(
        headers: {'Authorization': 'Bearer $token', ..._getHeaders()},
      ),
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
    // ✅ Ajouter la langue
    queryParams['lang'] = _getCurrentLanguage();

    final response = await _dio.get(
      '/analytics/spending/comparison',
      queryParameters: queryParams,
      options: Options(
        headers: {'Authorization': 'Bearer $token', ..._getHeaders()},
      ),
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
