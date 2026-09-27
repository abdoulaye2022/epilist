// widgets/home/shopping_list_card.dart - VERSION SIMPLIFIÉE POUR HOME SCREEN
import 'package:epilist/theme/app_theme.dart';
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
    final done = list.isCompleted && totalItems > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm + 4, AppSpacing.xs, AppSpacing.sm + 4),
          child: Row(
            children: [
              _buildProgressRing(progress, done),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            list.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (list.isShared) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.people_alt_rounded,
                            size: 14,
                            color: list.isOwner
                                ? AppColors.accent
                                : AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          totalItems == 0
                              ? l10n.inProgress
                              : '$completedItems/$totalItems ${l10n.articles.toLowerCase()}',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: done
                                ? AppColors.primaryDark
                                : AppColors.textSecondary,
                            fontWeight:
                                done ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        if (list.hasReceipts ?? false) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.receipt_long,
                              size: 12, color: AppColors.textDisabled),
                          const SizedBox(width: 2),
                          Text(
                            '${list.receiptsCount ?? 0}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textDisabled,
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          DateFormatter.formatDate(list.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textDisabled,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildPopupMenu(l10n),
            ],
          ),
        ),
      ),
    );
  }

  /// Anneau de progression : l'etat de la liste d'un coup d'oeil.
  Widget _buildProgressRing(double progress, bool done) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3.5,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(
              done ? AppColors.primary : AppColors.primary,
            ),
          ),
          done
              ? const Icon(Icons.check_rounded,
                  size: 18, color: AppColors.primary)
              : Text(
                  '${(progress * 100).round()}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(AppLocalizations l10n) {
    return Builder(
      builder:
          (context) => PopupMenuButton(
            icon: Icon(
              Icons.more_vert,
              color: AppColors.textSecondary,
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
              Icon(Icons.edit, size: 18, color: AppColors.accent),
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
            Icon(Icons.copy, size: 18, color: AppColors.primary),
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
            Icon(Icons.receipt_long, size: 18, color: AppColors.accent),
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
                    color: AppColors.accent,
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
              Icon(Icons.share, size: 18, color: AppColors.accent),
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
              Icon(Icons.delete, size: 18, color: AppColors.error),
              const SizedBox(width: 8),
              Text(l10n.delete, style: TextStyle(color: AppColors.error)),
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
              Icon(Icons.exit_to_app, size: 18, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(l10n.leave, style: TextStyle(color: AppColors.warning)),
            ],
          ),
        ),
      );
    }

    return items;
  }
}
