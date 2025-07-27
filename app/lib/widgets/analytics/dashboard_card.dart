// widgets/analytics/dashboard_card.dart
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';

class DashboardCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const DashboardCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentMonth = data['current_month'] ?? {};
    final quickStats = data['quick_stats'] ?? {};

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard, color: Colors.green[600], size: 28),
                const SizedBox(width: 12),
                Text(
                  l10n.monthlyOverview,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Métriques principales
            Row(
              children: [
                Expanded(
                  child: _buildMetricBox(
                    l10n.totalSpent,
                    currentMonth['formatted_total'] ?? '0',
                    Icons.account_balance_wallet,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricBox(
                    l10n.itemsPurchased,
                    '${currentMonth['items_purchased'] ?? 0}',
                    Icons.shopping_cart,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildMetricBox(
                    l10n.uniqueProducts,
                    '${currentMonth['unique_products'] ?? 0}',
                    Icons.inventory,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricBox(
                    l10n.shoppingSessions,
                    '${currentMonth['shopping_sessions'] ?? 0}',
                    Icons.store,
                    Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // Statistiques rapides
            Text(
              l10n.quickStats,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  '${l10n.averageDailySpending}: ${quickStats['average_daily_spending']?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),

            if (quickStats['busiest_day_this_week'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${l10n.busiestDay}: ${quickStats['busiest_day_this_week']}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
