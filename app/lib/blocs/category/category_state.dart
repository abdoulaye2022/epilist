// blocs/category/category_state.dart
part of 'category_bloc.dart';

@immutable
abstract class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => [];
}

// État initial
class CategoryInitial extends CategoryState {
  const CategoryInitial();
}

// Chargement en cours
class CategoryLoading extends CategoryState {
  const CategoryLoading();
}

// Catégories chargées avec succès
class CategoryLoaded extends CategoryState {
  final List<Category> categories;
  final int? selectedCategoryId;

  const CategoryLoaded({
    required this.categories,
    this.selectedCategoryId,
  });

  @override
  List<Object?> get props => [categories, selectedCategoryId];

  CategoryLoaded copyWith({
    List<Category>? categories,
    int? selectedCategoryId,
  }) {
    return CategoryLoaded(
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
    );
  }
}

// Opération en cours (création, mise à jour, suppression)
class CategoryOperationInProgress extends CategoryState {
  final List<Category> categories;
  final String operation;

  const CategoryOperationInProgress({
    required this.categories,
    required this.operation,
  });

  @override
  List<Object?> get props => [categories, operation];
}

// Opération réussie
class CategoryOperationSuccess extends CategoryState {
  final List<Category> categories;
  final String message;

  const CategoryOperationSuccess({
    required this.categories,
    required this.message,
  });

  @override
  List<Object?> get props => [categories, message];
}

// Erreur
class CategoryError extends CategoryState {
  final String message;
  final List<Category>? categories;

  const CategoryError({
    required this.message,
    this.categories,
  });

  @override
  List<Object?> get props => [message, categories];
}
