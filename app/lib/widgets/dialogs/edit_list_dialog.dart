import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditListDialog extends StatefulWidget {
  final ShoppingList list;

  const EditListDialog({super.key, required this.list});

  @override
  State<EditListDialog> createState() => _EditListDialogState();
}

class _EditListDialogState extends State<EditListDialog> {
  late final TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.list.name);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
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
            _buildIcon(),
            const SizedBox(height: 20),
            _buildTitle(l10n),
            const SizedBox(height: 12),
            _buildMessage(l10n),
            const SizedBox(height: 24),
            _buildTextField(l10n),
            const SizedBox(height: 24),
            _buildButtons(l10n),
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
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Icon(Icons.edit_rounded, size: 40, color: AppColors.accent),
    );
  }

  Widget _buildTitle(AppLocalizations l10n) {
    return Text(
      l10n.editListName,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildMessage(AppLocalizations l10n) {
    return Text(
      l10n.modifyListName,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.4),
    );
  }

  Widget _buildTextField(AppLocalizations l10n) {
    return TextField(
      controller: nameController,
      decoration: InputDecoration(
        labelText: l10n.listName,
        prefixIcon: Icon(Icons.list_alt, color: AppColors.accent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.accent, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        filled: true,
        fillColor: AppColors.background,
      ),
      autofocus: true,
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
                side: BorderSide(color: AppColors.border),
              ),
            ),
            child: Text(
              l10n.cancel,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: BlocBuilder<ShoppingListBloc, ShoppingListState>(
            builder: (context, state) {
              final isLoading = state is ShoppingListLoading;
              return ElevatedButton(
                onPressed: isLoading ? null : _updateList,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
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
                            color: Colors.white,
                          ),
                        )
                        : Text(
                          l10n.save,
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
    );
  }

  void _updateList() {
    if (nameController.text.trim().isNotEmpty) {
      context.read<ShoppingListBloc>().add(
        UpdateShoppingList(widget.list.id, nameController.text.trim()),
      );
      Navigator.pop(context);
    }
  }
}
