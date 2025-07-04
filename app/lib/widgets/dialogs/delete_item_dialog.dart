import 'package:epilist/blocs/list_item/list_item_bloc.dart';
import 'package:epilist/models/list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteItemDialog extends StatelessWidget {
  final ListItem item;
  final int listId;

  const DeleteItemDialog({super.key, required this.item, required this.listId});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            SizedBox(height: 20),
            _buildTitle(),
            SizedBox(height: 12),
            _buildMessage(),
            SizedBox(height: 8),
            _buildWarning(),
            SizedBox(height: 24),
            _buildButtons(context),
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

  Widget _buildTitle() {
    return Text(
      'Supprimer l\'article',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildMessage() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
        children: [
          TextSpan(text: 'Êtes-vous sûr de vouloir supprimer '),
          TextSpan(
            text: '"${item.productName}"',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          TextSpan(text: ' de votre liste ?'),
        ],
      ),
    );
  }

  Widget _buildWarning() {
    return Text(
      'Cette action est irréversible.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        color: Colors.red[600],
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12),
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
        SizedBox(width: 12),
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
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child:
                    isLoading
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(
                          'Supprimer',
                          style: TextStyle(
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
