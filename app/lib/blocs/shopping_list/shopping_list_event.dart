// shopping_list_event.dart - VERSION SIMPLIFIÉE
part of 'shopping_list_bloc.dart';

abstract class ShoppingListEvent extends Equatable {
  const ShoppingListEvent();

  @override
  List<Object?> get props => [];
}

class LoadShoppingLists extends ShoppingListEvent {
  const LoadShoppingLists(); // ✅ Plus besoin de context

  @override
  List<Object?> get props => [];
}

class CreateShoppingList extends ShoppingListEvent {
  final String name;

  const CreateShoppingList(this.name); // ✅ Plus besoin de context

  @override
  List<Object?> get props => [name];
}

class UpdateShoppingList extends ShoppingListEvent {
  final int id;
  final String name;

  const UpdateShoppingList(this.id, this.name); // ✅ Plus besoin de context

  @override
  List<Object?> get props => [id, name];
}

class DeleteShoppingList extends ShoppingListEvent {
  final int id;

  const DeleteShoppingList(this.id); // ✅ Plus besoin de context

  @override
  List<Object?> get props => [id];
}

class DuplicateShoppingList extends ShoppingListEvent {
  final int id;

  const DuplicateShoppingList(this.id); // ✅ Plus besoin de context

  @override
  List<Object?> get props => [id];
}
