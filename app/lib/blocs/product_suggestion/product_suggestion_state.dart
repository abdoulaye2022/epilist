// blocs/product_suggestion/product_suggestion_state.dart
part of 'product_suggestion_bloc.dart';

abstract class ProductSuggestionState extends Equatable {
  const ProductSuggestionState();

  @override
  List<Object> get props => [];
}

class ProductSuggestionInitial extends ProductSuggestionState {}

class ProductSuggestionLoading extends ProductSuggestionState {}

class ProductSuggestionLoaded extends ProductSuggestionState {
  final List<ProductSuggestion> suggestions;
  final String query;

  const ProductSuggestionLoaded(this.suggestions, this.query);

  @override
  List<Object> get props => [suggestions, query];
}

class ProductSuggestionPopularLoaded extends ProductSuggestionState {
  final List<ProductSuggestion> suggestions;

  const ProductSuggestionPopularLoaded(this.suggestions);

  @override
  List<Object> get props => [suggestions];
}

class ProductSuggestionEmpty extends ProductSuggestionState {
  final String query;

  const ProductSuggestionEmpty(this.query);

  @override
  List<Object> get props => [query];
}

class ProductSuggestionError extends ProductSuggestionState {
  final String message;

  const ProductSuggestionError(this.message);

  @override
  List<Object> get props => [message];
}
