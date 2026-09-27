// widgets/list_detail/list_stats_header.dart - VERSION AVEC SÉPARATION DE L'APPBAR
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progressPercentage =
        totalItems > 0 ? ((purchasedItems / totalItems) * 100).round() : 0;

    return Container(
      // ✅ SÉPARATION AVEC L'APPBAR
      decoration: BoxDecoration(
        color: Colors.white,
        // ✅ BORDURE SUPÉRIEURE POUR SÉPARER DE L'APPBAR
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
        // ✅ OMBRE SUBTILE POUR PLUS DE PROFONDEUR
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(l10n.articles, '$purchasedItems/$totalItems'),
            _buildVerticalDivider(),
            _buildStatItemWithAmount(l10n.total, totalPrice),
            _buildVerticalDivider(),
            _buildStatItem(l10n.progress, '$progressPercentage%'),
          ],
        ),
      ),
    );
  }

  // ✅ SÉPARATEUR VERTICAL ENTRE LES STATISTIQUES
  Widget _buildVerticalDivider() {
    return Container(height: 40, width: 1, color: AppColors.border);
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItemWithAmount(String label, double amount) {
    return Expanded(
      child: Column(
        children: [
          FormattedAmount(
            amount: amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            showCode: false,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
