// widgets/receipts/store_group_card.dart
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/receipt.dart';
import 'package:epilist/widgets/receipts/receipt_card.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart'; // Import ajouté
import 'package:flutter/material.dart';
import 'package:epilist/widgets/common/app_card.dart';

class StoreGroupCard extends StatefulWidget {
  final StoreReceiptGroup storeGroup;
  final bool canEdit;
  final Function(Receipt)? onEditReceipt;
  final Function(Receipt)? onDeleteReceipt;

  const StoreGroupCard({
    super.key,
    required this.storeGroup,
    required this.canEdit,
    this.onEditReceipt,
    this.onDeleteReceipt,
  });

  @override
  State<StoreGroupCard> createState() => _StoreGroupCardState();
}

class _StoreGroupCardState extends State<StoreGroupCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppCard.tight(
      radius: 14,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStoreHeader(),
                  const SizedBox(height: 12),
                  _buildStoreStats(l10n),
                ],
              ),
            ),
          ),
          if (_isExpanded) _buildReceiptsList(),
        ],
      ),
    );
  }

  Widget _buildStoreHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.store, color: AppColors.infoInk, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.storeGroup.storeName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              // CORRECTION: Calculer le total à partir des reçus
              FormattedAmount(
                amount: _calculateGroupTotal(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                showCode: false,
                fallbackCurrencyCode: 'CAD',
              ),
            ],
          ),
        ),
        Icon(
          _isExpanded ? Icons.expand_less : Icons.expand_more,
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildStoreStats(AppLocalizations l10n) {
    return Row(
      children: [
        _buildStatChip(
          icon: Icons.receipt,
          label: '${widget.storeGroup.receiptsCount} ${l10n.receipts}',
          color: AppColors.violet,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          icon: Icons.schedule,
          label:
              '${l10n.lastVisit}: ${_formatDate(widget.storeGroup.latestPurchase)}',
          color: AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTint.fill(color),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTint.line(color)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppTint.ink(color),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptsList() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Column(
        children:
            widget.storeGroup.receipts.map((receipt) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: ReceiptCard(
                  receipt: receipt,
                  canEdit: widget.canEdit,
                  onEdit: () => widget.onEditReceipt?.call(receipt),
                  onDelete: () => widget.onDeleteReceipt?.call(receipt),
                ),
              );
            }).toList(),
      ),
    );
  }

  // Méthode pour calculer le total du groupe
  double _calculateGroupTotal() {
    return widget.storeGroup.receipts.fold(
      0.0,
      (sum, receipt) => sum + receipt.totalAmount,
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
