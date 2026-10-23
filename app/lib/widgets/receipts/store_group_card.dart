// widgets/receipts/store_group_card.dart - Un magasin, ses factures.
//
// Les deux pastilles d'information — « 3 factures », « Derniere visite :
// 12/10/2026 » — tenaient dans une Row. Sur un ecran de 320 dp, elles
// debordaient de 29 px par la droite : la date etait coupee, et la rayure
// jaune et noire de Flutter s'affichait par-dessus.
//
// La cause tient en une phrase : une Row donne a ses enfants une largeur
// NON BORNEE. La pastille prenait donc sa largeur naturelle, le Flexible
// qu'elle contient n'avait rien contre quoi se retrecir, et c'est la Row
// du dessus qui debordait.
//
// C'est un Wrap maintenant. Il borne chaque ligne, donc le Flexible
// fonctionne, et la seconde pastille passe a la ligne au lieu d'etre
// coupee. Le texte de cet ecran grossit avec les reglages du telephone,
// et une Row ne peut pas s'etirer.
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
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sm),
            ),
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
            borderRadius: BorderRadius.circular(AppRadius.sm),
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

  Widget _buildStoreStats(AppLocalizations l10n) => StoreStatChips(
    receiptsCount: widget.storeGroup.receiptsCount,
    lastVisit: _formatDate(widget.storeGroup.latestPurchase),
  );

  Widget _buildReceiptsList() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.sm),
        ),
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

/// Les deux pastilles d'information d'un magasin : combien de factures,
/// et la derniere visite.
///
/// Publique, et c'est voulu : c'est elle qui debordait de 29 px sur un
/// ecran de 320 dp, et elle se teste SEULE. La carte entiere demande
/// les blocs de devise (`FormattedAmount`), que monter dans un test
/// couterait plus cher que ce qu'il verifierait.
class StoreStatChips extends StatelessWidget {
  const StoreStatChips({
    super.key,
    required this.receiptsCount,
    required this.lastVisit,
  });

  final int receiptsCount;

  /// La date, DEJA formatee : la mise en forme appartient a la carte,
  /// pas aux pastilles.
  final String lastVisit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Un Wrap, et non une Row : la seconde pastille passe a la ligne au
    // lieu d'etre coupee. Le texte de cet ecran grossit avec les
    // reglages du telephone, et une Row ne peut pas s'etirer.
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          _pastille(
            icon: Icons.receipt,
            label: '$receiptsCount ${l10n.receipts}',
            color: AppColors.violet,
          ),
          _pastille(
            icon: Icons.schedule,
            label: '${l10n.lastVisit}: $lastVisit',
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _pastille({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTint.fill(color),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppTint.line(color)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          // Le Flexible est SUR : dans un Wrap, la pastille recoit une
          // largeur bornee (celle d'une ligne du Wrap), et non pas
          // l'infini qu'une Row donne a ses enfants. C'etait tout le
          // probleme d'avant : la pastille prenait sa largeur naturelle
          // et c'est la Row du dessus qui debordait, de 29 px.
          //
          // Le Wrap passe a la ligne ; ce Flexible rattrape le cas
          // extreme — un libelle plus large qu'une ligne entiere, au
          // double grossissement.
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
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
}
