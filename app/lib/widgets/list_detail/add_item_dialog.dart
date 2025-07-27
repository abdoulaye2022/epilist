// widgets/dialogs/add_item_dialog.dart - VERSION CORRIGÉE SANS CAD
import 'package:epilist/blocs/list_item/list_item_bloc.dart';
import 'package:epilist/blocs/product_suggestion/product_suggestion_bloc.dart';
import 'package:epilist/models/product_suggestion.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/widgets/dialogs/duplicate_confirmation_dialog.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart'; // ✅ AJOUT
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';

class AddItemDialog extends StatefulWidget {
  final int listId;

  const AddItemDialog({super.key, required this.listId});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final productController = TextEditingController();
  final quantityController = TextEditingController(text: '1');
  final priceController = TextEditingController();
  final storeController = TextEditingController();

  bool _showSuggestions = false;
  ProductSuggestion? _selectedSuggestion;

  // ✅ CORRECTION: Sauvegarder le BLoC pour éviter les erreurs de contexte
  late ListItemBloc _listItemBloc;

  @override
  void initState() {
    super.initState();
    // ✅ Sauvegarder une référence au BLoC au moment de l'initialisation
    _listItemBloc = context.read<ListItemBloc>();
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

    return Dialog(
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
            // ✅ LISTENER CORRIGÉ
            BlocListener<ListItemBloc, ListItemState>(
              listener: (context, state) {
                print('🎯 AddItemDialog - State changé: ${state.runtimeType}');

                if (state is ListItemDuplicateDetected) {
                  print('🔍 Doublon détecté dans le dialog!');

                  // ✅ CORRECTION: Fermer le dialog avec un délai pour éviter les conflits
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      Navigator.pop(context);
                      _showDuplicateDialog(context, state);
                    }
                  });
                } else if (state is ListItemOperationSuccess) {
                  // Succès - fermer le dialog seulement si c'est un ajout réussi
                  if (state.message.contains('ajouté') ||
                      state.message.contains('added') ||
                      state.message.contains('fusionné') ||
                      state.message.contains('merged')) {
                    print('✅ Opération réussie: ${state.message}');
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    });
                  }
                } else if (state is ListItemValidationError) {
                  // Afficher les erreurs de validation
                  SmartSnackBarManager.showErrorSnackBar(
                    context,
                    state.message,
                    duration: const Duration(seconds: 3),
                  );
                }
              },
              child: Flexible(
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
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NOUVELLE MÉTHODE: Afficher le dialog de doublon avec le BLoC sauvegardé
  void _showDuplicateDialog(
    BuildContext parentContext,
    ListItemDuplicateDetected state,
  ) {
    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder:
          (dialogContext) => BlocProvider.value(
            // ✅ Utiliser le BLoC sauvegardé au lieu de context.read
            value: _listItemBloc,
            child: DuplicateConfirmationDialog(
              message: state.message,
              duplicates: state.duplicates,
              productName: state.productName,
              quantity: state.quantity,
              price: state.price,
              storeName: state.storeName,
              listId: state.listId,
              onActionSelected: (action, {existingItemId}) {
                print('🎯 Action sélectionnée: $action');

                // ✅ CORRECTION: Fermer le dialog de doublon d'abord
                Navigator.pop(dialogContext);

                // ✅ Utiliser le BLoC sauvegardé pour éviter les erreurs de contexte
                _listItemBloc.add(
                  HandleDuplicateAction(
                    action: action,
                    listId: state.listId,
                    productName: state.productName,
                    quantity: state.quantity,
                    price: state.price,
                    storeName: state.storeName,
                    existingItemId: existingItemId,
                  ),
                );
              },
            ),
          ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(40),
      ),
      child: Icon(
        Icons.add_shopping_cart_rounded,
        size: 40,
        color: Colors.green[600],
      ),
    );
  }

  Widget _buildTitle(AppLocalizations l10n) {
    return Text(
      l10n.newItem,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDescription(AppLocalizations l10n) {
    return Text(
      l10n.addNewItemToList,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
    );
  }

  Widget _buildForm(AppLocalizations l10n) {
    return Column(
      children: [
        _buildProductNameFieldWithSuggestions(l10n),
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
            prefixIcon: Icon(Icons.shopping_basket, color: Colors.green[600]),
            suffixIcon:
                _selectedSuggestion != null
                    ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[600]),
                      onPressed: _clearSelectedSuggestion,
                    )
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green[600]!, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            filled: true,
            fillColor:
                _selectedSuggestion != null
                    ? Colors.green[50]
                    : Colors.grey[50],
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
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.green[600], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Suggestion sélectionnée • ${_selectedSuggestion!.usageInfo}',
              style: TextStyle(
                color: Colors.green[700],
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
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Aucune suggestion trouvée',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            );
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
              prefixIcon: Icon(Icons.numbers, color: Colors.blue[600]),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Text(
        'CAD', // Temporaire - sera remplacé par la devise dynamique
        style: TextStyle(
          fontSize: 12,
          color: Colors.amber[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStoreField(AppLocalizations l10n) {
    return TextField(
      controller: storeController,
      decoration: InputDecoration(
        labelText: l10n.storeOptional,
        hintText: l10n.storeHint,
        prefixIcon: Icon(Icons.store, color: Colors.purple[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.purple[600]!, width: 2),
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
                onPressed: isLoading ? null : () => _addItem(l10n),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.green[300],
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
                            const Icon(Icons.add, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              l10n.add,
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
    if (value.trim().length >= 2) {
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
      priceController.clear();
      storeController.clear();
      quantityController.text = '1';
    });
  }

  void _addItem(AppLocalizations l10n) {
    // Validation côté client
    if (productController.text.trim().isEmpty) {
      SmartSnackBarManager.showWarningSnackBar(
        context,
        l10n.productNameRequired,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final quantity = int.tryParse(quantityController.text);
    if (quantity == null || quantity < 1) {
      SmartSnackBarManager.showWarningSnackBar(
        context,
        'La quantité doit être un nombre valide (minimum 1)',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final price =
        priceController.text.isNotEmpty
            ? double.tryParse(priceController.text)
            : null;

    if (priceController.text.isNotEmpty && price == null) {
      SmartSnackBarManager.showWarningSnackBar(
        context,
        'Le prix doit être un nombre valide',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    print('🚀 Tentative d\'ajout: ${productController.text.trim()}');

    // ✅ Utiliser le BLoC sauvegardé pour éviter les erreurs
    _listItemBloc.add(
      AddListItem(
        listId: widget.listId,
        productName: productController.text.trim(),
        quantity: quantity,
        price: price,
        storeName:
            storeController.text.trim().isEmpty
                ? null
                : storeController.text.trim(),
      ),
    );
  }
}
