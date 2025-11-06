// models/smart_suggestion.dart
class SmartSuggestion {
  final String productName;
  final int suggestedQuantity;
  final double? avgPrice;
  final String? preferredStore;
  final int? categoryId;
  final double confidenceScore;
  final String? lastPurchased;
  final bool shouldBuySoon;
  final String reason;
  final SuggestionType type;
  final String? basedOn;

  SmartSuggestion({
    required this.productName,
    required this.suggestedQuantity,
    this.avgPrice,
    this.preferredStore,
    this.categoryId,
    required this.confidenceScore,
    this.lastPurchased,
    this.shouldBuySoon = false,
    required this.reason,
    this.type = SuggestionType.pattern,
    this.basedOn,
  });

  factory SmartSuggestion.fromJson(Map<String, dynamic> json) {
    return SmartSuggestion(
      productName: json['product_name'] as String,
      suggestedQuantity: json['suggested_quantity'] as int? ?? 1,
      avgPrice: json['avg_price'] != null
          ? double.tryParse(json['avg_price'].toString())
          : null,
      preferredStore: json['preferred_store'] as String?,
      categoryId: json['category_id'] as int?,
      confidenceScore: json['confidence_score'] != null
          ? double.tryParse(json['confidence_score'].toString()) ?? 0.0
          : 0.0,
      lastPurchased: json['last_purchased'] as String?,
      shouldBuySoon: json['should_buy_soon'] == true || json['should_buy_soon'] == 1,
      reason: json['reason'] as String? ?? '',
      type: SuggestionType.fromString(json['type'] as String? ?? 'pattern'),
      basedOn: json['based_on'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_name': productName,
      'suggested_quantity': suggestedQuantity,
      'avg_price': avgPrice,
      'preferred_store': preferredStore,
      'category_id': categoryId,
      'confidence_score': confidenceScore,
      'last_purchased': lastPurchased,
      'should_buy_soon': shouldBuySoon,
      'reason': reason,
      'type': type.value,
      'based_on': basedOn,
    };
  }

  /// Get confidence level (low, medium, high)
  ConfidenceLevel get confidenceLevel {
    if (confidenceScore >= 70) return ConfidenceLevel.high;
    if (confidenceScore >= 40) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }

  /// Get formatted price
  String? getFormattedPrice(String currencySymbol) {
    if (avgPrice == null) return null;
    return '$currencySymbol${avgPrice!.toStringAsFixed(2)}';
  }

  SmartSuggestion copyWith({
    String? productName,
    int? suggestedQuantity,
    double? avgPrice,
    String? preferredStore,
    int? categoryId,
    double? confidenceScore,
    String? lastPurchased,
    bool? shouldBuySoon,
    String? reason,
    SuggestionType? type,
    String? basedOn,
  }) {
    return SmartSuggestion(
      productName: productName ?? this.productName,
      suggestedQuantity: suggestedQuantity ?? this.suggestedQuantity,
      avgPrice: avgPrice ?? this.avgPrice,
      preferredStore: preferredStore ?? this.preferredStore,
      categoryId: categoryId ?? this.categoryId,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      lastPurchased: lastPurchased ?? this.lastPurchased,
      shouldBuySoon: shouldBuySoon ?? this.shouldBuySoon,
      reason: reason ?? this.reason,
      type: type ?? this.type,
      basedOn: basedOn ?? this.basedOn,
    );
  }
}

/// Type of suggestion
enum SuggestionType {
  pattern('pattern'),
  seasonal('seasonal'),
  association('association'),
  trending('trending');

  final String value;
  const SuggestionType(this.value);

  static SuggestionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'seasonal':
        return SuggestionType.seasonal;
      case 'association':
        return SuggestionType.association;
      case 'trending':
        return SuggestionType.trending;
      case 'pattern':
      default:
        return SuggestionType.pattern;
    }
  }
}

/// Confidence level
enum ConfidenceLevel {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case ConfidenceLevel.high:
        return 'High';
      case ConfidenceLevel.medium:
        return 'Medium';
      case ConfidenceLevel.low:
        return 'Low';
    }
  }
}

/// Suggestion statistics
class SuggestionStatistics {
  final int totalPurchases;
  final int uniqueProducts;
  final int activePatterns;
  final double suggestionAcceptanceRate;
  final Map<String, int> feedback;

  SuggestionStatistics({
    required this.totalPurchases,
    required this.uniqueProducts,
    required this.activePatterns,
    required this.suggestionAcceptanceRate,
    required this.feedback,
  });

  factory SuggestionStatistics.fromJson(Map<String, dynamic> json) {
    return SuggestionStatistics(
      totalPurchases: json['total_purchases'] as int? ?? 0,
      uniqueProducts: json['unique_products'] as int? ?? 0,
      activePatterns: json['active_patterns'] as int? ?? 0,
      suggestionAcceptanceRate:
          double.tryParse(json['suggestion_acceptance_rate']?.toString() ?? '0') ?? 0.0,
      feedback: Map<String, int>.from(json['feedback'] as Map? ?? {}),
    );
  }
}
