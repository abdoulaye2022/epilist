// widgets/analytics/dashboard_card.dart - VERSION CORRIGÉE POUR LA NOUVELLE API
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart';

class DashboardCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const DashboardCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // ✅ CORRECTION: Accès correct aux données selon la nouvelle structure API
    final currentMonth = data['current_month'] ?? {};
    final quickStats = data['quick_stats'] ?? {};
    final last7Days = data['last_7_days'] as List<dynamic>? ?? [];

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

            // ✅ CORRECTION: Métriques principales avec les bonnes clés de l'API
            Row(
              children: [
                Expanded(
                  child: _buildMetricBox(
                    l10n.totalSpent,
                    currentMonth['total_spent']?.toDouble() ?? 0.0,
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

            // ✅ AJOUT: Section des 7 derniers jours
            if (last7Days.isNotEmpty) ...[
              Text(
                l10n.last7Days ?? 'Derniers 7 jours',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // ✅ CORRECTION: Affichage compact des 7 derniers jours avec protection overflow
              SizedBox(
                height: 70, // ✅ Hauteur légèrement augmentée
                child:
                    last7Days.length <= 4
                        ? // ✅ Si 4 jours ou moins, affichage en ligne
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children:
                              last7Days.take(4).map((dayData) {
                                return Flexible(
                                  child: _buildDayCard(
                                    dayData as Map<String, dynamic>,
                                  ),
                                );
                              }).toList(),
                        )
                        : // ✅ Si plus de 4 jours, ListView scrollable
                        ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: last7Days.length,
                          itemBuilder: (context, index) {
                            final dayData =
                                last7Days[index] as Map<String, dynamic>;
                            return _buildDayCard(dayData);
                          },
                        ),
              ),

              const SizedBox(height: 16),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 12),
            ],

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

            // ✅ AJOUT: Calcul et affichage du jour le plus actif basé sur last_7_days
            if (last7Days.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.busiestDay ?? "Jour le plus actif"}: ${_getBusiestDay(last7Days)}',
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

            // ✅ AJOUT: Calcul et affichage du plus gros achat basé sur last_7_days
            if (last7Days.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.local_offer, color: Colors.red[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${l10n.highestPurchase ?? "Plus gros jour"}: ',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  FormattedAmount(
                    amount: _getHighestDaySpending(last7Days),
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

            // ✅ AJOUT: Activité cette semaine
            if (last7Days.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.insights, color: Colors.purple[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.weeklyActivity ?? "Activité hebdomadaire"}: ${_getActiveDaysCount(last7Days)} jours actifs',
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

  // ✅ NOUVELLE MÉTHODE: Widget pour une carte de jour
  Widget _buildDayCard(Map<String, dynamic> dayData) {
    final totalSpent = dayData['total_spent']?.toDouble() ?? 0.0;
    final itemsCount = dayData['items_count'] ?? 0;
    final dayName = dayData['day_name'] ?? '';

    return Container(
      width: 75, // ✅ Largeur légèrement réduite
      margin: const EdgeInsets.only(right: 6), // ✅ Marge réduite
      padding: const EdgeInsets.all(6), // ✅ Padding réduit
      decoration: BoxDecoration(
        color:
            totalSpent > 0
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              totalSpent > 0
                  ? Colors.green.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // ✅ AJOUT: Éviter l'expansion
        children: [
          Text(
            dayName.length >= 3 ? dayName.substring(0, 3) : dayName,
            style: const TextStyle(
              fontSize: 9, // ✅ Taille réduite
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          if (totalSpent > 0)
            Flexible(
              // ✅ AJOUT: Protection overflow
              child: FormattedAmount(
                amount: totalSpent,
                style: const TextStyle(
                  fontSize: 9, // ✅ Taille réduite
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                showCode: false,
              ),
            )
          else
            const Text('-', style: TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 1),
          Text(
            '$itemsCount',
            style: const TextStyle(fontSize: 8, color: Colors.black54),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ✅ NOUVELLES MÉTHODES UTILITAIRES pour analyser les données des 7 derniers jours

  String _getBusiestDay(List<dynamic> last7Days) {
    if (last7Days.isEmpty) return 'N/A';

    var busiestDay = last7Days.first as Map<String, dynamic>;
    double maxSpent = busiestDay['total_spent']?.toDouble() ?? 0.0;

    for (var day in last7Days) {
      final dayData = day as Map<String, dynamic>;
      final spent = dayData['total_spent']?.toDouble() ?? 0.0;
      if (spent > maxSpent) {
        maxSpent = spent;
        busiestDay = dayData;
      }
    }

    return maxSpent > 0 ? (busiestDay['day_name'] ?? 'N/A') : 'Aucun';
  }

  double _getHighestDaySpending(List<dynamic> last7Days) {
    if (last7Days.isEmpty) return 0.0;

    double maxSpent = 0.0;
    for (var day in last7Days) {
      final dayData = day as Map<String, dynamic>;
      final spent = dayData['total_spent']?.toDouble() ?? 0.0;
      if (spent > maxSpent) {
        maxSpent = spent;
      }
    }

    return maxSpent;
  }

  int _getActiveDaysCount(List<dynamic> last7Days) {
    if (last7Days.isEmpty) return 0;

    return last7Days.where((day) {
      final dayData = day as Map<String, dynamic>;
      final spent = dayData['total_spent']?.toDouble() ?? 0.0;
      return spent > 0;
    }).length;
  }
}
