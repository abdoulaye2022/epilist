// widgets/list_detail/list_stats_header.dart - Bandeau de progression
// compact : une barre de progression + les chiffres sur UNE ligne, au lieu
// de l'ancien bloc à trois colonnes qui mangeait l'écran.
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart';
import 'package:flutter/material.dart';

class ListStatsHeader extends StatelessWidget {
  final int totalItems;
  final int purchasedItems;
  final double totalPrice;

  const ListStatsHeader({
    super.key,
    required this.totalItems,
    required this.purchasedItems,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = totalItems > 0 ? purchasedItems / totalItems : 0.0;
    final done = totalItems > 0 && purchasedItems == totalItems;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm + 4),
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              FormattedAmount(
                amount: totalPrice,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
                showCode: false,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
