import 'package:epilist/models/list_item.dart';

class ShoppingList {
  final int id;
  final int userId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final List<ListItem> items;

  ShoppingList({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.items,
  });

  // GETTERS CALCULÉS

  /// Nombre total d'articles dans la liste
  int get itemsCount => items.length;

  /// Nombre d'articles achetés
  int get purchasedItemsCount => items.where((item) => item.isPurchased).length;

  /// Nombre d'articles non achetés
  int get pendingItemsCount => items.where((item) => !item.isPurchased).length;

  /// Prix total de tous les articles (avec gestion des prix null)
  double get totalPrice {
    return items.fold(0.0, (sum, item) {
      final itemPrice = item.price ?? 0.0; // Gérer les prix null
      return sum + (itemPrice * item.quantity);
    });
  }

  /// Prix total des articles achetés
  double get purchasedTotalPrice {
    return items.where((item) => item.isPurchased).fold(0.0, (sum, item) {
      final itemPrice = item.price ?? 0.0;
      return sum + (itemPrice * item.quantity);
    });
  }

  /// Prix total des articles non achetés
  double get pendingTotalPrice {
    return items.where((item) => !item.isPurchased).fold(0.0, (sum, item) {
      final itemPrice = item.price ?? 0.0;
      return sum + (itemPrice * item.quantity);
    });
  }

  /// Progression en pourcentage (0.0 à 1.0)
  double get progress {
    if (items.isEmpty) return 0.0;
    return purchasedItemsCount / itemsCount;
  }

  /// Progression en pourcentage (0 à 100)
  int get progressPercentage => (progress * 100).round();

  /// Vérifie si la liste est terminée (tous les articles achetés)
  bool get isCompleted => items.isNotEmpty && purchasedItemsCount == itemsCount;

  /// Vérifie si la liste est vide
  bool get isEmpty => items.isEmpty;

  /// Vérifie si la liste a des articles
  bool get hasItems => items.isNotEmpty;

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    List<ListItem> itemsList = [];
    if (json['items'] != null) {
      try {
        itemsList =
            (json['items'] as List<dynamic>)
                .map((item) => ListItem.fromJson(item as Map<String, dynamic>))
                .toList();
      } catch (e) {
        print("Error parsing items: $e");
      }
    } else {
      print("No items found in JSON"); // Debug
    }

    return ShoppingList(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt:
          json['deleted_at'] != null
              ? DateTime.parse(json['deleted_at'] as String)
              : null,
      items: itemsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  ShoppingList copyWith({
    int? id,
    int? userId,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    List<ListItem>? items,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      items: items ?? this.items,
    );
  }

  @override
  String toString() {
    return 'ShoppingList{id: $id, name: $name, itemsCount: ${items.length}, items: $items}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingList &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          name == other.name &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt &&
          items == other.items;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      name.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      deletedAt.hashCode ^
      items.hashCode;
}
