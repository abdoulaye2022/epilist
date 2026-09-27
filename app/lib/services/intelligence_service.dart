// services/intelligence_service.dart - Client API de l'intelligence du
// foyer : prédictions, inventaire, projection budget, listes récurrentes
// et planificateur de repas. Dio partagé (jeton + refresh gérés).
//
// Les réglages ON/OFF (section « Intelligence EpiList ») sont stockés en
// SharedPreferences : ce sont des préférences d'affichage côté client.
import 'package:dio/dio.dart';
import 'package:epilist/models/intelligence.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntelligenceSettings {
  static const keyPredictions = 'intel_predictions_enabled';
  static const keyInventoryEstimates = 'intel_inventory_estimates_enabled';
  static const keyAutoAddOut = 'intel_auto_add_out_of_stock';
  static const keyBudgetForecast = 'intel_budget_forecast_enabled';

  static Future<bool> get(String key, {bool defaultValue = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }

  static Future<void> set(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {}
  }
}

class IntelligenceService {
  final Dio _dio;

  IntelligenceService({required Dio dio}) : _dio = dio;

  // --- Prédictions -------------------------------------------------------

  Future<List<ProductPrediction>> getPredictions({
    bool all = false,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/predictions',
      queryParameters: {'all': all, 'limit': limit},
    );
    final data = response.data['data']['predictions'] as List<dynamic>? ?? [];
    return data
        .map((e) => ProductPrediction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// action : added | not_now | still_have | never
  Future<void> sendPredictionFeedback(String productName, String action) async {
    await _dio.post(
      '/predictions/feedback',
      data: {'product_name': productName, 'action': action},
    );
  }

  // --- Inventaire ----------------------------------------------------------

  Future<List<InventoryItem>> getInventory() async {
    final response = await _dio.get('/inventory');
    final data = response.data['data']['items'] as List<dynamic>? ?? [];
    return data
        .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<InventoryItem> setInventoryStatus(
    String productName,
    String status,
  ) async {
    final response = await _dio.post(
      '/inventory/status',
      data: {'product_name': productName, 'status': status},
    );
    return InventoryItem.fromJson(
      response.data['data']['item'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteInventoryItem(int id) async {
    await _dio.delete('/inventory/$id');
  }

  // --- Budget ---------------------------------------------------------------

  Future<BudgetForecast> getBudgetForecast() async {
    final response = await _dio.get('/budgets/forecast');
    return BudgetForecast.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  // --- Listes récurrentes -----------------------------------------------------

  Future<List<RecurringListModel>> getRecurringLists() async {
    final response = await _dio.get('/recurring-lists');
    final data =
        response.data['data']['recurring_lists'] as List<dynamic>? ?? [];
    return data
        .map((e) => RecurringListModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RecurringListModel> createRecurringList({
    required String name,
    required String recurrenceType,
    int? weekday,
    bool autoGenerate = false,
    required List<String> productNames,
  }) async {
    final response = await _dio.post('/recurring-lists', data: {
      'name': name,
      'recurrence_type': recurrenceType,
      if (weekday != null) 'weekday': weekday,
      'auto_generate': autoGenerate,
      'items': productNames.map((n) => {'product_name': n}).toList(),
    });
    return RecurringListModel.fromJson(
      response.data['data']['recurring_list'] as Map<String, dynamic>,
    );
  }

  Future<RecurringListModel> updateRecurringList(
    int id,
    Map<String, dynamic> changes,
  ) async {
    final response = await _dio.put('/recurring-lists/$id', data: changes);
    return RecurringListModel.fromJson(
      response.data['data']['recurring_list'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteRecurringList(int id) async {
    await _dio.delete('/recurring-lists/$id');
  }

  Future<List<RecurringPreviewItem>> previewRecurringList(int id) async {
    final response = await _dio.get('/recurring-lists/$id/preview');
    final data = response.data['data']['items'] as List<dynamic>? ?? [];
    return data
        .map((e) => RecurringPreviewItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Crée la vraie liste de courses ; retourne son id.
  Future<int> generateRecurringList(
    int id,
    List<RecurringPreviewItem> chosen,
  ) async {
    final response = await _dio.post('/recurring-lists/$id/generate', data: {
      'items': chosen
          .map((i) => {'product_name': i.productName, 'quantity': i.quantity})
          .toList(),
    });
    return (response.data['data']['shopping_list_id'] as num).toInt();
  }

  // --- Planificateur de repas ---------------------------------------------------

  Future<List<RecipeSummary>> getRecipes() async {
    final response = await _dio.get('/recipes');
    final data = response.data['data']['recipes'] as List<dynamic>? ?? [];
    return data
        .map((e) => RecipeSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MealPlanPreview> previewMealPlan({
    required List<int> recipeIds,
    required int people,
    double? budgetMax,
  }) async {
    final response = await _dio.post('/meal-plans/preview', data: {
      'recipe_ids': recipeIds,
      'people': people,
      if (budgetMax != null) 'budget_max': budgetMax,
    });
    return MealPlanPreview.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// Enregistre le plan et crée la liste ; retourne l'id de la liste.
  Future<int> createMealPlan({
    required List<int> recipeIds,
    required int people,
    double? budgetMax,
    required List<MealPlanItem> items,
  }) async {
    final response = await _dio.post('/meal-plans', data: {
      'recipe_ids': recipeIds,
      'people': people,
      if (budgetMax != null) 'budget_max': budgetMax,
      'items': items
          .map((i) => {'product_name': i.productName, 'quantity': i.quantity})
          .toList(),
    });
    return (response.data['data']['shopping_list_id'] as num).toInt();
  }
}
