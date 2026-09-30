// models/intelligence.dart - Prédictions d'achat, inventaire maison,
// projection budgétaire, listes récurrentes et planificateur de repas.

/// Prédiction « Il te manque probablement… » pour un produit.
class ProductPrediction {
  final String productName;
  final int frequencyDays;
  final DateTime lastPurchasedAt;
  final int daysSinceLast;

  /// not_needed | soon | likely_needed | overdue
  final String status;

  /// low | medium | high
  final String confidence;
  final int purchasesCount;
  final double avgQuantity;
  final String? usualStore;
  final String? inventoryStatus;

  const ProductPrediction({
    required this.productName,
    required this.frequencyDays,
    required this.lastPurchasedAt,
    required this.daysSinceLast,
    required this.status,
    required this.confidence,
    required this.purchasesCount,
    this.avgQuantity = 1,
    this.usualStore,
    this.inventoryStatus,
  });

  factory ProductPrediction.fromJson(Map<String, dynamic> json) =>
      ProductPrediction(
        productName: json['product_name'] as String,
        frequencyDays: (json['frequency_days'] as num).toInt(),
        lastPurchasedAt: DateTime.parse(json['last_purchased_at'] as String),
        daysSinceLast: (json['days_since_last'] as num).toInt(),
        status: json['status'] as String,
        confidence: json['confidence'] as String? ?? 'low',
        purchasesCount: (json['purchases_count'] as num?)?.toInt() ?? 0,
        avgQuantity: (json['avg_quantity'] as num?)?.toDouble() ?? 1,
        usualStore: json['usual_store'] as String?,
        inventoryStatus: json['inventory_status'] as String?,
      );
}

/// Produit de l'inventaire maison (3 états simples).
class InventoryItem {
  final int id;
  final String productName;
  final String status; // at_home | running_low | out
  final double? quantity;
  final String? unit;
  final String source; // manual | estimated
  final DateTime? updatedAt;

  /// Estimation issue de l'historique — informative, jamais prioritaire.
  final String? estimatedStatus;

  /// Inventaire quantitatif (§21, espaces pro) : seuils et alerte.
  final double? minQuantity;
  final double? reorderQuantity;
  final bool belowMin;

  const InventoryItem({
    required this.id,
    required this.productName,
    required this.status,
    this.quantity,
    this.unit,
    this.source = 'manual',
    this.updatedAt,
    this.estimatedStatus,
    this.minQuantity,
    this.reorderQuantity,
    this.belowMin = false,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
    id: (json['id'] as num).toInt(),
    productName: json['product_name'] as String,
    status: json['status'] as String,
    quantity: (json['quantity'] as num?)?.toDouble(),
    unit: json['unit'] as String?,
    source: json['source'] as String? ?? 'manual',
    updatedAt: json['updated_at'] != null
        ? DateTime.tryParse(json['updated_at'] as String)
        : null,
    estimatedStatus: json['estimated_status'] as String?,
    minQuantity: (json['min_quantity'] as num?)?.toDouble(),
    reorderQuantity: (json['reorder_quantity'] as num?)?.toDouble(),
    belowMin: json['below_min'] == true,
  );
}

/// Projection budgétaire du mois courant.
class BudgetForecast {
  final bool hasBudget;
  final double budgetAmount;
  final double spent;
  final double remaining;
  final int daysLeft;
  final double perDayRemaining;
  final double projection;
  final double projectionGap;
  final double weeklyRecommended;
  final double? paceDeltaPct;

  const BudgetForecast({
    required this.hasBudget,
    this.budgetAmount = 0,
    this.spent = 0,
    this.remaining = 0,
    this.daysLeft = 0,
    this.perDayRemaining = 0,
    this.projection = 0,
    this.projectionGap = 0,
    this.weeklyRecommended = 0,
    this.paceDeltaPct,
  });

  factory BudgetForecast.fromJson(Map<String, dynamic> json) => BudgetForecast(
    hasBudget: json['has_budget'] as bool? ?? false,
    budgetAmount: (json['budget_amount'] as num?)?.toDouble() ?? 0,
    spent: (json['spent'] as num?)?.toDouble() ?? 0,
    remaining: (json['remaining'] as num?)?.toDouble() ?? 0,
    daysLeft: (json['days_left'] as num?)?.toInt() ?? 0,
    perDayRemaining: (json['per_day_remaining'] as num?)?.toDouble() ?? 0,
    projection: (json['projection'] as num?)?.toDouble() ?? 0,
    projectionGap: (json['projection_gap'] as num?)?.toDouble() ?? 0,
    weeklyRecommended: (json['weekly_recommended'] as num?)?.toDouble() ?? 0,
    paceDeltaPct: (json['pace_delta_pct'] as num?)?.toDouble(),
  );
}

/// Modèle de liste récurrente et ses articles par défaut.
class RecurringListModel {
  final int id;
  final String name;
  final String recurrenceType; // weekly | biweekly | monthly
  final int? weekday; // 1 = lundi ... 7 = dimanche
  final DateTime? nextRunAt;
  final bool enabled;
  final bool autoGenerate;
  final List<RecurringItem> items;

