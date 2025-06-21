part of 'shopping_list_bloc.dart';

abstract class ShoppingListEvent extends Equatable {
  const ShoppingListEvent();

  @override
  List<Object> get props => [];
}

class LoadShoppingLists extends ShoppingListEvent {}

class CreateShoppingList extends ShoppingListEvent {
  final String name;

  const CreateShoppingList(this.name);

  @override
  List<Object> get props => [name];
}

// AJOUT: Événements manquants
class UpdateShoppingList extends ShoppingListEvent {
  final int id;
  final String name;

  const UpdateShoppingList(this.id, this.name);

  @override
  List<Object> get props => [id, name];
}

class DeleteShoppingList extends ShoppingListEvent {
  final int id;

  const DeleteShoppingList(this.id);

  @override
  List<Object> get props => [id];
}

class DuplicateShoppingList extends ShoppingListEvent {
  final int id;

  const DuplicateShoppingList(this.id);

  @override
  List<Object> get props => [id];
}
