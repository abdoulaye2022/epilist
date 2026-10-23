// shopping_list_state.dart
part of 'shopping_list_bloc.dart';

abstract class ShoppingListState extends Equatable {
  const ShoppingListState();

  @override
  List<Object?> get props => [];
}

class ShoppingListInitial extends ShoppingListState {}

class ShoppingListLoading extends ShoppingListState {}

class ShoppingListLoaded extends ShoppingListState {
  final List<ShoppingList> lists;

  const ShoppingListLoaded(this.lists);

  @override
  List<Object> get props => [lists];
}

class ShoppingListError extends ShoppingListState {
  final String
  message; // ✅ COHÉRENCE: Utilise 'message' au lieu de 'error' pour cohérence avec le screen

  const ShoppingListError(this.message);

  @override
  List<Object> get props => [message];
}

/// Une liste vient d'etre creee.
///
/// Un simple « Liste creee avec succes » laissait l'utilisatrice sur le
/// tableau de bord, a chercher ou se trouve sa liste. L'etat porte la
/// LISTE : l'ecran peut alors l'ouvrir, la surligner, et proposer
/// « Ouvrir la liste ».
class ShoppingListCreated extends ShoppingListState {
  final ShoppingList list;
  final String message;

  const ShoppingListCreated(this.list, this.message);

  @override
  List<Object> get props => [list, message];
}

class ShoppingListOperationSuccess extends ShoppingListState {
  final String message;

  const ShoppingListOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}
