// widgets/shopping/shopping_list_app_bar.dart
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/common/app_top_bar.dart';
import 'package:flutter/material.dart';

class ShoppingListAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final VoidCallback onRefresh;

  const ShoppingListAppBar({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppTopBar(
      title: l10n.myShoppingLists,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: onRefresh,
          tooltip: l10n.refresh,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
