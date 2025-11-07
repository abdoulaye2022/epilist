// blocs/shopping_list/shopping_list_bloc.dart - VERSION CORRIGÉE
import 'package:bloc/bloc.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/services/shopping_list_service.dart';
import 'package:epilist/services/offline_storage_service.dart';
import 'package:epilist/services/offline_queue_service.dart';
import 'package:epilist/services/connectivity_service.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'shopping_list_event.dart';
part 'shopping_list_state.dart';

class ShoppingListBloc extends Bloc<ShoppingListEvent, ShoppingListState> {
  final ShoppingListService _shoppingListService;
  final LocalizationBloc _localizationBloc;
  final ConnectivityService _connectivityService = ConnectivityService();

  ShoppingListBloc({
    required ShoppingListService shoppingListService,
    required LocalizationBloc localizationBloc,
  }) : _shoppingListService = shoppingListService,
       _localizationBloc = localizationBloc,
       super(ShoppingListInitial()) {
    on<LoadShoppingLists>(_onLoadShoppingLists);
    on<CreateShoppingList>(_onCreateShoppingList);
    on<UpdateShoppingList>(_onUpdateShoppingList);
    on<DeleteShoppingList>(_onDeleteShoppingList);
    on<DuplicateShoppingList>(_onDuplicateShoppingList);
  }

