// blocs/shopping_list/shopping_list_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/services/shopping_list_service.dart';
import 'package:equatable/equatable.dart';

part 'shopping_list_event.dart';
part 'shopping_list_state.dart';

class ShoppingListBloc extends Bloc<ShoppingListEvent, ShoppingListState> {
  final ShoppingListService _shoppingListService;

  ShoppingListBloc({required ShoppingListService shoppingListService})
    : _shoppingListService = shoppingListService,
      super(ShoppingListInitial()) {
    on<LoadShoppingLists>(_onLoadShoppingLists);
    on<CreateShoppingList>(_onCreateShoppingList);
    on<UpdateShoppingList>(_onUpdateShoppingList);
    on<DeleteShoppingList>(_onDeleteShoppingList);
    on<DuplicateShoppingList>(_onDuplicateShoppingList);
  }

  Future<void> _onLoadShoppingLists(
    LoadShoppingLists event,
    Emitter<ShoppingListState> emit,
  ) async {
    emit(ShoppingListLoading());
    try {
      final lists = await _shoppingListService.getShoppingLists();
      emit(ShoppingListLoaded(lists));
    } catch (e) {
      print("Error loading shopping lists: $e");
      emit(ShoppingListError('Erreur lors du chargement des listes'));
    }
  }

  Future<void> _onCreateShoppingList(
    CreateShoppingList event,
    Emitter<ShoppingListState> emit,
  ) async {
    try {
      final newList = await _shoppingListService.createShoppingList(event.name);

      // Ajouter la nouvelle liste à la liste existante
      if (state is ShoppingListLoaded) {
        final currentState = state as ShoppingListLoaded;
        final updatedLists = [newList, ...currentState.lists];

        // Émettre d'abord le message de succès
        emit(ShoppingListOperationSuccess('Liste créée avec succès'));

        // Puis émettre l'état loaded avec les nouvelles données
        emit(ShoppingListLoaded(updatedLists));
      } else {
        // Si pas d'état loaded, recharger tout
        emit(ShoppingListOperationSuccess('Liste créée avec succès'));
        add(LoadShoppingLists());
      }
    } catch (e) {
      print("Error creating shopping list: $e");
      emit(ShoppingListError('Erreur lors de la création de la liste'));
    }
  }

  Future<void> _onUpdateShoppingList(
    UpdateShoppingList event,
    Emitter<ShoppingListState> emit,
  ) async {
    try {
      final updatedList = await _shoppingListService.updateShoppingList(
        event.id,
        event.name,
      );

      // Mettre à jour la liste dans l'état actuel
      if (state is ShoppingListLoaded) {
        final currentState = state as ShoppingListLoaded;
        final updatedLists =
            currentState.lists.map((list) {
              if (list.id == event.id) {
                return updatedList;
              }
              return list;
            }).toList();

        emit(ShoppingListOperationSuccess('Liste modifiée avec succès'));
        emit(ShoppingListLoaded(updatedLists));
      }
    } catch (e) {
      print("Error updating shopping list: $e");
      emit(ShoppingListError('Erreur lors de la modification'));
    }
  }

  Future<void> _onDeleteShoppingList(
    DeleteShoppingList event,
    Emitter<ShoppingListState> emit,
  ) async {
    try {
      await _shoppingListService.deleteShoppingList(event.id);

      // Supprimer la liste de l'état actuel
      if (state is ShoppingListLoaded) {
        final currentState = state as ShoppingListLoaded;
        final updatedLists =
            currentState.lists.where((list) => list.id != event.id).toList();

        emit(ShoppingListOperationSuccess('Liste supprimée avec succès'));
        emit(ShoppingListLoaded(updatedLists));
      }
    } catch (e) {
      print("Error deleting shopping list: $e");
      emit(ShoppingListError('Erreur lors de la suppression'));
    }
  }

  Future<void> _onDuplicateShoppingList(
    DuplicateShoppingList event,
    Emitter<ShoppingListState> emit,
  ) async {
    try {
      final duplicatedList = await _shoppingListService.duplicateShoppingList(
        event.id,
      );

      // Ajouter la liste dupliquée à l'état actuel
      if (state is ShoppingListLoaded) {
        final currentState = state as ShoppingListLoaded;
        final updatedLists = [duplicatedList, ...currentState.lists];

        emit(ShoppingListOperationSuccess('Liste dupliquée avec succès'));
        emit(ShoppingListLoaded(updatedLists));
      }
    } catch (e) {
      print("Error duplicating shopping list: $e");
      emit(ShoppingListError('Erreur lors de la duplication'));
    }
  }
}
