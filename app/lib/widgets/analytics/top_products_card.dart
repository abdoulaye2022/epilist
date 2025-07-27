// widgets/analytics/top_products_card.dart - VERSION FONCTIONNELLE
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/blocs/analytics/analytics_bloc.dart';
import 'package:epilist/blocs/analytics/analytics_event.dart';

class TopProductsCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? selectedCurrency;

  const TopProductsCard({super.key, required this.data, this.selectedCurrency});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final products = data['products'] as List<dynamic>? ?? [];
    final summary = data['summary'] ?? {};
    final sortBy = data['sort_by'] ?? 'total_spent';

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
                Icon(Icons.star, color: Colors.amber[600], size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.topProducts,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildSortButton(context, sortBy),
              ],
            ),
            const SizedBox(height: 20),

            // Résumé
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.totalProducts,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${summary['total_unique_products'] ?? 0}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[600],
                          ),
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
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${summary['showing_top'] ?? 0}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[600],
                          ),
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
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.noProductsData,
                        style: TextStyle(color: Colors.grey[600]),
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
                      return _buildProductItem(product, index + 1, sortBy);
                    }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortButton(BuildContext context, String currentSort) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.sort, color: Colors.grey[600]),
      tooltip: 'Trier par',
      onSelected: (sortBy) {
        // ✅ CORRECTION : Déclencher l'événement ChangeTopProductsSort
        print('Changement de tri vers: $sortBy'); // Debug
        context.read<AnalyticsBloc>().add(
          ChangeTopProductsSort(
            sortBy: sortBy,
            currencyCode: selectedCurrency,
            period: 'month',
            limit: 10,
          ),
        );
      },
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
                            ? Colors.green[600]
                            : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Par montant',
                    style: TextStyle(
                      fontWeight:
                          currentSort == 'total_spent'
                              ? FontWeight.bold
                              : FontWeight.normal,
                      color:
                          currentSort == 'total_spent'
                              ? Colors.green[600]
                              : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  if (currentSort == 'total_spent')
                    Icon(Icons.check, color: Colors.green[600], size: 18),
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
                            ? Colors.green[600]
                            : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Par quantité',
                    style: TextStyle(
                      fontWeight:
                          currentSort == 'quantity'
                              ? FontWeight.bold
                              : FontWeight.normal,
                      color:
                          currentSort == 'quantity'
                              ? Colors.green[600]
                              : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  if (currentSort == 'quantity')
                    Icon(Icons.check, color: Colors.green[600], size: 18),
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
                            ? Colors.green[600]
                            : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Par fréquence',
                    style: TextStyle(
                      fontWeight:
                          currentSort == 'frequency'
                              ? FontWeight.bold
                              : FontWeight.normal,
                      color:
                          currentSort == 'frequency'
                              ? Colors.green[600]
                              : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  if (currentSort == 'frequency')
                    Icon(Icons.check, color: Colors.green[600], size: 18),
                ],
              ),
            ),
          ],
    );
  }

  Widget _buildProductItem(
    Map<String, dynamic> product,
    int rank,
    String sortBy,
  ) {
    final productName = product['product_name'] ?? 'Produit inconnu';
    final totalSpent = product['total_spent']?.toDouble() ?? 0.0;
    final formattedTotal = product['formatted_total'] ?? '0';
    final totalQuantity = product['total_quantity'] ?? 0;
    final frequency = product['purchase_frequency'] ?? 0;
    final averagePrice = product['formatted_average'] ?? '0';
    final stores = product['stores'] as List<dynamic>? ?? [];

    // Déterminer la valeur principale selon le tri
    String mainValue;
    String subValue;
    IconData icon;
    Color color;

    switch (sortBy) {
      case 'quantity':
        mainValue = '$totalQuantity';
        subValue = formattedTotal;
        icon = Icons.shopping_cart;
        color = Colors.blue[600]!;
        break;
      case 'frequency':
        mainValue = '$frequency';
        subValue = formattedTotal;
        icon = Icons.repeat;
        color = Colors.purple[600]!;
        break;
      default: // total_spent
        mainValue = formattedTotal;
        subValue = '$totalQuantity articles';
        icon = Icons.attach_money;
        color = Colors.green[600]!;
        break;
    }

    // Couleur pour le rang
    Color rankColor = Colors.grey[600]!;
    if (rank <= 3) {
      rankColor =
          [Colors.amber[600]!, Colors.grey[500]!, Colors.orange[600]!][rank -
              1];
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
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (stores.isNotEmpty)
                  Text(
                    'Magasins: ${stores.take(2).join(', ')}${stores.length > 2 ? '...' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                Text(
                  'Prix moyen: $averagePrice',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                  Text(
                    mainValue,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              Text(
                subValue,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