  /// ✅ SOLUTION CORRIGÉE: Utiliser LocalizationBloc au lieu du context
  String _getTranslatedSuccessMessage(String operation) {
    // Fallbacks français par défaut
    const Map<String, String> frenchMessages = {
      'create': 'Liste créée avec succès',
      'update': 'Liste modifiée avec succès',
      'delete': 'Liste supprimée avec succès',
      'duplicate': 'Liste dupliquée avec succès',
      'load': 'Listes chargées avec succès',
    };

    const Map<String, String> englishMessages = {
      'create': 'List created successfully',
      'update': 'List updated successfully',
      'delete': 'List deleted successfully',
      'duplicate': 'List duplicated successfully',
      'load': 'Lists loaded successfully',
    };

    // Déterminer la langue depuis LocalizationBloc
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

  /// ✅ SOLUTION CORRIGÉE: Utiliser LocalizationBloc au lieu du context
  String _getTranslatedErrorMessage(dynamic error) {
    // Fallbacks français par défaut
    const Map<String, String> frenchErrors = {
      'network': 'Erreur de réseau',
      'permission': 'Permission insuffisante',
      'not_found': 'Liste non trouvée',
      'validation': 'Données invalides',
      'server': 'Erreur du serveur',
      'general': 'Une erreur est survenue',
    };

    const Map<String, String> englishErrors = {
      'network': 'Network error',
      'permission': 'Insufficient permission',
      'not_found': 'List not found',
      'validation': 'Invalid data',
      'server': 'Server error',
      'general': 'An error occurred',
    };

    // Déterminer la langue depuis LocalizationBloc
    final isEnglish =
        _localizationBloc.state is LocalizationLoaded &&
        (_localizationBloc.state as LocalizationLoaded).locale.languageCode ==
            'en';

    // Analyser le type d'erreur
    String errorString = error.toString().toLowerCase();
    String errorType = 'general';

    if (errorString.contains('network') ||
        errorString.contains('réseau') ||
        errorString.contains('connection') ||
        errorString.contains('connexion') ||
        errorString.contains('timeout') ||
        errorString.contains('délai')) {
      errorType = 'network';
    } else if (errorString.contains('permission') ||
        errorString.contains('autorisé') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden') ||
        errorString.contains('403')) {
      errorType = 'permission';
    } else if (errorString.contains('not found') ||
        errorString.contains('non trouvé') ||
        errorString.contains('404')) {
      errorType = 'not_found';
    } else if (errorString.contains('validation') ||
        errorString.contains('invalid') ||
        errorString.contains('invalide') ||
        errorString.contains('422')) {
      errorType = 'validation';
    } else if (errorString.contains('server') ||
        errorString.contains('serveur') ||
        errorString.contains('500') ||
        errorString.contains('503')) {
      errorType = 'server';
    }

    if (isEnglish) {
      return englishErrors[errorType]!;
    } else {
      return frenchErrors[errorType]!;
    }
  }

  Future<void> _onLoadShoppingLists(
    LoadShoppingLists event,
    Emitter<ShoppingListState> emit,
  ) async {
    emit(ShoppingListLoading());
    try {
      final lists = await _shoppingListService.getShoppingLists();

      // ✅ Sauvegarder dans le cache via OfflineStorageService
      await OfflineStorageService.saveShoppingLists(lists);

      emit(ShoppingListLoaded(lists));
    } catch (e) {
      print("Error loading shopping lists: $e");

      // ✅ Fallback: Charger depuis le cache si erreur réseau
      final cachedLists = await OfflineStorageService.getShoppingLists();

      if (cachedLists != null && cachedLists.isNotEmpty) {
        print("📦 Loading ${cachedLists.length} shopping lists from cache (offline mode)");
        emit(ShoppingListLoaded(cachedLists));
        return;
      }

      // ✅ Aucune donnée disponible
      final errorMessage = _getTranslatedErrorMessage(e);
      emit(ShoppingListError(errorMessage));
    }
  }

  Future<void> _onCreateShoppingList(
    CreateShoppingList event,
    Emitter<ShoppingListState> emit,
  ) async {
    // ✅ OPTIMISATION: Vérifier la connectivité AVANT l'appel API
    if (!_connectivityService.isConnected) {
      // Mode hors ligne : créer liste temporaire et mettre en queue
      await OfflineQueueService.enqueueAction(
        actionType: OfflineQueueService.ACTION_CREATE_LIST,
        payload: {'name': event.name},
      );

      // Créer une liste temporaire locale avec ID négatif
      final tempList = ShoppingList(
        id: -DateTime.now().millisecondsSinceEpoch,
        name: event.name,
        userId: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: [],
      );

      if (state is ShoppingListLoaded) {
        final currentState = state as ShoppingListLoaded;
        final updatedLists = [tempList, ...currentState.lists];
        await OfflineStorageService.saveShoppingLists(updatedLists);

        final successMessage = _getTranslatedSuccessMessage('create');
        emit(ShoppingListOperationSuccess(successMessage));
        emit(ShoppingListLoaded(updatedLists));
      }
      return;
    }

    // Mode en ligne : appel API normal
    try {
      final newList = await _shoppingListService.createShoppingList(event.name);

      // Sauvegarder dans le cache
      if (state is ShoppingListLoaded) {
        final currentState = state as ShoppingListLoaded;
        final updatedLists = [newList, ...currentState.lists];
        await OfflineStorageService.saveShoppingLists(updatedLists);

        final successMessage = _getTranslatedSuccessMessage('create');
        emit(ShoppingListOperationSuccess(successMessage));
        emit(ShoppingListLoaded(updatedLists));
      } else {
        final successMessage = _getTranslatedSuccessMessage('create');
        emit(ShoppingListOperationSuccess(successMessage));
        add(LoadShoppingLists());
      }
    } catch (e) {
      print("Error creating shopping list: $e");
      final errorMessage = _getTranslatedErrorMessage(e);
      emit(ShoppingListError(errorMessage));
    }
  }

  Future<void> _onUpdateShoppingList(
    UpdateShoppingList event,
    Emitter<ShoppingListState> emit,
  ) async {
    // ✅ OPTIMISATION: Vérifier la connectivité AVANT l'appel API
    if (!_connectivityService.isConnected) {
      // Mode hors ligne : mettre en queue et mise à jour locale
      if (state is ShoppingListLoaded) {
        await OfflineQueueService.enqueueAction(
          actionType: OfflineQueueService.ACTION_UPDATE_LIST,
          payload: {'id': event.id, 'name': event.name},
        );

        final currentState = state as ShoppingListLoaded;
        final updatedLists =
            currentState.lists.map((list) {
              if (list.id == event.id) {
                return ShoppingList(
                  id: list.id,
                  name: event.name,
                  userId: list.userId,
                  createdAt: list.createdAt,
                  updatedAt: DateTime.now(),
                  items: list.items,
                );
              }
              return list;
            }).toList();

        await OfflineStorageService.saveShoppingLists(updatedLists);

        final successMessage = _getTranslatedSuccessMessage('update');
        emit(ShoppingListOperationSuccess(successMessage));
        emit(ShoppingListLoaded(updatedLists));
      }
      return;
    }

    // Mode en ligne : appel API normal
    try {
      final updatedList = await _shoppingListService.updateShoppingList(
        event.id,
        event.name,
      );

      if (state is ShoppingListLoaded) {
        final currentState = state as ShoppingListLoaded;
        final updatedLists =
            currentState.lists.map((list) {
              if (list.id == event.id) {
                return updatedList;
              }
              return list;
            }).toList();

        await OfflineStorageService.saveShoppingLists(updatedLists);

        final successMessage = _getTranslatedSuccessMessage('update');
        emit(ShoppingListOperationSuccess(successMessage));
        emit(ShoppingListLoaded(updatedLists));
      }
    } catch (e) {
      print("Error updating shopping list: $e");
      final errorMessage = _getTranslatedErrorMessage(e);
      emit(ShoppingListError(errorMessage));
    }
  }

  Future<void> _onDeleteShoppingList(
    DeleteShoppingList event,
    Emitter<ShoppingListState> emit,
  ) async {
    // ✅ OPTIMISATION: Vérifier la connectivité AVANT l'appel API
    if (!_connectivityService.isConnected) {
      // Mode hors ligne : mettre en queue et supprimer localement
      if (state is ShoppingListLoaded) {
        await OfflineQueueService.enqueueAction(
          actionType: OfflineQueueService.ACTION_DELETE_LIST,
          payload: {'id': event.id},
        );

        final currentState = state as ShoppingListLoaded;
        final updatedLists =
            currentState.lists.where((list) => list.id != event.id).toList();

        await OfflineStorageService.saveShoppingLists(updatedLists);

        final successMessage = _getTranslatedSuccessMessage('delete');
        emit(ShoppingListOperationSuccess(successMessage));
        emit(ShoppingListLoaded(updatedLists));
      }
      return;
    }

    // Mode en ligne : appel API normal
    try {
      await _shoppingListService.deleteShoppingList(event.id);

      if (state is ShoppingListLoaded) {
        final currentState = state as ShoppingListLoaded;
        final updatedLists =
            currentState.lists.where((list) => list.id != event.id).toList();

        await OfflineStorageService.saveShoppingLists(updatedLists);

        final successMessage = _getTranslatedSuccessMessage('delete');
        emit(ShoppingListOperationSuccess(successMessage));
        emit(ShoppingListLoaded(updatedLists));
      }
    } catch (e) {
      print("Error deleting shopping list: $e");
      final errorMessage = _getTranslatedErrorMessage(e);
      emit(ShoppingListError(errorMessage));
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

      if (state is ShoppingListLoaded) {
        final currentState = state as ShoppingListLoaded;
        final updatedLists = [duplicatedList, ...currentState.lists];

        await OfflineStorageService.saveShoppingLists(updatedLists);

        final successMessage = _getTranslatedSuccessMessage('duplicate');
        emit(ShoppingListOperationSuccess(successMessage));
        emit(ShoppingListLoaded(updatedLists));
      }
    } catch (e) {
      print("Error duplicating shopping list: $e");

      // ✅ Si hors ligne, mettre en queue (note: duplication hors ligne complexe, on peut ignorer)
      final errorMessage = _getTranslatedErrorMessage(e);
      emit(ShoppingListError(errorMessage));
    }
  }
}
