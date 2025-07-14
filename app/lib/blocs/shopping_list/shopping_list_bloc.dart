// blocs/shopping_list/shopping_list_bloc.dart - VERSION CORRIGÉE
import 'package:bloc/bloc.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/services/shopping_list_service.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart'; // NOUVEAU
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'shopping_list_event.dart';
part 'shopping_list_state.dart';

class ShoppingListBloc extends Bloc<ShoppingListEvent, ShoppingListState> {
  final ShoppingListService _shoppingListService;
  final LocalizationBloc
  _localizationBloc; // ✅ NOUVEAU: Injection du LocalizationBloc

  ShoppingListBloc({
    required ShoppingListService shoppingListService,
    required LocalizationBloc localizationBloc, // ✅ NOUVEAU
  }) : _shoppingListService = shoppingListService,
       _localizationBloc = localizationBloc, // ✅ NOUVEAU
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
      emit(ShoppingListLoaded(lists));
    } catch (e) {
      print("Error loading shopping lists: $e");

      // ✅ UTILISER la nouvelle méthode sans context
      final errorMessage = _getTranslatedErrorMessage(e);
      emit(ShoppingListError(errorMessage));
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

        // ✅ UTILISER la nouvelle méthode sans context
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

      // ✅ UTILISER la nouvelle méthode sans context
      final errorMessage = _getTranslatedErrorMessage(e);
      emit(ShoppingListError(errorMessage));
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

      if (state is ShoppingListLoaded) {
        final currentState = state as ShoppingListLoaded;
        final updatedLists =
            currentState.lists.map((list) {
              if (list.id == event.id) {
                return updatedList;
              }
              return list;
            }).toList();

        // ✅ UTILISER la nouvelle méthode sans context
        final successMessage = _getTranslatedSuccessMessage('update');
        emit(ShoppingListOperationSuccess(successMessage));
        emit(ShoppingListLoaded(updatedLists));
      }
    } catch (e) {
      print("Error updating shopping list: $e");

      // ✅ UTILISER la nouvelle méthode sans context
      final errorMessage = _getTranslatedErrorMessage(e);
      emit(ShoppingListError(errorMessage));
    }
  }

  Future<void> _onDeleteShoppingList(
    DeleteShoppingList event,
    Emitter<ShoppingListState> emit,
  ) async {
    try {
      await _shoppingListService.deleteShoppingList(event.id);

      if (state is ShoppingListLoaded) {
        final currentState = state as ShoppingListLoaded;
        final updatedLists =
            currentState.lists.where((list) => list.id != event.id).toList();

        // ✅ UTILISER la nouvelle méthode sans context
        final successMessage = _getTranslatedSuccessMessage('delete');
        emit(ShoppingListOperationSuccess(successMessage));
        emit(ShoppingListLoaded(updatedLists));
      }
    } catch (e) {
      print("Error deleting shopping list: $e");

      // ✅ UTILISER la nouvelle méthode sans context
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

        // ✅ UTILISER la nouvelle méthode sans context
        final successMessage = _getTranslatedSuccessMessage('duplicate');
        emit(ShoppingListOperationSuccess(successMessage));
        emit(ShoppingListLoaded(updatedLists));
      }
    } catch (e) {
      print("Error duplicating shopping list: $e");

      // ✅ UTILISER la nouvelle méthode sans context
      final errorMessage = _getTranslatedErrorMessage(e);
      emit(ShoppingListError(errorMessage));
    }
  }
}
