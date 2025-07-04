// widgets/shopping/shopping_list_app_bar.dart
import 'package:flutter/material.dart';

class ShoppingListAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final VoidCallback onRefresh;

  const ShoppingListAppBar({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        'Mes Listes de Courses',
        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: Colors.black87),
          onPressed: onRefresh,
          tooltip: 'Actualiser',
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
