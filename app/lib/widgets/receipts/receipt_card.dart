// widgets/receipts/receipt_card.dart
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/receipt.dart';
import 'package:flutter/material.dart';

class ReceiptCard extends StatelessWidget {
  final Receipt receipt;
  final bool canEdit;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ReceiptCard({
    super.key,
    required this.receipt,
    required this.canEdit,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            _buildReceiptInfo(context),
            if (receipt.notes != null && receipt.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildNotes(context),
            ],
            const SizedBox(height: 8),
            _buildDateInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.store, color: Colors.green[600], size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  receipt.storeName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (canEdit) _buildPopupMenu(context),
      ],
    );
  }

  Widget _buildReceiptInfo(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          receipt.formattedAmount,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green[600],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Text(
            _formatPurchaseDate(context, receipt.purchaseDate),
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotes(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.notes,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            receipt.notes!,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          '${l10n.added} ${_formatCreatedDate(context, receipt.createdAt)}',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopupMenuButton(
      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
      itemBuilder:
          (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20, color: Colors.blue[600]),
                  const SizedBox(width: 12),
                  Text(l10n.edit),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red[600]),
                  const SizedBox(width: 12),
                  Text(l10n.delete, style: TextStyle(color: Colors.red[600])),
                ],
              ),
            ),
          ],
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
    );
  }

  String _formatPurchaseDate(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return AppLocalizations.of(context)!.today;
    } else if (difference == 1) {
      return AppLocalizations.of(context)!.yesterday;
    } else if (difference < 7) {
      return AppLocalizations.of(context)!.daysAgo(difference);
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatCreatedDate(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return AppLocalizations.of(context)!.today;
    } else if (difference == 1) {
      return AppLocalizations.of(context)!.yesterday;
    } else if (difference < 7) {
      return AppLocalizations.of(context)!.daysAgo(difference);
    } else {
      return '${AppLocalizations.of(context)!.on} ${date.day}/${date.month}/${date.year}';
    }
  }
}
