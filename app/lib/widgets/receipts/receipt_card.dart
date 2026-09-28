// widgets/receipts/receipt_card.dart
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/receipt.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart'; // Import ajouté
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

    // Carte plate bordée, sans ombre : le gabarit commun de l'app.
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
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
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.store, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  receipt.storeName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
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
        // CORRECTION : Utilisation de FormattedAmount au lieu de receipt.formattedAmount
        FormattedAmount(
          amount: receipt.totalAmount,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          showCode: false, // Pas d'affichage du code de devise ici
          fallbackCurrencyCode: 'CAD', // Devise de fallback
        ),
        // Puce de date neutre (fini le bleu qui détonnait).
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            _formatPurchaseDate(context, receipt.purchaseDate),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
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
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.notes,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            receipt.notes!,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Icon(Icons.access_time, size: 14, color: AppColors.textDisabled),
        const SizedBox(width: 4),
        Text(
          '${l10n.added} ${_formatCreatedDate(context, receipt.createdAt)}',
          style: TextStyle(fontSize: 12, color: AppColors.textDisabled),
        ),
      ],
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopupMenuButton(
      icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
      itemBuilder:
          (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined,
                      size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Text(l10n.edit),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete_outline,
                      size: 20, color: AppColors.error),
                  const SizedBox(width: 12),
                  Text(l10n.delete,
                      style: const TextStyle(color: AppColors.error)),
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
