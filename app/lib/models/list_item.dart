// models/list_item.dart - VERSION AFFICHAGE SEULEMENT
import 'package:epilist/models/currency.dart';
import 'package:epilist/models/user.dart';

class ListItem {
  final int id;
  final int listId;
  final String productName;
  final int quantity;
  final double? price; // Nullable pour gérer les prix absents
  final String? storeName; // Nullable pour gérer les magasins absents
  final bool isPurchased;
  final int? categoryId; // Nullable - ID de la catégorie associée
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
    this.categoryId, // Nullable
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

  /// Retourne le nom formaté avec quantité
  String get formattedName {
    if (quantity > 1) {
      return '${quantity}x $productName';
    }
    return productName;
  }

  // ✅ NOUVELLES MÉTHODES POUR LE FORMATAGE AVEC DEVISE D'AFFICHAGE (SANS CONVERSION)

  /// Obtenir le prix formaté dans une devise d'affichage spécifique
  /// ⚠️ IMPORTANT: Pas de conversion, seulement changement de symbole
  String getFormattedPriceInCurrency({Currency? currency}) {
    if (price == null) return '';

    if (currency != null) {
      return currency.formatAmount(price!);
    }

    // Format par défaut en CAD
    return '\$${price!.toStringAsFixed(2)}';
  }

  /// Obtenir le prix formaté selon la devise d'affichage de l'utilisateur
  /// ⚠️ IMPORTANT: Pas de conversion, seulement changement de symbole
  String getFormattedPriceForUser({User? user}) {
    if (price == null) return '';

    if (user != null) {
      return user.formatAmount(price!);
    }

    return getFormattedPriceInCurrency();
  }

  /// Obtenir le prix total formaté (prix × quantité)
  /// ⚠️ IMPORTANT: Pas de conversion, seulement changement de symbole
  String getFormattedTotalPriceInCurrency({Currency? currency}) {
    if (price == null) return '';

    final total = totalPrice;

    if (currency != null) {
      return currency.formatAmount(total);
    }

    return '\$${total.toStringAsFixed(2)}';
  }

  /// Obtenir le prix total formaté selon la devise d'affichage de l'utilisateur
  /// ⚠️ IMPORTANT: Pas de conversion, seulement changement de symbole
  String getFormattedTotalPriceForUser({User? user}) {
    if (price == null) return '';

    final total = totalPrice;

    if (user != null) {
      return user.formatAmount(total);
    }

    return '\$${total.toStringAsFixed(2)}';
  }

  /// ✅ SUPPRIMÉ: convertPriceTo, getPriceInUserCurrency, getTotalPriceInUserCurrency
  /// Ces méthodes faisaient de la conversion, ce qui n'est plus nécessaire

