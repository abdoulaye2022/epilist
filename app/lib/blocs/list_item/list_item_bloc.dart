// blocs/list_item/list_item_bloc.dart - VERSION CORRIGÉE
import 'package:bloc/bloc.dart';
import 'package:epilist/models/list_item.dart';
import 'package:epilist/services/list_item_service.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart'; // NOUVEAU
import 'package:equatable/equatable.dart';

part 'list_item_event.dart';
part 'list_item_state.dart';

class ListItemBloc extends Bloc<ListItemEvent, ListItemState> {
  final ListItemService _listItemService;
  final LocalizationBloc
  _localizationBloc; // ✅ NOUVEAU: Injection du LocalizationBloc

  ListItemBloc({
    required ListItemService listItemService,
    required LocalizationBloc localizationBloc, // ✅ NOUVEAU
  }) : _listItemService = listItemService,
       _localizationBloc = localizationBloc, // ✅ NOUVEAU
       super(ListItemInitial()) {
    on<LoadListItems>(_onLoadListItems);
    on<AddListItem>(_onAddListItem);
    on<UpdateListItem>(_onUpdateListItem);
    on<TogglePurchasedStatus>(_onTogglePurchasedStatus);
    on<DeleteListItem>(_onDeleteListItem);
  }

  /// ✅ SOLUTION CORRIGÉE: Utiliser LocalizationBloc au lieu du context
  String _getTranslatedSuccessMessage(String operation) {
    // Fallbacks français par défaut
    const Map<String, String> frenchMessages = {
      'add': 'Article ajouté avec succès',
      'update': 'Article mis à jour avec succès',
      'delete': 'Article supprimé avec succès',
      'toggle': 'Statut mis à jour avec succès',
      'load': 'Articles chargés avec succès',
    };

    const Map<String, String> englishMessages = {
      'add': 'Item added successfully',
      'update': 'Item updated successfully',
      'delete': 'Item deleted successfully',
      'toggle': 'Status updated successfully',
      'load': 'Items loaded successfully',
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
      'not_found': 'Article non trouvé',
      'validation': 'Données invalides',
      'server': 'Erreur du serveur',
      'general': 'Une erreur est survenue',
      'load': 'Erreur lors du chargement des articles',
      'add': 'Erreur lors de l\'ajout de l\'article',
      'update': 'Erreur lors de la mise à jour de l\'article',
      'delete': 'Erreur lors de la suppression de l\'article',
      'toggle': 'Erreur lors de la mise à jour du statut',
    };

    const Map<String, String> englishErrors = {
      'network': 'Network error',
      'permission': 'Insufficient permission',
      'not_found': 'Item not found',
      'validation': 'Invalid data',
      'server': 'Server error',
      'general': 'An error occurred',
      'load': 'Error loading items',
      'add': 'Error adding item',
      'update': 'Error updating item',
      'delete': 'Error deleting item',
      'toggle': 'Error updating status',
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

  /// ✅ NOUVEAU: Méthode spécialisée pour les erreurs d'opération
  String _getTranslatedOperationError(String operation) {
    const Map<String, String> frenchErrors = {
      'load': 'Erreur lors du chargement des articles',
      'add': 'Erreur lors de l\'ajout de l\'article',
      'update': 'Erreur lors de la mise à jour de l\'article',
      'delete': 'Erreur lors de la suppression de l\'article',
      'toggle': 'Erreur lors de la mise à jour du statut',
    };

    const Map<String, String> englishErrors = {
      'load': 'Error loading items',
      'add': 'Error adding item',
      'update': 'Error updating item',
      'delete': 'Error deleting item',
      'toggle': 'Error updating status',
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

      // ✅ UTILISER la nouvelle méthode de traduction
      final errorMessage = _getTranslatedOperationError('load');
      emit(ListItemError(errorMessage));
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

      // Ajouter l'item à la liste existante au lieu de recharger
      if (state is ListItemLoaded) {
        final currentState = state as ListItemLoaded;
        final updatedItems = [newItem, ...currentState.items];

        // ✅ UTILISER la nouvelle méthode de traduction
        final successMessage = _getTranslatedSuccessMessage('add');
        emit(ListItemOperationSuccess(successMessage));
        emit(ListItemLoaded(updatedItems));
      } else {
        final successMessage = _getTranslatedSuccessMessage('add');
        emit(ListItemOperationSuccess(successMessage));
        add(LoadListItems(event.listId));
      }
    } catch (e) {
      print("Error adding item: $e");

      // ✅ UTILISER la nouvelle méthode de traduction
      final errorMessage = _getTranslatedOperationError('add');
      emit(ListItemError(errorMessage));
    }
  }

  Future<void> _onUpdateListItem(
    UpdateListItem event,
    Emitter<ListItemState> emit,
  ) async {
    try {
      // Mettre à jour l'item via l'API
      final updatedItem = await _listItemService.updateListItem(
        listId: event.listId,
        itemId: event.itemId,
        productName: event.productName,
        quantity: event.quantity,
        price: event.price,
        storeName: event.storeName,
      );

      print("Item mis à jour avec succès: ${updatedItem.toJson()}");

      // Mettre à jour l'item dans la liste existante
      if (state is ListItemLoaded) {
        final currentState = state as ListItemLoaded;
        final updatedItems =
            currentState.items.map((item) {
              if (item.id == event.itemId) {
                return updatedItem;
              }
              return item;
            }).toList();

        // ✅ UTILISER la nouvelle méthode de traduction
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

      // ✅ UTILISER la nouvelle méthode de traduction
      final errorMessage = _getTranslatedOperationError('update');
      emit(ListItemError(errorMessage));
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

      // ✅ UTILISER la nouvelle méthode de traduction
      final errorMessage = _getTranslatedOperationError('toggle');
      emit(ListItemError(errorMessage));
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

        // ✅ UTILISER la nouvelle méthode de traduction
        final successMessage = _getTranslatedSuccessMessage('delete');
        emit(ListItemOperationSuccess(successMessage));
        emit(ListItemLoaded(updatedItems));
      }
    } catch (e) {
      print("Error deleting item: $e");

      // ✅ UTILISER la nouvelle méthode de traduction
      final errorMessage = _getTranslatedOperationError('delete');
      emit(ListItemError(errorMessage));
    }
  }
}
