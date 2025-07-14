import 'package:epilist/blocs/list_item/list_item_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteItemDialog extends StatelessWidget {
  final ListItem item;
  final int listId;

  const DeleteItemDialog({super.key, required this.item, required this.listId});

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
            const SizedBox(height: 8),
            _buildWarning(l10n),
            const SizedBox(height: 24),
            _buildButtons(context, l10n),
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
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(40),
      ),
      child: Icon(Icons.delete_rounded, size: 40, color: Colors.red[600]),
    );
  }

  Widget _buildTitle(AppLocalizations l10n) {
    return Text(
      l10n.deleteItemTitle,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildMessage(AppLocalizations l10n) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
        children: [
          TextSpan(text: l10n.sureToDeleteItem),
          TextSpan(
            text: ' "${item.productName}"',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          TextSpan(text: ' ${l10n.sureToLeaveQuestion}?'),
        ],
      ),
    );
  }

  Widget _buildWarning(AppLocalizations l10n) {
    return Text(
      l10n.actionIrreversible,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        color: Colors.red[600],
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildButtons(BuildContext context, AppLocalizations l10n) {
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
                onPressed: isLoading ? null : () => _deleteItem(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.red[300],
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
                          l10n.delete,
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

  void _deleteItem(BuildContext context) {
    context.read<ListItemBloc>().add(
      DeleteListItem(listId: listId, itemId: item.id),
    );
    Navigator.pop(context);
  }
}
