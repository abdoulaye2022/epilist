// widgets/shopping/manage_shares_dialog.dart
import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_event.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/widgets/share_list_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManageSharesDialog extends StatelessWidget {
  final ShoppingList list;

  const ManageSharesDialog({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        constraints: BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            SizedBox(height: 16),
            Text(
              'Liste: ${list.name}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            Expanded(child: _buildSharesList(context)),
            SizedBox(height: 16),
            _buildCreateNewShareButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Gérer les partages',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildSharesList(BuildContext context) {
    if (list.sharedWith.isEmpty) {
      return Center(
        child: Text(
          'Aucun partage actif',
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }

    return ListView.builder(
      itemCount: list.sharedWith.length,
      itemBuilder: (context, index) {
        final share = list.sharedWith[index];
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.person, color: Colors.blue[600]),
            ),
            title: Text(share.sharedWithUser?.name ?? 'Utilisateur'),
            subtitle: Text(share.sharedWithUser?.email ?? ''),
            trailing: PopupMenuButton(
              icon: Icon(Icons.more_vert),
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: 'change_permission',
                      child: Text('Modifier permissions'),
                    ),
                    PopupMenuItem(
                      value: 'revoke',
                      child: Text(
                        'Révoquer',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
              onSelected: (value) {
                if (value == 'revoke') {
                  context.read<SharedListBloc>().add(RevokeShare(share.id));
                  Navigator.pop(context);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCreateNewShareButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          _showShareDialog(context);
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600]),
        child: Text(
          'Créer un nouveau partage',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<SharedListBloc>(),
            child: ShareListDialog(listId: list.id, listName: list.name),
          ),
    );
  }
}
