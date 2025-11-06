// models/category.dart - Modèle pour les catégories de produits
import 'package:flutter/material.dart';

class Category {
  final int id;
  final int userId;
  final String name;
  final String iconCode; // Code de l'icône Material (ex: "shopping_cart")
  final String colorHex; // Couleur en hexadécimal (ex: "#4CAF50")
  final int orderIndex; // Pour trier les catégories
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.iconCode,
    required this.colorHex,
    this.orderIndex = 0,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  // Getters pour l'UI
  Color get color {
    try {
      // Convertir le hex en Color
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.green; // Couleur par défaut
    }
  }

  IconData get icon {
    try {
      // Mapper le code de l'icône à l'IconData
      return _getIconDataFromCode(iconCode);
    } catch (e) {
      return Icons.category; // Icône par défaut
    }
  }

  bool get isDeleted => deletedAt != null;

  // Version publique pour utilisation externe
  static IconData getIconDataFromCode(String code) {
    return _getIconDataFromCode(code);
  }

  // Mapper les codes d'icônes aux IconData
  static IconData _getIconDataFromCode(String code) {
    final iconMap = {
      // Nourriture & Boissons
      'restaurant': Icons.restaurant,
      'local_dining': Icons.local_dining,
      'fastfood': Icons.fastfood,
      'local_pizza': Icons.local_pizza,
      'local_cafe': Icons.local_cafe,
      'local_bar': Icons.local_bar,
      'cake': Icons.cake,
      'icecream': Icons.icecream,
      'lunch_dining': Icons.lunch_dining,
      'breakfast_dining': Icons.breakfast_dining,
      'dinner_dining': Icons.dinner_dining,
      'coffee': Icons.coffee,
      'liquor': Icons.liquor,
      'wine_bar': Icons.wine_bar,

      // Fruits & Légumes
      'eco': Icons.eco,
      'local_florist': Icons.local_florist,
      'grass': Icons.grass,
      'spa': Icons.spa,

      // Viandes & Poissons
      'set_meal': Icons.set_meal,
      'soup_kitchen': Icons.soup_kitchen,

      // Produits laitiers
      'egg': Icons.egg,

      // Boulangerie
      'bakery_dining': Icons.bakery_dining,

      // Boissons
      'local_drink': Icons.local_drink,
      'sports_bar': Icons.sports_bar,

      // Hygiène & Beauté
      'cleaning_services': Icons.cleaning_services,
      'clean_hands': Icons.clean_hands,
      'shower': Icons.shower,
      'bathtub': Icons.bathtub,
      'soap': Icons.soap,
      'face': Icons.face,

      // Maison & Entretien
      'home': Icons.home,
      'house': Icons.house,
      'cottage': Icons.cottage,
      'light': Icons.light,
      'lightbulb': Icons.lightbulb,
      'local_laundry_service': Icons.local_laundry_service,
      'iron': Icons.iron,

      // Bébé & Enfants
      'child_care': Icons.child_care,
      'baby_changing_station': Icons.baby_changing_station,
      'toys': Icons.toys,
      'stroller': Icons.stroller,

      // Animaux
      'pets': Icons.pets,
      'cruelty_free': Icons.cruelty_free,

      // Santé & Pharmacie
      'medical_services': Icons.medical_services,
      'local_pharmacy': Icons.local_pharmacy,
      'medication': Icons.medication,
      'vaccines': Icons.vaccines,
      'healing': Icons.healing,
      'health_and_safety': Icons.health_and_safety,

      // Électronique
      'devices': Icons.devices,
      'phone_android': Icons.phone_android,
      'computer': Icons.computer,
      'headphones': Icons.headphones,
      'cable': Icons.cable,
      'power': Icons.power,
      'battery_charging_full': Icons.battery_charging_full,

      // Vêtements & Mode
      'checkroom': Icons.checkroom,
      'dry_cleaning': Icons.dry_cleaning,
      'watch': Icons.watch,
      'diamond': Icons.diamond,

      // Sport & Loisirs
      'sports': Icons.sports,
      'sports_soccer': Icons.sports_soccer,
      'sports_basketball': Icons.sports_basketball,
      'sports_tennis': Icons.sports_tennis,
      'fitness_center': Icons.fitness_center,
      'pool': Icons.pool,
      'sports_esports': Icons.sports_esports,

      // Papeterie & Bureau
      'school': Icons.school,
      'menu_book': Icons.menu_book,
      'draw': Icons.draw,
      'edit': Icons.edit,
      'brush': Icons.brush,

      // Jardinage
      'yard': Icons.yard,
      'agriculture': Icons.agriculture,
      'nature': Icons.nature,
      'forest': Icons.forest,

      // Automobile
      'directions_car': Icons.directions_car,
      'local_gas_station': Icons.local_gas_station,
      'car_repair': Icons.car_repair,
      'car_rental': Icons.car_rental,

      // Autre
      'shopping_cart': Icons.shopping_cart,
      'shopping_bag': Icons.shopping_bag,
      'local_mall': Icons.local_mall,
      'store': Icons.store,
      'card_giftcard': Icons.card_giftcard,
      'category': Icons.category,
      'label': Icons.label,
      'star': Icons.star,
      'favorite': Icons.favorite,
      'bookmark': Icons.bookmark,
    };

    return iconMap[code] ?? Icons.category;
  }

