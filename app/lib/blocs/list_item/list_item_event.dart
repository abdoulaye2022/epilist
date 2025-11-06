// blocs/list_item/list_item_event.dart - VERSION AVEC GESTION DOUBLONS
part of 'list_item_bloc.dart';

abstract class ListItemEvent extends Equatable {
  const ListItemEvent();

  @override
  List<Object> get props => [];
}

class LoadListItems extends ListItemEvent {
  final int listId;
  const LoadListItems(this.listId);

  @override
  List<Object> get props => [listId];
}

class AddListItem extends ListItemEvent {
  final int listId;
  final String productName;
  final int quantity;
  final double? price;
  final String? storeName;
  final int? categoryId;

  const AddListItem({
    required this.listId,
    required this.productName,
    this.quantity = 1,
    this.price,
    this.storeName,
    this.categoryId,
  });

  @override
  List<Object> get props => [listId, productName, quantity];
}

// ✅ NOUVEAU: Event pour forcer l'ajout malgré les doublons
class ForceAddListItem extends ListItemEvent {
  final int listId;
  final String productName;
  final int quantity;
  final double? price;
  final String? storeName;

  const ForceAddListItem({
    required this.listId,
    required this.productName,
    this.quantity = 1,
    this.price,
    this.storeName,
  });

  @override
  List<Object> get props => [listId, productName, quantity];
}

// ✅ NOUVEAU: Event pour fusionner avec un item existant
class MergeWithExistingItem extends ListItemEvent {
  final int listId;
  final int existingItemId;
  final int additionalQuantity;
  final double? newPrice;

  const MergeWithExistingItem({
    required this.listId,
    required this.existingItemId,
    this.additionalQuantity = 1,
    this.newPrice,
  });

  @override
  List<Object> get props => [listId, existingItemId, additionalQuantity];
}

// ✅ NOUVEAU: Event pour confirmer l'action après détection de doublon
class HandleDuplicateAction extends ListItemEvent {
  final DuplicateAction action;
  final int listId;
  final String productName;
  final int quantity;
  final double? price;
  final String? storeName;
  final int? existingItemId;

  const HandleDuplicateAction({
    required this.action,
    required this.listId,
    required this.productName,
    this.quantity = 1,
    this.price,
    this.storeName,
    this.existingItemId,
  });

  @override
  List<Object> get props => [action, listId, productName, quantity];
}

class TogglePurchasedStatus extends ListItemEvent {
  final int listId;
  final int itemId;
  final bool isPurchased;

  const TogglePurchasedStatus({
    required this.listId,
    required this.itemId,
    required this.isPurchased,
  });

  @override
  List<Object> get props => [listId, itemId, isPurchased];
}

class DeleteListItem extends ListItemEvent {
  final int listId;
  final int itemId;

  const DeleteListItem({required this.listId, required this.itemId});

  @override
  List<Object> get props => [listId, itemId];
}

class UpdateListItem extends ListItemEvent {
  final int listId;
  final int itemId;
  final String productName;
  final int quantity;
  final double? price;
  final String? storeName;
  final int? categoryId;

  const UpdateListItem({
    required this.listId,
    required this.itemId,
    required this.productName,
    this.quantity = 1,
    this.price,
    this.storeName,
    this.categoryId,
  });

  @override
  List<Object> get props => [listId, itemId, productName, quantity];
}

// ✅ NOUVEAU: Event pour marquer tous les articles
class MarkAllItemsAs extends ListItemEvent {
  final int listId;
  final bool isPurchased;

  const MarkAllItemsAs({required this.listId, required this.isPurchased});

  @override
  List<Object> get props => [listId, isPurchased];
}

// ✅ NOUVEAU: Event pour supprimer tous les articles achetés
class ClearPurchasedItems extends ListItemEvent {
  final int listId;

  const ClearPurchasedItems(this.listId);

  @override
  List<Object> get props => [listId];
}

// ✅ NOUVEAU: Event pour obtenir les statistiques
class LoadListStats extends ListItemEvent {
  final int listId;

  const LoadListStats(this.listId);

  @override
  List<Object> get props => [listId];
}

// ✅ ENUM pour les actions de gestion des doublons
enum DuplicateAction { forceAdd, merge, cancel }
