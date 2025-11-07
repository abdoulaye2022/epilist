// blocs/list_item/list_item_bloc.dart - VERSION AVEC GESTION DOUBLONS
import 'package:bloc/bloc.dart';
import 'package:epilist/models/list_item.dart';
import 'package:epilist/services/list_item_service.dart';
import 'package:epilist/services/offline_storage_service.dart';
import 'package:epilist/services/offline_queue_service.dart';
import 'package:epilist/services/connectivity_service.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart';
import 'package:equatable/equatable.dart';

part 'list_item_event.dart';
part 'list_item_state.dart';

class ListItemBloc extends Bloc<ListItemEvent, ListItemState> {
  final ListItemService _listItemService;
  final LocalizationBloc _localizationBloc;
  final ConnectivityService _connectivityService = ConnectivityService();

  ListItemBloc({
    required ListItemService listItemService,
    required LocalizationBloc localizationBloc,
  }) : _listItemService = listItemService,
       _localizationBloc = localizationBloc,
       super(ListItemInitial()) {
    on<LoadListItems>(_onLoadListItems);
    on<AddListItem>(_onAddListItem);
    on<ForceAddListItem>(_onForceAddListItem);
    on<MergeWithExistingItem>(_onMergeWithExistingItem);
    on<HandleDuplicateAction>(_onHandleDuplicateAction);
    on<UpdateListItem>(_onUpdateListItem);
    on<TogglePurchasedStatus>(_onTogglePurchasedStatus);
    on<DeleteListItem>(_onDeleteListItem);
    on<MarkAllItemsAs>(_onMarkAllItemsAs);
    on<ClearPurchasedItems>(_onClearPurchasedItems);
    on<LoadListStats>(_onLoadListStats);
  }

  /// ✅ Méthodes de traduction (inchangées)
  String _getTranslatedSuccessMessage(String operation) {
    const Map<String, String> frenchMessages = {
      'add': 'Article ajouté avec succès',
      'force_add': 'Article ajouté (doublon ignoré)',
      'merge': 'Articles fusionnés avec succès',
      'update': 'Article mis à jour avec succès',
      'delete': 'Article supprimé avec succès',
      'toggle': 'Statut mis à jour avec succès',
      'load': 'Articles chargés avec succès',
      'mark_all': 'Tous les articles mis à jour',
      'clear_purchased': 'Articles achetés supprimés',
    };

    const Map<String, String> englishMessages = {
      'add': 'Item added successfully',
      'force_add': 'Item added (duplicate ignored)',
      'merge': 'Items merged successfully',
      'update': 'Item updated successfully',
      'delete': 'Item deleted successfully',
      'toggle': 'Status updated successfully',
      'load': 'Items loaded successfully',
      'mark_all': 'All items updated',
      'clear_purchased': 'Purchased items cleared',
    };

    final isEnglish =
        _localizationBloc.state is LocalizationLoaded &&
        (_localizationBloc.state as LocalizationLoaded).locale.languageCode ==
            'en';

    if (isEnglish) {
      return englishMessages[operation] ?? 'Operation successful';
    } else {
      return frenchMessages[operation] ?? 'Opération réussie';
    }
  }

