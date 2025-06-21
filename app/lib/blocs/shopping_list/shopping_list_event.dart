// blocs/shopping_list/shopping_list_event.dart
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
