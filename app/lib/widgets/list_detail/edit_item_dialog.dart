// widgets/dialogs/edit_item_dialog.dart - VERSION CORRIGÉE SANS CAD
import 'package:epilist/blocs/list_item/list_item_bloc.dart';
import 'package:epilist/blocs/product_suggestion/product_suggestion_bloc.dart';
import 'package:epilist/blocs/category/category_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/list_item.dart';
import 'package:epilist/models/product_suggestion.dart';
import 'package:epilist/models/category.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart';
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIcon(),
                    const SizedBox(height: 20),
                    _buildTitle(l10n),
                    const SizedBox(height: 12),
                    _buildDescription(l10n),
                    const SizedBox(height: 24),
                    _buildForm(l10n),
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

  Widget _buildIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(40),
      ),
      child: Icon(Icons.edit_rounded, size: 40, color: Colors.blue[600]),
    );
  }

  Widget _buildTitle(AppLocalizations l10n) {
    return Text(
      l10n.editItem,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDescription(AppLocalizations l10n) {
    return Text(
      l10n.modifyItemInformation,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
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
            prefixIcon: Icon(Icons.shopping_basket, color: Colors.blue[600]),
            suffixIcon:
                _selectedSuggestion != null
                    ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[600]),
                      onPressed: _clearSelectedSuggestion,
                    )
                    : (productController.text != _originalProductName &&
                        productController.text.isNotEmpty)
                    ? IconButton(
                      icon: Icon(Icons.refresh, color: Colors.orange[600]),
                      onPressed: _resetToOriginal,
                      tooltip: 'Restaurer le nom original',
                    )
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            filled: true,
            fillColor:
                _selectedSuggestion != null ? Colors.blue[50] : Colors.grey[50],
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
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.blue[600], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Suggestion sélectionnée • ${_selectedSuggestion!.usageInfo}',
              style: TextStyle(
                color: Colors.blue[700],
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
        border: Border.all(color: Colors.grey[300]!),
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
                      Divider(height: 1, color: Colors.grey[200]),
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
        backgroundColor: Colors.blue[50],
        child: Icon(Icons.history, color: Colors.blue[600], size: 16),
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
                color: Colors.green[600],
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
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
              prefixIcon: Icon(Icons.numbers, color: Colors.orange[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.orange[600]!, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
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
              prefixIcon: Icon(Icons.attach_money, color: Colors.amber[700]),
              // ✅ CORRECTION: Afficher uniquement l'indicateur de devise
              suffixIcon: _buildCurrencyIndicator(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.amber[700]!, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      textCapitalization: TextCapitalization.words,
    );
  }

  Widget _buildButtons(AppLocalizations l10n) {
    return Row(
      children: [
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
        Expanded(
          child: BlocBuilder<ListItemBloc, ListItemState>(
            builder: (context, state) {
              final isLoading = state is ListItemLoading;
              return ElevatedButton(
                onPressed: isLoading ? null : () => _updateItem(l10n),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.blue[300],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child:
                    isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              l10n.save,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
              );
            },
          ),
        ),
      ],
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
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.category,
                  color: _selectedCategory != null
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
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedCategory?.name ?? l10n.noCategorySelected,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _selectedCategory != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: _selectedCategory != null
                              ? Colors.black87
                              : Colors.grey[500],
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
                  Icon(
                    Icons.category,
                    color: Theme.of(context).primaryColor,
                  ),
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
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noCategoriesYet,
                        style: TextStyle(
                          color: Colors.grey[600],
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
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
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
}
