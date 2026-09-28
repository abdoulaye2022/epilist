// widgets/dialogs/edit_item_dialog.dart - VERSION CORRIGÉE SANS CAD
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:epilist/services/image_upload_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/app_dialog.dart';
import 'package:epilist/blocs/list_item/list_item_bloc.dart';
import 'package:epilist/blocs/product_suggestion/product_suggestion_bloc.dart';
import 'package:epilist/blocs/category/category_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/list_item.dart';
import 'package:epilist/models/product_suggestion.dart';
import 'package:epilist/models/category.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart';
import 'package:epilist/widgets/price/price_history_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditItemDialog extends StatefulWidget {
  final int listId;
  final ListItem item;

  const EditItemDialog({super.key, required this.listId, required this.item});

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  String? _photoUrl; // photo courante de l'article
  bool _photoBusy = false;
  late final TextEditingController productController;
  late final TextEditingController quantityController;
  late final TextEditingController priceController;
  late final TextEditingController storeController;

  bool _showSuggestions = false;
  ProductSuggestion? _selectedSuggestion;
  Category? _selectedCategory;
  late String _originalProductName;

  @override
  void initState() {
    super.initState();
    _originalProductName = widget.item.productName;
    _photoUrl = widget.item.imageUrl;
    productController = TextEditingController(text: widget.item.productName);
    quantityController = TextEditingController(
      text: widget.item.quantity.toString(),
    );
    priceController = TextEditingController(
      text: widget.item.price?.toStringAsFixed(2) ?? '',
    );
    storeController = TextEditingController(text: widget.item.storeName ?? '');

    // Charger les catégories
    context.read<CategoryBloc>().add(const LoadCategories());
  }

  void _tryInitializeCategory() {
    if (widget.item.categoryId == null || _selectedCategory != null) return;

    final categoryState = context.read<CategoryBloc>().state;
    List<Category> categories = [];

    if (categoryState is CategoryLoaded) {
      categories = categoryState.categories;
    } else if (categoryState is CategoryOperationSuccess) {
      categories = categoryState.categories;
    }

    if (categories.isNotEmpty) {
      try {
        final itemCategory = categories.firstWhere(
          (cat) => cat.id == widget.item.categoryId,
        );
        if (mounted) {
          setState(() {
            _selectedCategory = itemCategory;
          });
        }
      } catch (e) {
        // Catégorie non trouvée dans la liste
      }
    }
  }

  @override
  void dispose() {
    productController.dispose();
    quantityController.dispose();
    priceController.dispose();
    storeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<CategoryBloc, CategoryState>(
      listener: (context, state) {
        // Initialiser la catégorie quand elles sont chargées
        if ((state is CategoryLoaded || state is CategoryOperationSuccess) &&
            _selectedCategory == null &&
            widget.item.categoryId != null) {
          _tryInitializeCategory();
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            maxWidth: 500,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppDialogHeader(
                        icon: Icons.edit_outlined,
                        title: l10n.editItem,
                      ),
                      const SizedBox(height: 16),
                      _buildPhotoSection(l10n),
                      const SizedBox(height: 16),
                      _buildForm(l10n),
                      _buildPriceHistoryLink(l10n),
                      if (_showSuggestions) ...[
                        const SizedBox(height: 16),
                        _buildSuggestions(l10n),
                      ],
                      const SizedBox(height: 24),
                      _buildButtons(l10n),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Lien vers l'historique de prix du produit (fiche avec provenance).
  Widget _buildPriceHistoryLink(AppLocalizations l10n) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () {
          final name = productController.text.trim();
          if (name.isEmpty) return;
          showPriceHistorySheet(context, name);
        },
        icon: const Icon(Icons.query_stats, size: 18),
        label: Text(l10n.priceHistoryTitle),
      ),
    );
  }

  Widget _buildForm(AppLocalizations l10n) {
    return Column(
      children: [
        _buildProductNameFieldWithSuggestions(l10n),
        const SizedBox(height: 16),
        _buildCategorySelector(l10n),
        const SizedBox(height: 16),
        _buildQuantityAndPriceRow(l10n),
        const SizedBox(height: 16),
        _buildStoreField(l10n),
      ],
    );
  }

  Widget _buildProductNameFieldWithSuggestions(AppLocalizations l10n) {
    return Column(
      children: [
        TextField(
          controller: productController,
          decoration: InputDecoration(
            labelText: l10n.productNameRequired,
            hintText: l10n.productNameHint,
            suffixIcon:
                _selectedSuggestion != null
                    ? IconButton(
                      icon: Icon(Icons.clear, color: AppColors.textSecondary),
                      onPressed: _clearSelectedSuggestion,
                    )
                    : (productController.text != _originalProductName &&
                        productController.text.isNotEmpty)
                    ? IconButton(
                      icon: Icon(Icons.refresh, color: AppColors.warning),
                      onPressed: _resetToOriginal,
                      tooltip: AppLocalizations.of(context)!.restoreOriginalName,
                    )
                    : null,
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          onChanged: _onProductNameChanged,
        ),
        if (_selectedSuggestion != null) _buildSelectedSuggestionInfo(l10n),
      ],
    );
  }

  Widget _buildSelectedSuggestionInfo(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: AppColors.accent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Suggestion sélectionnée • ${_selectedSuggestion!.usageInfo}',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(AppLocalizations l10n) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: BlocBuilder<ProductSuggestionBloc, ProductSuggestionState>(
        builder: (context, state) {
          if (state is ProductSuggestionLoading) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is ProductSuggestionLoaded) {
            return ListView.separated(
              shrinkWrap: true,
              itemCount: state.suggestions.length,
              separatorBuilder:
                  (context, index) =>
                      Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) {
                final suggestion = state.suggestions[index];
                return _buildSuggestionItem(suggestion, l10n);
              },
            );
          }

          if (state is ProductSuggestionEmpty) {
            // Ne rien afficher si aucune suggestion n'est trouvée
            return const SizedBox.shrink();
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSuggestionItem(
    ProductSuggestion suggestion,
    AppLocalizations l10n,
  ) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        backgroundColor: AppColors.accentLight,
        child: Icon(Icons.history, color: AppColors.accent, size: 16),
      ),
      title: Text(
        suggestion.productName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Row(
        children: [
          if (suggestion.price != null) ...[
            // ✅ CORRECTION: Utiliser FormattedAmount au lieu de suggestion.formattedPrice
            FormattedAmount(
              amount: suggestion.price!,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
              showCode: false,
            ),
            if (suggestion.storeName != null)
              Text(' • ${suggestion.storeName}'),
          ] else if (suggestion.storeName != null)
            Text(suggestion.storeName!),
          const Spacer(),
          Text(
            suggestion.usageInfo,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
      onTap: () => _selectSuggestion(suggestion),
    );
  }

  Widget _buildQuantityAndPriceRow(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: TextField(
            controller: quantityController,
            decoration: InputDecoration(
              labelText: l10n.quantity,
              hintText: '1',
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: TextField(
            controller: priceController,
            decoration: InputDecoration(
              // ✅ CORRECTION: Remplacer l10n.priceCAD par l10n.price
              labelText: l10n.price, // Plus de référence à CAD
              hintText: '0.00',
              // ✅ CORRECTION: Afficher uniquement l'indicateur de devise
              suffixIcon: _buildCurrencyIndicator(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
      ],
    );
  }

  // ✅ CORRECTION: Widget pour afficher uniquement la devise sans montant
  Widget _buildCurrencyIndicator() {
    // Utiliser le nouveau widget CurrencyIndicator au lieu d'un placeholder fixe
    return const CurrencyIndicator(
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildStoreField(AppLocalizations l10n) {
    return TextField(
      controller: storeController,
      decoration: InputDecoration(
        labelText: l10n.storeOptional,
        hintText: l10n.storeHint,
        prefixIcon: Icon(Icons.store, color: Theme.of(context).primaryColor),
      ),
      textCapitalization: TextCapitalization.words,
    );
  }

  Widget _buildButtons(AppLocalizations l10n) {
    return BlocBuilder<ListItemBloc, ListItemState>(
      builder:
          (context, state) => AppDialogActions(
            cancelLabel: l10n.cancel,
            submitLabel: l10n.save,
            loading: state is ListItemLoading,
            onSubmit: () => _updateItem(l10n),
          ),
    );
  }

  void _onProductNameChanged(String value) {
    // Ne montrer les suggestions que si le nom a changé par rapport à l'original
    if (value.trim().length >= 2 && value.trim() != _originalProductName) {
      if (!_showSuggestions) {
        setState(() {
          _showSuggestions = true;
        });
      }
      context.read<ProductSuggestionBloc>().add(
        SearchProductSuggestions(value.trim()),
      );
    } else {
      if (_showSuggestions) {
        setState(() {
          _showSuggestions = false;
        });
      }
      context.read<ProductSuggestionBloc>().add(const ResetSuggestions());
    }
  }

  void _selectSuggestion(ProductSuggestion suggestion) {
    setState(() {
      _selectedSuggestion = suggestion;
      productController.text = suggestion.productName;
      if (suggestion.price != null) {
        priceController.text = suggestion.price!.toStringAsFixed(2);
      }
      if (suggestion.storeName != null) {
        storeController.text = suggestion.storeName!;
      }
      _showSuggestions = false;
    });
    context.read<ProductSuggestionBloc>().add(const ResetSuggestions());
  }

  void _clearSelectedSuggestion() {
    setState(() {
      _selectedSuggestion = null;
      productController.clear();
    });
  }

  void _resetToOriginal() {
    setState(() {
      _selectedSuggestion = null;
      productController.text = _originalProductName;
      quantityController.text = widget.item.quantity.toString();
      priceController.text = widget.item.price?.toStringAsFixed(2) ?? '';
      storeController.text = widget.item.storeName ?? '';
      _showSuggestions = false;
    });
    context.read<ProductSuggestionBloc>().add(const ResetSuggestions());
  }

  void _updateItem(AppLocalizations l10n) {
    if (productController.text.trim().isEmpty) {
      SmartSnackBarManager.showWarningSnackBar(
        context,
        l10n.productNameRequiredMessage,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    context.read<ListItemBloc>().add(
      UpdateListItem(
        listId: widget.listId,
        itemId: widget.item.id,
        productName: productController.text.trim(),
        quantity: int.tryParse(quantityController.text) ?? 1,
        price:
            priceController.text.trim().isEmpty
                ? null
                : double.tryParse(priceController.text),
        storeName:
            storeController.text.trim().isEmpty
                ? null
                : storeController.text.trim(),
        categoryId: _selectedCategory?.id,
      ),
    );
    Navigator.pop(context);
  }

  Widget _buildCategorySelector(AppLocalizations l10n) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        List<Category> categories = [];
        if (state is CategoryLoaded) {
          categories = state.categories;
        } else if (state is CategoryOperationSuccess) {
          categories = state.categories;
        }

        // Initialiser la catégorie après le build si elle n'est pas encore définie
        if (categories.isNotEmpty &&
            _selectedCategory == null &&
            widget.item.categoryId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selectedCategory == null) {
              try {
                final category = categories.firstWhere(
                  (cat) => cat.id == widget.item.categoryId,
                );
                setState(() {
                  _selectedCategory = category;
                });
              } catch (e) {
                // Category not found
              }
            }
          });
        }

        return InkWell(
          onTap: () => _showCategoryPicker(context, categories, l10n),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.background,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.category,
                  color:
                      _selectedCategory != null
                          ? _selectedCategory!.color
                          : Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.selectCategory,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedCategory?.name ?? l10n.noCategorySelected,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              _selectedCategory != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                          color:
                              _selectedCategory != null
                                  ? AppColors.textPrimary
                                  : AppColors.textDisabled,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedCategory != null) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _selectedCategory!.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedCategory!.color.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Icon(
                      _selectedCategory!.icon,
                      color: _selectedCategory!.color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        _selectedCategory = null;
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ] else
                  const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCategoryPicker(
    BuildContext context,
    List<Category> categories,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.category, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    l10n.selectCategory,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (categories.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 48,
                        color: AppColors.textDisabled,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noCategoriesYet,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = _selectedCategory?.id == category.id;

                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: category.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: category.color.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Icon(
                            category.icon,
                            color: category.color,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          category.name,
                          style: TextStyle(
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                        trailing:
                            isSelected
                                ? Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).primaryColor,
                                )
                                : null,
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Photo du produit : vignette + remplacement/suppression. L'upload part
  /// immediatement (l'article existe deja) ; l'API assainit puis stocke
  /// sur GCS et renvoie l'article a jour.
  Widget _buildPhotoSection(AppLocalizations l10n) {
    final hasPhoto = _photoUrl?.isNotEmpty == true;
    return Row(
      children: [
        GestureDetector(
          onTap: _photoBusy ? null : _showPhotoOptions,
          child: Container(
            width: 64,
            height: 64,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child:
                _photoBusy
                    ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                    : hasPhoto
                    ? CachedNetworkImage(
                      imageUrl: _photoUrl!,
                      fit: BoxFit.cover,
                      errorWidget:
                          (_, _, _) => const Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.textDisabled,
                          ),
                    )
                    : const Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.textSecondary,
                    ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            hasPhoto ? l10n.productPhoto : l10n.addPhoto,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  void _showPhotoOptions() {
    final l10n = AppLocalizations.of(context)!;
    final hasPhoto = _photoUrl?.isNotEmpty == true;
    showModalBottomSheet(
      context: context,
      builder:
          (sheetContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: Text(l10n.takePhoto),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickAndUploadPhoto(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(l10n.chooseFromGallery),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickAndUploadPhoto(ImageSource.gallery);
                  },
                ),
                if (hasPhoto)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                    ),
                    title: Text(
                      l10n.removePhoto,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _removePhoto();
                    },
                  ),
              ],
            ),
          ),
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      setState(() => _photoBusy = true);
      final updated = await context.read<ImageUploadService>().uploadItemImage(
        widget.item.listId,
        widget.item.id,
        File(picked.path),
      );
      if (!mounted) return;
      setState(() {
        _photoUrl = updated.imageUrl;
        _photoBusy = false;
      });
      context.read<ListItemBloc>().add(LoadListItems(widget.item.listId));
      SmartSnackBarManager.showSuccessSnackBar(context, l10n.photoUpdated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _photoBusy = false);
      SmartSnackBarManager.showErrorSnackBar(context, l10n.photoUploadFailed);
    }
  }

  Future<void> _removePhoto() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      setState(() => _photoBusy = true);
      await context.read<ImageUploadService>().deleteItemImage(
        widget.item.listId,
        widget.item.id,
      );
      if (!mounted) return;
      setState(() {
        _photoUrl = null;
        _photoBusy = false;
      });
      context.read<ListItemBloc>().add(LoadListItems(widget.item.listId));
      SmartSnackBarManager.showSuccessSnackBar(context, l10n.photoRemoved);
    } catch (e) {
      if (!mounted) return;
      setState(() => _photoBusy = false);
      SmartSnackBarManager.showErrorSnackBar(context, l10n.photoUploadFailed);
    }
  }
}
