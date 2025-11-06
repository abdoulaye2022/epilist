// blocs/category/category_event.dart
part of 'category_bloc.dart';

@immutable
abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

// Charger toutes les catégories
class LoadCategories extends CategoryEvent {
  const LoadCategories();
}

// Rafraîchir les catégories
class RefreshCategories extends CategoryEvent {
  const RefreshCategories();
}

// Créer une nouvelle catégorie
class CreateCategory extends CategoryEvent {
  final String name;
  final String iconCode;
  final String colorHex;
  final int orderIndex;

  const CreateCategory({
    required this.name,
    required this.iconCode,
    required this.colorHex,
    this.orderIndex = 0,
  });

  @override
  List<Object?> get props => [name, iconCode, colorHex, orderIndex];
}

// Mettre à jour une catégorie
class UpdateCategory extends CategoryEvent {
  final int categoryId;
  final String? name;
  final String? iconCode;
  final String? colorHex;
  final int? orderIndex;

  const UpdateCategory({
    required this.categoryId,
    this.name,
    this.iconCode,
    this.colorHex,
    this.orderIndex,
  });

  @override
  List<Object?> get props => [categoryId, name, iconCode, colorHex, orderIndex];
}

// Supprimer une catégorie
class DeleteCategory extends CategoryEvent {
  final int categoryId;

  const DeleteCategory(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

// Réorganiser les catégories
class ReorderCategories extends CategoryEvent {
  final List<int> categoryIds;

  const ReorderCategories(this.categoryIds);

  @override
  List<Object?> get props => [categoryIds];
}

// Initialiser les catégories par défaut
class InitializeDefaultCategories extends CategoryEvent {
  const InitializeDefaultCategories();
}

// Sélectionner une catégorie
class SelectCategory extends CategoryEvent {
  final int? categoryId;

  const SelectCategory(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}
