// widgets/analytics/dashboard_card.dart - VERSION AVEC TRADUCTION DES JOURS
import 'package:epilist/theme/app_theme.dart';
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
                Icon(Icons.dashboard, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.monthlyOverview,
                        style: TextStyle(
                          fontFamily: AppFonts.display,
                          fontVariations: const [FontVariation('wght', 800)],
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      // ✅ NOUVEAU: Indicateur de source des données
                      if (!includeShared)
                        Text(
                          l10n.ownListsOnly,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.warning,
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
                    AppColors.success,
                    isAmount: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricBox(
                    l10n.itemsPurchased,
                    (currentMonth['items_purchased'] ?? 0).toDouble(),
                    Icons.shopping_cart,
                    AppColors.info,
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
                    AppColors.warning,
                    isAmount: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricBox(
                    l10n.shoppingSessions,
                    (currentMonth['shopping_sessions'] ?? 0).toDouble(),
                    Icons.store,
                    AppColors.violet,
                    isAmount: false,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Divider(color: AppColors.border),
            const SizedBox(height: 16),

            // ✅ Section des 7 derniers jours avec traduction
            if (last7Days.isNotEmpty) ...[
              Text(
                l10n.last7Days,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
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
              Divider(color: AppColors.border),
              const SizedBox(height: 12),
            ],

            // ✅ Statistiques rapides avec traduction du jour le plus actif
            Text(
              l10n.quickStats,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Icon(Icons.trending_up, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${l10n.averageDailySpending}: ',
                  style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                ),
                FormattedAmount(
                  amount:
                      quickStats['average_daily_spending']?.toDouble() ?? 0.0,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  showCode: false,
                ),
              ],
            ),

            if (last7Days.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.busiestDay}: ${_getBusiestDay(last7Days, l10n)}', // ✅ AJOUT: Passer l10n
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.local_offer, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${l10n.highestPurchase}: ',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  FormattedAmount(
                    amount: _getHighestDaySpending(last7Days),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                    showCode: false,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.insights, color: AppColors.violet, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.weeklyActivity}: ${_getActiveDaysCount(last7Days)} jours actifs',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
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
        if (lowerDay.startsWith('mon') || lowerDay.startsWith('lun')) {
          return l10n.monday;
        }
        if (lowerDay.startsWith('tue') || lowerDay.startsWith('mar')) {
          return l10n.tuesday;
        }
        if (lowerDay.startsWith('wed') || lowerDay.startsWith('mer')) {
          return l10n.wednesday;
        }
        if (lowerDay.startsWith('thu') || lowerDay.startsWith('jeu')) {
          return l10n.thursday;
        }
        if (lowerDay.startsWith('fri') || lowerDay.startsWith('ven')) {
          return l10n.friday;
        }
        if (lowerDay.startsWith('sat') || lowerDay.startsWith('sam')) {
          return l10n.saturday;
        }
        if (lowerDay.startsWith('sun') || lowerDay.startsWith('dim')) {
          return l10n.sunday;
        }

        return dayName; // Retourner tel quel si pas de correspondance
    }
  }

  /// ✅ NOUVEAU: Traduit une abréviation de jour (anglais vers français)

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
        color: AppColors.infoTint,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.infoInk),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.dataSourceBreakdown,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
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
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${l10n.myLists}: ${ownPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 14.5),
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
                        color: AppColors.info.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${l10n.sharedLists}: ${sharedPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 14.5),
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
    // Le chiffre d'abord, en grand, et son nom en dessous en entier :
    // la planche veut « des chiffres grands et lisibles ». Il etait en
    // 18 points sous un libelle de 12.
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTint.fill(color),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTint.ink(color), size: 26),
          const SizedBox(height: AppSpacing.sm),
          if (isAmount)
            FormattedAmount(
              amount: value,
              style: AppFonts.displayStyle(
                size: 30,
                color: AppTint.ink(color),
                height: 1.1,
              ),
              showCode: false,
            )
          else
            Text(
              value.toInt().toString(),
              style: AppFonts.displayStyle(
                size: 30,
                color: AppTint.ink(color),
                height: 1.1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              height: 1.35,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 3,
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
        color: totalSpent > 0 ? AppColors.successTint : AppColors.shadow,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color:
              totalSpent > 0
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.shadow,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dayShort,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          if (totalSpent > 0)
            Flexible(
              child: FormattedAmount(
                amount: totalSpent,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
                showCode: false,
              ),
            )
          else
            Text(
              '-',
              style: TextStyle(fontSize: 14.5, color: AppColors.textSecondary),
            ),
          const SizedBox(height: 1),
          Text(
            '$itemsCount',
            style: TextStyle(fontSize: 14.5, color: AppColors.textSecondary),
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
