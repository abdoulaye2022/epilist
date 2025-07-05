// models/list_item.dart - VERSION CORRIGÉE
class ListItem {
  final int id;
  final int listId;
  final String productName;
  final int quantity;
  final double? price; // Nullable pour gérer les prix absents
  final String? storeName; // Nullable pour gérer les magasins absents
  final bool isPurchased;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  ListItem({
    required this.id,
    required this.listId,
    required this.productName,
    required this.quantity,
    this.price, // Nullable
    this.storeName, // Nullable
    required this.isPurchased,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  // Getters pour compatibilité avec l'UI
  bool get isCompleted => isPurchased;
  String get name => productName;

  /// Retourne le prix formaté ou une chaîne vide si null
  String get formattedPrice {
    if (price == null) return '';
    return '${price!.toStringAsFixed(2)} \$CAD';
  }

  /// Retourne le nom du magasin ou une chaîne vide si null
  String get storeDisplayName => storeName ?? '';

  /// Vérifie si l'article a un prix défini
  bool get hasPrice => price != null && price! > 0;

  /// Vérifie si l'article a un magasin défini
  bool get hasStore => storeName != null && storeName!.isNotEmpty;

  /// Calcule le prix total (prix * quantité)
  double get totalPrice => (price ?? 0.0) * quantity;

  factory ListItem.fromJson(Map<String, dynamic> json) {
    return ListItem(
      id: _parseInt(json['id']),
      listId: _parseInt(json['list_id']),
      productName: json['product_name'] as String? ?? '',
      quantity: _parseInt(json['quantity']),
      price: _parseDouble(json['price']), // Peut être null
      storeName: _parseString(json['store_name']), // Peut être null
      isPurchased: json['is_purchased'] == true || json['is_purchased'] == 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt:
          json['deleted_at'] != null
              ? DateTime.parse(json['deleted_at'] as String)
              : null,
    );
  }

  // Fonctions helpers pour le parsing améliorées
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed == 0.0 ? null : parsed; // Retourne null si 0
    }
    return null;
  }

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return value.toString().trim().isEmpty ? null : value.toString().trim();
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
    return 'ListItem{id: $id, product: $productName, qty: $quantity, '
        'price: ${price ?? 'N/A'}, store: ${storeName ?? 'N/A'}, '
        'purchased: $isPurchased}';
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

// Extension pour les validations d'articles
extension ListItemValidation on ListItem {
  /// Vérifie si l'article est valide
  bool get isValid {
    return productName.isNotEmpty && quantity > 0;
  }

  /// Vérifie si l'article est complet (avec toutes les informations)
  bool get isComplete {
    return isValid && hasPrice && hasStore;
  }

  /// Retourne les champs manquants
  List<String> get missingFields {
    List<String> missing = [];

    if (productName.isEmpty) missing.add('Nom du produit');
    if (quantity <= 0) missing.add('Quantité');
    if (!hasPrice) missing.add('Prix');
    if (!hasStore) missing.add('Magasin');

    return missing;
  }
}
