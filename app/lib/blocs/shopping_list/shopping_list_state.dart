// blocs/shopping_list/shopping_list_state.dart
part of 'shopping_list_bloc.dart';

abstract class ShoppingListState extends Equatable {
  const ShoppingListState();

  @override
  List<Object> get props => [];
}

class ShoppingListInitial extends ShoppingListState {}

class ShoppingListLoading extends ShoppingListState {}

class ShoppingListLoaded extends ShoppingListState {
  final List<ShoppingList> lists;

  const ShoppingListLoaded(this.lists);

  @override
  List<Object> get props => [lists];
}

class ShoppingListCreated extends ShoppingListState {
  final ShoppingList newList;

  const ShoppingListCreated(this.newList);

  @override
  List<Object> get props => [newList];
}

class ShoppingListError extends ShoppingListState {
  final String message;

  const ShoppingListError(this.message);

  @override
  List<Object> get props => [message];
}
