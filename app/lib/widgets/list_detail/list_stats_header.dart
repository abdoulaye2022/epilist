// widgets/list_detail/list_stats_header.dart - Bandeau de progression
// compact : une barre de progression + les chiffres sur UNE ligne, au lieu
// de l'ancien bloc à trois colonnes qui mangeait l'écran.
//
// Le total porte le NOMBRE D'ARTICLES SANS PRIX à côté de lui. Il
// affichait « 29,89 $ » — la somme des quatre articles qui avaient un
// prix — sans dire que trois autres n'en avaient pas : le chiffre se
// lisait comme le total de la liste, et il ne l'était pas.
import 'package:epilist/widgets/common/app_meters.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart';
import 'package:flutter/material.dart';

class ListStatsHeader extends StatelessWidget {
  final int totalItems;
  final int purchasedItems;
  final double totalPrice;

  /// Combien d'articles n'ont pas de prix. Zéro : le total est complet,
  /// et rien ne s'ajoute.
  final int itemsWithoutPrice;

  const ListStatsHeader({
    super.key,
    required this.totalItems,
    required this.purchasedItems,
    required this.totalPrice,
    this.itemsWithoutPrice = 0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = totalItems > 0 ? purchasedItems / totalItems : 0.0;
    final done = totalItems > 0 && purchasedItems == totalItems;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm + 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                done ? Icons.check_circle : Icons.shopping_basket_outlined,
                size: 16,
                color: done ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '$purchasedItems/$totalItems ${l10n.articles.toLowerCase()}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              FormattedAmount(
                amount: totalPrice,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
                showCode: false,
              ),
            ],
          ),
          if (itemsWithoutPrice > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                l10n.itemsWithoutPrice(itemsWithoutPrice),
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 16, color: AppColors.warningInk),
              ),
            ),
          const SizedBox(height: 8),
          AppGauge(
            ratio: progress,
            label: l10n.listCheckedSentence(purchasedItems, totalItems),
          ),
        ],
      ),
    );
  }
}
