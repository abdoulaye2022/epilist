// widgets/list_detail/list_detail_app_bar.dart
import 'package:flutter/material.dart';

class ListDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String listName;
  final VoidCallback onAddItem;

  const ListDetailAppBar({
    super.key,
    required this.listName,
    required this.onAddItem,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(listName),
      backgroundColor: Colors.white,
      elevation: 1,
      actions: [
        IconButton(
          onPressed: onAddItem,
          icon: Icon(Icons.add),
          tooltip: 'Ajouter un article',
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
