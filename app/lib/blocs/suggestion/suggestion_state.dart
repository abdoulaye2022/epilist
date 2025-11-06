// blocs/suggestion/suggestion_state.dart
import 'package:equatable/equatable.dart';
import 'package:epilist/models/smart_suggestion.dart';

abstract class SuggestionState extends Equatable {
  const SuggestionState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SuggestionInitial extends SuggestionState {}

/// Loading suggestions
class SuggestionLoading extends SuggestionState {}

/// Suggestions loaded successfully
class SuggestionLoaded extends SuggestionState {
  final List<SmartSuggestion> suggestions;
  final List<SmartSuggestion> highConfidence;
  final List<SmartSuggestion> mediumConfidence;
  final List<SmartSuggestion> lowConfidence;

  const SuggestionLoaded({
    required this.suggestions,
    required this.highConfidence,
    required this.mediumConfidence,
    required this.lowConfidence,
  });

  @override
  List<Object?> get props => [suggestions, highConfidence, mediumConfidence, lowConfidence];

  /// Group suggestions by confidence level
  factory SuggestionLoaded.fromSuggestions(List<SmartSuggestion> suggestions) {
    final high = suggestions.where((s) => s.confidenceLevel == ConfidenceLevel.high).toList();
    final medium = suggestions.where((s) => s.confidenceLevel == ConfidenceLevel.medium).toList();
    final low = suggestions.where((s) => s.confidenceLevel == ConfidenceLevel.low).toList();

    return SuggestionLoaded(
      suggestions: suggestions,
      highConfidence: high,
      mediumConfidence: medium,
      lowConfidence: low,
    );
  }

  SuggestionLoaded copyWith({
    List<SmartSuggestion>? suggestions,
  }) {
    return SuggestionLoaded.fromSuggestions(suggestions ?? this.suggestions);
  }
}

/// Suggestion accepted (added to list)
class SuggestionAccepted extends SuggestionState {
  final String productName;

  const SuggestionAccepted(this.productName);

  @override
  List<Object?> get props => [productName];
}

/// Suggestion rejected
class SuggestionRejected extends SuggestionState {
  final String productName;

  const SuggestionRejected(this.productName);

  @override
  List<Object?> get props => [productName];
}

/// Patterns recalculating
class PatternsRecalculating extends SuggestionState {}

/// Patterns recalculated
class PatternsRecalculated extends SuggestionState {}

/// Statistics loaded
class StatisticsLoaded extends SuggestionState {
  final SuggestionStatistics statistics;

  const StatisticsLoaded(this.statistics);

  @override
  List<Object?> get props => [statistics];
}

/// Trending loaded
class TrendingLoaded extends SuggestionState {
  final List<SmartSuggestion> trending;

  const TrendingLoaded(this.trending);

  @override
  List<Object?> get props => [trending];
}

/// Error state
class SuggestionError extends SuggestionState {
  final String message;

  const SuggestionError(this.message);

  @override
  List<Object?> get props => [message];
}
