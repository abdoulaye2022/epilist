import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteListDialog extends StatelessWidget {
  final ShoppingList list;

  const DeleteListDialog({super.key, required this.list});

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
            // Icône de suppression
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.delete_rounded,
                size: 40,
                color: Colors.red[600],
              ),
            ),

            const SizedBox(height: 20),

            // Titre
            Text(
              l10n.deleteListTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 12),

            // Message
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                children: [
                  TextSpan(text: l10n.sureToDeleteList),
                  TextSpan(
                    text: ' "${list.name}"',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const TextSpan(text: ' ?'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Text(
              l10n.actionIrreversible,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 24),

            // Boutons
            Row(
              children: [
                // Bouton Annuler
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

                // Bouton Supprimer
                Expanded(
                  child: BlocBuilder<ShoppingListBloc, ShoppingListState>(
                    builder: (context, state) {
                      final isLoading = state is ShoppingListLoading;
                      return ElevatedButton(
                        onPressed:
                            isLoading ? null : () => _deleteList(context),
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
            ),
          ],
        ),
      ),
    );
  }

  void _deleteList(BuildContext context) {
    context.read<ShoppingListBloc>().add(DeleteShoppingList(list.id));
    Navigator.pop(context);
  }
}
