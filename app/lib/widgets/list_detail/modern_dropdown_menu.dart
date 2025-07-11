// widgets/list_detail/modern_dropdown_menu.dart - VERSION COMPLÈTE
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      offset: const Offset(0, 8),
      itemBuilder: (context) => _buildMenuItems(),
      onSelected: (value) => _handleMenuSelection(value, context),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems() {
    List<PopupMenuEntry<String>> items = [];

    // Section: Actions principales
    if (onEdit != null) {
      items.add(
        _buildMenuItem(
          value: 'edit',
          icon: Icons.edit_rounded,
          title: 'Modifier la liste',
          subtitle: 'Changer le nom',
          color: Colors.blue[600]!,
        ),
      );
    }

    if (onShare != null) {
      items.add(
        _buildMenuItem(
          value: 'share',
          icon: Icons.share_rounded,
          title: 'Partager',
          subtitle: 'Inviter des collaborateurs',
          color: Colors.green[600]!,
        ),
      );
    }

    // Section: Gestion des partages (si applicable)
    if (onManageShares != null) {
      if (items.isNotEmpty) items.add(const PopupMenuDivider());

      items.add(
        _buildMenuItem(
          value: 'manage_shares',
          icon: Icons.people_alt_rounded,
          title: 'Gérer les partages',
          subtitle: 'Permissions et collaborateurs',
          color: Colors.purple[600]!,
        ),
      );
    }

    // Section: Informations
    if (onInfo != null) {
      if (items.isNotEmpty) items.add(const PopupMenuDivider());

      items.add(
        _buildMenuItem(
          value: 'info',
          icon: Icons.info_rounded,
          title: 'Informations',
          subtitle: 'Détails de la liste',
          color: Colors.blue[600]!,
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
          icon: Icons.exit_to_app_rounded,
          title: 'Quitter la liste',
          subtitle: 'Perdre l\'accès',
          color: Colors.orange[600]!,
          isDestructive: true,
        ),
      );
    }

    if (onDelete != null) {
      items.add(
        _buildMenuItem(
          value: 'delete',
          icon: Icons.delete_rounded,
          title: 'Supprimer',
          subtitle: 'Action irréversible',
          color: Colors.red[600]!,
          isDestructive: true,
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
