// models/receipt.dart - VERSION CORRIGÉE
import 'package:equatable/equatable.dart';

class Receipt extends Equatable {
  final int id;
  final int listId;
  final String storeName;
  final double totalAmount;
  final String? notes;
  final DateTime purchaseDate;
  final String formattedAmount;
  final Map<String, String>? currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Receipt({
    required this.id,
    required this.listId,
    required this.storeName,
    required this.totalAmount,
    this.notes,
    required this.purchaseDate,
    required this.formattedAmount,
    this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'] as int,
      listId: json['list_id'] as int,
      storeName: json['store_name'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      notes: json['notes'] as String?,
      purchaseDate: DateTime.parse(json['purchase_date'] as String),
      formattedAmount: json['formatted_amount'] as String,
      currency:
          json['currency'] != null
              ? Map<String, String>.from(json['currency'] as Map)
              : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'list_id': listId,
      'store_name': storeName,
      'total_amount': totalAmount,
      'notes': notes,
      'purchase_date': purchaseDate.toIso8601String().split('T')[0],
      'formatted_amount': formattedAmount,
      'currency': currency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Receipt copyWith({
    int? id,
    int? listId,
    String? storeName,
    double? totalAmount,
    String? notes,
    DateTime? purchaseDate,
    String? formattedAmount,
    Map<String, String>? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Receipt(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      storeName: storeName ?? this.storeName,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      formattedAmount: formattedAmount ?? this.formattedAmount,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    listId,
    storeName,
    totalAmount,
    notes,
    purchaseDate,
    formattedAmount,
    currency,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'Receipt(id: $id, storeName: $storeName, totalAmount: $totalAmount, purchaseDate: $purchaseDate)';
  }
}

// Modèle pour les factures groupées par magasin
class StoreReceiptGroup extends Equatable {
  final String storeName;
  final int receiptsCount;
  final double totalAmount;
  final String formattedTotal;
  final String latestPurchase;
  final List<Receipt> receipts;

  const StoreReceiptGroup({
    required this.storeName,
    required this.receiptsCount,
    required this.totalAmount,
    required this.formattedTotal,
    required this.latestPurchase,
    required this.receipts,
  });

  factory StoreReceiptGroup.fromJson(Map<String, dynamic> json) {
    return StoreReceiptGroup(
      storeName: json['store_name'] as String,
      receiptsCount: json['receipts_count'] as int,
      totalAmount: (json['total_amount'] as num).toDouble(),
      formattedTotal: json['formatted_total'] as String,
      latestPurchase: json['latest_purchase'] as String,
      receipts:
          (json['receipts'] as List)
              .map(
                (receipt) => Receipt.fromJson(receipt as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  @override
  List<Object?> get props => [
    storeName,
    receiptsCount,
    totalAmount,
    formattedTotal,
    latestPurchase,
    receipts,
  ];
}

// ✅ MODÈLE CORRIGÉ POUR LES STATISTIQUES DES FACTURES
class ReceiptStats extends Equatable {
  final double itemsTotal;
  final double receiptsTotal;
  final double bestTotal;
  final int totalItems;
  final int totalReceipts;
  final int itemsWithPrices;
  final double variance;
  final String dataQuality;
  final Map<String, String> formattedAmounts;

  const ReceiptStats({
    required this.itemsTotal,
    required this.receiptsTotal,
    required this.bestTotal,
    required this.totalItems,
    required this.totalReceipts,
    required this.itemsWithPrices,
    required this.variance,
    required this.dataQuality,
    required this.formattedAmounts,
  });

  factory ReceiptStats.fromJson(Map<String, dynamic> json) {
    try {
      return ReceiptStats(
        // ✅ GESTION SÉCURISÉE DES TYPES NUMÉRIQUES
        itemsTotal: _parseDouble(json['items_total']),
        receiptsTotal: _parseDouble(json['receipts_total']),
        bestTotal: _parseDouble(json['best_total']),
        totalItems: _parseInt(json['total_items']),
        totalReceipts: _parseInt(json['total_receipts']),
        itemsWithPrices: _parseInt(json['items_with_prices']),
        variance: _parseDouble(json['variance']),
        dataQuality: json['data_quality'] as String? ?? 'unknown',
        formattedAmounts: _parseFormattedAmounts(json['formatted_amounts']),
      );
    } catch (e) {
      print('❌ Erreur parsing ReceiptStats: $e');
      print('📥 JSON reçu: $json');
      rethrow;
    }
  }

  // ✅ MÉTHODES HELPERS POUR LE PARSING SÉCURISÉ
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static Map<String, String> _parseFormattedAmounts(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, dynamic>) {
      return value.map((key, value) => MapEntry(key, value.toString()));
    }
    if (value is Map<String, String>) {
      return value;
    }
    return {};
  }

  bool get hasReceiptData => totalReceipts > 0;
  bool get hasItemData => itemsWithPrices > 0;
  bool get hasGoodDataQuality =>
      dataQuality == 'good' || dataQuality == 'excellent';

  // ✅ GETTERS POUR LES POURCENTAGES
  double get itemsPriceCompleteness {
    if (totalItems == 0) return 0.0;
    return (itemsWithPrices / totalItems) * 100;
  }

  String get dataQualityDescription {
    return switch (dataQuality) {
      'excellent' => 'Excellente (80%+ des articles ont un prix)',
      'good' => 'Bonne (60-79% des articles ont un prix)',
      'fair' => 'Correcte (40-59% des articles ont un prix)',
      'poor' => 'Faible (<40% des articles ont un prix)',
      _ => 'Inconnue',
    };
  }

  bool get isOverBudget => variance > 0;
  bool get isUnderBudget => variance < 0;
  bool get isOnBudget => variance == 0;

  double get budgetAccuracy {
    if (bestTotal == 0) return 0.0;
    return ((bestTotal - variance.abs()) / bestTotal * 100).clamp(0.0, 100.0);
  }

  @override
  List<Object?> get props => [
    itemsTotal,
    receiptsTotal,
    bestTotal,
    totalItems,
    totalReceipts,
    itemsWithPrices,
    variance,
    dataQuality,
    formattedAmounts,
  ];

  @override
  String toString() {
    return 'ReceiptStats('
        'items: $totalItems, '
        'receipts: $totalReceipts, '
        'itemsTotal: $itemsTotal, '
        'receiptsTotal: $receiptsTotal, '
        'quality: $dataQuality'
        ')';
  }
}
