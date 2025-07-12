import 'package:epilist/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class EmptyListState extends StatelessWidget {
  final VoidCallback onCreateList;

  const EmptyListState({super.key, required this.onCreateList});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            l10n.noShoppingLists,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            l10n.createFirstListToStart,
            style: TextStyle(color: Colors.grey[500]),
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: onCreateList,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(l10n.createList),
          ),
        ],
      ),
    );
  }
}
