// widgets/list_detail/list_item_card.dart - VERSION AVEC PERMISSIONS
import 'package:epilist/models/list_item.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:flutter/material.dart';

class ListItemCard extends StatelessWidget {
  final ListItem item;
  final Function(bool)? onTogglePurchased;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final ShoppingList shoppingList; // Ajout pour les permissions

  const ListItemCard({
    super.key,
    required this.item,
    required this.shoppingList,
    this.onTogglePurchased,
    this.onDelete,
    this.onEdit,
  });

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(2)} \$CAD';
  }

  @override
  Widget build(BuildContext context) {
    // Vérification des permissions
    final canManageItems = shoppingList.canManageItems;
    final canEdit = shoppingList.canEdit;
    final isReadOnly = shoppingList.isReadOnly;

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      // Indication visuelle si lecture seule
      color: isReadOnly ? Colors.grey[50] : null,
      // Bordure spéciale pour le mode lecture seule
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side:
            isReadOnly
                ? BorderSide(color: Colors.blue[200]!, width: 1)
                : BorderSide.none,
      ),
      child: ListTile(
        leading: _buildCheckbox(canManageItems),
        title: _buildTitle(),
        subtitle: _buildSubtitle(),
        trailing: _buildTrailing(canManageItems, canEdit, context),
        // Désactiver les interactions en mode lecture seule
        enabled: !isReadOnly,
        // Style différent si lecture seule
        tileColor: isReadOnly ? Colors.grey[50] : null,
      ),
    );
  }

  Widget _buildCheckbox(bool canManageItems) {
    return Checkbox(
      value: item.isPurchased,
      onChanged:
          canManageItems
              ? (value) => onTogglePurchased?.call(value!)
              : null, // Désactive si pas de permission
      activeColor: Colors.green[600],
      // Style différent si désactivé
      fillColor:
          canManageItems ? null : MaterialStateProperty.all(Colors.grey[300]),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Expanded(
          child: Text(
            item.productName,
            style: TextStyle(
              decoration: item.isPurchased ? TextDecoration.lineThrough : null,
              color: item.isPurchased ? Colors.grey : Colors.black87,
              // Style plus pâle si lecture seule
              fontWeight:
                  shoppingList.isReadOnly ? FontWeight.normal : FontWeight.w500,
            ),
          ),
        ),
        if (shoppingList.isReadOnly) _buildReadOnlyIndicator(),
      ],
    );
  }

  Widget _buildReadOnlyIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility, size: 12, color: Colors.blue[600]),
          SizedBox(width: 2),
          Text(
            'Lecture seule',
            style: TextStyle(
              fontSize: 10,
              color: Colors.blue[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
            Text(
              'Qté: ${item.quantity}',
              style: TextStyle(
                color:
                    shoppingList.isReadOnly
                        ? Colors.grey[500]
                        : Colors.grey[600],
              ),
            ),
            if (item.price != null) ...[
              Text(
                ' • ${_formatPrice(item.price!)}',
                style: TextStyle(
                  color:
                      shoppingList.isReadOnly
                          ? Colors.grey[500]
                          : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        // Deuxième ligne : Magasin avec ellipsis si trop long
        if (item.storeName != null && item.storeName!.isNotEmpty) ...[
          SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.store,
                size: 12,
                color:
                    shoppingList.isReadOnly
                        ? Colors.grey[400]
                        : Colors.grey[600],
              ),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.storeName!,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        shoppingList.isReadOnly
                            ? Colors.grey[400]
                            : Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
        // Troisième ligne : Indicateur de permissions si pas propriétaire
        if (!shoppingList.isOwner && !shoppingList.isReadOnly) ...[
          SizedBox(height: 4),
          _buildPermissionInfo(),
        ],
      ],
    );
  }

  Widget _buildPermissionInfo() {
    String permissionText;
    Color permissionColor;
    IconData permissionIcon;

    if (shoppingList.isReadOnly) {
      permissionText = shoppingList.permissionDisplayName ?? 'Lecture seule';
      permissionColor = Colors.blue[600]!;
      permissionIcon = Icons.visibility;
    } else if (shoppingList.canEdit) {
      permissionText = shoppingList.permissionDisplayName ?? 'Modification';
      permissionColor = Colors.green[600]!;
      permissionIcon = Icons.edit;
    } else {
      permissionText = 'Accès limité';
      permissionColor = Colors.orange[600]!;
      permissionIcon = Icons.lock;
    }

    return Row(
      children: [
        Icon(permissionIcon, size: 12, color: permissionColor),
        SizedBox(width: 4),
        Text(
          permissionText,
          style: TextStyle(
            fontSize: 11,
            color: permissionColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget? _buildTrailing(
    bool canManageItems,
    bool canEdit,
    BuildContext context,
  ) {
    // Si aucune permission, pas de boutons d'action
    if (!canManageItems && !canEdit) {
      return Icon(Icons.lock, color: Colors.grey[400], size: 20);
    }

    // Si seulement modification d'état (cocher/décocher) mais pas suppression
    if (canManageItems && !canEdit) {
      return Icon(Icons.check_circle_outline, color: Colors.green[400]);
    }

    // Menu complet si toutes les permissions
    if (canEdit) {
      return PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: Colors.grey[600]),
        onSelected: (value) => _handleMenuAction(value, context),
        itemBuilder:
            (context) => [
              if (onEdit != null)
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20, color: Colors.blue[600]),
                      SizedBox(width: 8),
                      Text('Modifier'),
                    ],
                  ),
                ),
              if (onDelete != null)
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red[600]),
                      SizedBox(width: 8),
                      Text(
                        'Supprimer',
                        style: TextStyle(color: Colors.red[600]),
                      ),
                    ],
                  ),
                ),
            ],
      );
    }

    // Bouton de suppression simple si pas de menu d'édition
    return IconButton(
      icon: Icon(Icons.delete, color: Colors.red[400]),
      onPressed: canManageItems ? onDelete : null,
      tooltip:
          canManageItems ? 'Supprimer l\'article' : 'Permission insuffisante',
    );
  }

  void _handleMenuAction(String action, BuildContext context) {
    // Bloquer toutes les actions en mode lecture seule
    if (shoppingList.isReadOnly) {
      _showPermissionDenied(context, 'modifier cette liste');
      return;
    }

    switch (action) {
      case 'edit':
        if (shoppingList.canEdit) {
          onEdit?.call();
        } else {
          _showPermissionDenied(context, 'modifier cet article');
        }
        break;
      case 'delete':
        if (shoppingList.canEdit) {
          _showDeleteConfirmation(context);
        } else {
          _showPermissionDenied(context, 'supprimer cet article');
        }
        break;
    }
  }

  // Nouvelle méthode pour afficher l'alerte de permission refusée
  void _showPermissionDenied(BuildContext context, String action) {
    String title;
    String message;
    String permission;

    if (shoppingList.isReadOnly) {
      title = 'Accès en lecture seule';
      permission = shoppingList.permissionDisplayName ?? 'Lecture seule';
      message =
          'Vous ne pouvez pas $action car cette liste est en mode lecture seule.\n\n'
          'Votre permission actuelle : $permission';
    } else {
      title = 'Permission insuffisante';
      permission = shoppingList.permissionDisplayName ?? 'Limitée';
      message =
          'Vous n\'avez pas la permission de $action.\n\n'
          'Votre permission actuelle : $permission';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                shoppingList.isReadOnly ? Icons.visibility : Icons.lock,
                color:
                    shoppingList.isReadOnly
                        ? Colors.blue[600]
                        : Colors.orange[600],
                size: 24,
              ),
              SizedBox(width: 8),
              Expanded(child: Text(title)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              SizedBox(height: 16),
              if (!shoppingList.isOwner && shoppingList.sharedBy != null) ...[
                Text(
                  'Cette liste a été partagée par ${shoppingList.sharedBy!.name}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Compris'),
            ),
            if (!shoppingList.isReadOnly)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Utiliser SmartSnackBarManager pour afficher une info
                  SmartSnackBarManager.showMessage(
                    context,
                    'Contactez le propriétaire pour obtenir plus de permissions',
                    type: SnackBarType.info,
                  );
                },
                child: Text('Plus d\'infos'),
              ),
          ],
        );
      },
    );
  }

  void _showReadOnlyWarning(BuildContext context) {
    SmartSnackBarManager.showMessage(
      context,
      'Cette liste est en lecture seule - Aucune modification possible',
      type: SnackBarType.warning,
      duration: Duration(seconds: 3),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Supprimer l\'article'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer "${item.productName}" de la liste ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDelete?.call();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }
}

// Extension pour les permissions sur ListItem (optionnel)
extension ListItemPermissions on ListItem {
  /// Vérifie si l'utilisateur peut modifier cet article
  bool canModify(ShoppingList shoppingList) {
    return shoppingList.canManageItems;
  }

  /// Vérifie si l'utilisateur peut supprimer cet article
  bool canDelete(ShoppingList shoppingList) {
    return shoppingList.canEdit;
  }

  /// Vérifie si l'utilisateur peut seulement voir cet article
  bool isReadOnly(ShoppingList shoppingList) {
    return shoppingList.isReadOnly;
  }
}
