import 'package:equatable/equatable.dart';

class ProductInfo extends Equatable {
  final String barcode;
  final String name;
  final String? brand;
  final String? quantity;
  final String? imageUrl;
  final Map<String, dynamic>? nutriments;

  const ProductInfo({
    required this.barcode,
    required this.name,
    this.brand,
    this.quantity,
    this.imageUrl,
    this.nutriments,
  });

  /// Crée un ProductInfo depuis les données de OpenFoodFacts
  factory ProductInfo.fromOpenFoodFacts(Map<String, dynamic> json) {
    // Récupérer le nom du produit
    String productName = '';
    if (json['product_name'] != null && json['product_name'].toString().isNotEmpty) {
      productName = json['product_name'].toString();
    } else if (json['product_name_fr'] != null && json['product_name_fr'].toString().isNotEmpty) {
      productName = json['product_name_fr'].toString();
    } else if (json['product_name_en'] != null && json['product_name_en'].toString().isNotEmpty) {
      productName = json['product_name_en'].toString();
    } else if (json['generic_name'] != null && json['generic_name'].toString().isNotEmpty) {
      productName = json['generic_name'].toString();
    }

    // Récupérer la marque
    String? brand;
    if (json['brands'] != null && json['brands'].toString().isNotEmpty) {
      brand = json['brands'].toString().split(',').first.trim();
    }

    // Récupérer la quantité
    String? quantity;
    if (json['quantity'] != null && json['quantity'].toString().isNotEmpty) {
      quantity = json['quantity'].toString();
    }

    // Récupérer l'image
    String? imageUrl;
    if (json['image_url'] != null && json['image_url'].toString().isNotEmpty) {
      imageUrl = json['image_url'].toString();
    } else if (json['image_front_url'] != null && json['image_front_url'].toString().isNotEmpty) {
      imageUrl = json['image_front_url'].toString();
    } else if (json['image_small_url'] != null && json['image_small_url'].toString().isNotEmpty) {
      imageUrl = json['image_small_url'].toString();
    }

    return ProductInfo(
      barcode: json['code']?.toString() ?? '',
      name: productName,
      brand: brand,
      quantity: quantity,
      imageUrl: imageUrl,
      nutriments: json['nutriments'] as Map<String, dynamic>?,
    );
  }

  /// Retourne le nom complet (avec marque si disponible)
  String get fullName {
    if (brand != null && brand!.isNotEmpty) {
      return '$brand - $name';
    }
    return name;
  }

  /// Retourne un nom pour l'affichage dans une liste
  String get displayName {
    final parts = <String>[];

    if (brand != null && brand!.isNotEmpty) {
      parts.add(brand!);
    }

    parts.add(name);

    if (quantity != null && quantity!.isNotEmpty) {
      parts.add('($quantity)');
    }

    return parts.join(' ');
  }

  ProductInfo copyWith({
    String? barcode,
    String? name,
    String? brand,
    String? quantity,
    String? imageUrl,
    Map<String, dynamic>? nutriments,
  }) {
    return ProductInfo(
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      nutriments: nutriments ?? this.nutriments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'nutriments': nutriments,
    };
  }

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      barcode: json['barcode'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      quantity: json['quantity'] as String?,
      imageUrl: json['imageUrl'] as String?,
      nutriments: json['nutriments'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [barcode, name, brand, quantity, imageUrl];
}
