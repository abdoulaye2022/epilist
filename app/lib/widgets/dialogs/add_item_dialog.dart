import 'package:epilist/blocs/list_item/list_item_bloc.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
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
            // Contenu scrollable
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
                    const SizedBox(height: 24),
                    _buildButtons(l10n),
                  ],
                ),
              ),
            ),
          ],
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
        _buildProductNameField(l10n),
        const SizedBox(height: 16),
        _buildQuantityAndPriceRow(l10n),
        const SizedBox(height: 16),
        _buildStoreField(l10n),
      ],
    );
  }

  Widget _buildProductNameField(AppLocalizations l10n) {
    return TextField(
      controller: productController,
      decoration: InputDecoration(
        labelText: l10n.productNameRequired,
        hintText: l10n.productNameHint,
        prefixIcon: Icon(Icons.shopping_basket, color: Colors.green[600]),
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
        fillColor: Colors.grey[50],
      ),
      autofocus: true,
      textCapitalization: TextCapitalization.words,
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
              labelText: l10n.priceCAD,
              hintText: '0.00',
              prefixIcon: Icon(Icons.attach_money, color: Colors.amber[700]),
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

  void _addItem(AppLocalizations l10n) {
    if (productController.text.trim().isEmpty) {
      SmartSnackBarManager.showWarningSnackBar(
        context,
        l10n.productNameRequired,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    context.read<ListItemBloc>().add(
      AddListItem(
        listId: widget.listId,
        productName: productController.text.trim(),
        quantity: int.tryParse(quantityController.text) ?? 1,
        price: double.tryParse(priceController.text),
        storeName:
            storeController.text.trim().isEmpty
                ? null
                : storeController.text.trim(),
      ),
    );
    Navigator.pop(context);
  }
}
