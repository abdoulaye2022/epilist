// blocs/suggestion/suggestion_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/services/suggestion_service.dart';
import 'suggestion_event.dart';
import 'suggestion_state.dart';

class SuggestionBloc extends Bloc<SuggestionEvent, SuggestionState> {
  final SuggestionService suggestionService;

  SuggestionBloc({required this.suggestionService}) : super(SuggestionInitial()) {
    on<LoadSuggestions>(_onLoadSuggestions);
    on<AcceptSuggestion>(_onAcceptSuggestion);
    on<RejectSuggestion>(_onRejectSuggestion);
    on<ModifySuggestion>(_onModifySuggestion);
    on<RecalculatePatterns>(_onRecalculatePatterns);
    on<LoadStatistics>(_onLoadStatistics);
    on<LoadTrending>(_onLoadTrending);
  }

  /// Load suggestions
  Future<void> _onLoadSuggestions(
    LoadSuggestions event,
    Emitter<SuggestionState> emit,
  ) async {
    try {
      emit(SuggestionLoading());

      final suggestions = await suggestionService.getSuggestions(
        includeAssociations: event.includeAssociations,
        currentListItems: event.currentListItems,
      );

      emit(SuggestionLoaded.fromSuggestions(suggestions));
    } catch (e) {
      emit(SuggestionError(e.toString()));
    }
  }

  /// Accept a suggestion
  Future<void> _onAcceptSuggestion(
    AcceptSuggestion event,
    Emitter<SuggestionState> emit,
  ) async {
    try {
      // Record feedback
      await suggestionService.recordFeedback(
        productName: event.productName,
        action: 'accepted',
        suggestedQuantity: event.suggestedQuantity,
        actualQuantity: event.suggestedQuantity,
      );

      emit(SuggestionAccepted(event.productName));

      // Reload suggestions to remove accepted one
      if (state is SuggestionLoaded) {
        final currentState = state as SuggestionLoaded;
        final updated = currentState.suggestions
            .where((s) => s.productName != event.productName)
            .toList();

        emit(SuggestionLoaded.fromSuggestions(updated));
      }
    } catch (e) {
      emit(SuggestionError(e.toString()));
    }
  }

  /// Reject a suggestion
  Future<void> _onRejectSuggestion(
    RejectSuggestion event,
    Emitter<SuggestionState> emit,
  ) async {
    try {
      // Record feedback
      await suggestionService.recordFeedback(
        productName: event.productName,
        action: 'rejected',
      );

      emit(SuggestionRejected(event.productName));

      // Remove from list
      if (state is SuggestionLoaded) {
        final currentState = state as SuggestionLoaded;
        final updated = currentState.suggestions
            .where((s) => s.productName != event.productName)
            .toList();

        emit(SuggestionLoaded.fromSuggestions(updated));
      }
    } catch (e) {
      // Silently fail for feedback
      print('Failed to record rejection: $e');
    }
  }

  /// Modify a suggestion
  Future<void> _onModifySuggestion(
    ModifySuggestion event,
    Emitter<SuggestionState> emit,
  ) async {
    try {
      // Record feedback
      await suggestionService.recordFeedback(
        productName: event.productName,
        action: 'modified',
        suggestedQuantity: event.suggestedQuantity,
        actualQuantity: event.actualQuantity,
      );
    } catch (e) {
      // Silently fail for feedback
      print('Failed to record modification: $e');
    }
  }

  /// Recalculate patterns
  Future<void> _onRecalculatePatterns(
    RecalculatePatterns event,
    Emitter<SuggestionState> emit,
  ) async {
    try {
      emit(PatternsRecalculating());

      await suggestionService.recalculatePatterns();

      emit(PatternsRecalculated());
    } catch (e) {
      emit(SuggestionError(e.toString()));
    }
  }

  /// Load statistics
  Future<void> _onLoadStatistics(
    LoadStatistics event,
    Emitter<SuggestionState> emit,
  ) async {
    try {
      final stats = await suggestionService.getStatistics();
      emit(StatisticsLoaded(stats));
    } catch (e) {
      emit(SuggestionError(e.toString()));
    }
  }

  /// Load trending products
  Future<void> _onLoadTrending(
    LoadTrending event,
    Emitter<SuggestionState> emit,
  ) async {
    try {
      final trending = await suggestionService.getTrendingProducts();
      emit(TrendingLoaded(trending));
    } catch (e) {
      emit(SuggestionError(e.toString()));
    }
  }
}
