// widgets/list_detail/list_detail_app_bar.dart - VERSION AVEC PERMISSIONS
import 'package:epilist/models/shopping_list.dart';
import 'package:flutter/material.dart';

class ListDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String listName;
  final ShoppingList shoppingList;
  final VoidCallback? onAddItem;
  final VoidCallback? onShare;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ListDetailAppBar({
    super.key,
    required this.listName,
    required this.shoppingList,
    this.onAddItem,
    this.onShare,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            listName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (shoppingList.isShared) _buildSharingSubtitle(),
        ],
      ),
      backgroundColor: Colors.green[600],
      foregroundColor: Colors.white,
      elevation: 2,
      actions: _buildActions(context),
    );
  }

  Widget _buildSharingSubtitle() {
    String subtitle;
    if (shoppingList.isOwner) {
      subtitle = 'Liste partagée';
    } else {
      subtitle = shoppingList.permissionDisplayName ?? 'Liste partagée';
    }

    return Text(
      subtitle,
      style: TextStyle(
        fontSize: 12,
        color: Colors.white.withOpacity(0.9),
        fontWeight: FontWeight.normal,
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    List<Widget> actions = [];

    // Bouton d'ajout d'article (si permission)
    if (shoppingList.canManageItems && onAddItem != null) {
      actions.add(
        IconButton(
          onPressed: onAddItem,
          icon: Icon(Icons.add),
          tooltip: 'Ajouter un article',
        ),
      );
    }

    // Menu des options
    actions.add(_buildOptionsMenu(context));

    return actions;
  }

  Widget _buildOptionsMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert),
      onSelected: (value) => _handleMenuAction(value, context),
      itemBuilder: (context) => _buildMenuItems(),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems() {
    List<PopupMenuEntry<String>> items = [];

    // Modifier la liste (si permission)
    if (shoppingList.canEdit && onEdit != null) {
      items.add(
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20, color: Colors.blue[600]),
              SizedBox(width: 8),
              Text('Modifier la liste'),
            ],
          ),
        ),
      );
    }

    // Partager (si propriétaire ou admin)
    if (shoppingList.canShare && onShare != null) {
      items.add(
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, size: 20, color: Colors.green[600]),
              SizedBox(width: 8),
              Text('Partager'),
            ],
          ),
        ),
      );
    }

    // Informations sur les permissions
    items.add(
      PopupMenuItem(
        value: 'permissions',
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
            SizedBox(width: 8),
            Text('Informations'),
          ],
        ),
      ),
    );

    // Séparateur avant actions destructives
    if (shoppingList.canDelete || !shoppingList.isOwner) {
      items.add(PopupMenuDivider());
    }

    // Quitter la liste partagée (si pas propriétaire)
    if (!shoppingList.isOwner) {
      items.add(
        PopupMenuItem(
          value: 'leave',
          child: Row(
            children: [
              Icon(Icons.exit_to_app, size: 20, color: Colors.orange[600]),
              SizedBox(width: 8),
              Text(
                'Quitter la liste',
                style: TextStyle(color: Colors.orange[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Supprimer (si permission)
    if (shoppingList.canDelete && onDelete != null) {
      items.add(
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red[600]),
              SizedBox(width: 8),
              Text('Supprimer', style: TextStyle(color: Colors.red[600])),
            ],
          ),
        ),
      );
    }

    return items;
  }

  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'edit':
        onEdit?.call();
        break;
      case 'share':
        onShare?.call();
        break;
      case 'permissions':
        _showPermissionsDialog(context);
        break;
      case 'leave':
        _showLeaveDialog(context);
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }

  void _showPermissionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600]),
                SizedBox(width: 8),
                Text('Informations de la liste'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Nom', shoppingList.name),
                SizedBox(height: 8),
                _buildInfoRow(
                  'Statut',
                  shoppingList.isShared ? 'Partagée' : 'Privée',
                ),
                if (shoppingList.isShared) ...[
                  SizedBox(height: 8),
                  _buildInfoRow(
                    'Votre rôle',
                    shoppingList.isOwner
                        ? 'Propriétaire'
                        : (shoppingList.permissionDisplayName ??
                            'Collaborateur'),
                  ),
                  if (!shoppingList.isOwner &&
                      shoppingList.sharedBy != null) ...[
                    SizedBox(height: 8),
                    _buildInfoRow('Partagée par', shoppingList.sharedBy!.name),
                  ],
                  SizedBox(height: 8),
                  _buildPermissionsList(),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Fermer'),
              ),
            ],
          ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(child: Text(value, style: TextStyle(color: Colors.black87))),
      ],
    );
  }

  Widget _buildPermissionsList() {
    List<String> permissions = [];

    if (shoppingList.canEdit) {
      permissions.add('✅ Modifier les articles');
    } else {
      permissions.add('❌ Modifier les articles');
    }

    if (shoppingList.canShare) {
      permissions.add('✅ Partager la liste');
    } else {
      permissions.add('❌ Partager la liste');
    }

    if (shoppingList.canDelete) {
      permissions.add('✅ Supprimer la liste');
    } else {
      permissions.add('❌ Supprimer la liste');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Permissions:',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 4),
        ...permissions.map(
          (permission) => Padding(
            padding: EdgeInsets.only(left: 8, top: 2),
            child: Text(
              permission,
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ),
      ],
    );
  }

  void _showLeaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Quitter la liste'),
            content: Text(
              'Êtes-vous sûr de vouloir quitter "${shoppingList.name}" ?\n\n'
              'Vous perdrez l\'accès à cette liste et ne pourrez plus voir son contenu.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // TODO: Implémenter la logique de quitter la liste
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Vous avez quitté la liste "${shoppingList.name}"',
                      ),
                      backgroundColor: Colors.orange[600],
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                child: Text('Quitter'),
              ),
            ],
          ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
