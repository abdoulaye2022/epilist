// widgets/list_detail/list_item_card.dart - VERSION CORRIGÉE AVEC TRADUCTIONS
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/list_item.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:flutter/material.dart';

class ListItemCard extends StatelessWidget {
  final ListItem item;
  final Function(bool)? onTogglePurchased;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final ShoppingList shoppingList;

  const ListItemCard({
    super.key,
    required this.item,
    required this.shoppingList,
    this.onTogglePurchased,
    this.onDelete,
    this.onEdit,
  });

  String _formatPrice(BuildContext context, double price) {
    final l10n = AppLocalizations.of(context)!;
    return '${price.toStringAsFixed(2)}${l10n.cad}';
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = shoppingList.canEdit;
    final isReadOnly = shoppingList.isReadOnly;
    final canToggle =
        !isReadOnly; // Peut cocher/décocher si pas en lecture seule

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _getCardBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: _getBorder(),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap:
              canToggle
                  ? () => onTogglePurchased?.call(!item.isPurchased)
                  : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildCheckbox(canToggle),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 8),
                      _buildDetails(context),
                      if (_shouldShowPermissionInfo()) ...[
                        const SizedBox(height: 8),
                        _buildPermissionChip(context),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildTrailing(canToggle, canEdit, context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCardBackgroundColor() {
    return Colors.white;
  }

  Border? _getBorder() {
    if (item.isPurchased) {
      return Border.all(color: Colors.green[200]!, width: 1);
    } else if (shoppingList.isReadOnly) {
      return Border.all(color: Colors.blue[200]!, width: 1.5);
    }
    return null;
  }

  Widget _buildCheckbox(bool canToggle) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getCheckboxColor(),
        border: Border.all(color: _getCheckboxBorderColor(), width: 2),
      ),
      child:
          item.isPurchased
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : null,
    );
  }

  Color _getCheckboxColor() {
    if (item.isPurchased) return Colors.green[600]!;
    if (shoppingList.isReadOnly) return Colors.grey[300]!;
    return Colors.transparent;
  }

  Color _getCheckboxBorderColor() {
    if (item.isPurchased) return Colors.green[600]!;
    if (shoppingList.isReadOnly) return Colors.grey[400]!;
    return Colors.grey[500]!;
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            item.productName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              decoration: item.isPurchased ? TextDecoration.lineThrough : null,
              color: _getTitleColor(),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (shoppingList.isReadOnly) ...[
          const SizedBox(width: 8),
          _buildReadOnlyBadge(context),
        ],
      ],
    );
  }

  Color _getTitleColor() {
    if (item.isPurchased) return Colors.grey[500]!;
    if (shoppingList.isReadOnly) return Colors.blue[700]!;
    return Colors.black87;
  }

  Widget _buildReadOnlyBadge(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility, size: 10, color: Colors.blue[600]),
          const SizedBox(width: 2),
          Text(
            l10n.readOnlyShort,
            style: TextStyle(
              fontSize: 9,
              color: Colors.blue[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 250;

        if (isSmallScreen && item.price != null) {
          // Layout vertical pour très petits écrans
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailChip(
                icon: Icons.shopping_basket_outlined,
                text: '${l10n.quantityShort}: ${item.quantity}',
                color: Colors.grey[600]!,
              ),
              const SizedBox(height: 6),
              _buildDetailChip(
                icon: Icons.attach_money,
                text: _formatPrice(context, item.price!),
                color: Colors.green[600]!,
              ),
              if (item.storeName != null && item.storeName!.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildStoreInfo(),
              ],
            ],
          );
        } else {
          // Layout horizontal pour écrans normaux
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne quantité et prix
              Row(
                children: [
                  _buildDetailChip(
                    icon: Icons.shopping_basket_outlined,
                    text: '${l10n.quantityShort}: ${item.quantity}',
                    color: Colors.grey[600]!,
                  ),
                  if (item.price != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDetailChip(
                        icon: Icons.attach_money,
                        text: _formatPrice(context, item.price!),
                        color: Colors.green[600]!,
                      ),
                    ),
                  ],
                ],
              ),
              // Magasin si disponible
              if (item.storeName != null && item.storeName!.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildStoreInfo(),
              ],
            ],
          );
        }
      },
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.store, size: 12, color: Colors.purple[600]),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              item.storeName!,
              style: TextStyle(
                fontSize: 11,
                color: Colors.purple[600],
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowPermissionInfo() {
    return !shoppingList.isOwner && !shoppingList.isReadOnly;
  }

  Widget _buildPermissionChip(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String permissionText;
    Color permissionColor;
    IconData permissionIcon;

    if (shoppingList.canEdit) {
      permissionText = l10n.modification;
      permissionColor = Colors.green[600]!;
      permissionIcon = Icons.edit;
    } else if (!shoppingList.isReadOnly) {
      permissionText = l10n.consultation;
      permissionColor = Colors.blue[600]!;
      permissionIcon = Icons.check_circle_outline;
    } else {
      permissionText = l10n.limitedAccess;
      permissionColor = Colors.orange[600]!;
      permissionIcon = Icons.lock;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: permissionColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: permissionColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(permissionIcon, size: 10, color: permissionColor),
          const SizedBox(width: 2),
          Text(
            permissionText,
            style: TextStyle(
              fontSize: 9,
              color: permissionColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailing(bool canToggle, bool canEdit, BuildContext context) {
    // Icône de verrouillage si aucune permission
    if (!canToggle && !canEdit) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.lock, color: Colors.grey[400], size: 16),
      );
    }

    // Icône de validation si seulement toggle mais pas d'édition
    if (canToggle && !canEdit) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green[50],
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_circle_outline,
          color: Colors.green[400],
          size: 16,
        ),
      );
    }

    // Menu complet si édition possible
    if (canEdit) {
      return PopupMenuButton<String>(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.more_vert, color: Colors.grey[600], size: 16),
        ),
        onSelected: (value) => _handleMenuAction(value, context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        itemBuilder: (context) => _buildMenuItems(context),
      );
    }

    // Cas par défaut - ne devrait pas arriver
    return const SizedBox.shrink();
  }

  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    List<PopupMenuEntry<String>> items = [];

    // Modifier
    if (onEdit != null) {
      items.add(
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(l10n.edit),
            ],
          ),
        ),
      );
    }

    // Supprimer
    if (onDelete != null) {
      items.add(
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red[600]),
              const SizedBox(width: 8),
              Text(l10n.delete, style: TextStyle(color: Colors.red[600])),
            ],
          ),
        ),
      );
    }

    return items;
  }

  void _handleMenuAction(String action, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (shoppingList.isReadOnly) {
      _showPermissionDenied(context, l10n.modifyThisList);
      return;
    }

    switch (action) {
      case 'edit':
        if (shoppingList.canEdit) {
          onEdit?.call();
        } else {
          _showPermissionDenied(context, l10n.modifyThisItem);
        }
        break;
      case 'delete':
        if (shoppingList.canEdit) {
          _showDeleteConfirmation(context);
        } else {
          _showPermissionDenied(context, l10n.deleteThisItem);
        }
        break;
    }
  }

  void _showPermissionDenied(BuildContext context, String action) {
    final l10n = AppLocalizations.of(context)!;
    String title;
    String message;
    String permission;

    if (shoppingList.isReadOnly) {
      title = l10n.readOnlyAccess;
      permission = shoppingList.permissionDisplayName ?? l10n.readOnlyAccess;
      message = l10n.cannotActionReadOnly(action, permission);
    } else {
      title = l10n.insufficientPermission;
      permission = shoppingList.permissionDisplayName ?? l10n.limited;
      message = l10n.cannotActionPermission(action, permission);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      shoppingList.isReadOnly
                          ? Colors.blue[50]
                          : Colors.orange[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  shoppingList.isReadOnly ? Icons.visibility : Icons.lock,
                  color:
                      shoppingList.isReadOnly
                          ? Colors.blue[600]
                          : Colors.orange[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 16),
              if (!shoppingList.isOwner && shoppingList.sharedBy != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.sharedByUser(shoppingList.sharedBy!.name),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.understood),
            ),
            if (!shoppingList.isReadOnly)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  SmartSnackBarManager.showMessage(
                    context,
                    l10n.contactOwnerForPermissions,
                    type: SnackBarType.info,
                  );
                },
                child: Text(l10n.moreInfo),
              ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete, color: Colors.red[600], size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.deleteItemTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Text(l10n.deleteItemConfirm(item.productName)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDelete?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
  }
}

// Extension pour les permissions sur ListItem
extension ListItemPermissions on ListItem {
  /// Vérifie si l'utilisateur peut modifier cet article
  bool canModify(ShoppingList shoppingList) {
    return !shoppingList.isReadOnly;
  }

  /// Vérifie si l'utilisateur peut supprimer cet article
  bool canDelete(ShoppingList shoppingList) {
    return shoppingList.canEdit;
  }

  /// Vérifie si l'utilisateur peut seulement voir cet article
  bool isReadOnly(ShoppingList shoppingList) {
    return shoppingList.isReadOnly;
  }
}
