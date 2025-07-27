// widgets/list_detail/list_stats_header.dart - VERSION CORRIGÉE
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart'; // ✅ AJOUT
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
    final progressPercentage =
        totalItems > 0 ? ((purchasedItems / totalItems) * 100).round() : 0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(l10n.articles, '$purchasedItems/$totalItems'),
          // ✅ CORRECTION: Utiliser FormattedAmount pour le total
          _buildStatItemWithAmount(l10n.total, totalPrice),
          _buildStatItem(l10n.progress, '$progressPercentage%'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green[600],
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  // ✅ NOUVELLE MÉTHODE: Pour afficher les montants avec FormattedAmount
  Widget _buildStatItemWithAmount(String label, double amount) {
    return Column(
      children: [
        FormattedAmount(
          amount: amount,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green[600],
          ),
          showCode: false,
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
