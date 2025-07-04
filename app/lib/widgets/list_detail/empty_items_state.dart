// widgets/list_detail/empty_items_state.dart
import 'package:flutter/material.dart';

class EmptyItemsState extends StatelessWidget {
  final VoidCallback onAddItem;

  const EmptyItemsState({super.key, required this.onAddItem});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_shopping_cart, size: 60, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Liste vide',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Ajoutez votre premier article',
            style: TextStyle(color: Colors.grey[500]),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAddItem,
            icon: Icon(Icons.add),
            label: Text('Ajouter un article'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
