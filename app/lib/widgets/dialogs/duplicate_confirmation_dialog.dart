// widgets/dialogs/duplicate_confirmation_dialog.dart - VERSION TRADUITE
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:epilist/blocs/list_item/list_item_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';

class DuplicateConfirmationDialog extends StatelessWidget {
  final String message;
  final List<DuplicateItem> duplicates;
  final String productName;
  final int quantity;
  final double? price;
  final String? storeName;
  final int listId;
  final Function(DuplicateAction, {int? existingItemId}) onActionSelected;

  const DuplicateConfirmationDialog({
    super.key,
    required this.message,
    required this.duplicates,
    required this.productName,
    required this.quantity,
    this.price,
    this.storeName,
    required this.listId,
    required this.onActionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 500,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIcon(),
                    const SizedBox(height: 12),
                    _buildTitle(l10n),
                    const SizedBox(height: 12),
                    _buildMessage(),
                    const SizedBox(height: 20),
                    _buildNewItemInfo(l10n),
                    const SizedBox(height: 16),
                    _buildDuplicatesList(l10n),
                  ],
                ),
              ),
            ),
            _buildActions(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.warning_rounded, size: 22, color: AppColors.warning),
    );
  }

  Widget _buildTitle(AppLocalizations l10n) {
    return Text(
      l10n.similarItemDetected, // ✅ TRADUIT
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildMessage() {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13.5,
        color: AppColors.textSecondary,
        height: 1.4,
      ),
    );
  }

  Widget _buildNewItemInfo(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.itemToAdd, // ✅ TRADUIT
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow(l10n.product, productName, l10n), // ✅ TRADUIT
          _buildInfoRow(l10n.quantity, quantity.toString(), l10n), // ✅ TRADUIT
          if (price != null)
            _buildInfoRow(
              l10n.priceCAD,
              '${price!.toStringAsFixed(2)} \$CAD',
              l10n,
            ), // ✅ TRADUIT
          if (storeName != null && storeName!.isNotEmpty)
            _buildInfoRow(l10n.store, storeName!, l10n), // ✅ TRADUIT
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuplicatesList(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              l10n.similarItemsFound, // ✅ TRADUIT
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: duplicates.length,
              separatorBuilder:
                  (context, index) =>
                      Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) {
                final duplicate = duplicates[index];
                return _buildDuplicateItem(duplicate, l10n);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuplicateItem(DuplicateItem duplicate, AppLocalizations l10n) {
    Color matchColor =
        duplicate.suggestionType == DuplicateType.exactMatch
            ? AppColors.error
            : AppColors.warning;

    return ListTile(
      dense: true,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: matchColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              duplicate.suggestionType == DuplicateType.exactMatch
                  ? Icons.warning
                  : Icons.info,
              color: matchColor,
              size: 16,
            ),
            Text(
              '${duplicate.similarityScore}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: matchColor,
              ),
            ),
          ],
        ),
      ),
      title: Text(
        duplicate.productName,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${l10n.quantityShort}: ${duplicate.quantity}'), // ✅ TRADUIT
              if (duplicate.price != null)
                Text(' • ${duplicate.formattedPrice}'),
            ],
          ),
          if (duplicate.storeName != null && duplicate.storeName!.isNotEmpty)
            Text(
              duplicate.storeName!,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
        ],
      ),
      trailing:
          duplicate.suggestionType == DuplicateType.exactMatch
              ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  l10n.identical, // ✅ TRADUIT
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              )
              : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Text(
                  l10n.similar, // ✅ TRADUIT
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ),
      // ✅ CORRECTION: Ne pas gérer le tap ici pour éviter l'erreur de contexte
      onTap:
          duplicate.suggestionType == DuplicateType.exactMatch
              ? () {
                debugPrint(
                  '🎯 Sélection pour fusion: ${duplicate.productName}',
                );
                // Juste indiquer visuellement la sélection
              }
              : null,
    );
  }

  // ✅ CORRECTION: Passer le contexte en paramètre
  Widget _buildActions(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Bouton principal : Fusionner (si match exact)
          if (duplicates.any(
            (d) => d.suggestionType == DuplicateType.exactMatch,
          )) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                // ✅ CORRECTION: Utiliser le contexte passé en paramètre
                onPressed: () {
                  final exactMatch = duplicates.firstWhere(
                    (d) => d.suggestionType == DuplicateType.exactMatch,
                  );
                  debugPrint('🎯 Fusion avec item ${exactMatch.id}');
                  onActionSelected(
                    DuplicateAction.merge,
                    existingItemId: exactMatch.id,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.merge, size: 18),
                label: Text(
                  // ✅ CHANGÉ: Retiré const
                  l10n.mergeWithExisting, // ✅ TRADUIT
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Actions secondaires
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    debugPrint('🎯 Annulation');
                    onActionSelected(DuplicateAction.cancel);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: Text(
                    l10n.cancel, // ✅ TRADUIT
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    debugPrint('🎯 Ajout forcé');
                    onActionSelected(DuplicateAction.forceAdd);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    // ✅ CHANGÉ: Retiré const
                    l10n.addAnyway, // ✅ TRADUIT
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
