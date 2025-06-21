// blocs/list_item/list_item_event.dart
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

  const AddListItem({
    required this.listId,
    required this.productName,
    this.quantity = 1,
    this.price,
    this.storeName,
  });

  @override
  List<Object> get props => [listId, productName, quantity];
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

  const UpdateListItem({
    required this.listId,
    required this.itemId,
    required this.productName,
    this.quantity = 1,
    this.price,
    this.storeName,
  });

  @override
  List<Object> get props => [listId, itemId, productName, quantity];
}
