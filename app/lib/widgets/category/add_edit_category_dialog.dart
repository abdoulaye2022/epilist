// widgets/category/add_edit_category_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/category/category_bloc.dart';
import '../../models/category.dart';
import '../../utils/smart_snackbar_manager.dart';
import 'icon_picker.dart';
import 'color_picker.dart';
import '../../l10n/app_localizations.dart';

class AddEditCategoryDialog extends StatefulWidget {
  final Category? category;

  const AddEditCategoryDialog({
    Key? key,
    this.category,
  }) : super(key: key);

  @override
  State<AddEditCategoryDialog> createState() => _AddEditCategoryDialogState();
}

class _AddEditCategoryDialogState extends State<AddEditCategoryDialog> {
  final _nameController = TextEditingController();
  late String _selectedIconCode;
  late Color _selectedColor;

  bool get isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.category?.name ?? '';
    _selectedIconCode = widget.category?.iconCode ?? 'category';
    _selectedColor = widget.category?.color ?? Colors.green;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône en haut
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _selectedColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Category.getIconDataFromCode(_selectedIconCode),
                size: 40,
                color: _selectedColor,
              ),
            ),

            const SizedBox(height: 20),

            // Titre
            Text(
              isEditing ? l10n.editCategory : l10n.addCategory,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 12),

            // Message
            Text(
              isEditing
                  ? l10n.modifyCategoryInfo
                  : l10n.createNewCategory,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            // Nom de la catégorie
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.categoryName,
                hintText: 'Ex: ${l10n.categoryFruitsVegetables}',
                prefixIcon: Icon(Icons.label, color: theme.primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.primaryColor, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: !isEditing,
            ),

            const SizedBox(height: 16),

            // Sélection d'icône et couleur
            Row(
              children: [
                // Icône
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final iconCode = await showDialog<String>(
                        context: context,
                        builder: (context) => IconPickerDialog(
                          selectedIconCode: _selectedIconCode,
                        ),
                      );
                      if (iconCode != null) {
                        setState(() {
                          _selectedIconCode = iconCode;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[50],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Category.getIconDataFromCode(_selectedIconCode),
                            color: _selectedColor,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              l10n.selectIcon,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Couleur
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final color = await showDialog<Color>(
                        context: context,
                        builder: (context) => ColorPickerDialog(
                          selectedColor: _selectedColor,
                        ),
                      );
                      if (color != null) {
                        setState(() {
                          _selectedColor = color;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[50],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _selectedColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              l10n.selectColor,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Boutons
            Row(
              children: [
                // Bouton Annuler
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
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

                // Bouton Sauvegarder/Créer
                Expanded(
                  child: BlocBuilder<CategoryBloc, CategoryState>(
                    builder: (context, state) {
                      final isLoading = state is CategoryOperationInProgress;
                      return ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                if (_nameController.text.trim().isEmpty) {
                                  SmartSnackBarManager.showErrorSnackBar(
                                    context,
                                    l10n.categoryNameRequired,
                                  );
                                  return;
                                }
                                if (_nameController.text.trim().length < 2) {
                                  SmartSnackBarManager.showErrorSnackBar(
                                    context,
                                    l10n.categoryNameTooShort,
                                  );
                                  return;
                                }
                                _saveCategory();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              theme.primaryColor.withValues(alpha: 0.5),
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
                                isEditing ? l10n.save : l10n.add,
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
    );
  }

  void _saveCategory() {
    final name = _nameController.text.trim();
    final colorHex = Category.colorToHex(_selectedColor);

    if (isEditing) {
      context.read<CategoryBloc>().add(
            UpdateCategory(
              categoryId: widget.category!.id,
              name: name,
              iconCode: _selectedIconCode,
              colorHex: colorHex,
            ),
          );
    } else {
      context.read<CategoryBloc>().add(
            CreateCategory(
              name: name,
              iconCode: _selectedIconCode,
              colorHex: colorHex,
            ),
          );
    }

    Navigator.of(context).pop();
  }
}