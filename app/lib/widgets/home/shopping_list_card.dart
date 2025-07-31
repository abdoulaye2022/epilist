// widgets/home/shopping_list_card.dart - VERSION SIMPLIFIÉE POUR HOME SCREEN
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/screens/receipts_screen.dart';
import 'package:epilist/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final totalItems = list.itemsCount;
    final completedItems = list.purchasedItemsCount;
    final progress = list.progress;

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
            mainAxisSize: MainAxisSize.min, // ✅ NOUVEAU: Taille minimale
            children: [
              _buildHeader(l10n),
              const SizedBox(height: 12),
              _buildEssentialInfo(totalItems, l10n),
              if (totalItems > 0) ...[
                const SizedBox(height: 12),
                _buildProgressSection(progress, completedItems, totalItems),
              ],
              const SizedBox(height: 8),
              _buildCompactFooter(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Text(
            list.name,
            style: const TextStyle(
              fontSize: 16, // ✅ RÉDUIT: 18 -> 16
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 8),
        if (list.isShared) _buildCompactSharingIndicator(),
        const SizedBox(width: 8),
        _buildPopupMenu(l10n),
      ],
    );
  }

  // ✅ NOUVEAU: Info essentielle simplifiée
  Widget _buildEssentialInfo(int totalItems, AppLocalizations l10n) {
    final hasReceipts = list.hasReceipts ?? false;

    return Row(
      children: [
        // Articles
        Icon(Icons.shopping_cart, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '$totalItems',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),

        // Factures badge si applicable
        if (hasReceipts) ...[
          const SizedBox(width: 12),
          _buildCompactReceiptsBadge(),
        ],

        const Spacer(),

        // Statut
        _buildCompactStatusChip(l10n),
      ],
    );
  }

  // ✅ NOUVEAU: Badge factures compact
  Widget _buildCompactReceiptsBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long, size: 10, color: Colors.blue[600]),
          const SizedBox(width: 2),
          Text(
            '${list.receiptsCount ?? 0}',
            style: TextStyle(
              fontSize: 9,
              color: Colors.blue[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NOUVEAU: Indicateur de partage compact
  Widget _buildCompactSharingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: list.isOwner ? Colors.blue[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: list.isOwner ? Colors.blue[200]! : Colors.green[200]!,
        ),
      ),
      child: Icon(
        list.isOwner ? Icons.people : Icons.share,
        size: 10,
        color: list.isOwner ? Colors.blue[600] : Colors.green[600],
      ),
    );
  }

  Widget _buildProgressSection(
    double progress,
    int completedItems,
    int totalItems,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$completedItems/$totalItems',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            list.isCompleted ? Colors.green[600]! : Colors.blue[600]!,
          ),
          minHeight: 4, // ✅ RÉDUIT: 6 -> 4
        ),
      ],
    );
  }

  // ✅ NOUVEAU: Statut compact
  Widget _buildCompactStatusChip(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: list.isCompleted ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: list.isCompleted ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Text(
        list.isCompleted ? l10n.completed : l10n.inProgress,
        style: TextStyle(
          fontSize: 10, // ✅ RÉDUIT: 12 -> 10
          color: list.isCompleted ? Colors.green[700] : Colors.orange[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ✅ NOUVEAU: Footer compact avec juste la date
  Widget _buildCompactFooter(AppLocalizations l10n) {
    return Text(
      DateFormatter.formatDate(list.createdAt),
      style: TextStyle(
        fontSize: 10, // ✅ RÉDUIT: 12 -> 10
        color: Colors.grey[500],
      ),
    );
  }

  Widget _buildPopupMenu(AppLocalizations l10n) {
    return Builder(
      builder:
          (context) => PopupMenuButton(
            icon: Icon(
              Icons.more_vert,
              color: Colors.grey[600],
              size: 18, // ✅ RÉDUIT: 24 -> 18
            ),
            itemBuilder: (context) => _buildMenuItems(l10n),
            onSelected: (value) => _handleMenuAction(context, value.toString()),
          ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    if (action == 'receipts') {
      _navigateToReceipts(context);
    } else {
      onAction(action);
    }
  }

  void _navigateToReceipts(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptsScreen(shoppingList: list),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(AppLocalizations l10n) {
    List<PopupMenuEntry<String>> items = [];

    // Modifier (si permission d'édition)
    if (list.canEdit) {
      items.add(
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(l10n.edit),
            ],
          ),
        ),
      );
    }

    // Dupliquer
    items.add(
      PopupMenuItem(
        value: 'duplicate',
        child: Row(
          children: [
            Icon(Icons.copy, size: 18, color: Colors.green[600]),
            const SizedBox(width: 8),
            Text(l10n.duplicate),
          ],
        ),
      ),
    );

    // Factures
    items.add(
      PopupMenuItem(
        value: 'receipts',
        child: Row(
          children: [
            Icon(Icons.receipt_long, size: 18, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.receipts)),
            if ((list.hasReceipts ?? false)) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${list.receiptsCount ?? 0}',
                  style: TextStyle(
                    fontSize: 9,
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

    // Partager (si applicable)
    if (list.canShare) {
      items.add(const PopupMenuDivider());
      items.add(
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, size: 18, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(l10n.share),
            ],
          ),
        ),
      );
    }

    // Actions destructives
    items.add(const PopupMenuDivider());

    if (list.canDelete) {
      items.add(
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red[600]),
              const SizedBox(width: 8),
              Text(l10n.delete, style: TextStyle(color: Colors.red[600])),
            ],
          ),
        ),
      );
    } else if (!list.isOwner) {
      items.add(
        PopupMenuItem(
          value: 'leave',
          child: Row(
            children: [
              Icon(Icons.exit_to_app, size: 18, color: Colors.orange[600]),
              const SizedBox(width: 8),
              Text(l10n.leave, style: TextStyle(color: Colors.orange[600])),
            ],
          ),
        ),
      );
    }

    return items;
  }
}
