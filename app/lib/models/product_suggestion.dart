// models/product_suggestion.dart - VERSION CORRIGÉE AVEC STRUCTURE ROBUSTE
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';

class ProductSuggestion extends Equatable {
  final int id;
  final int userId;
  final String productName;
  final String normalizedName;
  final double? price;
  final String? storeName;
  final int usageCount;
  final DateTime? lastUsedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductSuggestion({
    required this.id,
    required this.userId,
    required this.productName,
    required this.normalizedName,
    this.price,
    this.storeName,
    required this.usageCount,
    this.lastUsedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// ✅ Prix formaté localisé avec devise
  String getFormattedPrice(BuildContext context) {
    if (price == null) return '';
    final l10n = AppLocalizations.of(context)!;
    return l10n.priceFormat(price!.toStringAsFixed(2));
  }

  /// ✅ Prix formaté simple (sans contexte) - fallback
  String get formattedPrice {
    if (price == null) return '';
    return '\$${price!.toStringAsFixed(2)}';
  }

  /// ✅ Nom du magasin localisé
  String getStoreDisplayName(BuildContext context) {
    if (storeName == null || storeName!.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return l10n.noStoreSpecified;
    }
    return storeName!;
  }

  /// ✅ Nom du magasin simple (sans contexte) - fallback
  String get storeDisplayName => storeName ?? '';

  /// Vérifie si la suggestion a un prix défini
  bool get hasPrice => price != null && price! > 0;

  /// Vérifie si la suggestion a un magasin défini
  bool get hasStore => storeName != null && storeName!.isNotEmpty;

  /// ✅ Information d'usage localisée
  String getUsageInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (usageCount == 1) {
      return l10n.usedOnce;
    } else {
      return l10n.usedXTimes(usageCount);
    }
  }

  /// ✅ Information d'usage simple (sans contexte) - fallback
  String get usageInfo {
    if (usageCount == 1) {
      return 'Utilisé 1 fois'; // Fallback français
    } else {
      return 'Utilisé $usageCount fois';
    }
  }

  /// ✅ Date de dernière utilisation formatée et localisée
  String? getLastUsedFormatted(BuildContext context) {
    if (lastUsedAt == null) return null;

    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(lastUsedAt!);

    if (difference.inDays == 0) {
      return l10n.today;
    } else if (difference.inDays == 1) {
      return l10n.yesterday;
    } else if (difference.inDays < 7) {
      return l10n.daysAgo(difference.inDays);
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      // ✅ CORRECTION: Ajouter le paramètre pluriel pour weeksAgo
      final plural = weeks > 1 ? 's' : '';
      return l10n.weeksAgo(weeks, plural);
    } else {
      final months = (difference.inDays / 30).floor();
      // ✅ CORRECTION: monthsAgo attend aussi 2 paramètres selon votre fichier ARB
      final plural = months > 1 ? 's' : '';
      return l10n.monthsAgo(months, plural);
    }
  }

  /// ✅ Date de dernière utilisation simple (sans contexte) - fallback
  String? get lastUsedFormatted {
    if (lastUsedAt == null) return null;

    final now = DateTime.now();
    final difference = now.difference(lastUsedAt!);

    if (difference.inDays == 0) {
      return "Aujourd'hui";
    } else if (difference.inDays == 1) {
      return "Hier";
    } else if (difference.inDays < 7) {
      return "Il y a ${difference.inDays} jours";
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return "Il y a $weeks semaine${weeks > 1 ? 's' : ''}";
    } else {
      final months = (difference.inDays / 30).floor();
      return "Il y a $months mois";
    }
  }

  /// ✅ Description complète localisée pour l'affichage
  String getDisplayDescription(BuildContext context) {
    final usage = getUsageInfo(context);
    final lastUsed = getLastUsedFormatted(context);

    if (lastUsed != null) {
      // ✅ CORRECTION: Simple concaténation au lieu d'une méthode l10n complexe
      return '$usage - $lastUsed';
    } else {
      return usage;
    }
  }

  /// ✅ Description complète avec toutes les informations
  String getFullDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final usage = getUsageInfo(context);
    final priceInfo = hasPrice ? getFormattedPrice(context) : l10n.noPriceSet;
    final storeInfo = getStoreDisplayName(context);

    return l10n.suggestionDescription(productName, usage, priceInfo, storeInfo);
  }

  factory ProductSuggestion.fromJson(Map<String, dynamic> json) {
    return ProductSuggestion(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      productName: json['product_name'] as String? ?? '',
      normalizedName: json['normalized_name'] as String? ?? '',
      price: _parseDouble(json['price']),
      storeName: _parseString(json['store_name']),
      usageCount: _parseInt(json['usage_count']),
      lastUsedAt:
          json['last_used_at'] != null
              ? DateTime.tryParse(json['last_used_at'] as String)
              : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // ✅ Fonctions helpers pour le parsing robuste (comme ListItem)
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
      'user_id': userId,
      'product_name': productName,
      'normalized_name': normalizedName,
      'price': price,
      'store_name': storeName,
      'usage_count': usageCount,
      'last_used_at': lastUsedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    productName,
    normalizedName,
    price,
    storeName,
    usageCount,
    lastUsedAt,
    createdAt,
    updatedAt,
  ];

  ProductSuggestion copyWith({
    int? id,
    int? userId,
    String? productName,
    String? normalizedName,
    double? price,
    String? storeName,
    int? usageCount,
    DateTime? lastUsedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductSuggestion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productName: productName ?? this.productName,
      normalizedName: normalizedName ?? this.normalizedName,
      price: price ?? this.price,
      storeName: storeName ?? this.storeName,
      usageCount: usageCount ?? this.usageCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ProductSuggestion{id: $id, product: $productName, usage: $usageCount, '
        'price: ${price ?? 'N/A'}, store: ${storeName ?? 'N/A'}}';
  }
}

// ✅ Extension pour les validations de suggestions (comme ListItem)
extension ProductSuggestionValidation on ProductSuggestion {
  /// Vérifie si la suggestion est valide
  bool get isValid {
    return productName.isNotEmpty && usageCount > 0;
  }

  /// Vérifie si la suggestion est complète (avec toutes les informations)
  bool get isComplete {
    return isValid && hasPrice && hasStore;
  }

  /// Retourne les champs manquants
  List<String> get missingFields {
    List<String> missing = [];

    if (productName.isEmpty) missing.add('Nom du produit');
    if (usageCount <= 0) missing.add('Nombre d\'utilisations');
    if (!hasPrice) missing.add('Prix');
    if (!hasStore) missing.add('Magasin');

    return missing;
  }

  /// Vérifie si la suggestion est récente (utilisée dans les 30 derniers jours)
  bool get isRecent {
    if (lastUsedAt == null) return false;
    final now = DateTime.now();
    final difference = now.difference(lastUsedAt!);
    return difference.inDays <= 30;
  }

  /// Vérifie si la suggestion est populaire (utilisée plus de 3 fois)
  bool get isPopular {
    return usageCount > 3;
  }
}
