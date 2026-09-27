// widgets/analytics/top_products_card.dart - VERSION AVEC FormattedAmount
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/blocs/analytics/analytics_bloc.dart';
import 'package:epilist/blocs/analytics/analytics_event.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart';

class TopProductsCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const TopProductsCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final products = data['products'] as List<dynamic>? ?? [];
    final summary = data['summary'] ?? {};
    final sortBy = data['sort_by'] ?? 'total_spent';

    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber[600], size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.topProducts,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const CurrencyIndicator(),
                const SizedBox(width: 8),
                _buildSortButton(context, sortBy, l10n),
              ],
            ),
            const SizedBox(height: 20),

            // Résumé
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[100]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.totalProducts,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${summary['total_unique_products'] ?? 0}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.showing,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${summary['showing_top'] ?? 0}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Liste des produits
            if (products.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.shopping_basket,
                        size: 48,
                        color: AppColors.textDisabled,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.noProductsData,
                        style: TextStyle(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children:
                    products.asMap().entries.map<Widget>((entry) {
                      final index = entry.key;
                      final product = entry.value;
                      return _buildProductItem(
                        product,
                        index + 1,
                        sortBy,
                        l10n,
                      );
                    }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortButton(
    BuildContext context,
    String currentSort,
    AppLocalizations l10n,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: PopupMenuButton<String>(
        icon: Icon(Icons.sort, color: AppColors.textSecondary),
        tooltip: l10n.sortBy,
        onSelected: (sortBy) {
          context.read<AnalyticsBloc>().add(
            ChangeTopProductsSort(sortBy: sortBy, period: 'month', limit: 10),
          );
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        color: Colors.white,
        elevation: 8,
        itemBuilder:
            (context) => [
              PopupMenuItem(
                value: 'total_spent',
                child: Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      size: 20,
                      color:
                          currentSort == 'total_spent'
                              ? AppColors.primary
                              : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.sortByAmount,
                        style: TextStyle(
                          fontWeight:
                              currentSort == 'total_spent'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          color:
                              currentSort == 'total_spent'
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (currentSort == 'total_spent')
                      Icon(Icons.check, color: AppColors.primary, size: 18),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'quantity',
                child: Row(
                  children: [
                    Icon(
                      Icons.numbers,
                      size: 20,
                      color:
                          currentSort == 'quantity'
                              ? AppColors.primary
                              : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.sortByQuantity,
                        style: TextStyle(
                          fontWeight:
                              currentSort == 'quantity'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          color:
                              currentSort == 'quantity'
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (currentSort == 'quantity')
                      Icon(Icons.check, color: AppColors.primary, size: 18),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'frequency',
                child: Row(
                  children: [
                    Icon(
                      Icons.repeat,
                      size: 20,
                      color:
                          currentSort == 'frequency'
                              ? AppColors.primary
                              : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.sortByFrequency,
                        style: TextStyle(
                          fontWeight:
                              currentSort == 'frequency'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          color:
                              currentSort == 'frequency'
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (currentSort == 'frequency')
                      Icon(Icons.check, color: AppColors.primary, size: 18),
                  ],
                ),
              ),
            ],
      ),
    );
  }

  Widget _buildProductItem(
    Map<String, dynamic> product,
    int rank,
    String sortBy,
    AppLocalizations l10n,
  ) {
    final productName = product['product_name'] ?? l10n.unknownProduct;
    final totalSpent = product['total_spent']?.toDouble() ?? 0.0;
    final totalQuantity = product['total_quantity'] ?? 0;
    final frequency = product['purchase_frequency'] ?? 0;
    final averagePrice = product['average_price']?.toDouble() ?? 0.0;
    final stores = product['stores'] as List<dynamic>? ?? [];

    // Déterminer la valeur principale selon le tri
    Widget mainValue;
    String subValue;
    IconData icon;
    Color color;

    switch (sortBy) {
      case 'quantity':
        mainValue = Text(
          '$totalQuantity',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.accent,
          ),
        );
        subValue = '${l10n.itemsCount}';
        icon = Icons.shopping_cart;
        color = AppColors.accent;
        break;
      case 'frequency':
        mainValue = Text(
          '$frequency',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.purple[600],
          ),
        );
        subValue = '${l10n.timesPlural}';
        icon = Icons.repeat;
        color = Colors.purple[600]!;
        break;
      default: // total_spent
        mainValue = FormattedAmount(
          amount: totalSpent,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
          showCode: false,
        );
        subValue = '$totalQuantity ${l10n.itemsCount}';
        icon = Icons.attach_money;
        color = AppColors.primary;
        break;
    }

    // Couleur pour le rang
    Color rankColor = AppColors.textSecondary;
    if (rank <= 3) {
      rankColor =
          [
            Colors.amber[600]!, // 1er - Or
            AppColors.textDisabled, // 2ème - Argent
            AppColors.warning, // 3ème - Bronze
          ][rank - 1];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Rang
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: rankColor, shape: BoxShape.circle),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Informations du produit
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (stores.isNotEmpty)
                  Text(
                    '${l10n.storesLabel}: ${stores.take(2).join(', ')}${stores.length > 2 ? '...' : ''}',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                // ✅ REMPLACEMENT: FormattedAmount pour le prix moyen
                Row(
                  children: [
                    Text(
                      '${l10n.averagePriceLabel}: ',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Flexible(
                      child: FormattedAmount(
                        amount: averagePrice,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        showCode: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Valeurs
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 4),
                  mainValue,
                ],
              ),
              if (subValue.isNotEmpty)
                Text(
                  subValue,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
