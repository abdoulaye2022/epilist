// widgets/list_detail/modern_dropdown_menu.dart
import 'package:epilist/models/shopping_list.dart';
import 'package:flutter/material.dart';

class ModernDropdownMenu extends StatelessWidget {
  final ShoppingList shoppingList;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onInfo;
  final VoidCallback? onManageShares;
  final VoidCallback? onLeave;
  final VoidCallback? onDelete;

  const ModernDropdownMenu({
    super.key,
    required this.shoppingList,
    this.onEdit,
    this.onShare,
    this.onInfo,
    this.onManageShares,
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

  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    List<PopupMenuEntry<String>> items = [];

    // Section: Actions principales
    if (onEdit != null) {
      items.add(
        _buildMenuItem(
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

    if (onShare != null) {
      items.add(
        _buildMenuItem(
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

    // Section: Informations
    if (onInfo != null) {
      if (items.isNotEmpty) items.add(const PopupMenuDivider());

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
      );
    }

    // Section: Actions destructives
    if (onLeave != null || onDelete != null) {
      if (items.isNotEmpty) items.add(const PopupMenuDivider());
    }

    if (onLeave != null) {
      items.add(
        _buildMenuItem(
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

    if (onDelete != null) {
      items.add(
        _buildMenuItem(
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

  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    bool isDestructive = false,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    isDestructive
                        ? color.withOpacity(0.1)
                        : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? color : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isDestructive
                              ? color.withOpacity(0.8)
                              : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuSelection(String value, BuildContext context) {
    switch (value) {
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
