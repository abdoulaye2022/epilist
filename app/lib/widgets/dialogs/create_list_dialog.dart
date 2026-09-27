// widgets/dialogs/create_list_dialog.dart - Nouvelle liste : un en-tête
// compact, un champ, deux boutons. Les styles viennent du thème.
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateListDialog extends StatefulWidget {
  const CreateListDialog({super.key});

  @override
  State<CreateListDialog> createState() => _CreateListDialogState();
}

class _CreateListDialogState extends State<CreateListDialog> {
  final nameController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void _createList() {
    if (nameController.text.trim().isEmpty) return;
    context.read<ShoppingListBloc>().add(
      CreateShoppingList(nameController.text.trim()),
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
              icon: Icons.playlist_add_rounded,
              title: l10n.newList,
            ),
            const SizedBox(height: AppSpacing.md + 4),
            TextField(
              controller: nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.listName,
                hintText: l10n.listNameHint,
              ),
              onSubmitted: (_) => _createList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            BlocBuilder<ShoppingListBloc, ShoppingListState>(
              builder:
                  (context, state) => AppDialogActions(
                    cancelLabel: l10n.cancel,
                    submitLabel: l10n.create,
                    loading: state is ShoppingListLoading,
                    onSubmit: _createList,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
