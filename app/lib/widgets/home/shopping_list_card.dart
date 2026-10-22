// widgets/home/shopping_list_card.dart - VERSION SIMPLIFIÉE POUR HOME SCREEN
import 'package:epilist/widgets/common/app_meters.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/screens/receipts_screen.dart';
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
    final percent = (progress * 100).round();
    final done = list.isCompleted && totalItems > 0;

    // La bordure prend la couleur de l'avancement : verte quand c'est
    // fini, vive quand ca avance, orange au debut. Elle ne porte jamais
    // le sens seule — les phrases en dessous le disent.
    final teinte =
        totalItems == 0
            ? AppColors.border
            : done
            ? AppColors.primary
            : percent >= 50
            ? AppColors.primaryVivid
            : AppColors.warning;

    final noms =
        list.sharedWith
            .map((p) => p.sharedWithUser?.firstName ?? '')
            .where((n) => n.isNotEmpty)
            .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: teinte, width: 3),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md + 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      list.name,
                      style: AppFonts.displayStyle(
                        size: 23,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (list.isShared)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: Icon(
                        Icons.people_alt_rounded,
                        size: 24,
                        color: AppColors.accent,
                      ),
                    ),
                  _buildPopupMenu(l10n),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              // Trois phrases, la ou tenait « 14/17 articles » en 12,5
              // points : l'etat de la liste se lisait a la loupe, et le
              // reste a prendre n'etait ecrit nulle part.
              Text(
                totalItems == 0
                    ? l10n.listEmptySentence
                    : [
                      l10n.listFullSentence('$percent'),
                      l10n.listCheckedSentence(completedItems, totalItems),
                      l10n.listRemainingSentence(totalItems - completedItems),
                    ].join(' '),
                style: TextStyle(
                  fontSize: 18,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),

              if (totalItems > 0) ...[
                const SizedBox(height: AppSpacing.sm + 2),
                AppGauge(
                  ratio: progress,
                  color: teinte,
                  label: l10n.listGaugeLabel('$percent'),
                ),
              ],

              if (list.isShared) ...[
                const SizedBox(height: AppSpacing.sm + 4),
                _buildCollaborators(l10n, noms),
              ],

              if (list.hasReceipts) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${l10n.receipts} : ${list.receiptsCount}',
                  style: TextStyle(
                    fontSize: 17,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.shopping_cart_checkout_rounded),
                label: Text(l10n.listOpenAndShop),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Les collaborateurs : leurs initiales en pastilles colorees, ET
  /// leurs noms ecrits en toutes lettres. La pastille seule ne dit rien
  /// a qui ne connait pas la couleur de chacun.
  Widget _buildCollaborators(AppLocalizations l10n, List<String> noms) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (noms.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm + 2),
            child: SizedBox(
              height: 38,
              width: 38 + (noms.length - 1) * 29,
              child: Stack(
                children: [
                  for (final (i, nom) in noms.indexed)
                    Positioned(
                      left: i * 29,
                      child: Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.chart[i % AppColors.chart.length],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          nom.characters.first.toUpperCase(),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onOverlay,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        Expanded(
          child: Text(
            noms.isEmpty
                ? l10n.listSharedNoNames
                : l10n.listCollaborators(_enumerate(noms)),
            style: TextStyle(
              fontSize: 17.5,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  /// « Sara, Malik et Chloé » — avec le « et » avant le dernier.
  String _enumerate(List<String> noms) {
    if (noms.length == 1) return noms.first;
    return '${noms.sublist(0, noms.length - 1).join(', ')} et ${noms.last}';
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
            if ((list.hasReceipts)) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.infoTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${list.receiptsCount}',
                  style: TextStyle(
                    fontSize: 14.5,
                    color: AppColors.infoInk,
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
