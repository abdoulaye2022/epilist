// blocs/list_item/list_item_state.dart - VERSION AVEC GESTION DOUBLONS
part of 'list_item_bloc.dart';

abstract class ListItemState extends Equatable {
  const ListItemState();

  @override
  List<Object> get props => [];
}

class ListItemInitial extends ListItemState {}

class ListItemLoading extends ListItemState {}

class ListItemLoaded extends ListItemState {
  final List<ListItem> items;

  const ListItemLoaded(this.items);

  @override
  List<Object> get props => [items];
}

class ListItemOperationSuccess extends ListItemState {
  final String message;

  const ListItemOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class ListItemError extends ListItemState {
  final String message;

  const ListItemError(this.message);

  @override
  List<Object> get props => [message];
}

// ✅ NOUVEAU: State pour la détection de doublons
class ListItemDuplicateDetected extends ListItemState {
  final String message;
  final List<DuplicateItem> duplicates;
  final String productName;
  final int quantity;
  final double? price;
  final String? storeName;
  final int listId;

  const ListItemDuplicateDetected({
    required this.message,
    required this.duplicates,
    required this.productName,
    required this.quantity,
    this.price,
    this.storeName,
    required this.listId,
  });

  @override
  List<Object> get props => [
    message,
    duplicates,
    productName,
    quantity,
    listId,
  ];
}

// ✅ NOUVEAU: State pour les statistiques de liste
class ListItemStatsLoaded extends ListItemState {
  final ListStats stats;

  const ListItemStatsLoaded(this.stats);

  @override
  List<Object> get props => [stats];
}

// ✅ NOUVEAU: State pour les erreurs de validation
class ListItemValidationError extends ListItemState {
  final String message;
  final Map<String, List<String>> validationErrors;

  const ListItemValidationError({
    required this.message,
    required this.validationErrors,
  });

  @override
  List<Object> get props => [message, validationErrors];
}

// ✅ NOUVEAU: Classes de données pour les doublons
class DuplicateItem extends Equatable {
  final int id;
  final String productName;
  final String? storeName;
  final int quantity;
  final double? price;
  final int similarityScore;
  final DuplicateType suggestionType;
  final String suggestionMessage;

  const DuplicateItem({
    required this.id,
    required this.productName,
    this.storeName,
    required this.quantity,
    this.price,
    required this.similarityScore,
    required this.suggestionType,
    required this.suggestionMessage,
  });

  factory DuplicateItem.fromJson(Map<String, dynamic> json) {
    return DuplicateItem(
      id: json['id'] as int,
      productName: json['product_name'] as String,
      storeName: json['store_name'] as String?,
      quantity: json['quantity'] as int,
      price: json['price']?.toDouble(),
      similarityScore: json['similarity_score'] as int,
      suggestionType: _parseSuggestionType(json['suggestion_type'] as String),
      suggestionMessage: json['suggestion_message'] as String,
    );
  }

  static DuplicateType _parseSuggestionType(String type) {
    switch (type) {
      case 'exact_match':
        return DuplicateType.exactMatch;
      case 'similar_match':
        return DuplicateType.similarMatch;
      default:
        return DuplicateType.similarMatch;
    }
  }

  String get formattedPrice {
    if (price == null) return '';
    return '${price!.toStringAsFixed(2)} \$CAD';
  }

  String get displayText {
    String text = productName;
    if (storeName != null && storeName!.isNotEmpty) {
      text += ' (${storeName})';
    }
    if (price != null) {
      text += ' - ${formattedPrice}';
    }
    return text;
  }

  @override
  List<Object?> get props => [
    id,
    productName,
    storeName,
    quantity,
    price,
    similarityScore,
    suggestionType,
    suggestionMessage,
  ];
}

enum DuplicateType { exactMatch, similarMatch }

// ✅ NOUVEAU: Classe pour les statistiques de liste
class ListStats extends Equatable {
  final int totalItems;
  final int purchasedItems;
  final int pendingItems;
  final double totalPrice;
  final double purchasedPrice;
  final double pendingPrice;
  final DateTime lastUpdated;

  const ListStats({
    required this.totalItems,
    required this.purchasedItems,
    required this.pendingItems,
    required this.totalPrice,
    required this.purchasedPrice,
    required this.pendingPrice,
    required this.lastUpdated,
  });

  factory ListStats.fromJson(Map<String, dynamic> json) {
    return ListStats(
      totalItems: json['total_items'] as int,
      purchasedItems: json['purchased_items'] as int,
      pendingItems: json['pending_items'] as int,
      totalPrice: (json['total_price'] as num).toDouble(),
      purchasedPrice: (json['purchased_price'] as num).toDouble(),
      pendingPrice: (json['pending_price'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  double get completionPercentage {
    if (totalItems == 0) return 0.0;
    return (purchasedItems / totalItems) * 100;
  }

  String get formattedTotalPrice => '${totalPrice.toStringAsFixed(2)} \$CAD';
  String get formattedPurchasedPrice =>
      '${purchasedPrice.toStringAsFixed(2)} \$CAD';
  String get formattedPendingPrice =>
      '${pendingPrice.toStringAsFixed(2)} \$CAD';

  @override
  List<Object> get props => [
    totalItems,
    purchasedItems,
    pendingItems,
    totalPrice,
    purchasedPrice,
    pendingPrice,
    lastUpdated,
  ];
}
