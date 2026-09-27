// widgets/dialogs/edit_list_dialog.dart - Renommer une liste : en-tête
// compact, un champ, deux boutons. Styles du thème.
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/app_dialog.dart';
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

  void _updateList() {
    if (nameController.text.trim().isEmpty) return;
    context.read<ShoppingListBloc>().add(
      UpdateShoppingList(widget.list.id, nameController.text.trim()),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppDialogHeader(
              icon: Icons.edit_outlined,
              title: l10n.editListName,
            ),
            const SizedBox(height: AppSpacing.md + 4),
            TextField(
              controller: nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.listName),
              onSubmitted: (_) => _updateList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            BlocBuilder<ShoppingListBloc, ShoppingListState>(
              builder:
                  (context, state) => AppDialogActions(
                    cancelLabel: l10n.cancel,
                    submitLabel: l10n.save,
                    loading: state is ShoppingListLoading,
                    onSubmit: _updateList,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
