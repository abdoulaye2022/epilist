// widgets/list_detail/list_stats_header.dart
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

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(2)} \$CAD';
  }

  @override
  Widget build(BuildContext context) {
    final progressPercentage =
        totalItems > 0 ? ((purchasedItems / totalItems) * 100).round() : 0;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Articles', '$purchasedItems/$totalItems'),
          _buildStatItem('Total', _formatPrice(totalPrice)),
          _buildStatItem('Progression', '$progressPercentage%'),
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