  // ✅ NOUVEAUX ACCESSEURS POUR LES DONNÉES API
  Map<String, dynamic> get apiData {
    return {
      'id': id,
      'list_id': listId,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      'store_name': storeName,
      'is_purchased': isPurchased,
      'formatted_name': formattedName,
      'formatted_price': formattedPrice,
      'formatted_total_price': getFormattedTotalPriceInCurrency(),
      'total_price': totalPrice,
      'has_price': hasPrice,
      'has_store': hasStore,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Obtenir les données API formatées selon la devise d'affichage de l'utilisateur
  Map<String, dynamic> getApiDataForUser({User? user}) {
    final data = apiData;

    if (user != null && price != null) {
      data['formatted_price'] = getFormattedPriceForUser(user: user);
      data['formatted_total_price'] = getFormattedTotalPriceForUser(user: user);
      // ✅ SUPPRIMÉ: price_in_user_currency, total_price_in_user_currency (pas de conversion)
      data['display_currency'] = {
        'code': user.currencyCode,
        'symbol': user.currencySymbol,
        'name': user.currencyDisplayName,
      };
    }

    return data;
  }

  factory ListItem.fromJson(Map<String, dynamic> json) {
    return ListItem(
      id: _parseInt(json['id']),
      listId: _parseInt(json['list_id']),
      productName: json['product_name'] as String? ?? '',
      quantity: _parseInt(json['quantity']),
      price: _parseDouble(json['price']), // Peut être null
      storeName: _parseString(json['store_name']), // Peut être null
      isPurchased: json['is_purchased'] == true || json['is_purchased'] == 1,
      categoryId: json['category_id'] != null ? _parseInt(json['category_id']) : null,
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
      'category_id': categoryId,
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
    int? categoryId,
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
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  /// Copie avec nouveau prix
  ListItem withPrice(double? newPrice) {
    return copyWith(price: newPrice);
  }

  /// Copie avec nouveau magasin
  ListItem withStore(String? newStoreName) {
    return copyWith(storeName: newStoreName);
  }

  /// Copie avec statut d'achat basculé
  ListItem togglePurchased() {
    return copyWith(isPurchased: !isPurchased);
  }

  /// Copie marquée comme achetée
  ListItem markAsPurchased() {
    return copyWith(isPurchased: true);
  }

  /// Copie marquée comme non achetée
  ListItem markAsNotPurchased() {
    return copyWith(isPurchased: false);
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
          categoryId == other.categoryId &&
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
      categoryId.hashCode ^
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

  /// Vérifie si l'article a des informations minimales
  bool get hasMinimalInfo {
    return productName.isNotEmpty && quantity > 0;
  }

  /// Vérifie si l'article a des informations étendues
  bool get hasExtendedInfo {
    return hasMinimalInfo && (hasPrice || hasStore);
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

  /// Retourne les champs optionnels manquants
  List<String> get missingOptionalFields {
    List<String> missing = [];

    if (!hasPrice) missing.add('Prix');
    if (!hasStore) missing.add('Magasin');

    return missing;
  }

  /// Vérifie si l'article peut être acheté (a un prix)
  bool get canBePurchased {
    return hasPrice && price! > 0;
  }

  /// Vérifie si l'article est récent (créé dans les dernières 24h)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inHours < 24;
  }

  /// Vérifie si l'article a été modifié récemment
  bool get isRecentlyModified {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);
    return difference.inHours < 1;
  }

  /// Vérifie si l'article est supprimé (soft delete)
  bool get isDeleted {
    return deletedAt != null;
  }

  /// Calcule le score de complétude (0-100%)
  int get completenessScore {
    int score = 0;

    if (productName.isNotEmpty) score += 40; // Nom = 40%
    if (quantity > 0) score += 20; // Quantité = 20%
    if (hasPrice) score += 20; // Prix = 20%
    if (hasStore) score += 20; // Magasin = 20%

    return score;
  }

  /// Obtient le niveau de complétude
  String get completenessLevel {
    final score = completenessScore;

    if (score >= 100) return 'Complet';
    if (score >= 80) return 'Très bon';
    if (score >= 60) return 'Bon';
    if (score >= 40) return 'Minimal';
    return 'Incomplet';
  }
}

// ✅ EXTENSION MODIFIÉE: Utilitaires de devise d'affichage pour ListItem
extension ListItemCurrencyExtension on ListItem {
  /// Formater le prix avec options avancées (AFFICHAGE SEULEMENT)
  /// ⚠️ IMPORTANT: Pas de conversion, seulement changement de symbole
  String formatPriceAdvanced({
    Currency? currency,
    User? user,
    bool showCode = false,
    bool showSymbol = true,
    int decimals = 2,
    String? prefix,
    String? suffix,
  }) {
    if (price == null) return '';

    Currency curr;
    if (user != null) {
      curr = user.displayCurrency;
    } else if (currency != null) {
      curr = currency;
    } else {
      curr = Currency.cad;
    }

    final formatted = price!.toStringAsFixed(decimals);

    String result = '';

    if (prefix != null) result += prefix;
    if (showSymbol) result += curr.symbol;
    result += formatted;
    if (showCode) result += ' ${curr.code}';
    if (suffix != null) result += suffix;

    return result;
  }

  /// Formater le prix total avec options avancées (AFFICHAGE SEULEMENT)
  /// ⚠️ IMPORTANT: Pas de conversion, seulement changement de symbole
  String formatTotalPriceAdvanced({
    Currency? currency,
    User? user,
    bool showCode = false,
    bool showSymbol = true,
    int decimals = 2,
    String? prefix,
    String? suffix,
  }) {
    if (price == null) return '';

    Currency curr;
    if (user != null) {
      curr = user.displayCurrency;
    } else if (currency != null) {
      curr = currency;
    } else {
      curr = Currency.cad;
    }

    final total = totalPrice;
    final formatted = total.toStringAsFixed(decimals);

    String result = '';

    if (prefix != null) result += prefix;
    if (showSymbol) result += curr.symbol;
    result += formatted;
    if (showCode) result += ' ${curr.code}';
    if (suffix != null) result += suffix;

    return result;
  }

  /// Obtenir des informations de prix formatées pour l'UI (AFFICHAGE SEULEMENT)
  Map<String, String> getPriceInfo({Currency? currency, User? user}) {
    if (price == null) {
      return {
        'unitPrice': '',
        'totalPrice': '',
        'currency': 'CAD',
        'symbol': '\$',
        'hasPrice': 'false',
      };
    }

    Currency curr;
    if (user != null) {
      curr = user.displayCurrency;
    } else if (currency != null) {
      curr = currency;
    } else {
      curr = Currency.cad;
    }

    return {
      'unitPrice': curr.formatAmount(price!),
      'totalPrice': curr.formatAmount(totalPrice),
      'unitPriceWithCode': curr.formatAmount(price!, showCode: true),
      'totalPriceWithCode': curr.formatAmount(totalPrice, showCode: true),
      'currency': curr.code,
      'symbol': curr.symbol,
      'hasPrice': 'true',
      'quantity': quantity.toString(),
    };
  }

  /// ✅ SUPPRIMÉ: calculatePriceDifference, calculateSavingsPercentage, isGoodDeal
  /// Ces méthodes impliquaient des calculs de conversion
}
