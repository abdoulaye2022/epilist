// widgets/shopping/shopping_list_app_bar.dart
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/common/drawer_menu_button.dart';
import 'package:flutter/material.dart';

class ShoppingListAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final VoidCallback onRefresh;

  const ShoppingListAppBar({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AppBar(
      // Onglet de la coquille : bouton menu ; ecran pousse : fleche retour.
      leading: DrawerMenuButton.leadingOrNull(context),
      title: Text(
        l10n.myShoppingLists,
        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: AppColors.textPrimary),
          onPressed: onRefresh,
          tooltip: l10n.refresh,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}