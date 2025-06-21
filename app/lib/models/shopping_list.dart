// models/shopping_list.dart
class ShoppingList {
  final int id;
  final int userId;
  final String name;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  ShoppingList({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
      deletedAt:
          json['deleted_at'] != null
              ? DateTime.parse(json['deleted_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
