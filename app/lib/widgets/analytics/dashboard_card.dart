// widgets/analytics/dashboard_card.dart - VERSION AVEC FormattedAmount
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart';

class DashboardCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const DashboardCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentMonth = data['current_month'] ?? {};
    final quickStats = data['quick_stats'] ?? {};

    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard, color: Colors.green[600], size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.monthlyOverview,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // ✅ AJOUT: Indicateur de devise dans le header
                const CurrencyIndicator(),
              ],
            ),
            const SizedBox(height: 20),

            // Métriques principales avec FormattedAmount
            Row(
              children: [
                Expanded(
                  child: _buildMetricBox(
                    l10n.totalSpent,
                    currentMonth['total']?.toDouble() ?? 0.0,
                    Icons.account_balance_wallet,
                    Colors.green,
                    isAmount: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricBox(
                    l10n.itemsPurchased,
                    (currentMonth['items_purchased'] ?? 0).toDouble(),
                    Icons.shopping_cart,
                    Colors.blue,
                    isAmount: false,
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
                    (currentMonth['unique_products'] ?? 0).toDouble(),
                    Icons.inventory,
                    Colors.orange,
                    isAmount: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricBox(
                    l10n.shoppingSessions,
                    (currentMonth['shopping_sessions'] ?? 0).toDouble(),
                    Icons.store,
                    Colors.purple,
                    isAmount: false,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 16),

            // Statistiques rapides avec FormattedAmount
            Text(
              l10n.quickStats,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  '${l10n.averageDailySpending}: ',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                // ✅ REMPLACEMENT: Utilisation de FormattedAmount
                FormattedAmount(
                  amount:
                      quickStats['average_daily_spending']?.toDouble() ?? 0.0,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  showCode: false,
                ),
              ],
            ),

            if (quickStats['busiest_day_this_week'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.busiestDay}: ${quickStats['busiest_day_this_week']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Statistiques supplémentaires avec FormattedAmount si disponibles
            if (quickStats['highest_single_purchase'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.local_offer, color: Colors.red[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${l10n.highestPurchase ?? "Plus gros achat"}: ',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  FormattedAmount(
                    amount:
                        quickStats['highest_single_purchase']?.toDouble() ??
                        0.0,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[600],
                    ),
                    showCode: false,
                  ),
                ],
              ),
            ],

            if (quickStats['most_frequent_category'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.category, color: Colors.purple[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.topCategory ?? "Catégorie principale"}: ${quickStats['most_frequent_category']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
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
    double value,
    IconData icon,
    Color color, {
    bool isAmount = false,
  }) {
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
          // ✅ LOGIQUE CONDITIONNELLE: FormattedAmount pour les montants, Text pour les nombres
          if (isAmount)
            FormattedAmount(
              amount: value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              showCode: false,
            )
          else
            Text(
              value.toInt().toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
