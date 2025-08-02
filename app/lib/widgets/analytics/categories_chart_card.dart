// widgets/analytics/categories_chart_card.dart - VERSION CORRIGÉE AVEC CALCUL SÉCURISÉ
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart';

class CategoriesChartCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const CategoriesChartCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = data['categories'] as List<dynamic>? ?? [];
    final summary = data['summary'] ?? {};

    return Container(
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.purple[600], size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.spendingByCategory,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const CurrencyIndicator(),
              ],
            ),
            const SizedBox(height: 20),

            // ✅ CORRIGÉ: Résumé avec calcul sécurisé
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple[100]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.totalSpent,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // ✅ CORRIGÉ: Utilise le calcul sécurisé avec fallback
                        FormattedAmount(
                          amount: _calculateTotalSpent(summary, categories),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[600],
                          ),
                          showCode: false,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.categories,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_getTotalCategories(summary, categories)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[600],
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

            // Liste des catégories
            if (categories.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.category, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        l10n.noCategoriesData ?? 'Aucune donnée de catégorie',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children:
                    categories.take(8).map<Widget>((category) {
                      return _buildCategoryItem(category, l10n);
                    }).toList(),
              ),

            // ✅ NOUVEAU: Informations supplémentaires si plus de 8 catégories
            if (categories.length > 8)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '${l10n.andXMore ?? 'Et'} ${categories.length - 8} ${l10n.moreCategories ?? 'autres catégories'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ✅ NOUVEAU: Méthode utilitaire pour conversion sécurisée vers double
  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? 0.0;
    }
    return 0.0;
  }

  // ✅ NOUVEAU: Calcul sécurisé du total dépensé
  double _calculateTotalSpent(
    Map<String, dynamic> summary,
    List<dynamic> categories,
  ) {
    // Priorité 1: Utiliser le summary si disponible
    final summaryTotal = _safeToDouble(summary['total_spent']);
    if (summaryTotal > 0) {
      return summaryTotal;
    }

    // Priorité 2: Calculer depuis les catégories
    double total = 0.0;
    for (var category in categories) {
      if (category is Map<String, dynamic>) {
        total += _safeToDouble(category['total_spent']);
      }
    }
    return total;
  }

  // ✅ NOUVEAU: Calcul sécurisé du nombre total de catégories
  int _getTotalCategories(
    Map<String, dynamic> summary,
    List<dynamic> categories,
  ) {
    // Priorité 1: Utiliser le summary si disponible
    final summaryCount = summary['total_categories'];
    if (summaryCount != null && summaryCount is num && summaryCount > 0) {
      return summaryCount.toInt();
    }

    // Priorité 2: Compter les catégories réelles
    return categories.length;
  }

  Widget _buildCategoryItem(dynamic category, AppLocalizations l10n) {
    if (category is! Map<String, dynamic>) return const SizedBox.shrink();

    final categoryName = category['category']?.toString() ?? 'Inconnu';
    final totalAmount = _safeToDouble(category['total_spent']);
    final percentage = _safeToDouble(category['percentage_of_total']);
    final totalItems = category['total_items']?.toInt() ?? 0;

    // Couleurs pour les catégories
    final colors = [
      Colors.green[600]!,
      Colors.blue[600]!,
      Colors.orange[600]!,
      Colors.purple[600]!,
      Colors.red[600]!,
      Colors.teal[600]!,
      Colors.indigo[600]!,
      Colors.brown[600]!,
    ];

    final colorIndex = categoryName.hashCode.abs() % colors.length;
    final color = colors[colorIndex];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$totalItems ${l10n.articles ?? 'articles'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // ✅ Utilisation de FormattedAmount avec montant sécurisé
                  FormattedAmount(
                    amount: totalAmount,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    showCode: false,
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage > 0 ? (percentage / 100).clamp(0.0, 1.0) : 0.0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
