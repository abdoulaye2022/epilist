// blocs/category/category_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' hide Category;
import '../../models/category.dart';
import '../../services/category_service.dart';
import '../../services/offline_storage_service.dart';
import '../../services/offline_queue_service.dart';
import '../../services/connectivity_service.dart';
import '../localization/localization_bloc.dart';

part 'category_event.dart';
part 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryService _categoryService;
  final LocalizationBloc _localizationBloc;
  final ConnectivityService _connectivityService = ConnectivityService();

  CategoryBloc({
    required CategoryService categoryService,
    required LocalizationBloc localizationBloc,
  })  : _categoryService = categoryService,
        _localizationBloc = localizationBloc,
        super(const CategoryInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<RefreshCategories>(_onRefreshCategories);
    on<CreateCategory>(_onCreateCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);
    on<ReorderCategories>(_onReorderCategories);
    on<InitializeDefaultCategories>(_onInitializeDefaultCategories);
    on<SelectCategory>(_onSelectCategory);
  }

  /// Messages traduits selon la langue
  String _getTranslatedSuccessMessage(String operation) {
    const Map<String, String> frenchMessages = {
      'create': 'Catégorie créée avec succès',
      'update': 'Catégorie mise à jour avec succès',
      'delete': 'Catégorie supprimée avec succès',
      'reorder': 'Catégories réorganisées avec succès',
      'initialize': 'Catégories par défaut initialisées',
      'load': 'Catégories chargées avec succès',
    };

    const Map<String, String> englishMessages = {
      'create': 'Category created successfully',
      'update': 'Category updated successfully',
      'delete': 'Category deleted successfully',
      'reorder': 'Categories reordered successfully',
      'initialize': 'Default categories initialized',
      'load': 'Categories loaded successfully',
    };

    final isEnglish = _localizationBloc.state is LocalizationLoaded &&
        (_localizationBloc.state as LocalizationLoaded).locale.languageCode ==
            'en';

    if (isEnglish) {
      return englishMessages[operation] ?? 'Operation successful';
    } else {
      return frenchMessages[operation] ?? 'Opération réussie';
    }
  }

  String _getTranslatedErrorMessage(dynamic error) {
    const Map<String, String> frenchErrors = {
      'network': 'Erreur de réseau',
      'permission': 'Permission insuffisante',
      'not_found': 'Catégorie non trouvée',
      'validation': 'Données invalides',
      'server': 'Erreur du serveur',
      'general': 'Une erreur est survenue',
    };

    const Map<String, String> englishErrors = {
      'network': 'Network error',
      'permission': 'Insufficient permission',
      'not_found': 'Category not found',
      'validation': 'Invalid data',
      'server': 'Server error',
      'general': 'An error occurred',
    };

    final isEnglish = _localizationBloc.state is LocalizationLoaded &&
        (_localizationBloc.state as LocalizationLoaded).locale.languageCode ==
            'en';

    String errorString = error.toString().toLowerCase();
    String errorType = 'general';

    if (errorString.contains('network') ||
        errorString.contains('réseau') ||
        errorString.contains('connection')) {
      errorType = 'network';
    } else if (errorString.contains('permission') ||
        errorString.contains('autorisé') ||
        errorString.contains('forbidden')) {
      errorType = 'permission';
    } else if (errorString.contains('not found') ||
        errorString.contains('non trouvée') ||
        errorString.contains('introuvable')) {
      errorType = 'not_found';
    } else if (errorString.contains('invalid') ||
        errorString.contains('invalide') ||
        errorString.contains('validation')) {
      errorType = 'validation';
    } else if (errorString.contains('server') ||
        errorString.contains('serveur') ||
        errorString.contains('500')) {
      errorType = 'server';
    }

    if (isEnglish) {
      return englishErrors[errorType] ?? englishErrors['general']!;
    } else {
      return frenchErrors[errorType] ?? frenchErrors['general']!;
    }
  }

  // Charger toutes les catégories
  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      emit(const CategoryLoading());
      final categories = await _categoryService.getCategories();

      // ✅ Sauvegarder dans le cache
      final categoriesJson = categories.map((c) => c.toJson()).toList();
      await OfflineStorageService.saveCategories(categoriesJson);

      emit(CategoryLoaded(categories: categories));
    } catch (e) {
      debugPrint('Error loading categories: $e');

      // ✅ Fallback: Charger depuis le cache (mode offline)
      try {
        final cachedCategories = await OfflineStorageService.getCategories();
        if (cachedCategories != null && cachedCategories.isNotEmpty) {
          debugPrint('📦 Loading ${cachedCategories.length} categories from cache (offline mode)');
          final categories = cachedCategories.map((json) => Category.fromJson(json)).toList();
          emit(CategoryLoaded(categories: categories));
          return;
        }
      } catch (cacheError) {
        debugPrint('❌ Categories cache load failed: $cacheError');
      }

      emit(CategoryError(message: _getTranslatedErrorMessage(e)));
    }
  }

  // Rafraîchir les catégories
  Future<void> _onRefreshCategories(
    RefreshCategories event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      final categories = await _categoryService.getCategories();

      // ✅ Sauvegarder dans le cache
      final categoriesJson = categories.map((c) => c.toJson()).toList();
      await OfflineStorageService.saveCategories(categoriesJson);

      emit(CategoryLoaded(categories: categories));
    } catch (e) {
      debugPrint('Error refreshing categories: $e');

      // ✅ Fallback: Charger depuis le cache (mode offline)
      try {
        final cachedCategories = await OfflineStorageService.getCategories();
        if (cachedCategories != null && cachedCategories.isNotEmpty) {
          debugPrint('📦 Loading ${cachedCategories.length} categories from cache (offline mode)');
          final categories = cachedCategories.map((json) => Category.fromJson(json)).toList();
          emit(CategoryLoaded(categories: categories));
          return;
        }
      } catch (cacheError) {
        debugPrint('❌ Categories cache load failed: $cacheError');
      }

      final currentState = state;
      if (currentState is CategoryLoaded) {
        emit(CategoryError(
          message: _getTranslatedErrorMessage(e),
          categories: currentState.categories,
        ));
      } else {
        emit(CategoryError(message: _getTranslatedErrorMessage(e)));
      }
    }
  }

  // Créer une nouvelle catégorie
  Future<void> _onCreateCategory(
    CreateCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      final currentState = state;
      List<Category> currentCategories = [];
      if (currentState is CategoryLoaded) {
        currentCategories = currentState.categories;
      }

      emit(CategoryOperationInProgress(
        categories: currentCategories,
        operation: 'create',
      ));

      await _categoryService.createCategory(
        name: event.name,
        iconCode: event.iconCode,
        colorHex: event.colorHex,
        orderIndex: event.orderIndex,
      );

      final categories = await _categoryService.getCategories();

      // ✅ Sauvegarder dans le cache
      final categoriesJson = categories.map((c) => c.toJson()).toList();
      await OfflineStorageService.saveCategories(categoriesJson);

      emit(CategoryOperationSuccess(
        categories: categories,
        message: _getTranslatedSuccessMessage('create'),
      ));

      // Retourner à l'état chargé
      await Future.delayed(const Duration(milliseconds: 500));
      emit(CategoryLoaded(categories: categories));
    } catch (e) {
      debugPrint('Error creating category: $e');

      // ✅ Si hors ligne, mettre en queue
      if (!_connectivityService.isConnected) {
        await OfflineQueueService.enqueueAction(
          actionType: OfflineQueueService.ACTION_CREATE_CATEGORY,
          payload: {
            'name': event.name,
            'icon_code': event.iconCode,
            'color_hex': event.colorHex,
            'order_index': event.orderIndex,
          },
        );

        // Créer une catégorie temporaire locale avec ID négatif
        final now = DateTime.now();
        final tempCategory = Category(
          id: -now.millisecondsSinceEpoch,
          userId: 0, // Temporaire
          name: event.name,
          iconCode: event.iconCode,
          colorHex: event.colorHex,
          orderIndex: event.orderIndex ?? 0,
          createdAt: now,
          updatedAt: now,
        );

        // ✅ Récupérer les catégories actuelles depuis le state
        final currentState = state;
        List<Category> currentCategories = [];
        if (currentState is CategoryLoaded) {
          currentCategories = currentState.categories;
        } else if (currentState is CategoryOperationInProgress) {
          currentCategories = currentState.categories;
        }

        final updatedCategories = [...currentCategories, tempCategory];

        // ✅ Sauvegarder dans le cache
        final categoriesJson = updatedCategories.map((c) => c.toJson()).toList();
        await OfflineStorageService.saveCategories(categoriesJson);

        emit(CategoryOperationSuccess(
          categories: updatedCategories,
          message: _getTranslatedSuccessMessage('create'),
        ));

        await Future.delayed(const Duration(milliseconds: 500));
        emit(CategoryLoaded(categories: updatedCategories));
        return;
      }

      final currentState = state;
      List<Category>? currentCategories;
      if (currentState is CategoryOperationInProgress) {
        currentCategories = currentState.categories;
      }
      emit(CategoryError(
        message: _getTranslatedErrorMessage(e),
        categories: currentCategories,
      ));
    }
  }

  // Mettre à jour une catégorie
  Future<void> _onUpdateCategory(
    UpdateCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      final currentState = state;
      List<Category> currentCategories = [];
      if (currentState is CategoryLoaded) {
        currentCategories = currentState.categories;
      }

      emit(CategoryOperationInProgress(
        categories: currentCategories,
        operation: 'update',
      ));

      await _categoryService.updateCategory(
        categoryId: event.categoryId,
        name: event.name,
        iconCode: event.iconCode,
        colorHex: event.colorHex,
        orderIndex: event.orderIndex,
      );

      final categories = await _categoryService.getCategories();

      // ✅ Sauvegarder dans le cache
      final categoriesJson = categories.map((c) => c.toJson()).toList();
      await OfflineStorageService.saveCategories(categoriesJson);

      emit(CategoryOperationSuccess(
        categories: categories,
        message: _getTranslatedSuccessMessage('update'),
      ));

      // Retourner à l'état chargé
      await Future.delayed(const Duration(milliseconds: 500));
      emit(CategoryLoaded(categories: categories));
    } catch (e) {
      debugPrint('Error updating category: $e');

      // ✅ Si hors ligne, mettre en queue
      if (!_connectivityService.isConnected) {
        await OfflineQueueService.enqueueAction(
          actionType: OfflineQueueService.ACTION_UPDATE_CATEGORY,
          payload: {
            'category_id': event.categoryId,
            'name': event.name,
            'icon_code': event.iconCode,
            'color_hex': event.colorHex,
            'order_index': event.orderIndex,
          },
        );

        // Mettre à jour localement la catégorie
        final currentState = state;
        List<Category> currentCategories = [];
        if (currentState is CategoryLoaded) {
          currentCategories = currentState.categories;
        } else if (currentState is CategoryOperationInProgress) {
          currentCategories = currentState.categories;
        }

        final updatedCategories = currentCategories.map((cat) {
          if (cat.id == event.categoryId) {
            return Category(
              id: cat.id,
              userId: cat.userId,
              name: event.name ?? cat.name,
              iconCode: event.iconCode ?? cat.iconCode,
              colorHex: event.colorHex ?? cat.colorHex,
              orderIndex: event.orderIndex ?? cat.orderIndex,
              createdAt: cat.createdAt,
              updatedAt: DateTime.now(),
            );
          }
          return cat;
        }).toList();

        // ✅ Sauvegarder dans le cache
        final categoriesJson = updatedCategories.map((c) => c.toJson()).toList();
        await OfflineStorageService.saveCategories(categoriesJson);

        emit(CategoryOperationSuccess(
          categories: updatedCategories,
          message: _getTranslatedSuccessMessage('update'),
        ));

        await Future.delayed(const Duration(milliseconds: 500));
        emit(CategoryLoaded(categories: updatedCategories));
        return;
      }

      final currentState = state;
      List<Category>? currentCategories;
      if (currentState is CategoryOperationInProgress) {
        currentCategories = currentState.categories;
      }
      emit(CategoryError(
        message: _getTranslatedErrorMessage(e),
        categories: currentCategories,
      ));
    }
  }

  // Supprimer une catégorie
  Future<void> _onDeleteCategory(
    DeleteCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      final currentState = state;
      List<Category> currentCategories = [];
      if (currentState is CategoryLoaded) {
        currentCategories = currentState.categories;
      }

      emit(CategoryOperationInProgress(
        categories: currentCategories,
        operation: 'delete',
      ));

      await _categoryService.deleteCategory(event.categoryId);

      final categories = await _categoryService.getCategories();

      // ✅ Sauvegarder dans le cache
      final categoriesJson = categories.map((c) => c.toJson()).toList();
      await OfflineStorageService.saveCategories(categoriesJson);

      emit(CategoryOperationSuccess(
        categories: categories,
        message: _getTranslatedSuccessMessage('delete'),
      ));

      // Retourner à l'état chargé
      await Future.delayed(const Duration(milliseconds: 500));
      emit(CategoryLoaded(categories: categories));
    } catch (e) {
      debugPrint('Error deleting category: $e');

      // ✅ Si hors ligne, mettre en queue
      if (!_connectivityService.isConnected) {
        await OfflineQueueService.enqueueAction(
          actionType: OfflineQueueService.ACTION_DELETE_CATEGORY,
          payload: {
            'category_id': event.categoryId,
          },
        );

        // Supprimer localement la catégorie
        final currentState = state;
        List<Category> currentCategories = [];
        if (currentState is CategoryLoaded) {
          currentCategories = currentState.categories;
        } else if (currentState is CategoryOperationInProgress) {
          currentCategories = currentState.categories;
        }

        final updatedCategories = currentCategories
            .where((cat) => cat.id != event.categoryId)
            .toList();

        // ✅ Sauvegarder dans le cache
        final categoriesJson = updatedCategories.map((c) => c.toJson()).toList();
        await OfflineStorageService.saveCategories(categoriesJson);

        emit(CategoryOperationSuccess(
          categories: updatedCategories,
          message: _getTranslatedSuccessMessage('delete'),
        ));

        await Future.delayed(const Duration(milliseconds: 500));
        emit(CategoryLoaded(categories: updatedCategories));
        return;
      }

      final currentState = state;
      List<Category>? currentCategories;
      if (currentState is CategoryOperationInProgress) {
        currentCategories = currentState.categories;
      }
      emit(CategoryError(
        message: _getTranslatedErrorMessage(e),
        categories: currentCategories,
      ));
    }
  }

  // Réorganiser les catégories
  Future<void> _onReorderCategories(
    ReorderCategories event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      final currentState = state;
      List<Category> currentCategories = [];
      if (currentState is CategoryLoaded) {
        currentCategories = currentState.categories;
      }

      emit(CategoryOperationInProgress(
        categories: currentCategories,
        operation: 'reorder',
      ));

      await _categoryService.reorderCategories(event.categoryIds);

      final categories = await _categoryService.getCategories();

      // ✅ Sauvegarder dans le cache
      final categoriesJson = categories.map((c) => c.toJson()).toList();
      await OfflineStorageService.saveCategories(categoriesJson);

      emit(CategoryOperationSuccess(
        categories: categories,
        message: _getTranslatedSuccessMessage('reorder'),
      ));

      // Retourner à l'état chargé
      await Future.delayed(const Duration(milliseconds: 500));
      emit(CategoryLoaded(categories: categories));
    } catch (e) {
      final currentState = state;
      List<Category>? currentCategories;
      if (currentState is CategoryOperationInProgress) {
        currentCategories = currentState.categories;
      }
      emit(CategoryError(
        message: _getTranslatedErrorMessage(e),
        categories: currentCategories,
      ));
    }
  }

  // Initialiser les catégories par défaut
  Future<void> _onInitializeDefaultCategories(
    InitializeDefaultCategories event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      emit(const CategoryLoading());
      final categories = await _categoryService.initializeDefaultCategories();

      // ✅ Sauvegarder dans le cache
      final categoriesJson = categories.map((c) => c.toJson()).toList();
      await OfflineStorageService.saveCategories(categoriesJson);

      emit(CategoryOperationSuccess(
        categories: categories,
        message: _getTranslatedSuccessMessage('initialize'),
      ));

      // Retourner à l'état chargé
      await Future.delayed(const Duration(milliseconds: 500));
      emit(CategoryLoaded(categories: categories));
    } catch (e) {
      emit(CategoryError(message: _getTranslatedErrorMessage(e)));
    }
  }

  // Sélectionner une catégorie
  Future<void> _onSelectCategory(
    SelectCategory event,
    Emitter<CategoryState> emit,
  ) async {
    final currentState = state;
    if (currentState is CategoryLoaded) {
      emit(CategoryLoaded(
        categories: currentState.categories,
        selectedCategoryId: event.categoryId,
      ));
    }
  }
}
