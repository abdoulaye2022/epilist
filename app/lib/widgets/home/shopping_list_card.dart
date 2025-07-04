// widgets/home/shopping_list_card.dart
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/utils/date_formatter.dart';
import 'package:flutter/material.dart';

class ShoppingListCard extends StatelessWidget {
  final ShoppingList list;
  final VoidCallback onTap;
  final Function(String) onAction;

  const ShoppingListCard({
    super.key,
    required this.list,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final totalItems = list.itemsCount;
    final completedItems = list.purchasedItemsCount;
    final progress = list.progress;
    final totalPrice = list.totalPrice;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nom de la liste et menu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      list.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  SizedBox(width: 8),
                  _buildPopupMenu(),
                ],
              ),

              SizedBox(height: 12),

              // Informations détaillées - responsive
              _buildListInfo(totalItems, totalPrice),

              if (totalItems > 0) ...[
                SizedBox(height: 8),
                _buildProgressSection(progress, completedItems, totalItems),
                SizedBox(height: 8),
                _buildStatusChip(),
              ],

              SizedBox(height: 8),

              // Date
              Text(
                'Créée ${DateFormatter.formatDate(list.createdAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton(
      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
      itemBuilder:
          (context) => [
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
          ],
      onSelected: (value) => onAction(value.toString()),
    );
  }

  Widget _buildListInfo(int totalItems, double totalPrice) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 300;

        if (isSmallScreen && totalPrice > 0) {
          // Layout vertical pour très petits écrans
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shopping_cart, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 6),
                  Text(
                    '$totalItems articles',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.green[600]),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${totalPrice.toStringAsFixed(2)} \$CAD',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          // Layout horizontal pour écrans normaux
          return Row(
            children: [
              Icon(Icons.shopping_cart, size: 16, color: Colors.grey[600]),
              SizedBox(width: 6),
              Text(
                '$totalItems articles',
                style: TextStyle(color: Colors.grey[600]),
              ),
              if (totalPrice > 0) ...[
                SizedBox(width: 16),
                Icon(Icons.attach_money, size: 16, color: Colors.green[600]),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${totalPrice.toStringAsFixed(2)} \$CAD',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          );
        }
      },
    );
  }

  Widget _buildProgressSection(
    double progress,
    int completedItems,
    int totalItems,
  ) {
    return Column(
      children: [
        // Barre de progression
        Row(
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
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip() {
    return Container(
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
          fontSize: 11,
          color: list.isCompleted ? Colors.green[700] : Colors.orange[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
