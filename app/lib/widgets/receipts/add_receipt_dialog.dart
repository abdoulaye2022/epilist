// widgets/receipts/add_receipt_dialog.dart
import 'package:epilist/blocs/receipt/receipt_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddReceiptDialog extends StatefulWidget {
  final int listId;

  const AddReceiptDialog({super.key, required this.listId});

  @override
  State<AddReceiptDialog> createState() => _AddReceiptDialogState();
}

class _AddReceiptDialogState extends State<AddReceiptDialog> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _storeNameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
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
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildIcon(),
                      const SizedBox(height: 20),
                      _buildTitle(l10n),
                      const SizedBox(height: 12),
                      _buildDescription(l10n),
                      const SizedBox(height: 24),
                      _buildStoreNameField(l10n),
                      const SizedBox(height: 16),
                      _buildAmountField(l10n),
                      const SizedBox(height: 16),
                      _buildDateField(l10n),
                      const SizedBox(height: 16),
                      _buildNotesField(l10n),
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

  Widget _buildIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(40),
      ),
      child: Icon(Icons.receipt_long, size: 40, color: Colors.green[600]),
    );
  }

  Widget _buildTitle(AppLocalizations l10n) {
    return Text(
      l10n.addReceipt,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDescription(AppLocalizations l10n) {
    return Text(
      "Ajoutez une nouvelle facture à votre liste",
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
    );
  }

  Widget _buildStoreNameField(AppLocalizations l10n) {
    return TextFormField(
      controller: _storeNameController,
      decoration: InputDecoration(
        labelText: l10n.storeName,
        hintText: l10n.enterStoreName,
        prefixIcon: Icon(Icons.store, color: Colors.green[600]),
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
      textCapitalization: TextCapitalization.words,
      enabled: !_isLoading,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.storeNameRequired;
        }
        if (value.trim().length < 2) {
          return l10n.storeNameTooShort;
        }
        return null;
      },
    );
  }

  Widget _buildAmountField(AppLocalizations l10n) {
    return TextFormField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: l10n.totalAmount,
        hintText: l10n.enterAmount,
        prefixIcon: Icon(Icons.attach_money, color: Colors.green[600]),
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
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      enabled: !_isLoading,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.amountRequired;
        }
        final amount = double.tryParse(value);
        if (amount == null) {
          return l10n.invalidAmount;
        }
        if (amount <= 0) {
          return l10n.amountMustBePositive;
        }
        if (amount > 999999.99) {
          return l10n.amountTooHigh;
        }
        return null;
      },
    );
  }

  Widget _buildDateField(AppLocalizations l10n) {
    return InkWell(
      onTap: _isLoading ? null : _selectDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.green[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.purchaseDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(_selectedDate),
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField(AppLocalizations l10n) {
    return TextFormField(
      controller: _notesController,
      decoration: InputDecoration(
        labelText: l10n.notes,
        hintText: l10n.optionalNotes,
        prefixIcon: Icon(Icons.note, color: Colors.green[600]),
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
        alignLabelWithHint: true,
      ),
      maxLines: 3,
      maxLength: 1000,
      textCapitalization: TextCapitalization.sentences,
      enabled: !_isLoading,
    );
  }

  Widget _buildButtons(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
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
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,
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
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Text(
                      l10n.add,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final l10n = AppLocalizations.of(context)!;

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 730)), // 2 ans
      lastDate: DateTime.now(),
      helpText: l10n.selectDate,
      cancelText: l10n.cancel,
      confirmText: l10n.confirm,
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final storeName = _storeNameController.text.trim();
    final amount = double.parse(_amountController.text);
    final notes =
        _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim();

    context.read<ReceiptBloc>().add(
      CreateReceipt(
        listId: widget.listId,
        storeName: storeName,
        totalAmount: amount,
        purchaseDate: _selectedDate,
        notes: notes,
      ),
    );

    Navigator.pop(context);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return AppLocalizations.of(context)!.today;
    } else if (difference == 1) {
      return AppLocalizations.of(context)!.yesterday;
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
