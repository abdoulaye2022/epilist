// widgets/list_detail/list_stats_header.dart
import 'package:epilist/l10n/app_localizations.dart';
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

  String _formatPrice(BuildContext context, double price) {
    final l10n = AppLocalizations.of(context)!;
    return '${price.toStringAsFixed(2)}${l10n.cad}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progressPercentage =
        totalItems > 0 ? ((purchasedItems / totalItems) * 100).round() : 0;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(l10n.articles, '$purchasedItems/$totalItems'),
          _buildStatItem(l10n.total, _formatPrice(context, totalPrice)),
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
}
