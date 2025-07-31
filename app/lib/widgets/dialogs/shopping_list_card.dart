// widgets/dialogs/shopping_list_card.dart - VERSION AVEC SIGNATURE CORRIGÉE
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/screens/receipts_screen.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart';
import 'package:flutter/material.dart';

class ShoppingListCard extends StatelessWidget {
  final ShoppingList list;
  final VoidCallback onTap;
  final Function(String) onMenuAction; // ✅ CORRECTION: Signature simple

  const ShoppingListCard({
    super.key,
    required this.list,
    required this.onTap,
    required this.onMenuAction,
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
              _buildListInfo(context, totalItems, totalPrice),
              if (list.isShared) ...[
                const SizedBox(height: 8),
                _buildSharingInfo(context),
              ],
              if (totalItems > 0) ...[
                const SizedBox(height: 12),
                _buildProgressSection(progress, completedItems, totalItems),
                const SizedBox(height: 12),
                _buildBottomRow(context),
              ],
              const SizedBox(height: 8),
              _buildDateInfo(context),
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

  Widget _buildListInfo(
    BuildContext context,
    int totalItems,
    double totalPrice,
  ) {
    final l10n = AppLocalizations.of(context)!;
    // ✅ CORRECTION : Protection contre null avec ??
    final hasReceipts = list.hasReceipts ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 300;

        if (isSmallScreen) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shopping_cart, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    '$totalItems ${l10n.articles}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  if (hasReceipts) ...[
                    const SizedBox(width: 12),
                    _buildReceiptsBadge(context),
                  ],
                ],
              ),
              if (totalPrice > 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 16,
                      color: Colors.green[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            '${l10n.budget}: ',
                            style: TextStyle(
                              color: Colors.green[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Flexible(
                            child: FormattedAmount(
                              amount: totalPrice,
                              style: TextStyle(
                                color: Colors.green[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        } else {
          return Row(
            children: [
              Icon(Icons.shopping_cart, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                '$totalItems ${l10n.articles}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              if (hasReceipts) ...[
                const SizedBox(width: 12),
                _buildReceiptsBadge(context),
              ],
              if (totalPrice > 0) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.account_balance_wallet,
                  size: 16,
                  color: Colors.green[600],
                ),
                const SizedBox(width: 6),
                Text(
                  '${l10n.budget}: ',
                  style: TextStyle(
                    color: Colors.green[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Flexible(
                  child: FormattedAmount(
                    amount: totalPrice,
                    style: TextStyle(
                      color: Colors.green[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          );
        }
      },
    );
  }

  Widget _buildReceiptsBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long, size: 12, color: Colors.blue[600]),
          const SizedBox(width: 2),
          Text(
            '${list.receiptsCount ?? 0}', // ✅ Protection contre null
            style: TextStyle(
              fontSize: 10,
              color: Colors.blue[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharingInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
          Expanded(
            child: Text(
              list.isOwner
                  ? '${l10n.sharedList} • ${list.sharedWithCount ?? 0} ${l10n.collaborators}' // ✅ Protection contre null
                  : '${l10n.sharedBy} ${list.sharedBy?.name ?? "un utilisateur"}',
              style: TextStyle(
                fontSize: 12,
                color: list.isOwner ? Colors.blue[600] : Colors.green[600],
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
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

  Widget _buildBottomRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatusChip(context),
        if (!list.isOwner) _buildPermissionIndicator(context),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
        list.isCompleted ? l10n.completed : l10n.inProgress,
        style: TextStyle(
          fontSize: 12,
          color: list.isCompleted ? Colors.green[700] : Colors.orange[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDateInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Text(
      '${l10n.created} ${_formatDate(context, list.createdAt)}',
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
              '${list.sharedWithCount ?? 0}', // ✅ Protection contre null
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

  Widget _buildPermissionIndicator(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (list.isOwner) return const SizedBox.shrink();

    String text = list.permissionDisplayName ?? 'Accès';
    Color color;
    IconData icon;

    if (list.isReadOnly) {
      color = Colors.blue[600]!;
      icon = Icons.visibility;
      text = l10n.readOnlyAccess;
    } else if (list.canEdit) {
      color = Colors.green[600]!;
      icon = Icons.edit;
      text = l10n.editAccess;
    } else {
      color = Colors.purple[600]!;
      icon = Icons.admin_panel_settings;
      text = l10n.adminAccess;
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
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu() {
    return Builder(
      builder:
          (context) => PopupMenuButton(
            icon: Icon(Icons.more_vert, color: Colors.grey[600]),
            itemBuilder: (context) => _buildMenuItems(context),
            onSelected: (value) => _handleMenuAction(context, value.toString()),
          ),
    );
  }

  // ✅ NOUVEAU: Méthode pour gérer les actions du menu avec navigation
  void _handleMenuAction(BuildContext context, String action) {
    if (action == 'receipts') {
      _navigateToReceipts(context);
    } else {
      onMenuAction(action); // ✅ CORRECTION: Appel simple sans context
    }
  }

  // ✅ NOUVEAU: Méthode de navigation vers l'écran des factures
  void _navigateToReceipts(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptsScreen(shoppingList: list),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    List<PopupMenuEntry<String>> items = [];

    // ===== SECTION ÉDITION =====
    // Modifier (si permission d'édition)
    if (list.canEdit) {
      items.add(
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20, color: Colors.blue[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.edit,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
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
            Icon(Icons.copy, size: 20, color: Colors.green[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.duplicate,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );

    // ✅ MODIFICATION: Menu Factures avec gestion de navigation
    items.add(
      PopupMenuItem(
        value: 'receipts',
        child: Row(
          children: [
            Icon(Icons.receipt_long, size: 20, color: Colors.blue[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.receipts,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            // ✅ AJOUT: Badge avec nombre de factures si applicable
            if ((list.hasReceipts ?? false)) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${list.receiptsCount ?? 0}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    // ===== SECTION PARTAGE =====
    if (list.canShare || (list.isOwner && list.isShared)) {
      items.add(const PopupMenuDivider());
    }

    // Partager (si propriétaire ou admin)
    if (list.canShare) {
      items.add(
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, size: 20, color: Colors.blue[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.share,
                  style: TextStyle(color: Colors.blue[600]),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
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
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.manageShares,
                  style: TextStyle(color: Colors.purple[600]),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ===== SECTION ACTIONS DESTRUCTIVES =====
    if (list.canDelete || !list.isOwner) {
      items.add(const PopupMenuDivider());
    }

    // Quitter (si pas propriétaire)
    if (!list.isOwner) {
      items.add(
        PopupMenuItem(
          value: 'leave',
          child: Row(
            children: [
              Icon(Icons.exit_to_app, size: 20, color: Colors.orange[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.leave,
                  style: TextStyle(color: Colors.orange[600]),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
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
              Icon(Icons.delete, size: 20, color: Colors.red[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.delete,
                  style: TextStyle(color: Colors.red[600]),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return items;
  }

  String _formatDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return l10n.today;
    } else if (difference == 1) {
      return l10n.yesterday;
    } else if (difference < 7) {
      return l10n.daysAgo(difference);
    } else {
      return '${l10n.on} ${date.day}/${date.month}/${date.year}';
    }
  }
}
