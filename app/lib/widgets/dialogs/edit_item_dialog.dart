// widgets/dialogs/edit_item_dialog.dart
import 'package:epilist/blocs/list_item/list_item_bloc.dart';
import 'package:epilist/models/list_item.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
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

  @override
  void initState() {
    super.initState();
    productController = TextEditingController(text: widget.item.productName);
    quantityController = TextEditingController(
      text: widget.item.quantity.toString(),
    );
    priceController = TextEditingController(
      text: widget.item.price?.toStringAsFixed(2) ?? '',
    );
    storeController = TextEditingController(text: widget.item.storeName ?? '');
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
                    _buildTitle(),
                    const SizedBox(height: 12),
                    _buildDescription(),
                    const SizedBox(height: 24),
                    _buildForm(),
                    const SizedBox(height: 24),
                    _buildButtons(),
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
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(40),
      ),
      child: Icon(Icons.edit_rounded, size: 40, color: Colors.blue[600]),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Modifier l\'article',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      'Modifiez les informations de votre article',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        _buildProductNameField(),
        const SizedBox(height: 16),
        _buildQuantityAndPriceRow(),
        const SizedBox(height: 16),
        _buildStoreField(),
      ],
    );
  }

  Widget _buildProductNameField() {
    return TextField(
      controller: productController,
      decoration: InputDecoration(
        labelText: 'Nom du produit*',
        hintText: 'Ex: Bananes, Pain, Lait...',
        prefixIcon: Icon(Icons.shopping_basket, color: Colors.blue[600]),
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
      autofocus: true,
      textCapitalization: TextCapitalization.words,
    );
  }

  Widget _buildQuantityAndPriceRow() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: TextField(
            controller: quantityController,
            decoration: InputDecoration(
              labelText: 'Quantité',
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
              labelText: 'Prix (\$CAD)',
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

  Widget _buildStoreField() {
    return TextField(
      controller: storeController,
      decoration: InputDecoration(
        labelText: 'Magasin (optionnel)',
        hintText: 'Ex: IGA, Metro, Provigo...',
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

  Widget _buildButtons() {
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
              'Annuler',
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
                onPressed: isLoading ? null : _updateItem,
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
                        : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Modifier',
                              style: TextStyle(
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

  void _updateItem() {
    if (productController.text.trim().isEmpty) {
      SmartSnackBarManager.showWarningSnackBar(
        context,
        'Le nom du produit est obligatoire',
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
      ),
    );
    Navigator.pop(context);
  }
}
