// screens/category_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/category/category_bloc.dart';
import '../models/category.dart';
import '../widgets/category/category_list_item.dart';
import '../widgets/category/add_edit_category_dialog.dart';
import '../l10n/app_localizations.dart';
import '../utils/smart_snackbar_manager.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({Key? key}) : super(key: key);

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les catégories au démarrage
    context.read<CategoryBloc>().add(const LoadCategories());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageCategories),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<CategoryBloc>().add(const RefreshCategories());
            },
            tooltip: l10n.refreshTooltip,
          ),
        ],
      ),
      body: BlocConsumer<CategoryBloc, CategoryState>(
        listener: (context, state) {
          if (state is CategoryOperationSuccess) {
            SmartSnackBarManager.showSuccessSnackBar(
              context,
              state.message,
              duration: const Duration(seconds: 2),
            );
          } else if (state is CategoryError) {
            SmartSnackBarManager.showErrorSnackBar(
              context,
              state.message,
              duration: const Duration(seconds: 3),
            );
          }
        },
        builder: (context, state) {
          if (state is CategoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CategoryError && state.categories == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<CategoryBloc>().add(const LoadCategories());
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.refreshTooltip),
                  ),
                ],
              ),
            );
          }

          List<Category> categories = [];
          if (state is CategoryLoaded) {
            categories = state.categories;
          } else if (state is CategoryOperationInProgress) {
            categories = state.categories;
          } else if (state is CategoryOperationSuccess) {
            categories = state.categories;
          } else if (state is CategoryError && state.categories != null) {
            categories = state.categories!;
          }

          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noCategoriesYet,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.createFirstCategoryDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context
                          .read<CategoryBloc>()
                          .add(const InitializeDefaultCategories());
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(l10n.categories),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Header avec nombre de catégories
              Container(
                padding: const EdgeInsets.all(16),
                color: theme.primaryColor.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Icon(
                      Icons.category,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${categories.length} ${l10n.categories.toLowerCase()}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Liste des catégories
              Expanded(
                child: state is CategoryOperationInProgress
                    ? Stack(
                        children: [
                          _buildCategoryList(categories),
                          Container(
                            color: Colors.black.withValues(alpha: 0.3),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ],
                      )
                    : _buildCategoryList(categories),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          l10n.addCategory,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildCategoryList(List<Category> categories) {
    return ReorderableListView.builder(
      itemCount: categories.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        final reorderedIds = List<int>.from(
          categories.map((c) => c.id),
        );
        final item = reorderedIds.removeAt(oldIndex);
        reorderedIds.insert(newIndex, item);

        context.read<CategoryBloc>().add(ReorderCategories(reorderedIds));
      },
      itemBuilder: (context, index) {
        final category = categories[index];
        return CategoryListItem(
          key: ValueKey(category.id),
          category: category,
          onEdit: () => _showEditCategoryDialog(context, category),
          onDelete: () => _showDeleteConfirmation(context, category),
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<CategoryBloc>(),
        child: const AddEditCategoryDialog(),
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<CategoryBloc>(),
        child: AddEditCategoryDialog(category: category),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Category category) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône de suppression
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.delete_rounded,
                  size: 40,
                  color: Colors.red[600],
                ),
              ),

              const SizedBox(height: 20),

              // Titre
              Text(
                l10n.deleteCategory,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              // Message
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(text: l10n.deleteCategoryConfirm),
                    TextSpan(
                      text: ' "${category.name}"',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const TextSpan(text: ' ?'),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Text(
                l10n.actionIrreversible,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red[600],
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 24),

              // Boutons
              Row(
                children: [
                  // Bouton Annuler
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Text(
                        l10n.cancel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Bouton Supprimer
                  Expanded(
                    child: BlocBuilder<CategoryBloc, CategoryState>(
                      builder: (context, state) {
                        final isLoading = state is CategoryOperationInProgress;
                        return ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  context.read<CategoryBloc>().add(DeleteCategory(category.id));
                                  Navigator.of(dialogContext).pop();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.red[300],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  l10n.delete,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
