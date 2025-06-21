// blocs/list_item/list_item_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:epilist/models/list_item.dart';
import 'package:epilist/services/list_item_service.dart';
import 'package:equatable/equatable.dart';

part 'list_item_event.dart';
part 'list_item_state.dart';

class ListItemBloc extends Bloc<ListItemEvent, ListItemState> {
  final ListItemService _listItemService;

  ListItemBloc({required ListItemService listItemService})
    : _listItemService = listItemService,
      super(ListItemInitial()) {
    on<LoadListItems>(_onLoadListItems);
    on<AddListItem>(_onAddListItem);
    on<TogglePurchasedStatus>(_onTogglePurchasedStatus);
    on<DeleteListItem>(_onDeleteListItem);
  }

  Future<void> _onLoadListItems(
    LoadListItems event,
    Emitter<ListItemState> emit,
  ) async {
    emit(ListItemLoading());
    try {
      final items = await _listItemService.getListItems(event.listId);
      emit(ListItemLoaded(items));
    } catch (e) {
      print("Error loading items: $e");
      emit(ListItemError('Failed to load items'));
    }
  }

  Future<void> _onAddListItem(
    AddListItem event,
    Emitter<ListItemState> emit,
  ) async {
    try {
      // Ajouter l'item via l'API
      final newItem = await _listItemService.addListItem(
        listId: event.listId,
        productName: event.productName,
        quantity: event.quantity,
        price: event.price,
        storeName: event.storeName,
      );

      print("Item ajouté avec succès: ${newItem.toJson()}");

      // Recharger la liste complète pour éviter les problèmes de synchronisation
      add(LoadListItems(event.listId));

      // Émettre un message de succès
      emit(ListItemOperationSuccess('Item ajouté avec succès'));
    } catch (e) {
      print("Error adding item: $e");
      emit(ListItemError('Erreur lors de l\'ajout de l\'item'));
    }
  }

  Future<void> _onTogglePurchasedStatus(
    TogglePurchasedStatus event,
    Emitter<ListItemState> emit,
  ) async {
    try {
      await _listItemService.togglePurchasedStatus(
        listId: event.listId,
        itemId: event.itemId,
        isPurchased: event.isPurchased,
      );

      // Mettre à jour l'item dans la liste actuelle
      if (state is ListItemLoaded) {
        final currentState = state as ListItemLoaded;
        final updatedItems =
            currentState.items.map((item) {
              if (item.id == event.itemId) {
                return item.copyWith(isPurchased: event.isPurchased);
              }
              return item;
            }).toList();

        emit(ListItemLoaded(updatedItems));
      }
    } catch (e) {
      print("Error toggling status: $e");
      emit(ListItemError('Erreur lors de la mise à jour du statut'));
    }
  }

  Future<void> _onDeleteListItem(
    DeleteListItem event,
    Emitter<ListItemState> emit,
  ) async {
    try {
      await _listItemService.deleteListItem(
        listId: event.listId,
        itemId: event.itemId,
      );

      // Supprimer l'item de la liste actuelle
      if (state is ListItemLoaded) {
        final currentState = state as ListItemLoaded;
        final updatedItems =
            currentState.items
                .where((item) => item.id != event.itemId)
                .toList();

        emit(ListItemLoaded(updatedItems));

        // Émettre un message de succès
        emit(ListItemOperationSuccess('Item supprimé avec succès'));

        // Revenir à l'état loaded
        emit(ListItemLoaded(updatedItems));
      }
    } catch (e) {
      print("Error deleting item: $e");
      emit(ListItemError('Erreur lors de la suppression'));
    }
  }
}
