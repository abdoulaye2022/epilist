// widgets/home/shopping_list_card.dart - VERSION MISE À JOUR
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/utils/date_formatter.dart';
import 'package:flutter/material.dart';

class ShoppingListCard extends StatelessWidget {
  final ShoppingList list;
  final VoidCallback onTap;
  final Function(String) onAction;

  const ShoppingListCard({
    super.key,
    required this.list,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final totalItems = list.itemsCount;
    final completedItems = list.purchasedItemsCount;
    final progress = list.progress;
    final totalPrice = list.totalPrice;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // Bordure colorée si la liste est partagée
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border:
              list.isShared
                  ? Border.all(
                    color:
                        list.isOwner ? Colors.blue[200]! : Colors.green[200]!,
                    width: 1.5,
                  )
                  : null,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom de la liste et menu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              list.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (list.isShared) ...[
                            SizedBox(width: 8),
                            _buildSharingIndicator(),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    _buildPopupMenu(),
                  ],
                ),

                SizedBox(height: 12),

                // Informations détaillées - responsive
                _buildListInfo(totalItems, totalPrice),

                // Indicateur de partage si applicable
                if (list.isShared) ...[
                  SizedBox(height: 8),
                  _buildSharingInfo(),
                ],

                if (totalItems > 0) ...[
                  SizedBox(height: 8),
                  _buildProgressSection(progress, completedItems, totalItems),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusChip(),
                      if (!list.isOwner) _buildPermissionIndicator(),
                    ],
                  ),
                ],

                SizedBox(height: 8),

                // Date
                Text(
                  'Créée ${DateFormatter.formatDate(list.createdAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSharingIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: list.isOwner ? Colors.blue[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: list.isOwner ? Colors.blue[200]! : Colors.green[200]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            list.isOwner ? Icons.people : Icons.share,
            size: 12,
            color: list.isOwner ? Colors.blue[600] : Colors.green[600],
          ),
          if (list.isOwner) ...[
            SizedBox(width: 2),
            Text(
              'Propriétaire',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSharingInfo() {
    if (!list.isShared) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: list.isOwner ? Colors.blue[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: list.isOwner ? Colors.blue[200]! : Colors.green[200]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            list.isOwner ? Icons.people_outline : Icons.person_add,
            size: 14,
            color: list.isOwner ? Colors.blue[600] : Colors.green[600],
          ),
          SizedBox(width: 4),
          Text(
            list.isOwner
                ? 'Liste partagée'
                : 'Partagée par ${list.sharedBy?.name ?? "un utilisateur"}',
            style: TextStyle(
              fontSize: 12,
              color: list.isOwner ? Colors.blue[600] : Colors.green[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionIndicator() {
    if (list.isOwner) return SizedBox.shrink();

    String text = list.permissionDisplayName ?? 'Accès';
    Color color;
    IconData icon;

    if (list.isReadOnly) {
      color = Colors.blue[600]!;
      icon = Icons.visibility;
    } else if (list.canEdit) {
      color = Colors.green[600]!;
      icon = Icons.edit;
    } else {
      color = Colors.purple[600]!;
      icon = Icons.admin_panel_settings;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton(
      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
      itemBuilder: (context) => _buildMenuItems(),
      onSelected: (value) => onAction(value.toString()),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems() {
    List<PopupMenuEntry<String>> items = [];

    // Modifier (si permission d'édition)
    if (list.canEdit) {
      items.add(
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 8),
              Text('Modifier'),
            ],
          ),
        ),
      );
    }

    // Dupliquer (toujours disponible)
    items.add(
      PopupMenuItem(
        value: 'duplicate',
        child: Row(
          children: [
            Icon(Icons.copy, size: 20),
            SizedBox(width: 8),
            Text('Dupliquer'),
          ],
        ),
      ),
    );

    // Partager (si propriétaire ou admin)
    if (list.canShare) {
      items.add(
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, size: 20, color: Colors.blue[600]),
              SizedBox(width: 8),
              Text('Partager', style: TextStyle(color: Colors.blue[600])),
            ],
          ),
        ),
      );
    }

    // Gérer les partages (si propriétaire et liste partagée)
    if (list.isOwner && list.isShared) {
      items.add(
        PopupMenuItem(
          value: 'manage_shares',
          child: Row(
            children: [
              Icon(Icons.people_outline, size: 20, color: Colors.purple[600]),
              SizedBox(width: 8),
              Text(
                'Gérer les partages',
                style: TextStyle(color: Colors.purple[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Séparateur si actions de suppression/quitter
    if (list.canDelete || !list.isOwner) {
      items.add(PopupMenuDivider());
    }

    // Quitter (si pas propriétaire)
    if (!list.isOwner) {
      items.add(
        PopupMenuItem(
          value: 'leave',
          child: Row(
            children: [
              Icon(Icons.exit_to_app, size: 20, color: Colors.orange),
              SizedBox(width: 8),
              Text('Quitter', style: TextStyle(color: Colors.orange)),
            ],
          ),
        ),
      );
    }

    // Supprimer (si permission)
    if (list.canDelete) {
      items.add(
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red),
              SizedBox(width: 8),
              Text('Supprimer', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }

    return items;
  }

  Widget _buildListInfo(int totalItems, double totalPrice) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 300;

        if (isSmallScreen && totalPrice > 0) {
          // Layout vertical pour très petits écrans
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shopping_cart, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 6),
                  Text(
                    '$totalItems articles',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.green[600]),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${totalPrice.toStringAsFixed(2)} \$CAD',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          // Layout horizontal pour écrans normaux
          return Row(
            children: [
              Icon(Icons.shopping_cart, size: 16, color: Colors.grey[600]),
              SizedBox(width: 6),
              Text(
                '$totalItems articles',
                style: TextStyle(color: Colors.grey[600]),
              ),
              if (totalPrice > 0) ...[
                SizedBox(width: 16),
                Icon(Icons.attach_money, size: 16, color: Colors.green[600]),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${totalPrice.toStringAsFixed(2)} \$CAD',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          );
        }
      },
    );
  }

  Widget _buildProgressSection(
    double progress,
    int completedItems,
    int totalItems,
  ) {
    return Column(
      children: [
        // Barre de progression
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
              ),
            ),
            SizedBox(width: 12),
            Text(
              '$completedItems/$totalItems',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: list.isCompleted ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: list.isCompleted ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Text(
        list.isCompleted ? '✅ Terminée' : '🛒 En cours',
        style: TextStyle(
          fontSize: 11,
          color: list.isCompleted ? Colors.green[700] : Colors.orange[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
