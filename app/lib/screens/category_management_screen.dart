// screens/category_management_screen.dart
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/category/category_bloc.dart';
import '../models/category.dart';
import '../widgets/category/category_list_item.dart';
import '../widgets/category/add_edit_category_dialog.dart';
import '../l10n/app_localizations.dart';
import '../utils/smart_snackbar_manager.dart';
import '../widgets/common/app_dialog.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

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

    return Scaffold(
      backgroundColor: AppColors.background,
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
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 56, color: Colors.red[300]),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      state.message,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: () {
                        context.read<CategoryBloc>().add(const LoadCategories());
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(l10n.refreshTooltip),
                    ),
                  ],
                ),
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
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.category_outlined,
                        size: 36,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.noCategoriesYet,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.createFirstCategoryDescription,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton.icon(
                      onPressed: () {
                        context
                            .read<CategoryBloc>()
                            .add(const InitializeDefaultCategories());
                      },
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: Text(l10n.categories),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compteur discret, sans bandeau coloré.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
                child: Text(
                  '${categories.length} ${l10n.categories.toLowerCase()}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
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
        icon: const Icon(Icons.add),
        label: Text(l10n.addCategory),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildCategoryList(List<Category> categories) {
    return ReorderableListView.builder(
      itemCount: categories.length,
      onReorderItem: (oldIndex, newIndex) {
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
    final categoryBloc = context.read<CategoryBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppDialogHeader(
                icon: Icons.delete_outline,
                title: l10n.deleteCategory,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.md),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(text: l10n.deleteCategoryConfirm),
                    TextSpan(
                      text: ' « ${category.name} »',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const TextSpan(text: ' ?'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.actionIrreversible,
                style: const TextStyle(fontSize: 12.5, color: AppColors.error),
              ),
              const SizedBox(height: AppSpacing.lg),
              BlocBuilder<CategoryBloc, CategoryState>(
                bloc: categoryBloc,
                builder: (context, state) => AppDialogActions(
                  cancelLabel: l10n.cancel,
                  submitLabel: l10n.delete,
                  destructive: true,
                  loading: state is CategoryOperationInProgress,
                  onCancel: () => Navigator.of(dialogContext).pop(),
                  onSubmit: () {
                    categoryBloc.add(DeleteCategory(category.id));
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
