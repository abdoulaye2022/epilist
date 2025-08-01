// widgets/list_detail/list_detail_app_bar.dart - POPUP INFORMATION CORRIGÉ
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
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black87),
      foregroundColor: Colors.black87,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            listName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
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
      icon: const Icon(Icons.more_vert, color: Colors.black87),
      onSelected: (value) => _handleMenuAction(value, context),
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
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 10,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
                maxWidth: 500,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildInfoIcon(),
                          const SizedBox(height: 20),
                          _buildInfoTitle(l10n),
                          const SizedBox(height: 12),
                          _buildInfoDescription(l10n),
                          const SizedBox(height: 24),
                          _buildInfoContent(l10n),
                          const SizedBox(height: 24),
                          _buildCloseButton(l10n, context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildInfoIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(40),
      ),
      child: Icon(
        Icons.info_outline_rounded,
        size: 40,
        color: Colors.blue[600],
      ),
    );
  }

  Widget _buildInfoTitle(AppLocalizations l10n) {
    return Text(
      l10n.listInformation,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildInfoDescription(AppLocalizations l10n) {
    return Text(
      'Détails et permissions de cette liste',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
    );
  }

  Widget _buildInfoContent(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(l10n.name, shoppingList.name),
          const SizedBox(height: 16),
          _buildInfoRow(
            l10n.status,
            shoppingList.isShared ? l10n.sharedList : l10n.private,
          ),
          if (shoppingList.isShared) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              l10n.yourRole,
              shoppingList.isOwner
                  ? l10n.owner
                  : (shoppingList.permissionDisplayName ?? l10n.collaborator),
            ),
            if (!shoppingList.isOwner && shoppingList.sharedBy != null) ...[
              const SizedBox(height: 16),
              // ✅ CORRECTION: Utiliser seulement le label sans le nom en double
              _buildInfoRow(
                'Partagée par', // Label simple
                shoppingList.sharedBy!.name, // Valeur
              ),
            ],
            const SizedBox(height: 20),
            _buildPermissionsList(l10n),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsList(AppLocalizations l10n) {
    List<Map<String, dynamic>> permissions = [];

    if (shoppingList.canEdit) {
      permissions.add({
        'icon': Icons.edit,
        'color': Colors.green[600],
        'text': l10n.editItems,
        'granted': true,
      });
    } else {
      permissions.add({
        'icon': Icons.edit_off,
        'color': Colors.red[400],
        'text': l10n.editItems,
        'granted': false,
      });
    }

    if (shoppingList.canShare) {
      permissions.add({
        'icon': Icons.share,
        'color': Colors.green[600],
        'text': l10n.shareList,
        'granted': true,
      });
    } else {
      permissions.add({
        'icon': Icons.share_outlined,
        'color': Colors.red[400],
        'text': l10n.shareList,
        'granted': false,
      });
    }

    if (shoppingList.canDelete) {
      permissions.add({
        'icon': Icons.delete,
        'color': Colors.green[600],
        'text': l10n.deleteList,
        'granted': true,
      });
    } else {
      permissions.add({
        'icon': Icons.delete_outline,
        'color': Colors.red[400],
        'text': l10n.deleteList,
        'granted': false,
      });
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, size: 18, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(
                '${l10n.permissions}:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...permissions.map(
            (permission) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    permission['icon'] as IconData,
                    size: 18,
                    color: permission['color'] as Color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      permission['text'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            permission['granted']
                                ? Colors.black87
                                : Colors.grey[600],
                        fontWeight:
                            permission['granted']
                                ? FontWeight.w500
                                : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (permission['granted'])
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Text(
                        'Autorisé',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        'Refusé',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton(AppLocalizations l10n, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check, size: 18),
            const SizedBox(width: 8),
            Text(
              l10n.understood,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
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
