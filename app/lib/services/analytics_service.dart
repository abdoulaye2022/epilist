// services/analytics_service.dart - VERSION AVEC FILTRAGE
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

  String _getCurrentLanguage() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final languageCode = locale.languageCode;

    if (languageCode == 'fr' || languageCode == 'en') {
      return languageCode;
    }

    return 'fr';
  }

  Map<String, String> _getHeaders() {
    final language = _getCurrentLanguage();
    return {'Accept-Language': language, 'Content-Type': 'application/json'};
  }

  // ✅ MODIFIÉ: Dashboard avec support du filtrage
  Future<Map<String, dynamic>> getDashboard([
    String? currencyCode,
    bool includeShared = true,
  ]) async {
    final token = await _authService.getToken();

    final queryParams = <String, dynamic>{};
    if (currencyCode != null) {
      queryParams['currency'] = currencyCode;
    }
    // ✅ NOUVEAU: Paramètre pour inclure/exclure les listes partagées
    queryParams['include_shared'] = includeShared.toString();
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

  // ✅ MODIFIÉ: Dépenses mensuelles avec filtrage
  Future<Map<String, dynamic>> getMonthlySpending({
    int months = 12,
    String? currencyCode,
    bool includeShared = true,
  }) async {
    final token = await _authService.getToken();

    final queryParams = <String, dynamic>{
      'months': months,
      'include_shared': includeShared.toString(),
    };
    if (currencyCode != null) {
      queryParams['currency'] = currencyCode;
    }
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

  // ✅ MODIFIÉ: Dépenses quotidiennes avec filtrage
  Future<Map<String, dynamic>> getDailySpending({
    int days = 30,
    String? currencyCode,
    bool includeShared = true,
  }) async {
    final token = await _authService.getToken();

    final queryParams = <String, dynamic>{
      'days': days,
      'include_shared': includeShared.toString(),
    };
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

  // ✅ MODIFIÉ: Dépenses hebdomadaires avec filtrage
  Future<Map<String, dynamic>> getWeeklySpending({
    int weeks = 12,
    String? currencyCode,
    bool includeShared = true,
  }) async {
    final token = await _authService.getToken();

    final queryParams = <String, dynamic>{
      'weeks': weeks,
      'include_shared': includeShared.toString(),
    };
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

  // ✅ MODIFIÉ: Dépenses annuelles avec filtrage
  Future<Map<String, dynamic>> getYearlySpending({
    int years = 5,
    String? currencyCode,
    bool includeShared = true,
  }) async {
    final token = await _authService.getToken();

    final queryParams = <String, dynamic>{
      'years': years,
      'include_shared': includeShared.toString(),
    };
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

  // ✅ MODIFIÉ: Tendances avec filtrage
  Future<Map<String, dynamic>> getSpendingTrends({
    String period = 'month',
    String? currencyCode,
    bool includeShared = true,
  }) async {
    switch (period) {
      case 'day':
        return await getDailySpending(
          currencyCode: currencyCode,
          includeShared: includeShared,
        );
      case 'week':
        return await getWeeklySpending(
          currencyCode: currencyCode,
          includeShared: includeShared,
        );
      case 'year':
        return await getYearlySpending(
          currencyCode: currencyCode,
          includeShared: includeShared,
        );
      case 'month':
      default:
        return await getMonthlySpending(
          currencyCode: currencyCode,
          includeShared: includeShared,
        );
    }
  }

  // ✅ MODIFIÉ: Catégories avec filtrage
  Future<Map<String, dynamic>> getSpendingCategories({
    String period = 'month',
    int limit = 10,
    String? currencyCode,
    bool includeShared = true,
  }) async {
    final token = await _authService.getToken();

    final queryParams = <String, dynamic>{
      'period': period,
      'limit': limit,
      'include_shared': includeShared.toString(),
    };
    if (currencyCode != null) {
      queryParams['currency'] = currencyCode;
    }
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

  // ✅ MODIFIÉ: Top produits avec filtrage
  Future<Map<String, dynamic>> getTopProducts({
    String period = 'month',
    String sortBy = 'total_spent',
    int limit = 10,
    String? currencyCode,
    bool includeShared = true,
  }) async {
    final token = await _authService.getToken();

    final queryParams = <String, dynamic>{
      'period': period,
      'sort_by': sortBy,
      'limit': limit,
      'include_shared': includeShared.toString(),
    };
    if (currencyCode != null) {
      queryParams['currency'] = currencyCode;
    }
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

  // ✅ MODIFIÉ: Comparaison des périodes avec filtrage
  Future<Map<String, dynamic>> getPeriodComparison({
    String periodType = 'month',
    String? currencyCode,
    bool includeShared = true,
  }) async {
    final token = await _authService.getToken();

    final queryParams = <String, dynamic>{
      'period_type': periodType,
      'include_shared': includeShared.toString(),
    };
    if (currencyCode != null) {
      queryParams['currency'] = currencyCode;
    }
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

  // ✅ NOUVEAU: Obtenir les statistiques de répartition des listes
  Future<Map<String, dynamic>> getListsBreakdown({
    String period = 'month',
    String? currencyCode,
  }) async {
    final token = await _authService.getToken();

    final queryParams = <String, dynamic>{'period': period};
    if (currencyCode != null) {
      queryParams['currency'] = currencyCode;
    }
    queryParams['lang'] = _getCurrentLanguage();

    final response = await _dio.get(
      '/analytics/lists-breakdown',
      queryParameters: queryParams,
      options: Options(
        headers: {'Authorization': 'Bearer $token', ..._getHeaders()},
      ),
    );

    if (response.data['success'] == true) {
      return response.data['data'] as Map<String, dynamic>;
    } else {
      throw Exception(
        response.data['error']['message'] ?? 'Erreur breakdown listes',
      );
    }
  }

  // ✅ Rapport de propriétaire de liste
  Future<Map<String, dynamic>> getOwnerListReport(
    String listId, {
    String? currencyCode,
  }) async {
    final token = await _authService.getToken();

    final queryParams = <String, dynamic>{};
    if (currencyCode != null) {
      queryParams['currency'] = currencyCode;
    }
    queryParams['lang'] = _getCurrentLanguage();

    final response = await _dio.get(
      '/analytics/list/$listId/owner-report',
      queryParameters: queryParams,
      options: Options(
        headers: {'Authorization': 'Bearer $token', ..._getHeaders()},
      ),
    );

    if (response.data['success'] == true) {
      return response.data['data'] as Map<String, dynamic>;
    } else {
      throw Exception(
        response.data['error']['message'] ?? 'Erreur rapport propriétaire',
      );
    }
  }

  // ✅ Rapport de contribution d'un participant
  Future<Map<String, dynamic>> getParticipantReport(
    String listId, {
    String? currencyCode,
  }) async {
    final token = await _authService.getToken();

    final queryParams = <String, dynamic>{};
    if (currencyCode != null) {
      queryParams['currency'] = currencyCode;
    }
    queryParams['lang'] = _getCurrentLanguage();

    final response = await _dio.get(
      '/analytics/list/$listId/participant-report',
      queryParameters: queryParams,
      options: Options(
        headers: {'Authorization': 'Bearer $token', ..._getHeaders()},
      ),
    );

    if (response.data['success'] == true) {
      return response.data['data'] as Map<String, dynamic>;
    } else {
      throw Exception(
        response.data['error']['message'] ?? 'Erreur rapport participant',
      );
    }
  }

  // ✅ Rapport de transparence
  Future<Map<String, dynamic>> getTransparencyReport(
    String listId, {
    String? currencyCode,
  }) async {
    final token = await _authService.getToken();

    final queryParams = <String, dynamic>{};
    if (currencyCode != null) {
      queryParams['currency'] = currencyCode;
    }
    queryParams['lang'] = _getCurrentLanguage();

    final response = await _dio.get(
      '/analytics/list/$listId/transparency',
      queryParameters: queryParams,
      options: Options(
        headers: {'Authorization': 'Bearer $token', ..._getHeaders()},
      ),
    );

    if (response.data['success'] == true) {
      return response.data['data'] as Map<String, dynamic>;
    } else {
      throw Exception(
        response.data['error']['message'] ?? 'Erreur rapport transparence',
      );
    }
  }

  // ✅ Rapport d'impact budgétaire
  Future<Map<String, dynamic>> getBudgetImpactReport(
    String listId, {
    String? currencyCode,
  }) async {
    final token = await _authService.getToken();

    final queryParams = <String, dynamic>{};
    if (currencyCode != null) {
      queryParams['currency'] = currencyCode;
    }
    queryParams['lang'] = _getCurrentLanguage();

    final response = await _dio.get(
      '/analytics/list/$listId/budget-impact',
      queryParameters: queryParams,
      options: Options(
        headers: {'Authorization': 'Bearer $token', ..._getHeaders()},
      ),
    );

    if (response.data['success'] == true) {
      return response.data['data'] as Map<String, dynamic>;
    } else {
      throw Exception(
        response.data['error']['message'] ?? 'Erreur rapport budget',
      );
    }
  }
}
