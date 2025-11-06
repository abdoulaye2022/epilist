// widgets/list_detail/empty_items_state.dart - VERSION AVEC FOND BLANC
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:flutter/material.dart';

class EmptyItemsState extends StatelessWidget {
  final VoidCallback? onAddItem;
  final ShoppingList shoppingList;

  const EmptyItemsState({
    super.key,
    this.onAddItem,
    required this.shoppingList,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // ✅ AJOUT: Fond blanc pour le conteneur principal
      color: Colors.white,
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.3,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIcon(),
                  const SizedBox(height: 24),
                  _buildTitle(context),
                  const SizedBox(height: 12),
                  _buildDescription(context),
                  const SizedBox(height: 32),
                  _buildActionButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        // ✅ MODIFICATION: Couleurs plus subtiles pour fond blanc
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.grey[200]!, width: 2),
      ),
      child: Icon(
        Icons.shopping_cart_outlined,
        size: 40,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String title;

    if (shoppingList.isReadOnly) {
      title = l10n.thisListIsEmpty;
    } else {
      title = l10n.yourListIsEmpty;
    }

    return Text(
      title,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        // ✅ MODIFICATION: Couleur plus foncée pour fond blanc
        color: Colors.grey[800],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String description;

    if (shoppingList.isReadOnly) {
      description = l10n.noItemsReadOnlyDescription;
    } else if (!shoppingList.canManageItems) {
      description = l10n.noItemsNoPermissionDescription;
    } else {
      description = l10n.noItemsAddFirstDescription;
    }

    return Text(
      description,
      style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActionButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Si aucune permission d'ajout, afficher un message informatif
    if (!shoppingList.canManageItems) {
      return _buildPermissionInfo(context);
    }

    // Si permission d'ajout mais pas de callback, ne rien afficher
    if (onAddItem == null) {
      return const SizedBox.shrink();
    }

    // Bouton normal d'ajout
    return ElevatedButton.icon(
      onPressed: onAddItem,
      icon: const Icon(Icons.add, color: Colors.white),
      label: Text(
        l10n.addItem,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[600],
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    );
  }

  Widget _buildPermissionInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String infoText;
    Color infoColor;
    IconData infoIcon;

    if (shoppingList.isReadOnly) {
      infoText = l10n.readOnlyMode;
      infoColor = Colors.blue[600]!;
      infoIcon = Icons.visibility;
    } else {
      infoText = l10n.permissionRequiredToAdd;
      infoColor = Colors.orange[600]!;
      infoIcon = Icons.lock;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: infoColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: infoColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(infoIcon, size: 20, color: infoColor),
          const SizedBox(width: 8),
          Text(
            infoText,
            style: TextStyle(
              fontSize: 14,
              color: infoColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
