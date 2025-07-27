// widgets/list_detail/list_item_card.dart - VERSION AVEC DEBUG TEMPORAIRE
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/list_item.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart';
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

  @override
  Widget build(BuildContext context) {
    final canEdit = shoppingList.canEdit;
    final isReadOnly = shoppingList.isReadOnly;
    final canToggle = !isReadOnly;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
    return Text(
      item.productName,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        decoration: item.isPurchased ? TextDecoration.lineThrough : null,
        color: _getTitleColor(),
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Color _getTitleColor() {
    if (item.isPurchased) return Colors.grey[500]!;
    if (shoppingList.isReadOnly) return Colors.blue[700]!;
    return Colors.black87;
  }

  Widget _buildDetails(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    List<Widget> details = [];

    // Quantité - toujours affiché
    details.add(
      _buildDetailChip(
        icon: Icons.shopping_basket_outlined,
        text: '${l10n.quantityShort}: ${item.quantity}',
        color: Colors.grey[600]!,
      ),
    );

    // Prix si disponible et > 0
    if (item.price != null && item.price! > 0) {
      details.add(const SizedBox(width: 8));
      details.add(_buildPriceChip());
    }

    // Magasin si disponible
    if (item.storeName != null && item.storeName!.isNotEmpty) {
      details.add(const SizedBox(width: 8));
      details.add(_buildStoreChip());
    }

    return Wrap(spacing: 8, runSpacing: 4, children: details);
  }

  Widget _buildPriceChip() {
    // Vérification de sécurité
    if (item.price == null || item.price! <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.attach_money, size: 12, color: Colors.green[600]),
          const SizedBox(width: 4),
          // ✅ ACTIVÉ: Debug temporaire pour voir ce qui se passe
          FormattedAmount(
            amount: item.price!,
            style: TextStyle(
              fontSize: 11,
              color: Colors.green[600]!,
              fontWeight: FontWeight.w500,
            ),
            showCode:
                false, // Ne pas afficher le code de devise pour économiser l'espace
          ),
        ],
      ),
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
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStoreChip() {
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

  Widget _buildTrailing(bool canToggle, bool canEdit, BuildContext context) {
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

    return const SizedBox.shrink();
  }

  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    List<PopupMenuEntry<String>> items = [];

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
    SmartSnackBarManager.showWarningSnackBar(
      context,
      'Vous n\'avez pas les permissions pour cette action',
      duration: const Duration(seconds: 2),
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
          title: Text(l10n.deleteItemTitle ?? 'Supprimer l\'article'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer "${item.productName}" ?',
          ),
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
              ),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
  }
}
