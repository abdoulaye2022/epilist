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

  /// Upsert d'un état d'inventaire. Les champs quantitatifs (§21) ne
  /// sont ENVOYÉS que s'ils sont fournis : le serveur ne touche pas
  /// aux champs absents (un changement de statut n'efface jamais les
  /// seuils).
  Future<InventoryItem> setInventoryStatus(
    String productName,
    String status, {
    double? quantity,
    String? unit,
    double? minQuantity,
    double? reorderQuantity,
    // Ces trois-là s'envoient MÊME à null : c'est ainsi qu'on efface
    // une date de péremption ou un niveau. Les drapeaux disent de les
    // mettre dans le corps, la valeur dit quoi y mettre.
    bool sendExpiresAt = false,
    DateTime? expiresAt,
    bool sendLevel = false,
    String? level,
  }) async {
    final response = await _dio.post(
      '/inventory/status',
      data: {
        'product_name': productName,
        'status': status,
        if (quantity != null) 'quantity': quantity,
        if (unit != null) 'unit': unit,
        if (minQuantity != null) 'min_quantity': minQuantity,
        if (reorderQuantity != null) 'reorder_quantity': reorderQuantity,
        if (sendExpiresAt)
          'expires_at': expiresAt?.toIso8601String().substring(0, 10),
        if (sendLevel) 'level': level,
      },
    );
    return InventoryItem.fromJson(
      response.data['data']['item'] as Map<String, dynamic>,
    );
  }

  /// Les boutons « − » et « + ». Ils ne touchent QUE la quantité :
  /// l'état se recalcule côté serveur, le seuil et la date ne bougent
  /// pas.
  Future<InventoryItem> setInventoryQuantity(int id, double quantity) async {
    final response = await _dio.post(
      '/inventory/$id/quantity',
      data: {'quantity': quantity},
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
    final response = await _dio.post(
      '/recurring-lists',
      data: {
        'name': name,
        'recurrence_type': recurrenceType,
        if (weekday != null) 'weekday': weekday,
        'auto_generate': autoGenerate,
        'items': productNames.map((n) => {'product_name': n}).toList(),
      },
    );
    return RecurringListModel.fromJson(
      response.data['data']['recurring_list'] as Map<String, dynamic>,
    );
  }

  /// La même création, mais avec les QUANTITÉS. Le serveur lit
  /// « quantity » là où il rend « default_quantity » : la conversion se
  /// fait côté appelant, pas ici.
  Future<RecurringListModel> createRecurringListWithItems({
    required String name,
    required String recurrenceType,
    int? weekday,
    bool autoGenerate = false,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _dio.post(
      '/recurring-lists',
      data: {
        'name': name,
        'recurrence_type': recurrenceType,
        if (weekday != null) 'weekday': weekday,
        'auto_generate': autoGenerate,
        'items': items,
      },
    );
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
    final response = await _dio.post(
      '/recurring-lists/$id/generate',
      data: {
        'items':
            chosen
                .map(
                  (i) => {
                    'product_name': i.productName,
                    'quantity': i.quantity,
                  },
                )
                .toList(),
      },
    );
    return (response.data['data']['shopping_list_id'] as num).toInt();
  }

  // --- Planificateur de repas ---------------------------------------------------

  /// Le catalogue, filtré.
  ///
  /// [q] cherche dans le NOM et dans les INGRÉDIENTS (« qu'est-ce que
  /// je fais avec du poulet ? »), [maxTime] en minutes, [favoritesOnly]
  /// ne garde que les favorites. Sans filtre, tout le catalogue, les
  /// favorites d'abord.
  Future<List<RecipeSummary>> getRecipes({
    String? q,
    int? maxTime,
    bool favoritesOnly = false,
  }) async {
    final response = await _dio.get(
      '/recipes',
      queryParameters: {
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (maxTime != null) 'max_time': maxTime,
        if (favoritesOnly) 'favorites': 1,
      },
    );
    final data = response.data['data']['recipes'] as List<dynamic>? ?? [];
    return data
        .map((e) => RecipeSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// « Écrire mon repas » : une recette à soi, avec ses ingrédients.
  ///
  /// Les ingrédients sont facultatifs — un repas sans ingrédient
  /// n'ajoutera rien aux courses, et c'est l'écran qui le dit.
  Future<RecipeSummary> createRecipe({
    required String name,
    int servings = 4,
    int? preparationTime,
    List<Map<String, dynamic>> ingredients = const [],
  }) async {
    final response = await _dio.post(
      '/recipes',
      data: {
        'name': name,
        'servings': servings,
        if (preparationTime != null) 'preparation_time': preparationTime,
        'ingredients': ingredients,
      },
    );
    return RecipeSummary.fromJson(
      response.data['data']['recipe'] as Map<String, dynamic>,
    );
  }

  Future<MealPlanPreview> previewMealPlan({
    required List<int> recipeIds,
    required int people,
    double? budgetMax,
  }) async {
    final response = await _dio.post(
      '/meal-plans/preview',
      data: {
        'recipe_ids': recipeIds,
        'people': people,
        if (budgetMax != null) 'budget_max': budgetMax,
      },
    );
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
    List<Map<String, dynamic>>? assignments,
  }) async {
    final response = await _dio.post(
      '/meal-plans',
      data: {
        'recipe_ids': recipeIds,
        'people': people,
        if (budgetMax != null) 'budget_max': budgetMax,
        // Un repas place, c'est une recette, un JOUR et un MOMENT :
        // 1 = lundi ... 7 = dimanche, 'lunch' ou 'dinner'. Une LISTE,
        // et non une table par recette — le meme plat peut revenir
        // deux fois dans la semaine, et deux repas peuvent tomber le
        // meme jour.
        if (assignments != null && assignments.isNotEmpty)
          'assignments': assignments,
        'items':
            items
                .map(
                  (i) => {
                    'product_name': i.productName,
                    'quantity': i.quantity,
                  },
                )
                .toList(),
      },
    );
    return (response.data['data']['shopping_list_id'] as num).toInt();
  }

  /// Allume ou éteint l'étoile d'une recette.
  ///
  /// Le favori appartient au MEMBRE : les recettes livrées avec
  /// l'application sont partagées par tous les comptes, donc le marquer
  /// sur la recette elle-même aurait valu pour tout le monde.
  Future<void> setRecipeFavorite(int recipeId, bool favorite) async {
    if (favorite) {
      await _dio.put('/recipes/$recipeId/favorite');
    } else {
      await _dio.delete('/recipes/$recipeId/favorite');
    }
  }
}
