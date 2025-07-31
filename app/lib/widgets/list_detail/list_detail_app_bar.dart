// widgets/list_detail/list_detail_app_bar.dart - CORRIGÉ AVEC FOND BLANC UNIFORME
import 'package:epilist/blocs/localization/localization_bloc.dart';
import 'package:epilist/blocs/receipt/receipt_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/screens/receipts_screen.dart';
import 'package:epilist/services/receipt_service.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      // ✅ FOND BLANC UNIFORME (comme HomeAppBar)
      backgroundColor: Colors.white,

      // ✅ SUPPRESSION DE L'OMBRE (comme HomeAppBar)
      elevation: 0,

      // ✅ COULEUR DES ICÔNES NOIRE POUR FOND BLANC
      iconTheme: const IconThemeData(color: Colors.black87),

      // ✅ COULEUR DU TEXTE DE L'APPBAR
      foregroundColor: Colors.black87,

      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            listName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              // ✅ COULEUR NOIRE POUR FOND BLANC
              color: Colors.black87,
            ),
          ),
          if (shoppingList.isShared) _buildSharingSubtitle(context),
        ],
      ),
      actions: _buildActions(context),
    );
  }

  Widget _buildSharingSubtitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String subtitle;
    Color subtitleColor;

    if (shoppingList.isOwner) {
      subtitle = l10n.sharedList;
      subtitleColor = Colors.blue[600]!;
    } else {
      subtitle = shoppingList.permissionDisplayName ?? l10n.sharedList;
      subtitleColor =
          shoppingList.isReadOnly ? Colors.blue[600]! : Colors.green[600]!;
    }

    return Text(
      subtitle,
      style: TextStyle(
        fontSize: 12,
        // ✅ COULEUR COLORÉE POUR CONTRASTE SUR FOND BLANC
        color: subtitleColor,
        fontWeight: FontWeight.normal,
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    List<Widget> actions = [];

    // Bouton d'ajout d'article (si permission)
    if (shoppingList.canManageItems && onAddItem != null) {
      actions.add(
        IconButton(
          onPressed: onAddItem,
          // ✅ ICÔNE NOIRE POUR FOND BLANC
          icon: const Icon(Icons.add, color: Colors.black87),
          tooltip: l10n.addItemTooltip,
        ),
      );
    }

    // Menu des options
    actions.add(_buildOptionsMenu(context));

    return actions;
  }

  Widget _buildOptionsMenu(BuildContext context) {
    return PopupMenuButton<String>(
      // ✅ ICÔNE NOIRE POUR FOND BLANC
      icon: const Icon(Icons.more_vert, color: Colors.black87),
      onSelected: (value) => _handleMenuAction(value, context),
      // ✅ STYLE POUR FOND BLANC UNIFORME
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 8,
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
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.editList,
                  style: const TextStyle(color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.share,
                  style: const TextStyle(color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.information,
                style: const TextStyle(color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    // Factures
    items.add(
      PopupMenuItem(
        value: 'receipts',
        child: Row(
          children: [
            Icon(Icons.receipt_long, size: 20, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.receipts,
                style: const TextStyle(color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    // Séparateur avant actions destructives
    if (shoppingList.canDelete || !shoppingList.isOwner) {
      items.add(const PopupMenuDivider());
    }

    // Quitter la liste partagée (si pas propriétaire)
    if (!shoppingList.isOwner) {
      items.add(
        PopupMenuItem(
          value: 'leave',
          child: Row(
            children: [
              Icon(Icons.exit_to_app, size: 20, color: Colors.orange[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.leaveList,
                  style: TextStyle(color: Colors.orange[600]),
                  overflow: TextOverflow.ellipsis,
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
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.delete,
                  style: TextStyle(color: Colors.red[600]),
                  overflow: TextOverflow.ellipsis,
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
      case 'permissions':
        _showPermissionsDialog(context);
        break;
      case 'leave':
        _showLeaveDialog(context);
        break;
      case 'delete':
        onDelete?.call();
        break;
      case 'receipts':
        _openReceiptsScreen(context);
        break;
    }
  }

  void _showPermissionsDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            // ✅ FOND BLANC POUR LA DIALOG
            backgroundColor: Colors.white,
            title: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.listInformation,
                    style: const TextStyle(color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(l10n.name, shoppingList.name),
                const SizedBox(height: 8),
                _buildInfoRow(
                  l10n.status,
                  shoppingList.isShared ? l10n.sharedList : l10n.private,
                ),
                if (shoppingList.isShared) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    l10n.yourRole,
                    shoppingList.isOwner
                        ? l10n.owner
                        : (shoppingList.permissionDisplayName ??
                            l10n.collaborator),
                  ),
                  if (!shoppingList.isOwner &&
                      shoppingList.sharedBy != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(l10n.sharedBy, shoppingList.sharedBy!.name),
                  ],
                  const SizedBox(height: 8),
                  _buildPermissionsList(context),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.close),
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
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsList(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    List<String> permissions = [];

    if (shoppingList.canEdit) {
      permissions.add('✅ ${l10n.editItems}');
    } else {
      permissions.add('❌ ${l10n.editItems}');
    }

    if (shoppingList.canShare) {
      permissions.add('✅ ${l10n.shareList}');
    } else {
      permissions.add('❌ ${l10n.shareList}');
    }

    if (shoppingList.canDelete) {
      permissions.add('✅ ${l10n.deleteList}');
    } else {
      permissions.add('❌ ${l10n.deleteList}');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.permissions}:',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        ...permissions.map(
          (permission) => Padding(
            padding: const EdgeInsets.only(left: 8, top: 2),
            child: Text(
              permission,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ),
      ],
    );
  }

  void _openReceiptsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BlocProvider(
              create:
                  (context) => ReceiptBloc(
                    receiptService: context.read<ReceiptService>(),
                    localizationBloc: context.read<LocalizationBloc>(),
                  ),
              child: ReceiptsScreen(shoppingList: shoppingList),
            ),
      ),
    );
  }

  void _showLeaveDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            // ✅ FOND BLANC POUR LA DIALOG
            backgroundColor: Colors.white,
            title: Text(
              l10n.leaveList,
              style: const TextStyle(color: Colors.black87),
            ),
            content: Text(
              l10n.leaveListConfirm(shoppingList.name),
              style: const TextStyle(color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  SmartSnackBarManager.showWarningSnackBar(
                    context,
                    l10n.leftList(shoppingList.name),
                    duration: const Duration(seconds: 3),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                child: Text(l10n.leave),
              ),
            ],
          ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
