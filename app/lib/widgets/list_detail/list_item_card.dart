// widgets/list_detail/list_item_card.dart
import 'package:epilist/models/list_item.dart';
import 'package:flutter/material.dart';

class ListItemCard extends StatelessWidget {
  final ListItem item;
  final Function(bool) onTogglePurchased;
  final VoidCallback onDelete;

  const ListItemCard({
    super.key,
    required this.item,
    required this.onTogglePurchased,
    required this.onDelete,
  });

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(2)} \$CAD';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: item.isPurchased,
          onChanged: (value) => onTogglePurchased(value!),
          activeColor: Colors.green[600],
        ),
        title: Text(
          item.productName,
          style: TextStyle(
            decoration: item.isPurchased ? TextDecoration.lineThrough : null,
            color: item.isPurchased ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: _buildSubtitle(),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red[400]),
          onPressed: onDelete,
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Première ligne : Quantité et prix
        Row(
          children: [
            Text('Qté: ${item.quantity}'),
            if (item.price != null) ...[
              Text(' • ${_formatPrice(item.price!)}'),
            ],
          ],
        ),
        // Deuxième ligne : Magasin avec ellipsis si trop long
        if (item.storeName != null) ...[
          SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.store, size: 12, color: Colors.grey[600]),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.storeName!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
}
