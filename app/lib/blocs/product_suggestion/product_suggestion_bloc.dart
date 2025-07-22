// blocs/product_suggestion/product_suggestion_bloc.dart - VERSION CORRIGÉE
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:epilist/models/product_suggestion.dart';
import 'package:epilist/services/product_suggestion_service.dart';
import 'package:equatable/equatable.dart';

part 'product_suggestion_event.dart';
part 'product_suggestion_state.dart';

class ProductSuggestionBloc
    extends Bloc<ProductSuggestionEvent, ProductSuggestionState> {
  final ProductSuggestionService _suggestionService;
  Timer? _searchTimer;

  ProductSuggestionBloc({required ProductSuggestionService suggestionService})
    : _suggestionService = suggestionService,
      super(ProductSuggestionInitial()) {
    on<SearchProductSuggestions>(_onSearchProductSuggestions);
    on<LoadPopularSuggestions>(_onLoadPopularSuggestions);
    on<ClearSuggestions>(_onClearSuggestions);
    on<DeleteSuggestion>(_onDeleteSuggestion);
    on<ResetSuggestions>(_onResetSuggestions);
  }

  @override
  Future<void> close() {
    _searchTimer?.cancel();
    return super.close();
  }

  /// ✅ CORRECTION: Recherche avec debounce mais sans Timer dans le gestionnaire
  Future<void> _onSearchProductSuggestions(
    SearchProductSuggestions event,
    Emitter<ProductSuggestionState> emit,
  ) async {
    // Annuler la recherche précédente
    _searchTimer?.cancel();

    if (event.query.trim().isEmpty) {
      emit(ProductSuggestionInitial());
      return;
    }

    // Si la requête est trop courte, ne pas chercher
    if (event.query.trim().length < 2) {
      emit(ProductSuggestionInitial());
      return;
    }

    // ✅ CORRECTION: Utiliser un Completer pour gérer le debounce
    final completer = Completer<void>();

    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    // Attendre le délai de debounce
    await completer.future;

    // Vérifier si le bloc n'est pas fermé et si l'emitter est encore valide
    if (isClosed || emit.isDone) {
      return;
    }

    emit(ProductSuggestionLoading());

    try {
      final suggestions = await _suggestionService.searchSuggestions(
        query: event.query.trim(),
        limit: event.limit,
      );

      // ✅ CORRECTION: Vérifier encore une fois avant d'émettre
      if (!isClosed && !emit.isDone) {
        if (suggestions.isEmpty) {
          emit(ProductSuggestionEmpty(event.query.trim()));
        } else {
          emit(ProductSuggestionLoaded(suggestions, event.query.trim()));
        }
      }
    } catch (e) {
      if (!isClosed && !emit.isDone) {
        emit(ProductSuggestionError('Erreur lors de la recherche: $e'));
      }
    }
  }

  /// Charge les suggestions populaires
  Future<void> _onLoadPopularSuggestions(
    LoadPopularSuggestions event,
    Emitter<ProductSuggestionState> emit,
  ) async {
    emit(ProductSuggestionLoading());
    try {
      final suggestions = await _suggestionService.getPopularSuggestions(
        limit: event.limit,
      );

      if (suggestions.isEmpty) {
        emit(ProductSuggestionEmpty(''));
      } else {
        emit(ProductSuggestionPopularLoaded(suggestions));
      }
    } catch (e) {
      emit(ProductSuggestionError('Erreur lors du chargement: $e'));
    }
  }

  /// Supprime toutes les suggestions
  Future<void> _onClearSuggestions(
    ClearSuggestions event,
    Emitter<ProductSuggestionState> emit,
  ) async {
    try {
      final success = await _suggestionService.clearAllSuggestions();
      if (success) {
        emit(ProductSuggestionInitial());
      } else {
        emit(ProductSuggestionError('Erreur lors de la suppression'));
      }
    } catch (e) {
      emit(ProductSuggestionError('Erreur lors de la suppression: $e'));
    }
  }

  /// Supprime une suggestion spécifique
  Future<void> _onDeleteSuggestion(
    DeleteSuggestion event,
    Emitter<ProductSuggestionState> emit,
  ) async {
    try {
      final success = await _suggestionService.deleteSuggestion(
        event.suggestionId,
      );
      if (success) {
        // Recharger les suggestions si on était dans un état chargé
        if (state is ProductSuggestionLoaded) {
          final currentState = state as ProductSuggestionLoaded;
          add(SearchProductSuggestions(currentState.query));
        } else if (state is ProductSuggestionPopularLoaded) {
          add(LoadPopularSuggestions());
        }
      } else {
        emit(ProductSuggestionError('Erreur lors de la suppression'));
      }
    } catch (e) {
      emit(ProductSuggestionError('Erreur lors de la suppression: $e'));
    }
  }

  /// Remet à zéro l'état des suggestions
  void _onResetSuggestions(
    ResetSuggestions event,
    Emitter<ProductSuggestionState> emit,
  ) {
    _searchTimer?.cancel();
    emit(ProductSuggestionInitial());
  }
}
