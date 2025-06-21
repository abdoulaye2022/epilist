// blocs/shopping_list/shopping_list_bloc.dart
// ignore: depend_on_referenced_packages
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
      emit(ShoppingListError('Failed to load shopping lists'));
    }
  }

  Future<void> _onCreateShoppingList(
    CreateShoppingList event,
    Emitter<ShoppingListState> emit,
  ) async {
    try {
      final newList = await _shoppingListService.createShoppingList(event.name);
      emit(ShoppingListCreated(newList));
      // Recharge les listes après création
      add(LoadShoppingLists());
    } catch (e) {
      emit(ShoppingListError('Failed to create shopping list'));
    }
  }
}
