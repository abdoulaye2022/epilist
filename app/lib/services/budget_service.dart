// services/budget_service.dart
import 'package:dio/dio.dart';
import 'package:epilist/models/budget.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:flutter/foundation.dart';

class BudgetService {
  final Dio _dio;
  final AuthService _authService;

  BudgetService({required Dio dio, required AuthService authService})
    : _dio = dio,
      _authService = authService;

  /// Obtenir tous les budgets avec filtres optionnels
  Future<List<Budget>> getBudgets({
    String? status, // 'active', 'expired', 'upcoming', 'exceeded'
    String? periodType, // 'weekly', 'monthly', 'yearly', 'custom'
    String? listId, // ID de liste ou 'general'
  }) async {
    try {
      final token = await _authService.getToken();

      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (periodType != null) queryParams['period_type'] = periodType;
      if (listId != null) queryParams['list_id'] = listId;

      debugPrint('🔄 Chargement des budgets avec filtres: $queryParams');

      final response = await _dio.get(
        '/budgets',
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('✅ Budgets chargés: ${response.data['data'].length} budgets');

      return (response.data['data'] as List)
          .map((json) => Budget.fromJson(json))
          .toList();
    } on DioException catch (e) {
      debugPrint(
        '❌ Erreur lors du chargement des budgets: ${e.response?.data}',
      );
      throw _handleDioError(e, 'Erreur lors du chargement des budgets');
    }
  }

  /// Obtenir un budget spécifique
  Future<Budget> getBudget(int budgetId) async {
    try {
      final token = await _authService.getToken();

      debugPrint('🔄 Chargement du budget: $budgetId');

      final response = await _dio.get(
        '/budgets/$budgetId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('✅ Budget chargé: ${response.data['data']['name']}');

      return Budget.fromJson(response.data['data']);
    } on DioException catch (e) {
      debugPrint('❌ Erreur lors du chargement du budget: ${e.response?.data}');
      throw _handleDioError(e, 'Erreur lors du chargement du budget');
    }
  }

  /// ✅ CRÉATION DE BUDGET CORRIGÉE
  Future<Budget> createBudget(CreateBudgetRequest request) async {
    try {
      final token = await _authService.getToken();

      debugPrint('🔄 Création du budget: ${request.name}');
      debugPrint('📊 Données: ${request.toJson()}');

      final response = await _dio.post(
        '/budgets',
        data: request.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('✅ Budget créé avec succès: ${response.data['data']['name']}');

      return Budget.fromJson(response.data['data']);
    } on DioException catch (e) {
      debugPrint('❌ Erreur lors de la création du budget: ${e.response?.data}');
      throw _handleDioError(e, 'Erreur lors de la création du budget');
    }
  }

  /// ✅ MISE À JOUR DE BUDGET CORRIGÉE
  Future<Budget> updateBudget(int budgetId, UpdateBudgetRequest request) async {
    try {
      final token = await _authService.getToken();

      debugPrint('🔄 Mise à jour du budget: $budgetId');
      debugPrint('📊 Données: ${request.toJson()}');

      final response = await _dio.put(
        '/budgets/$budgetId',
        data: request.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('✅ Budget mis à jour avec succès');

      return Budget.fromJson(response.data['data']);
    } on DioException catch (e) {
      debugPrint(
        '❌ Erreur lors de la mise à jour du budget: ${e.response?.data}',
      );
      throw _handleDioError(e, 'Erreur lors de la mise à jour du budget');
    }
  }

  /// Supprimer un budget
  Future<void> deleteBudget(int budgetId) async {
    try {
      final token = await _authService.getToken();

      debugPrint('🔄 Suppression du budget: $budgetId');

      await _dio.delete(
        '/budgets/$budgetId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('✅ Budget supprimé avec succès');
    } on DioException catch (e) {
      debugPrint(
        '❌ Erreur lors de la suppression du budget: ${e.response?.data}',
      );
      throw _handleDioError(e, 'Erreur lors de la suppression du budget');
    }
  }

  /// Obtenir le tableau de bord des budgets
  Future<Map<String, dynamic>> getBudgetDashboard() async {
    try {
      final token = await _authService.getToken();

      debugPrint('🔄 Chargement du tableau de bord budgets');

      final response = await _dio.get(
        '/budgets/dashboard',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('✅ Tableau de bord chargé');

      final data = response.data['data'];
      return {
        'summary': BudgetSummary.fromJson(data['summary']),
        'status_breakdown': data['status_breakdown'],
        'current_budgets':
            (data['current_budgets'] as List)
                .map((json) => Budget.fromJson(json))
                .toList(),
        'recent_expired':
            (data['recent_expired'] as List)
                .map((json) => Budget.fromJson(json))
                .toList(),
        'performance': data['performance'],
      };
    } on DioException catch (e) {
      debugPrint(
        '❌ Erreur lors du chargement du tableau de bord: ${e.response?.data}',
      );
      throw _handleDioError(e, 'Erreur lors du chargement du tableau de bord');
    }
  }

  /// Obtenir les alertes de budget
  Future<List<BudgetAlert>> getBudgetAlerts() async {
    try {
      final token = await _authService.getToken();

      debugPrint('🔄 Chargement des alertes budgets');

      final response = await _dio.get(
        '/budgets/alerts',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('✅ Alertes chargées: ${response.data['data'].length} alertes');

      return (response.data['data'] as List)
          .map((json) => BudgetAlert.fromJson(json))
          .toList();
    } on DioException catch (e) {
      debugPrint(
        '❌ Erreur lors du chargement des alertes: ${e.response?.data}',
      );
      throw _handleDioError(e, 'Erreur lors du chargement des alertes');
    }
  }

  /// ✅ CRÉATION DE BUDGET RAPIDE CORRIGÉE
  Future<Budget> createQuickBudget({
    required String type, // 'weekly', 'monthly', 'yearly'
    required double amount,
    String? name,
    int? listId,
  }) async {
    try {
      final token = await _authService.getToken();

      debugPrint('🔄 Création du budget rapide: $type - $amount');

      final data = {
        'type': type,
        'amount': amount,
        if (name != null) 'name': name,
        if (listId != null) 'list_id': listId,
      };

      final response = await _dio.post(
        '/budgets/quick',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('✅ Budget rapide créé avec succès');

      return Budget.fromJson(response.data['data']);
    } on DioException catch (e) {
      debugPrint(
        '❌ Erreur lors de la création du budget rapide: ${e.response?.data}',
      );
      throw _handleDioError(e, 'Erreur lors de la création du budget rapide');
    }
  }

  /// Obtenir les budgets actifs avec leurs statistiques
  Future<List<Budget>> getActiveBudgets() async {
    return getBudgets(status: 'active');
  }

  /// Obtenir les budgets dépassés
  Future<List<Budget>> getExceededBudgets() async {
    return getBudgets(status: 'exceeded');
  }

  /// Obtenir les budgets généraux (non liés à une liste)
  Future<List<Budget>> getGeneralBudgets() async {
    return getBudgets(listId: 'general');
  }

  /// Obtenir les budgets pour une liste spécifique
  Future<List<Budget>> getListBudgets(int listId) async {
    return getBudgets(listId: listId.toString());
  }

  /// ✅ GESTION DES ERREURS AMÉLIORÉE
  Exception _handleDioError(DioException e, String defaultMessage) {
    final responseData = e.response?.data;

    // ✅ Gestion spécifique des réponses JSON de l'API
    if (responseData is Map<String, dynamic>) {
      final error = responseData['error'];

      if (error is Map<String, dynamic>) {
        final code = error['code'];
        final message = error['message'];

        // ✅ Gestion spécifique des codes d'erreur de l'API
        switch (code) {
          case 'OVERLAPPING_BUDGET':
            return Exception(
              '🚨 Un budget existe déjà pour cette période et ce scope. Veuillez choisir des dates différentes ou modifier le budget existant.',
            );
          case 'VALIDATION_ERROR':
            final validationErrors = error['validation_errors'];
            if (validationErrors != null) {
              final errorMessages = <String>[];
              if (validationErrors is Map) {
                validationErrors.forEach((field, messages) {
                  if (messages is List) {
                    errorMessages.addAll(messages.cast<String>());
                  }
                });
                return Exception(
                  '❌ Erreurs de validation:\n${errorMessages.join('\n• ')}',
                );
              }
            }
            return Exception('❌ ${message ?? 'Données invalides'}');
          case 'ACCESS_DENIED':
            return Exception('🔒 Accès refusé à cette ressource');
          case 'NOT_FOUND':
            return Exception('🔍 Budget non trouvé');
          case 'INTERNAL_ERROR':
            return Exception(
              '⚠️ Erreur du serveur. Veuillez réessayer plus tard.',
            );
          default:
            return Exception(message ?? defaultMessage);
        }
      } else {
        // ✅ Si pas de structure error, chercher message directement
        final message = responseData['message'];
        if (message != null) {
          return Exception(message);
        }
      }
    }

    // ✅ Gestion des codes de statut HTTP standard
    switch (e.response?.statusCode) {
      case 401:
        return Exception('Session expirée, veuillez vous reconnecter');
      case 403:
        return Exception('Accès refusé');
      case 404:
        return Exception('Budget non trouvé');
      case 409:
        return Exception('Un budget existe déjà pour cette période');
      case 422:
        return Exception('Données invalides');
      case 500:
        return Exception('Erreur du serveur');
      default:
        return Exception(defaultMessage);
    }
  }
}
