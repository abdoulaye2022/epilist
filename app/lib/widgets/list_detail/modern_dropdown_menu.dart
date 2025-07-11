// widgets/list_detail/modern_dropdown_menu.dart
import 'package:epilist/models/shopping_list.dart';
import 'package:flutter/material.dart';

class ModernDropdownMenu extends StatelessWidget {
  final ShoppingList shoppingList;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onInfo;
  final VoidCallback? onLeave;
  final VoidCallback? onDelete;

  const ModernDropdownMenu({
    super.key,
    required this.shoppingList,
    this.onEdit,
    this.onShare,
    this.onInfo,
    this.onLeave,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) => _handleMenuAction(value, context),
      itemBuilder: (context) => _buildMenuItems(),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems() {
    List<PopupMenuEntry<String>> items = [];

    if (shoppingList.canEdit && onEdit != null) {
      items.add(
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20, color: Colors.blue[600]),
              const SizedBox(width: 8),
              const Text('Modifier la liste'),
            ],
          ),
        ),
      );
    }

    if (shoppingList.canShare && onShare != null) {
      items.add(
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, size: 20, color: Colors.green[600]),
              const SizedBox(width: 8),
              const Text('Partager'),
            ],
          ),
        ),
      );
    }

    items.add(
      PopupMenuItem(
        value: 'info',
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            const Text('Informations'),
          ],
        ),
      ),
    );

    if (!shoppingList.isOwner || (shoppingList.canDelete && onDelete != null)) {
      items.add(const PopupMenuDivider());
    }

    if (!shoppingList.isOwner) {
      items.add(
        PopupMenuItem(
          value: 'leave',
          child: Row(
            children: [
              Icon(Icons.exit_to_app, size: 20, color: Colors.orange[600]),
              const SizedBox(width: 8),
              Text('Quitter', style: TextStyle(color: Colors.orange[600])),
            ],
          ),
        ),
      );
    }

    if (shoppingList.canDelete && onDelete != null) {
      items.add(
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red[600]),
              const SizedBox(width: 8),
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
      case 'info':
        onInfo?.call();
        break;
      case 'leave':
        onLeave?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }
}
