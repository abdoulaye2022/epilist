// widgets/list_detail/modern_dropdown_menu.dart - MENU COMPLET AVEC TOUTES LES FONCTIONNALITÉS
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
      icon: Icon(Icons.more_vert, color: Colors.grey[700]),
      onSelected: (value) => _handleMenuAction(value, context),
      itemBuilder: (context) => _buildMenuItems(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      offset: const Offset(0, 10),
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
          child: _buildMenuItem(
            icon: Icons.edit_outlined,
            title: l10n.editList,
            subtitle: 'Nom, description...',
            color: Colors.blue[600]!,
          ),
        ),
      );
    }

    // Partager (si permission)
    if (shoppingList.canShare && onShare != null) {
      items.add(
        PopupMenuItem(
          value: 'share',
          child: _buildMenuItem(
            icon: Icons.share_outlined,
            title: l10n.shareList,
            subtitle: 'Créer un lien de partage',
            color: Colors.green[600]!,
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
          child: _buildMenuItem(
            icon: Icons.people_outline,
            title: l10n.manageShares,
            subtitle: 'Voir les collaborateurs',
            color: Colors.purple[600]!,
          ),
        ),
      );
    }

    // Informations
    if (onInfo != null) {
      items.add(
        PopupMenuItem(
          value: 'info',
          child: _buildMenuItem(
            icon: Icons.info_outline,
            title: l10n.listInformation,
            subtitle: 'Détails et permissions',
            color: Colors.grey[600]!,
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
          child: _buildMenuItem(
            icon: Icons.exit_to_app_outlined,
            title: l10n.leaveList,
            subtitle: 'Perdre l\'accès à cette liste',
            color: Colors.orange[600]!,
          ),
        ),
      );
    }

    // Supprimer (si permission)
    if (shoppingList.canDelete && onDelete != null) {
      items.add(
        PopupMenuItem(
          value: 'delete',
          child: _buildMenuItem(
            icon: Icons.delete_outline,
            title: l10n.deleteList,
            subtitle: 'Action irréversible',
            color: Colors.red[600]!,
          ),
        ),
      );
    }

    return items;
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
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
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