  String _getTranslatedOperationError(String operation) {
    const Map<String, String> frenchErrors = {
      'load': 'Erreur lors du chargement des articles',
      'add': 'Erreur lors de l\'ajout de l\'article',
      'update': 'Erreur lors de la mise à jour de l\'article',
      'delete': 'Erreur lors de la suppression de l\'article',
      'toggle': 'Erreur lors de la mise à jour du statut',
      'mark_all': 'Erreur lors de la mise à jour des articles',
      'clear_purchased': 'Erreur lors de la suppression des articles achetés',
    };

    const Map<String, String> englishErrors = {
      'load': 'Error loading items',
      'add': 'Error adding item',
      'update': 'Error updating item',
      'delete': 'Error deleting item',
      'toggle': 'Error updating status',
      'mark_all': 'Error updating all items',
      'clear_purchased': 'Error clearing purchased items',
    };

    final isEnglish =
        _localizationBloc.state is LocalizationLoaded &&
        (_localizationBloc.state as LocalizationLoaded).locale.languageCode ==
            'en';

    if (isEnglish) {
      return englishErrors[operation] ?? 'An error occurred';
    } else {
      return frenchErrors[operation] ?? 'Une erreur est survenue';
    }
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

      // ✅ Fallback: Essayer de charger depuis le cache (mode offline)
      // Note: Les items sont dans la liste en cache
      try {
        final cachedLists = await OfflineStorageService.getShoppingLists();
        if (cachedLists != null) {
          final cachedList = cachedLists.firstWhere(
            (list) => list.id == event.listId,
            orElse: () => throw Exception('List not found in cache'),
          );
          print('📦 Loading ${cachedList.items.length} items from cache (offline mode)');
          emit(ListItemLoaded(cachedList.items));
          return;
        }
      } catch (cacheError) {
        print('❌ Cache load failed: $cacheError');
      }

      final errorMessage = _getTranslatedOperationError('load');
      emit(ListItemError(errorMessage));
    }
  }

  /// ✅ NOUVELLE IMPLÉMENTATION: Gestion des doublons lors de l'ajout
  Future<void> _onAddListItem(
    AddListItem event,
    Emitter<ListItemState> emit,
  ) async {
    try {
      final result = await _listItemService.addListItem(
        listId: event.listId,
        productName: event.productName,
        quantity: event.quantity,
        price: event.price,
        storeName: event.storeName,
        categoryId: event.categoryId,
      );

      if (result.isSuccess) {
        // Succès - pas de doublon
        print("Item ajouté avec succès: ${result.item!.toJson()}");

        if (state is ListItemLoaded) {
          final currentState = state as ListItemLoaded;
          final updatedItems = [result.item!, ...currentState.items];

          final successMessage = _getTranslatedSuccessMessage('add');
          emit(ListItemOperationSuccess(successMessage));
          emit(ListItemLoaded(updatedItems));
        } else {
          final successMessage = _getTranslatedSuccessMessage('add');
          emit(ListItemOperationSuccess(successMessage));
          add(LoadListItems(event.listId));
        }
      } else if (result.isDuplicateDetected) {
        // Doublon détecté - émettre un état spécial
        emit(
          ListItemDuplicateDetected(
            message: result.message!,
            duplicates: result.duplicates!,
            productName: event.productName,
            quantity: event.quantity,
            price: event.price,
            storeName: event.storeName,
            listId: event.listId,
          ),
        );
      } else if (result.isValidationError) {
        // Erreur de validation
        emit(
          ListItemValidationError(
            message: result.message!,
            validationErrors: result.validationErrors!,
          ),
        );
      }
    } catch (e) {
      print("Error adding item: $e");

      // ✅ Si hors ligne, mettre en queue
      if (!_connectivityService.isConnected) {
        await OfflineQueueService.enqueueAction(
          actionType: OfflineQueueService.ACTION_CREATE_ITEM,
          payload: {
            'list_id': event.listId,
            'product_name': event.productName,
            'quantity': event.quantity,
            'price': event.price,
            'store_name': event.storeName,
            'category_id': event.categoryId,
          },
        );

        // Créer un item temporaire local avec ID négatif
        final tempItem = ListItem(
          id: -DateTime.now().millisecondsSinceEpoch,
          listId: event.listId,
          productName: event.productName,
          quantity: event.quantity,
          price: event.price,
          storeName: event.storeName,
          categoryId: event.categoryId,
          isPurchased: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (state is ListItemLoaded) {
          final currentState = state as ListItemLoaded;
          final updatedItems = [tempItem, ...currentState.items];

          final successMessage = _getTranslatedSuccessMessage('add');
          emit(ListItemOperationSuccess(successMessage));
          emit(ListItemLoaded(updatedItems));
        }
        return;
      }

      final errorMessage = _getTranslatedOperationError('add');
      emit(ListItemError(errorMessage));
    }
  }

  /// ✅ NOUVELLE MÉTHODE: Forcer l'ajout d'un item
  Future<void> _onForceAddListItem(
    ForceAddListItem event,
    Emitter<ListItemState> emit,
  ) async {
    try {
      final newItem = await _listItemService.forceAddListItem(
        listId: event.listId,
        productName: event.productName,
        quantity: event.quantity,
        price: event.price,
        storeName: event.storeName,
      );

      print("Item forcé avec succès: ${newItem.toJson()}");

      if (state is ListItemLoaded) {
        final currentState = state as ListItemLoaded;
        final updatedItems = [newItem, ...currentState.items];

        final successMessage = _getTranslatedSuccessMessage('force_add');
        emit(ListItemOperationSuccess(successMessage));
        emit(ListItemLoaded(updatedItems));
      } else {
        final successMessage = _getTranslatedSuccessMessage('force_add');
        emit(ListItemOperationSuccess(successMessage));
        add(LoadListItems(event.listId));
      }
    } catch (e) {
      print("Error force adding item: $e");
      final errorMessage = _getTranslatedOperationError('add');
      emit(ListItemError(errorMessage));
    }
  }

  /// ✅ NOUVELLE MÉTHODE: Fusionner avec un item existant
  Future<void> _onMergeWithExistingItem(
    MergeWithExistingItem event,
    Emitter<ListItemState> emit,
  ) async {
    try {
      final updatedItem = await _listItemService.mergeWithExistingItem(
        listId: event.listId,
        existingItemId: event.existingItemId,
        additionalQuantity: event.additionalQuantity,
        newPrice: event.newPrice,
      );

      print("Items fusionnés avec succès: ${updatedItem.toJson()}");

      if (state is ListItemLoaded) {
        final currentState = state as ListItemLoaded;
        final updatedItems =
            currentState.items.map((item) {
              if (item.id == event.existingItemId) {
                return updatedItem;
              }
              return item;
            }).toList();

        final successMessage = _getTranslatedSuccessMessage('merge');
        emit(ListItemOperationSuccess(successMessage));
        emit(ListItemLoaded(updatedItems));
      } else {
        final successMessage = _getTranslatedSuccessMessage('merge');
        emit(ListItemOperationSuccess(successMessage));
        add(LoadListItems(event.listId));
      }
    } catch (e) {
      print("Error merging items: $e");
      final errorMessage = _getTranslatedOperationError('add');
      emit(ListItemError(errorMessage));
    }
  }

  /// ✅ NOUVELLE MÉTHODE: Gérer les actions de doublon
  Future<void> _onHandleDuplicateAction(
    HandleDuplicateAction event,
    Emitter<ListItemState> emit,
  ) async {
    switch (event.action) {
      case DuplicateAction.forceAdd:
        add(
          ForceAddListItem(
            listId: event.listId,
            productName: event.productName,
            quantity: event.quantity,
            price: event.price,
            storeName: event.storeName,
          ),
        );
        break;
      case DuplicateAction.merge:
        if (event.existingItemId != null) {
          add(
            MergeWithExistingItem(
              listId: event.listId,
              existingItemId: event.existingItemId!,
              additionalQuantity: event.quantity,
              newPrice: event.price,
            ),
          );
        }
        break;
      case DuplicateAction.cancel:
        // Retourner à l'état précédent
        if (state is ListItemDuplicateDetected) {
          add(LoadListItems(event.listId));
        }
        break;
    }
  }

  /// ✅ NOUVELLE MÉTHODE: Marquer tous les articles
  Future<void> _onMarkAllItemsAs(
    MarkAllItemsAs event,
    Emitter<ListItemState> emit,
  ) async {
    try {
      final updatedCount = await _listItemService.markAllItemsAs(
        listId: event.listId,
        isPurchased: event.isPurchased,
      );

      print("$updatedCount articles mis à jour");

      final successMessage = _getTranslatedSuccessMessage('mark_all');
      emit(ListItemOperationSuccess(successMessage));
      add(LoadListItems(event.listId));
    } catch (e) {
      print("Error marking all items: $e");
      final errorMessage = _getTranslatedOperationError('mark_all');
      emit(ListItemError(errorMessage));
    }
  }

  /// ✅ NOUVELLE MÉTHODE: Supprimer tous les articles achetés
  Future<void> _onClearPurchasedItems(
    ClearPurchasedItems event,
    Emitter<ListItemState> emit,
  ) async {
    try {
      final deletedCount = await _listItemService.clearPurchasedItems(
        event.listId,
      );

      print("$deletedCount articles supprimés");

      final successMessage = _getTranslatedSuccessMessage('clear_purchased');
      emit(ListItemOperationSuccess(successMessage));
      add(LoadListItems(event.listId));
    } catch (e) {
      print("Error clearing purchased items: $e");
      final errorMessage = _getTranslatedOperationError('clear_purchased');
      emit(ListItemError(errorMessage));
    }
  }

  /// ✅ NOUVELLE MÉTHODE: Charger les statistiques
  Future<void> _onLoadListStats(
    LoadListStats event,
    Emitter<ListItemState> emit,
  ) async {
    try {
      final stats = await _listItemService.getListStats(event.listId);
      emit(ListItemStatsLoaded(stats));
    } catch (e) {
      print("Error loading stats: $e");
      final errorMessage = _getTranslatedOperationError('load');
      emit(ListItemError(errorMessage));
    }
  }

  // ✅ OPTIMISATION: Vérifier connectivité AVANT l'appel API
  Future<void> _onUpdateListItem(
    UpdateListItem event,
    Emitter<ListItemState> emit,
  ) async {
    // Mode hors ligne : mettre en queue et mise à jour locale
    if (!_connectivityService.isConnected) {
      await OfflineQueueService.enqueueAction(
        actionType: OfflineQueueService.ACTION_UPDATE_ITEM,
        payload: {
          'list_id': event.listId,
          'item_id': event.itemId,
          'product_name': event.productName,
          'quantity': event.quantity,
          'price': event.price,
          'store_name': event.storeName,
          'category_id': event.categoryId,
        },
      );

      // Mettre à jour localement l'item
      if (state is ListItemLoaded) {
        final currentState = state as ListItemLoaded;
        final updatedItems =
            currentState.items.map((item) {
              if (item.id == event.itemId) {
                return item.copyWith(
                  productName: event.productName,
                  quantity: event.quantity,
                  price: event.price,
                  storeName: event.storeName,
                  categoryId: event.categoryId,
                );
              }
              return item;
            }).toList();

        final successMessage = _getTranslatedSuccessMessage('update');
        emit(ListItemOperationSuccess(successMessage));
        emit(ListItemLoaded(updatedItems));
      }
      return;
    }

    // Mode en ligne : appel API normal
    try {
      final updatedItem = await _listItemService.updateListItem(
        listId: event.listId,
        itemId: event.itemId,
        productName: event.productName,
        quantity: event.quantity,
        price: event.price,
        storeName: event.storeName,
        categoryId: event.categoryId,
      );

      print("Item mis à jour avec succès: ${updatedItem.toJson()}");

      if (state is ListItemLoaded) {
        final currentState = state as ListItemLoaded;
        final updatedItems =
            currentState.items.map((item) {
              if (item.id == event.itemId) {
                return updatedItem;
              }
              return item;
            }).toList();

        final successMessage = _getTranslatedSuccessMessage('update');
        emit(ListItemOperationSuccess(successMessage));
        emit(ListItemLoaded(updatedItems));
      } else {
        final successMessage = _getTranslatedSuccessMessage('update');
        emit(ListItemOperationSuccess(successMessage));
        add(LoadListItems(event.listId));
      }
    } catch (e) {
      print("Error updating item: $e");
      final errorMessage = _getTranslatedOperationError('update');
      emit(ListItemError(errorMessage));
    }
  }

  Future<void> _onTogglePurchasedStatus(
    TogglePurchasedStatus event,
    Emitter<ListItemState> emit,
  ) async {
    // ✅ OPTIMISATION: Vérifier la connectivité AVANT l'appel API
    if (!_connectivityService.isConnected) {
      // Mode hors ligne : mettre en queue et toggle local
      await OfflineQueueService.enqueueAction(
        actionType: OfflineQueueService.ACTION_TOGGLE_ITEM,
        payload: {
          'list_id': event.listId,
          'item_id': event.itemId,
          'is_purchased': event.isPurchased,
        },
      );

      // Toggle localement le statut
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
      return;
    }

    // Mode en ligne : appel API normal
    try {
      await _listItemService.togglePurchasedStatus(
        listId: event.listId,
        itemId: event.itemId,
        isPurchased: event.isPurchased,
      );

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
      final errorMessage = _getTranslatedOperationError('toggle');
      emit(ListItemError(errorMessage));
    }
  }

  Future<void> _onDeleteListItem(
    DeleteListItem event,
    Emitter<ListItemState> emit,
  ) async {
    // ✅ OPTIMISATION: Vérifier la connectivité AVANT l'appel API
    if (!_connectivityService.isConnected) {
      // Mode hors ligne : mettre en queue et supprimer localement
      await OfflineQueueService.enqueueAction(
        actionType: OfflineQueueService.ACTION_DELETE_ITEM,
        payload: {
          'list_id': event.listId,
          'item_id': event.itemId,
        },
      );

      // Supprimer localement l'item
      if (state is ListItemLoaded) {
        final currentState = state as ListItemLoaded;
        final updatedItems =
            currentState.items
                .where((item) => item.id != event.itemId)
                .toList();

        final successMessage = _getTranslatedSuccessMessage('delete');
        emit(ListItemOperationSuccess(successMessage));
        emit(ListItemLoaded(updatedItems));
      }
      return;
    }

    // Mode en ligne : appel API normal
    try {
      await _listItemService.deleteListItem(
        listId: event.listId,
        itemId: event.itemId,
      );

      if (state is ListItemLoaded) {
        final currentState = state as ListItemLoaded;
        final updatedItems =
            currentState.items
                .where((item) => item.id != event.itemId)
                .toList();

        final successMessage = _getTranslatedSuccessMessage('delete');
        emit(ListItemOperationSuccess(successMessage));
        emit(ListItemLoaded(updatedItems));
      }
    } catch (e) {
      print("Error deleting item: $e");
      final errorMessage = _getTranslatedOperationError('delete');
      emit(ListItemError(errorMessage));
    }
  }
}
