// widgets/dialogs/delete_item_dialog.dart - Confirmation de suppression
// d'un article : en-tête compact rouge, message court, deux boutons.
import 'package:epilist/blocs/list_item/list_item_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/list_item.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteItemDialog extends StatelessWidget {
  final ListItem item;
  final int listId;

  const DeleteItemDialog({super.key, required this.item, required this.listId});

  void _deleteItem(BuildContext context) {
    context.read<ListItemBloc>().add(
      DeleteListItem(listId: listId, itemId: item.id),
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
              icon: Icons.delete_outline,
              title: l10n.deleteItemTitle,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                children: [
                  TextSpan(text: l10n.sureToDeleteItem),
                  TextSpan(
                    text: ' « ${item.productName} »',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const TextSpan(text: ' ?'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.actionIrreversible,
              style: const TextStyle(fontSize: 12.5, color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.lg),
            BlocBuilder<ListItemBloc, ListItemState>(
              builder:
                  (context, state) => AppDialogActions(
                    cancelLabel: l10n.cancel,
                    submitLabel: l10n.delete,
                    destructive: true,
                    loading: state is ListItemLoading,
                    onSubmit: () => _deleteItem(context),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
