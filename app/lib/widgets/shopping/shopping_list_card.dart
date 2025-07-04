// widgets/shopping/shopping_list_card.dart
import 'package:epilist/models/shopping_list.dart';
import 'package:flutter/material.dart';

class ShoppingListCard extends StatelessWidget {
  final ShoppingList list;
  final VoidCallback onTap;
  final Function(String) onMenuAction;

  const ShoppingListCard({
    super.key,
    required this.list,
    required this.onTap,
    required this.onMenuAction,
  });

  @override
  Widget build(BuildContext context) {
    final totalItems = list.itemsCount;
    final completedItems = list.purchasedItemsCount;
    final progress = list.progress;
    final totalPrice = list.totalPrice;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
        border: list.isShared
            ? Border.all(
                color: list.isOwner ? Colors.blue[200]! : Colors.green[200]!,
                width: 1,
              )
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 8),
              _buildBasicInfo(totalItems),
              if (totalPrice > 0) ...[
                SizedBox(height: 4),
                _buildPriceInfo(totalPrice),
              ],
              SizedBox(height: 12),
              _buildProgressBar(progress, completedItems, totalItems),
              SizedBox(height: 12),
              _buildStatusRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  list.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (list.isShared) ...[
                SizedBox(width: 8),
                _buildSharingIndicator(),
              ],
            ],
          ),
        ),
        _buildPopupMenu(),
      ],
    );
  }

  Widget _buildBasicInfo(int totalItems) {
    return Row(
      children: [
        Text(
          '${_formatDate(list.createdAt)} • $totalItems articles',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        if (list.isShared) ...[
          Text(' • ', style: TextStyle(color: Colors.grey[600])),
          Text(
            list.sharingStatus,
            style: TextStyle(
              color: list.isOwner ? Colors.blue[600] : Colors.green[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriceInfo(double totalPrice) {
    return Text(
      'Budget estimé: ${totalPrice.toStringAsFixed(2)} \$CAD',
      style: TextStyle(
        color: Colors.green[600],
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildProgressBar(double progress, int completedItems, int totalItems) {
    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
          ),
        ),
        SizedBox(width: 12),
        Text(
          '$completedItems/$totalItems',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: list.isCompleted ? Colors.green[50] : Colors.orange[50],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: list.isCompleted ? Colors.green[200]! : Colors.orange[200]!,
            ),
          ),
          child: Text(
            list.isCompleted ? '✅ Terminée' : '🛒 En cours',
            style: TextStyle(
              fontSize: 12,
              color: list.isCompleted ? Colors.green[700] : Colors.orange[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (!list.isOwner) _buildPermissionIndicator(),
      ],
    );
  }

  Widget _buildSharingIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: list.isOwner ? Colors.blue[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: list.isOwner ? Colors.blue[200]! : Colors.green[200]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            list.isOwner ? Icons.people : Icons.share,
            size: 12,
            color: list.isOwner ? Colors.blue[600] : Colors.green[600],
          ),
          if (list.isOwner) ...[
            SizedBox(width: 2),
            Text(
              '${list.sharedWithCount}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionIndicator() {
    String text;
    Color color;
    IconData icon;

    if (list.isReadOnly) {
      text = 'Lecture seule';
      color = Colors.blue[600]!;
      icon = Icons.visibility;
    } else if (list.canEdit) {
      text = 'Modification';
      color = Colors.green[600]!;
      icon = Icons.edit;
    } else {
      text = 'Admin';
      color = Colors.purple[600]!;
      icon = Icons.admin_panel_settings;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton(
      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
      itemBuilder: (context) => _buildMenuItems(),
      onSelected: (value) => onMenuAction(value.toString()),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems() {
    List<PopupMenuEntry<String>> items = [];

    if (list.canEdit) {
      items.add(
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 8),
              Text('Modifier'),
            ],
          ),
        ),
      );
    }

    items.add(
      PopupMenuItem(
        value: 'duplicate',
        child: Row(
          children: [
            Icon(Icons.copy, size: 20),
            SizedBox(width: 8),
            Text('Dupliquer'),
          ],
        ),
      ),
    );

    if (list.canShare) {
      items.add(
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, size: 20, color: Colors.blue[600]),
              SizedBox(width: 8),
              Text('Partager', style: TextStyle(color: Colors.blue[600])),
            ],
          ),
        ),
      );
    }

    if (list.isOwner && list.isShared) {
      items.add(
        PopupMenuItem(
          value: 'manage_shares',
          child: Row(
            children: [
              Icon(Icons.people_outline, size: 20, color: Colors.purple[600]),
              SizedBox(width: 8),
              Text(
                'Gérer les partages',
                style: TextStyle(color: Colors.purple[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (list.canDelete || !list.isOwner) {
      items.add(PopupMenuDivider());
    }

    if (!list.isOwner) {
      items.add(
        PopupMenuItem(
          value: 'leave',
          child: Row(
            children: [
              Icon(Icons.exit_to_app, size: 20, color: Colors.orange),
              SizedBox(width: 8),
              Text('Quitter', style: TextStyle(color: Colors.orange)),
            ],
          ),
        ),
      );
    }

    if (list.canDelete) {
      items.add(
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red),
              SizedBox(width: 8),
              Text('Supprimer', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }

    return items;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Aujourd\'hui';
    } else if (difference == 1) {
      return 'Hier';
    } else if (difference < 7) {
      return 'Il y a $difference jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}