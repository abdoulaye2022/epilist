// widgets/home/shopping_list_card.dart - VERSION CORRIGÉE
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border:
            list.isShared
                ? Border.all(
                  color: list.isOwner ? Colors.blue[200]! : Colors.green[200]!,
                  width: 1.5,
                )
                : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildListInfo(totalItems, totalPrice),
              if (list.isShared) ...[
                const SizedBox(height: 8),
                _buildSharingInfo(),
              ],
              if (totalItems > 0) ...[
                const SizedBox(height: 12),
                _buildProgressSection(progress, completedItems, totalItems),
                const SizedBox(height: 12),
                _buildBottomRow(),
              ],
              const SizedBox(height: 8),
              _buildDateInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  list.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (list.isShared) ...[
                const SizedBox(width: 8),
                _buildSharingIndicator(),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildPopupMenu(),
      ],
    );
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
                  const SizedBox(width: 6),
                  Text(
                    '$totalItems articles',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Budget: ${totalPrice.toStringAsFixed(2)} \$CAD',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontSize: 14,
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
              const SizedBox(width: 6),
              Text(
                '$totalItems articles',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              if (totalPrice > 0) ...[
                const SizedBox(width: 16),
                Icon(Icons.attach_money, size: 16, color: Colors.green[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Budget: ${totalPrice.toStringAsFixed(2)} \$CAD',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontSize: 14,
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

  Widget _buildSharingInfo() {
    if (!list.isShared) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          const SizedBox(width: 4),
          Text(
            list.isOwner
                ? 'Liste partagée • ${list.sharedWithCount ?? 0} collaborateur(s)'
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

  Widget _buildProgressSection(
    double progress,
    int completedItems,
    int totalItems,
  ) {
    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
            minHeight: 6,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$completedItems/$totalItems',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatusChip(),
        if (!list.isOwner) _buildPermissionIndicator(),
      ],
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          fontSize: 12,
          color: list.isCompleted ? Colors.green[700] : Colors.orange[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDateInfo() {
    return Text(
      'Créée ${DateFormatter.formatDate(list.createdAt)}',
      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
    );
  }

  Widget _buildSharingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            const SizedBox(width: 2),
            Text(
              '${list.sharedWithCount ?? 0}',
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

  Widget _buildPermissionIndicator() {
    if (list.isOwner) return const SizedBox.shrink();

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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
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
        const PopupMenuItem(
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
      const PopupMenuItem(
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
              const SizedBox(width: 8),
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
              const SizedBox(width: 8),
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
      items.add(const PopupMenuDivider());
    }

    // Quitter (si pas propriétaire)
    if (!list.isOwner) {
      items.add(
        const PopupMenuItem(
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
        const PopupMenuItem(
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
}
