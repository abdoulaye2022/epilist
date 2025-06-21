// models/list_item.dart
class ListItem {
  final int id;
  final int listId;
  final String productName;
  final int quantity;
  final double? price;
  final String? storeName;
  final bool isPurchased;

  ListItem({
    required this.id,
    required this.listId,
    required this.productName,
    this.quantity = 1,
    this.price,
    this.storeName,
    this.isPurchased = false,
  });

  factory ListItem.fromJson(Map<String, dynamic> json) {
    return ListItem(
      id: _parseInt(json['id']),
      listId: _parseInt(json['list_id']),
      productName: json['product_name'] ?? '',
      quantity: _parseInt(json['quantity']) ?? 1,
      price: _parseDouble(json['price']),
      storeName: json['store_name'],
      isPurchased: json['is_purchased'] == 1 || json['is_purchased'] == true,
    );
  }

  // Fonction helper pour parser les entiers (gère String et int)
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Fonction helper pour parser les doubles (gère String et double)
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
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
    };
  }

  // Méthode pour créer une copie avec modifications
  ListItem copyWith({
    int? id,
    int? listId,
    String? productName,
    int? quantity,
    double? price,
    String? storeName,
    bool? isPurchased,
  }) {
    return ListItem(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      storeName: storeName ?? this.storeName,
      isPurchased: isPurchased ?? this.isPurchased,
    );
  }
}
