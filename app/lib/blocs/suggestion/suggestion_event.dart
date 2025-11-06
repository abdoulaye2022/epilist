// blocs/suggestion/suggestion_event.dart
import 'package:equatable/equatable.dart';

abstract class SuggestionEvent extends Equatable {
  const SuggestionEvent();

  @override
  List<Object?> get props => [];
}

/// Load suggestions
class LoadSuggestions extends SuggestionEvent {
  final bool includeAssociations;
  final List<String> currentListItems;

  const LoadSuggestions({
    this.includeAssociations = true,
    this.currentListItems = const [],
  });

  @override
  List<Object?> get props => [includeAssociations, currentListItems];
}

/// Accept a suggestion (add to list)
class AcceptSuggestion extends SuggestionEvent {
  final String productName;
  final int suggestedQuantity;

  const AcceptSuggestion(this.productName, this.suggestedQuantity);

  @override
  List<Object?> get props => [productName, suggestedQuantity];
}

/// Reject a suggestion
class RejectSuggestion extends SuggestionEvent {
  final String productName;

  const RejectSuggestion(this.productName);

  @override
  List<Object?> get props => [productName];
}

/// Modify a suggestion (user changed quantity)
class ModifySuggestion extends SuggestionEvent {
  final String productName;
  final int suggestedQuantity;
  final int actualQuantity;

  const ModifySuggestion(
    this.productName,
    this.suggestedQuantity,
    this.actualQuantity,
  );

  @override
  List<Object?> get props => [productName, suggestedQuantity, actualQuantity];
}

/// Recalculate patterns
class RecalculatePatterns extends SuggestionEvent {
  const RecalculatePatterns();
}

/// Load statistics
class LoadStatistics extends SuggestionEvent {
  const LoadStatistics();
}

/// Load trending products
class LoadTrending extends SuggestionEvent {
  const LoadTrending();
}
