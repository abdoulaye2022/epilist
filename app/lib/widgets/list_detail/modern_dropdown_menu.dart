// widgets/list_detail/modern_dropdown_menu.dart - MENU SIMPLE INSPIRÉ DU SHOPPING CARD
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:flutter/material.dart';

class ModernDropdownMenu extends StatelessWidget {
  final ShoppingList shoppingList;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onManageShares;
  final VoidCallback? onInfo;
  final VoidCallback? onLeave;
  final VoidCallback? onDelete;

  const ModernDropdownMenu({
    super.key,
    required this.shoppingList,
    this.onEdit,
    this.onShare,
    this.onManageShares,
    this.onInfo,
    this.onLeave,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
      onSelected: (value) => _handleMenuAction(value, context),
      itemBuilder: (context) => _buildMenuItems(context),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    List<PopupMenuEntry<String>> items = [];

    // Modifier la liste (si permission)
    if (shoppingList.canEdit && onEdit != null) {
      items.add(
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20, color: Colors.blue[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.editList,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Partager (si permission)
    if (shoppingList.canShare && onShare != null) {
      items.add(
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, size: 20, color: Colors.green[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.shareList,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Gérer les partages (si propriétaire et liste partagée)
    if (shoppingList.isOwner &&
        shoppingList.isShared &&
        onManageShares != null) {
      items.add(
        PopupMenuItem(
          value: 'manage_shares',
          child: Row(
            children: [
              Icon(Icons.people_outline, size: 20, color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.manageShares,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Informations
    if (onInfo != null) {
      items.add(
        PopupMenuItem(
          value: 'info',
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.listInformation,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Séparateur avant actions destructives
    if ((shoppingList.canDelete && onDelete != null) ||
        (!shoppingList.isOwner && onLeave != null)) {
      items.add(const PopupMenuDivider());
    }

    // Quitter la liste partagée (si pas propriétaire)
    if (!shoppingList.isOwner && onLeave != null) {
      items.add(
        PopupMenuItem(
          value: 'leave',
          child: Row(
            children: [
              Icon(Icons.exit_to_app, size: 20, color: Colors.orange[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.leaveList,
                  style: TextStyle(color: Colors.orange[600]),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
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
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.deleteList,
                  style: TextStyle(color: Colors.red[600]),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
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
      case 'manage_shares':
        onManageShares?.call();
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
