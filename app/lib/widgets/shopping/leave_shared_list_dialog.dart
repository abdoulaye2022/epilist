// widgets/shopping/leave_shared_list_dialog.dart
import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_event.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LeaveSharedListDialog extends StatelessWidget {
  final ShoppingList list;

  const LeaveSharedListDialog({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.exit_to_app, color: Colors.orange[600]),
          SizedBox(width: 8),
          Text('Quitter la liste'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Êtes-vous sûr de vouloir quitter "${list.name}" ?'),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orange[600], size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vous perdrez l\'accès à cette liste et à tous ses éléments.',
                    style: TextStyle(fontSize: 13, color: Colors.orange[700]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            context.read<SharedListBloc>().add(LeaveSharedList(list.id));
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[600]),
          child: Text('Quitter', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
