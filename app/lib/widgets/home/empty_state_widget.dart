// widgets/home/empty_state_widget.dart
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';

class EmptyStateWidget extends StatelessWidget {
  final VoidCallback onCreateNew;

  const EmptyStateWidget({super.key, required this.onCreateNew});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            l10n.noGroceryLists,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(l10n.createFirstList, style: TextStyle(color: Colors.grey[500])),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onCreateNew,
            icon: const Icon(Icons.add),
            label: Text(l10n.createList),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