  const RecurringListModel({
    required this.id,
    required this.name,
    required this.recurrenceType,
    this.weekday,
    this.nextRunAt,
    this.enabled = true,
    this.autoGenerate = false,
    this.items = const [],
  });

  factory RecurringListModel.fromJson(Map<String, dynamic> json) =>
      RecurringListModel(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        recurrenceType: json['recurrence_type'] as String? ?? 'weekly',
        weekday: (json['weekday'] as num?)?.toInt(),
        nextRunAt: json['next_run_at'] != null
            ? DateTime.tryParse(json['next_run_at'] as String)
            : null,
        enabled: json['enabled'] as bool? ?? true,
        autoGenerate: json['auto_generate'] as bool? ?? false,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => RecurringItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class RecurringItem {
  final String productName;
  final int quantity;
  final String? unit;
  final bool optional;

  const RecurringItem({
    required this.productName,
    this.quantity = 1,
    this.unit,
    this.optional = false,
  });

  factory RecurringItem.fromJson(Map<String, dynamic> json) => RecurringItem(
    productName: json['product_name'] as String,
    quantity: (json['default_quantity'] as num?)?.toInt() ??
        (json['quantity'] as num?)?.toInt() ??
        1,
    unit: json['unit'] as String?,
    optional: json['optional'] as bool? ?? false,
  );
}

/// Article de l'aperçu d'une génération (pré-coché + raison).
class RecurringPreviewItem {
  final String productName;
  final int quantity;
  final String? unit;
  bool suggested;

  /// inventory_out | inventory_at_home | bought_recently |
  /// prediction_due | normal_cycle
  final String reason;

  RecurringPreviewItem({
    required this.productName,
    this.quantity = 1,
    this.unit,
    required this.suggested,
    required this.reason,
  });

  factory RecurringPreviewItem.fromJson(Map<String, dynamic> json) =>
      RecurringPreviewItem(
        productName: json['product_name'] as String,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        unit: json['unit'] as String?,
        suggested: json['suggested'] as bool? ?? true,
        reason: json['reason'] as String? ?? 'normal_cycle',
      );
}

/// Recette (base EpiList ou personnelle).
class RecipeSummary {
  final int id;
  final String name;
  final String? description;
  final int servings;
  final int? preparationTime;
  final String? category;
  final int ingredientsCount;

  const RecipeSummary({
    required this.id,
    required this.name,
    this.description,
    this.servings = 4,
    this.preparationTime,
    this.category,
    this.ingredientsCount = 0,
  });

  factory RecipeSummary.fromJson(Map<String, dynamic> json) => RecipeSummary(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    description: json['description'] as String?,
    servings: (json['servings'] as num?)?.toInt() ?? 4,
    preparationTime: (json['preparation_time'] as num?)?.toInt(),
    category: json['category'] as String?,
    ingredientsCount: (json['ingredients_count'] as num?)?.toInt() ?? 0,
  );
}

/// Ingrédient consolidé de l'aperçu d'un plan de repas.
class MealPlanItem {
  final String productName;
  final double quantity;
  final String? unit;
  final bool optional;
  final bool atHome;
  final double? estimatedPrice;
  bool suggested;

  MealPlanItem({
    required this.productName,
    required this.quantity,
    this.unit,
    this.optional = false,
    this.atHome = false,
    this.estimatedPrice,
    required this.suggested,
  });

  factory MealPlanItem.fromJson(Map<String, dynamic> json) => MealPlanItem(
    productName: json['product_name'] as String,
    quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
    unit: json['unit'] as String?,
    optional: json['optional'] as bool? ?? false,
    atHome: json['at_home'] as bool? ?? false,
    estimatedPrice: (json['estimated_price'] as num?)?.toDouble(),
    suggested: json['suggested'] as bool? ?? true,
  );
}

class MealPlanPreview {
  final List<MealPlanItem> items;
  final double estimatedTotal;
  final double? budgetMax;
  final bool overBudget;
  final int priceCoveragePct;

  const MealPlanPreview({
    this.items = const [],
    this.estimatedTotal = 0,
    this.budgetMax,
    this.overBudget = false,
    this.priceCoveragePct = 0,
  });

  factory MealPlanPreview.fromJson(Map<String, dynamic> json) {
    final budget = json['budget'] as Map<String, dynamic>? ?? {};
    return MealPlanPreview(
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => MealPlanItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      estimatedTotal: (budget['estimated_total'] as num?)?.toDouble() ?? 0,
      budgetMax: (budget['budget_max'] as num?)?.toDouble(),
      overBudget: budget['over_budget'] as bool? ?? false,
      priceCoveragePct: (budget['price_coverage_pct'] as num?)?.toInt() ?? 0,
    );
  }
}
