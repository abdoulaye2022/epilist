// widgets/list_detail/swipeable_item_card.dart
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/list_item.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:flutter/material.dart';

class SwipeableItemCard extends StatelessWidget {
  final ListItem item;
  final ShoppingList shoppingList;
  final Function(ListItem) onEdit;
  final Function(ListItem) onDelete;
  final Function(ListItem, bool) onTogglePurchased;
  final VoidCallback? onPermissionDenied;

  const SwipeableItemCard({
    super.key,
    required this.item,
    required this.shoppingList,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePurchased,
    this.onPermissionDenied,
  });

  String _formatPrice(BuildContext context, double price) {
    final l10n = AppLocalizations.of(context)!;
    return '${price.toStringAsFixed(2)}${l10n.cad}';
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('item_${item.id}'),
      direction:
          shoppingList.canEdit
              ? DismissDirection.horizontal
              : DismissDirection.none,
      background: _buildDismissBackground(context, isStartToEnd: true),
      secondaryBackground: _buildDismissBackground(
        context,
        isStartToEnd: false,
      ),
      confirmDismiss: (direction) async {
        if (!shoppingList.canEdit) {
          onPermissionDenied?.call();
          return false;
        }
        return await _showQuickDeleteConfirmation(context);
      },
      onDismissed: (direction) => onDelete(item),
      child: Card(
        margin: EdgeInsets.only(bottom: 8),
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side:
              shoppingList.isReadOnly
                  ? BorderSide(color: Colors.blue[200]!, width: 1)
                  : BorderSide.none,
        ),
        child: ListTile(
          leading: _buildCheckbox(),
          title: _buildTitle(),
          subtitle: _buildSubtitle(context),
          trailing: _buildTrailing(context),
          onTap: shoppingList.canEdit ? () => onEdit(item) : null,
        ),
      ),
    );
  }

  Widget _buildDismissBackground(
    BuildContext context, {
    required bool isStartToEnd,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.red[600],
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: isStartToEnd ? Alignment.centerLeft : Alignment.centerRight,
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_rounded, color: Colors.white, size: 32),
          SizedBox(height: 4),
          Text(
            l10n.delete,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showQuickDeleteConfirmation(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(l10n.deleteItemTitle),
                content: Text(l10n.deleteQuickConfirm(item.productName)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: Text(l10n.delete),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Widget _buildCheckbox() {
    if (shoppingList.isReadOnly) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: item.isPurchased ? Colors.green[100] : Colors.grey[100],
          border: Border.all(
            color: item.isPurchased ? Colors.green[300]! : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child:
            item.isPurchased
                ? Icon(Icons.check, size: 16, color: Colors.green[600])
                : null,
      );
    }

    return Checkbox(
      value: item.isPurchased,
      onChanged:
          shoppingList.canManageItems
              ? (value) => onTogglePurchased(item, value!)
              : (value) => onPermissionDenied?.call(),
      activeColor: Colors.green[600],
      fillColor:
          shoppingList.canManageItems
              ? null
              : MaterialStateProperty.all(Colors.grey[300]),
    );
  }

  Widget _buildTitle() {
    return Text(
      item.productName,
      style: TextStyle(
        decoration: item.isPurchased ? TextDecoration.lineThrough : null,
        color:
            shoppingList.isReadOnly
                ? (item.isPurchased ? Colors.grey[500] : Colors.grey[700])
                : (item.isPurchased ? Colors.grey : Colors.black87),
        fontWeight:
            shoppingList.isReadOnly ? FontWeight.normal : FontWeight.w500,
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${l10n.quantityShort}: ${item.quantity}',
              style: TextStyle(
                color:
                    shoppingList.isReadOnly
                        ? Colors.grey[500]
                        : Colors.grey[600],
              ),
            ),
            if (item.price != null) ...[
              Text(
                ' • ${_formatPrice(context, item.price!)}',
                style: TextStyle(
                  color:
                      shoppingList.isReadOnly
                          ? Colors.grey[500]
                          : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        if (item.storeName != null && item.storeName!.isNotEmpty) ...[
          SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.store,
                size: 12,
                color:
                    shoppingList.isReadOnly
                        ? Colors.grey[400]
                        : Colors.grey[600],
              ),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.storeName!,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        shoppingList.isReadOnly
                            ? Colors.grey[400]
                            : Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTrailing(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (shoppingList.isReadOnly) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility, size: 14, color: Colors.blue[600]),
            SizedBox(width: 4),
            Text(
              l10n.readOnlyShort,
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return IconButton(
      icon: Icon(Icons.edit, color: Colors.blue[600]),
      onPressed: shoppingList.canEdit ? () => onEdit(item) : onPermissionDenied,
      tooltip:
          shoppingList.canEdit ? l10n.editItem : l10n.insufficientPermission,
    );
  }
}
