// widgets/dialogs/delete_list_dialog.dart - Confirmation de suppression :
// en-tête compact rouge, message court, deux boutons.
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteListDialog extends StatelessWidget {
  final ShoppingList list;

  const DeleteListDialog({super.key, required this.list});

  void _deleteList(BuildContext context) {
    context.read<ShoppingListBloc>().add(DeleteShoppingList(list.id));
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
              title: l10n.deleteListTitle,
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
                  TextSpan(text: l10n.sureToDeleteList),
                  TextSpan(
                    text: ' « ${list.name} »',
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
            BlocBuilder<ShoppingListBloc, ShoppingListState>(
              builder:
                  (context, state) => AppDialogActions(
                    cancelLabel: l10n.cancel,
                    submitLabel: l10n.delete,
                    destructive: true,
                    loading: state is ShoppingListLoading,
                    onSubmit: () => _deleteList(context),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