  // Obtenir le code d'icône depuis IconData (pour la sauvegarde)
  static String getIconCodeFromData(IconData iconData) {
    final iconMap = {
      Icons.restaurant.codePoint: 'restaurant',
      Icons.local_dining.codePoint: 'local_dining',
      Icons.fastfood.codePoint: 'fastfood',
      Icons.local_pizza.codePoint: 'local_pizza',
      Icons.local_cafe.codePoint: 'local_cafe',
      Icons.local_bar.codePoint: 'local_bar',
      Icons.cake.codePoint: 'cake',
      Icons.icecream.codePoint: 'icecream',
      Icons.eco.codePoint: 'eco',
      Icons.cleaning_services.codePoint: 'cleaning_services',
      Icons.home.codePoint: 'home',
      Icons.child_care.codePoint: 'child_care',
      Icons.pets.codePoint: 'pets',
      Icons.medical_services.codePoint: 'medical_services',
      Icons.devices.codePoint: 'devices',
      Icons.checkroom.codePoint: 'checkroom',
      Icons.sports.codePoint: 'sports',
      Icons.school.codePoint: 'school',
      Icons.yard.codePoint: 'yard',
      Icons.directions_car.codePoint: 'directions_car',
      Icons.shopping_cart.codePoint: 'shopping_cart',
      Icons.category.codePoint: 'category',
    };

    return iconMap[iconData.codePoint] ?? 'category';
  }

  // Convertir Color en hex
  static String colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      name: json['name'] as String? ?? '',
      iconCode: json['icon_code'] as String? ?? 'category',
      colorHex: json['color_hex'] as String? ?? '#4CAF50',
      orderIndex: _parseInt(json['order_index']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt:
          json['deleted_at'] != null
              ? DateTime.parse(json['deleted_at'] as String)
              : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'icon_code': iconCode,
      'color_hex': colorHex,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  Category copyWith({
    int? id,
    int? userId,
    String? name,
    String? iconCode,
    String? colorHex,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      iconCode: iconCode ?? this.iconCode,
      colorHex: colorHex ?? this.colorHex,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() {
    return 'Category{id: $id, name: $name, icon: $iconCode, color: $colorHex}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          name == other.name &&
          iconCode == other.iconCode &&
          colorHex == other.colorHex;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      name.hashCode ^
      iconCode.hashCode ^
      colorHex.hashCode;
}

// Catégories prédéfinies pour faciliter la configuration initiale
class PredefinedCategories {
  static List<Map<String, String>> get defaults => [
        {
          'name_fr': 'Fruits & Légumes',
          'name_en': 'Fruits & Vegetables',
          'icon': 'eco',
          'color': '#4CAF50'
        },
        {
          'name_fr': 'Viandes & Poissons',
          'name_en': 'Meat & Fish',
          'icon': 'set_meal',
          'color': '#F44336'
        },
        {
          'name_fr': 'Produits laitiers',
          'name_en': 'Dairy Products',
          'icon': 'egg',
          'color': '#FFEB3B'
        },
        {
          'name_fr': 'Boulangerie',
          'name_en': 'Bakery',
          'icon': 'bakery_dining',
          'color': '#FF9800'
        },
        {
          'name_fr': 'Boissons',
          'name_en': 'Beverages',
          'icon': 'local_bar',
          'color': '#2196F3'
        },
        {
          'name_fr': 'Snacks & Sucreries',
          'name_en': 'Snacks & Sweets',
          'icon': 'cake',
          'color': '#E91E63'
        },
        {
          'name_fr': 'Hygiène & Beauté',
          'name_en': 'Hygiene & Beauty',
          'icon': 'spa',
          'color': '#9C27B0'
        },
        {
          'name_fr': 'Entretien ménager',
          'name_en': 'Household Cleaning',
          'icon': 'cleaning_services',
          'color': '#00BCD4'
        },
        {
          'name_fr': 'Bébé & Enfants',
          'name_en': 'Baby & Kids',
          'icon': 'child_care',
          'color': '#FF5722'
        },
        {
          'name_fr': 'Animaux',
          'name_en': 'Pets',
          'icon': 'pets',
          'color': '#795548'
        },
        {
          'name_fr': 'Santé & Pharmacie',
          'name_en': 'Health & Pharmacy',
          'icon': 'medical_services',
          'color': '#F44336'
        },
        {
          'name_fr': 'Autre',
          'name_en': 'Other',
          'icon': 'category',
          'color': '#9E9E9E'
        },
      ];
}
