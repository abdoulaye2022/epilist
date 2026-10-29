import 'package:flutter/foundation.dart';
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

  /// Ancienne URL publique de la photo, null depuis la migration 015.
  ///
  /// Elle n'est plus produite : un reçu porte le magasin, la date et les
  /// montants, et une URL publique le rendait lisible par quiconque la
  /// connaissait. Le champ survit pour les reçus d'avant, le temps que
  /// le rattrapage soit joué côté serveur.
  final String? imageUrl;

  /// Ce reçu porte-t-il une photo ? C'est le serveur qui le dit, quelle
  /// que soit la façon dont l'image est rangée. L'URL pour la regarder
  /// se demande au moment de l'afficher, et ne vaut que quinze minutes.
  final bool hasImage;

  /// Nom de la liste porteuse. Renseigné par GET /receipts (onglet
  /// Factures, toutes listes confondues), absent des routes par liste —
  /// on y connaît déjà la liste.
  final String? listName;

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
    this.imageUrl,
    this.hasImage = false,
    this.listName,
  });

  /// Décodage TOLÉRANT. Chaque champ était auparavant casté durement
  /// (`as int`, `as num`, `DateTime.parse`) : une seule facture au format
  /// inattendu — un montant renvoyé en chaîne par la base, une date
  /// absente — faisait échouer le décodage de TOUTE la liste, et la page
  /// Factures restait vide sans message. On préfère une facture affichée
  /// avec une valeur de repli qu'un écran mort.
  factory Receipt.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;
    double asDouble(Object? v) =>
        v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0.0;
    DateTime asDate(Object? v) =>
        DateTime.tryParse('${v ?? ''}') ?? DateTime.now();

    final total = asDouble(json['total_amount']);

    return Receipt(
      id: asInt(json['id']),
      listId: asInt(json['list_id']),
      storeName: json['store_name'] as String? ?? '',
      totalAmount: total,
      notes: json['notes'] as String?,
      purchaseDate: asDate(json['purchase_date']),
      formattedAmount:
          json['formatted_amount'] as String? ?? total.toStringAsFixed(2),
      currency: json['currency'] is Map
          ? (json['currency'] as Map).map(
              (k, v) => MapEntry(k.toString(), v?.toString() ?? ''))
          : null,
      createdAt: asDate(json['created_at']),
      updatedAt: asDate(json['updated_at']),
      imageUrl: json['image_url'] as String?,
      // `has_image` vient des serveurs à jour. Sans lui — serveur plus
      // ancien que la migration 015 — on retombe sur la présence d'une
      // URL, qui était alors le seul indice.
      hasImage:
          json['has_image'] as bool? ??
          ((json['image_url'] as String?)?.isNotEmpty ?? false),
      listName: json['list_name'] as String?,
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
      'image_url': imageUrl,
      'has_image': hasImage,
      'list_name': listName,
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
    String? imageUrl,
    bool? hasImage,
    String? listName,
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
      imageUrl: imageUrl ?? this.imageUrl,
      hasImage: hasImage ?? this.hasImage,
      listName: listName ?? this.listName,
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
    imageUrl,
    hasImage,
    listName,
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
      debugPrint('❌ Erreur parsing ReceiptStats: $e');
      debugPrint('📥 JSON reçu: $json');
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
