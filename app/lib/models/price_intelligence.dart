// models/price_intelligence.dart - Historique de prix, comparateur de
// magasins et plan d'achat optimisé (réponses de l'API intelligence prix).

/// Une observation de prix, toujours accompagnée de sa provenance.
class PriceObservation {
  final double price;
  final double? unitPrice;
  final String? unit;
  final int quantity;
  final int? storeId;
  final String? storeName;
  final DateTime purchasedAt;

  /// shopping_list | receipt_ocr | manual
  final String source;

  const PriceObservation({
    required this.price,
    this.unitPrice,
    this.unit,
    this.quantity = 1,
    this.storeId,
    this.storeName,
    required this.purchasedAt,
    this.source = 'shopping_list',
  });

  factory PriceObservation.fromJson(Map<String, dynamic> json) =>
      PriceObservation(
        price: (json['price'] as num).toDouble(),
        unitPrice: (json['unit_price'] as num?)?.toDouble(),
        unit: json['unit'] as String?,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        storeId: (json['store_id'] as num?)?.toInt(),
        storeName: json['store_name'] as String?,
        purchasedAt: DateTime.parse(json['purchased_at'] as String),
        source: json['source'] as String? ?? 'shopping_list',
      );
}

/// Statistiques d'historique pour un produit (fenêtre configurable).
class PriceStats {
  final double lastPrice;
  final String? lastStore;
  final DateTime lastAt;
  final double usualPrice;
  final double medianPrice;
  final double minPrice;
  final double maxPrice;

  /// % d'écart du dernier prix vs le prix habituel (null si 1 seul achat).
  final double? variationPct;
  final int observations;
  final int windowDays;
  final Map<String, StorePriceStat> byStore;

  const PriceStats({
    required this.lastPrice,
    this.lastStore,
    required this.lastAt,
    required this.usualPrice,
    required this.medianPrice,
    required this.minPrice,
    required this.maxPrice,
    this.variationPct,
    required this.observations,
    required this.windowDays,
    this.byStore = const {},
  });

  factory PriceStats.fromJson(Map<String, dynamic> json) => PriceStats(
    lastPrice: (json['last_price'] as num).toDouble(),
    lastStore: json['last_store'] as String?,
    lastAt: DateTime.parse(json['last_at'] as String),
    usualPrice: (json['usual_price'] as num).toDouble(),
    medianPrice: (json['median_price'] as num).toDouble(),
    minPrice: (json['min_price'] as num).toDouble(),
    maxPrice: (json['max_price'] as num).toDouble(),
    variationPct: (json['variation_pct'] as num?)?.toDouble(),
    observations: (json['observations'] as num).toInt(),
    windowDays: (json['window_days'] as num).toInt(),
    byStore: (json['by_store'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(k, StorePriceStat.fromJson(v as Map<String, dynamic>)),
    ),
  );
}

class StorePriceStat {
  final double avgPrice;
  final double lastPrice;
  final DateTime lastAt;
  final int observations;

  const StorePriceStat({
    required this.avgPrice,
    required this.lastPrice,
    required this.lastAt,
    required this.observations,
  });

  factory StorePriceStat.fromJson(Map<String, dynamic> json) => StorePriceStat(
    avgPrice: (json['avg_price'] as num).toDouble(),
    lastPrice: (json['last_price'] as num).toDouble(),
    lastAt: DateTime.parse(json['last_at'] as String),
    observations: (json['observations'] as num).toInt(),
  );
}

class ProductPriceHistory {
  final String product;
  final PriceStats? stats;
  final List<PriceObservation> observations;

  const ProductPriceHistory({
    required this.product,
    this.stats,
    this.observations = const [],
  });

