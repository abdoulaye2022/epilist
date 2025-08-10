// widgets/analytics/dashboard_card.dart - VERSION AVEC TRADUCTION DES JOURS
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart';

class DashboardCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const DashboardCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // ✅ NOUVEAU: Récupérer les informations de filtrage
    final includeShared = data['include_shared'] ?? true;
    final dataBreakdown = data['data_breakdown'] as Map<String, dynamic>?;

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
            // ✅ Header avec indicateur de filtrage
            Row(
              children: [
                Icon(Icons.dashboard, color: Colors.green[600], size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.monthlyOverview,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      // ✅ NOUVEAU: Indicateur de source des données
                      if (!includeShared)
                        Text(
                          l10n.ownListsOnly ?? 'Listes personnelles uniquement',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                const CurrencyIndicator(),
              ],
            ),

            // ✅ NOUVEAU: Affichage du breakdown si disponible et listes partagées incluses
            if (includeShared && dataBreakdown != null)
              _buildDataSourceInfo(context, dataBreakdown),

            const SizedBox(height: 20),

            // ✅ Métriques principales (inchangées)
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

            // ✅ Section des 7 derniers jours avec traduction
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

              SizedBox(
                height: 70,
                child:
                    last7Days.length <= 4
                        ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children:
                              last7Days.take(4).map((dayData) {
                                return Flexible(
                                  child: _buildDayCard(
                                    dayData as Map<String, dynamic>,
                                    l10n, // ✅ AJOUT: Passer l10n pour traduction
                                  ),
                                );
                              }).toList(),
                        )
                        : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: last7Days.length,
                          itemBuilder: (context, index) {
                            final dayData =
                                last7Days[index] as Map<String, dynamic>;
                            return _buildDayCard(
                              dayData,
                              l10n, // ✅ AJOUT: Passer l10n pour traduction
                            );
                          },
                        ),
              ),

              const SizedBox(height: 16),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 12),
            ],

            // ✅ Statistiques rapides avec traduction du jour le plus actif
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

            if (last7Days.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.busiestDay ?? "Jour le plus actif"}: ${_getBusiestDay(last7Days, l10n)}', // ✅ AJOUT: Passer l10n
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
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

  // ==================== TRADUCTION DES JOURS ====================

  /// ✅ NOUVEAU: Traduit un nom de jour complet (anglais vers français)
  String _translateDayName(String dayName, AppLocalizations l10n) {
    if (dayName.isEmpty) return dayName;

    final lowerDay = dayName.toLowerCase().trim();

    // Mapping des noms complets
    switch (lowerDay) {
      case 'monday':
      case 'lundi':
        return l10n.monday;
      case 'tuesday':
      case 'mardi':
        return l10n.tuesday;
      case 'wednesday':
      case 'mercredi':
        return l10n.wednesday;
      case 'thursday':
      case 'jeudi':
        return l10n.thursday;
      case 'friday':
      case 'vendredi':
        return l10n.friday;
      case 'saturday':
      case 'samedi':
        return l10n.saturday;
      case 'sunday':
      case 'dimanche':
        return l10n.sunday;
      default:
        // Fallback: essayer de détecter par les premières lettres
        if (lowerDay.startsWith('mon') || lowerDay.startsWith('lun'))
          return l10n.monday;
        if (lowerDay.startsWith('tue') || lowerDay.startsWith('mar'))
          return l10n.tuesday;
        if (lowerDay.startsWith('wed') || lowerDay.startsWith('mer'))
          return l10n.wednesday;
        if (lowerDay.startsWith('thu') || lowerDay.startsWith('jeu'))
          return l10n.thursday;
        if (lowerDay.startsWith('fri') || lowerDay.startsWith('ven'))
          return l10n.friday;
        if (lowerDay.startsWith('sat') || lowerDay.startsWith('sam'))
          return l10n.saturday;
        if (lowerDay.startsWith('sun') || lowerDay.startsWith('dim'))
          return l10n.sunday;

        return dayName; // Retourner tel quel si pas de correspondance
    }
  }

  /// ✅ NOUVEAU: Traduit une abréviation de jour (anglais vers français)
  String _translateDayShort(String dayShort, AppLocalizations l10n) {
    if (dayShort.isEmpty) return dayShort;

    final lowerShort = dayShort.toLowerCase().trim();

    // Mapping des abréviations
    switch (lowerShort) {
      case 'mon':
      case 'lun':
        return l10n.mondayShort;
      case 'tue':
      case 'mar':
        return l10n.tuesdayShort;
      case 'wed':
      case 'mer':
        return l10n.wednesdayShort;
      case 'thu':
      case 'jeu':
        return l10n.thursdayShort;
      case 'fri':
      case 'ven':
        return l10n.fridayShort;
      case 'sat':
      case 'sam':
        return l10n.saturdayShort;
      case 'sun':
      case 'dim':
        return l10n.sundayShort;
      default:
        // Fallback: si c'est plus long, prendre les 3 premières lettres
        if (dayShort.length > 3) {
          return _translateDayShort(dayShort.substring(0, 3), l10n);
        }
        return dayShort;
    }
  }

  // ✅ NOUVEAU: Widget pour afficher les informations de source des données
  Widget _buildDataSourceInfo(
    BuildContext context,
    Map<String, dynamic> breakdown,
  ) {
    final l10n = AppLocalizations.of(context)!;

    final ownTotal = breakdown['own_lists_total']?.toDouble() ?? 0.0;
    final sharedTotal = breakdown['shared_lists_total']?.toDouble() ?? 0.0;
    final ownPercentage = breakdown['own_lists_percentage']?.toDouble() ?? 0.0;
    final sharedPercentage =
        breakdown['shared_lists_percentage']?.toDouble() ?? 0.0;

    // Ne pas afficher si pas de données
    if (ownTotal == 0 && sharedTotal == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.dataSourceBreakdown ?? 'Sources des données',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              // Mes listes
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${l10n.myLists ?? "Mes listes"}: ${ownPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Listes partagées
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${l10n.sharedLists ?? "Partagées"}: ${sharedPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ Méthodes existantes inchangées
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

  // ✅ MODIFIÉ: Widget de carte jour avec traduction
  Widget _buildDayCard(Map<String, dynamic> dayData, AppLocalizations l10n) {
    final totalSpent = dayData['total_spent']?.toDouble() ?? 0.0;
    final itemsCount = dayData['items_count'] ?? 0;
    final dayName = dayData['day_name'] ?? '';

    // ✅ CORRECTION: Traduire le nom du jour
    final translatedDayName = _translateDayName(dayName, l10n);
    final dayShort =
        translatedDayName.length >= 3
            ? translatedDayName.substring(0, 3)
            : translatedDayName;

    return Container(
      width: 75,
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.all(6),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dayShort,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          if (totalSpent > 0)
            Flexible(
              child: FormattedAmount(
                amount: totalSpent,
                style: const TextStyle(
                  fontSize: 9,
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

  // ✅ MODIFIÉ: Méthode pour obtenir le jour le plus actif avec traduction
  String _getBusiestDay(List<dynamic> last7Days, AppLocalizations l10n) {
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

    if (maxSpent > 0) {
      final dayName = busiestDay['day_name'] ?? 'N/A';
      // ✅ CORRECTION: Traduire le nom du jour
      return _translateDayName(dayName, l10n);
    }

    return 'Aucun';
  }

  // ✅ Méthodes utilitaires inchangées
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
