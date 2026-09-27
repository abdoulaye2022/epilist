// models/store.dart - Magasin de l'utilisateur, avec son ordre de rayons
import 'package:equatable/equatable.dart';

class Store extends Equatable {
  final int id;
  final String name;
  final String slug;

  /// Ordre des rayons : liste de kinds de catégories
  /// (ex. ["fruits_vegetables", "bakery", "dairy"...]).
  /// Vide = pas encore configuré pour ce magasin.
  final List<String> categoryOrder;

  const Store({
    required this.id,
    required this.name,
    required this.slug,
    this.categoryOrder = const [],
  });

  bool get hasAisleOrder => categoryOrder.isNotEmpty;

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      categoryOrder: (json['category_order'] is List)
          ? (json['category_order'] as List).map((e) => e.toString()).toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'category_order': categoryOrder,
    };
  }

  Store copyWith({
    int? id,
    String? name,
    String? slug,
    List<String>? categoryOrder,
  }) {
    return Store(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      categoryOrder: categoryOrder ?? this.categoryOrder,
    );
  }

  @override
  List<Object?> get props => [id, name, slug, categoryOrder];
}
