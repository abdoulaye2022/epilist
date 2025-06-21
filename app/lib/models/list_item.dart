class ListItem {
  final int id;
  final int listId;
  final String productName;
  final int quantity;
  final double price;
  final String storeName;
  final bool isPurchased;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  ListItem({
    required this.id,
    required this.listId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.storeName,
    required this.isPurchased,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  // Getters pour compatibilité avec l'UI
  bool get isCompleted => isPurchased;
  String get name => productName;

  factory ListItem.fromJson(Map<String, dynamic> json) {
    return ListItem(
      id: _parseInt(json['id']),
      listId: _parseInt(json['list_id']),
      productName: json['product_name'] as String? ?? '',
      quantity: _parseInt(json['quantity']),
      price: _parseDouble(json['price']) ?? 0.0,
      storeName: json['store_name'] as String? ?? '',
      isPurchased: json['is_purchased'] == true || json['is_purchased'] == 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt:
          json['deleted_at'] != null
              ? DateTime.parse(json['deleted_at'] as String)
              : null,
    );
  }

  // Fonctions helpers pour le parsing
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'list_id': listId,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      'store_name': storeName,
      'is_purchased': isPurchased,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  ListItem copyWith({
    int? id,
    int? listId,
    String? productName,
    int? quantity,
    double? price,
    String? storeName,
    bool? isPurchased,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ListItem(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      storeName: storeName ?? this.storeName,
      isPurchased: isPurchased ?? this.isPurchased,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() {
    return 'ListItem{id: $id, product: $productName, qty: $quantity, purchased: $isPurchased}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          listId == other.listId &&
          productName == other.productName &&
          quantity == other.quantity &&
          price == other.price &&
          storeName == other.storeName &&
          isPurchased == other.isPurchased &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      listId.hashCode ^
      productName.hashCode ^
      quantity.hashCode ^
      price.hashCode ^
      storeName.hashCode ^
      isPurchased.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      deletedAt.hashCode;
}