  factory ProductPriceHistory.fromJson(Map<String, dynamic> json) =>
      ProductPriceHistory(
        product: json['product'] as String,
        stats: json['stats'] == null
            ? null
            : PriceStats.fromJson(json['stats'] as Map<String, dynamic>),
        observations: (json['observations'] as List<dynamic>? ?? [])
            .map((e) => PriceObservation.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Prix connu (ou non) d'un article de la liste dans un magasin donné.
class ComparisonItem {
  final int itemId;
  final String name;
  final int quantity;
  final double? price;
  final int? ageDays;

  /// fresh (≤14 j) | acceptable (≤30 j) | old (≤90 j) | stale
  final String? freshness;
  final String? source;

  const ComparisonItem({
    required this.itemId,
    required this.name,
    required this.quantity,
    this.price,
    this.ageDays,
    this.freshness,
    this.source,
  });

  factory ComparisonItem.fromJson(Map<String, dynamic> json) => ComparisonItem(
    itemId: (json['item_id'] as num).toInt(),
    name: json['name'] as String,
    quantity: (json['quantity'] as num).toInt(),
    price: (json['price'] as num?)?.toDouble(),
    ageDays: (json['age_days'] as num?)?.toInt(),
    freshness: json['freshness'] as String?,
    source: json['source'] as String?,
  );
}

/// Coût estimé de la liste dans un magasin, avec couverture des données.
class StoreComparison {
  final int storeId;
  final String? storeName;
  final double estimatedTotal;
  final int knownItems;
  final int itemsCount;
  final int coveragePct;
  final List<ComparisonItem> items;

  const StoreComparison({
    required this.storeId,
    this.storeName,
    required this.estimatedTotal,
    required this.knownItems,
    required this.itemsCount,
    required this.coveragePct,
    this.items = const [],
  });

  factory StoreComparison.fromJson(Map<String, dynamic> json) =>
      StoreComparison(
        storeId: (json['store_id'] as num).toInt(),
        storeName: json['store_name'] as String?,
        estimatedTotal: (json['estimated_total'] as num).toDouble(),
        knownItems: (json['known_items'] as num).toInt(),
        itemsCount: (json['items_count'] as num).toInt(),
        coveragePct: (json['coverage_pct'] as num).toInt(),
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => ComparisonItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ComparisonResult {
  final int itemsCount;
  final int windowDays;
  final List<StoreComparison> stores;

  const ComparisonResult({
    required this.itemsCount,
    required this.windowDays,
    this.stores = const [],
  });

  factory ComparisonResult.fromJson(Map<String, dynamic> json) =>
      ComparisonResult(
        itemsCount: (json['items_count'] as num).toInt(),
        windowDays: (json['window_days'] as num).toInt(),
        stores: (json['stores'] as List<dynamic>? ?? [])
            .map((e) => StoreComparison.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Article assigné à un magasin dans le plan optimisé.
class PlanItem {
  final int itemId;
  final String name;
  final int quantity;
  final int storeId;
  final String? storeName;
  final double price;
  final bool estimated;

  const PlanItem({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.storeId,
    this.storeName,
    required this.price,
    this.estimated = false,
  });

  factory PlanItem.fromJson(Map<String, dynamic> json) => PlanItem(
    itemId: (json['item_id'] as num).toInt(),
    name: json['name'] as String,
    quantity: (json['quantity'] as num).toInt(),
    storeId: (json['store_id'] as num).toInt(),
    storeName: json['store_name'] as String?,
    price: (json['price'] as num).toDouble(),
    estimated: json['estimated'] as bool? ?? false,
  );
}

class PlanStore {
  final int storeId;
  final String? storeName;
  final double subtotal;
  final List<PlanItem> items;

  const PlanStore({
    required this.storeId,
    this.storeName,
    required this.subtotal,
    this.items = const [],
  });

  factory PlanStore.fromJson(Map<String, dynamic> json) => PlanStore(
    storeId: (json['store_id'] as num).toInt(),
    storeName: json['store_name'] as String?,
    subtotal: (json['subtotal'] as num).toDouble(),
    items: (json['items'] as List<dynamic>? ?? [])
        .map((e) => PlanItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class OptimizationResult {
  final bool feasible;
  final String? reason;
  final int comparableItems;
  final int itemsCount;
  final int? singleStoreId;
  final String? singleStoreName;
  final double? singleStoreTotal;
  final List<PlanStore> planStores;
  final List<PlanItem> estimatedElsewhere;
  final double? optimizedTotal;
  final double saving;

  const OptimizationResult({
    required this.feasible,
    this.reason,
    this.comparableItems = 0,
    this.itemsCount = 0,
    this.singleStoreId,
    this.singleStoreName,
    this.singleStoreTotal,
    this.planStores = const [],
    this.estimatedElsewhere = const [],
    this.optimizedTotal,
    this.saving = 0,
  });

  factory OptimizationResult.fromJson(Map<String, dynamic> json) {
    final single = json['single_store'] as Map<String, dynamic>?;
    final optimized = json['optimized'] as Map<String, dynamic>?;
    return OptimizationResult(
      feasible: json['feasible'] as bool? ?? false,
      reason: json['reason'] as String?,
      comparableItems: (json['comparable_items'] as num?)?.toInt() ?? 0,
      itemsCount: (json['items_count'] as num?)?.toInt() ?? 0,
      singleStoreId: (single?['store_id'] as num?)?.toInt(),
      singleStoreName: single?['store_name'] as String?,
      singleStoreTotal: (single?['total'] as num?)?.toDouble(),
      planStores: (optimized?['stores'] as List<dynamic>? ?? [])
          .map((e) => PlanStore.fromJson(e as Map<String, dynamic>))
          .toList(),
      estimatedElsewhere:
          (optimized?['estimated_elsewhere'] as List<dynamic>? ?? [])
              .map((e) => PlanItem.fromJson(e as Map<String, dynamic>))
              .toList(),
      optimizedTotal: (optimized?['total'] as num?)?.toDouble(),
      saving: (json['saving'] as num?)?.toDouble() ?? 0,
    );
  }
}
