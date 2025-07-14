// widgets/shopping/shopping_list_app_bar.dart
import 'package:epilist/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ShoppingListAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final VoidCallback onRefresh;

  const ShoppingListAppBar({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AppBar(
      title: Text(
        l10n.myShoppingLists,
        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: Colors.black87),
          onPressed: onRefresh,
          tooltip: l10n.refresh,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}