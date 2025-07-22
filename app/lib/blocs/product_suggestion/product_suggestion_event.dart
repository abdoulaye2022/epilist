// blocs/product_suggestion/product_suggestion_event.dart
part of 'product_suggestion_bloc.dart';

abstract class ProductSuggestionEvent extends Equatable {
  const ProductSuggestionEvent();

  @override
  List<Object> get props => [];
}

class SearchProductSuggestions extends ProductSuggestionEvent {
  final String query;
  final int limit;

  const SearchProductSuggestions(this.query, {this.limit = 10});

  @override
  List<Object> get props => [query, limit];
}

class LoadPopularSuggestions extends ProductSuggestionEvent {
  final int limit;

  const LoadPopularSuggestions({this.limit = 20});

  @override
  List<Object> get props => [limit];
}

class ClearSuggestions extends ProductSuggestionEvent {
  const ClearSuggestions();
}

class DeleteSuggestion extends ProductSuggestionEvent {
  final int suggestionId;

  const DeleteSuggestion(this.suggestionId);

  @override
  List<Object> get props => [suggestionId];
}

class ResetSuggestions extends ProductSuggestionEvent {
  const ResetSuggestions();
}
