// widgets/suggestion/suggestion_card.dart
import 'package:flutter/material.dart';
import 'package:epilist/models/product_suggestion.dart';
import 'package:epilist/l10n/app_localizations.dart';

class SuggestionCard extends StatelessWidget {
  final ProductSuggestion suggestion;
  final VoidCallback onDelete;

  const SuggestionCard({
    super.key,
    required this.suggestion,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: _buildLeadingIcon(),
          title: _buildTitle(),
          subtitle: _buildSubtitle(context, l10n),
          trailing: _buildTrailing(context, l10n),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[100]!, Colors.blue[200]!],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.shopping_basket_outlined,
        color: Colors.blue[700],
        size: 24,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      suggestion.productName,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildBadges(),
        const SizedBox(height: 8),
        _buildUsageInfo(context, l10n),
      ],
    );
  }

  Widget _buildBadges() {
    return Row(
      children: [
        if (suggestion.hasPrice) ...[
          _buildBadge(
            text: suggestion.formattedPrice,
            color: Colors.green,
            icon: Icons.attach_money,
          ),
          const SizedBox(width: 8),
        ],
        if (suggestion.hasStore) ...[
          _buildBadge(
            text: suggestion.storeName!,
            color: Colors.purple,
            icon: Icons.store,
          ),
        ],
      ],
    );
  }

  Widget _buildBadge({
    required String text,
    required MaterialColor color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color[700]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageInfo(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.trending_up, size: 12, color: Colors.orange[600]),
              const SizedBox(width: 4),
              Text(
                suggestion.getUsageInfo(context),
                style: TextStyle(
                  color: Colors.orange[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (suggestion.lastUsedAt != null)
          Text(
            '${l10n.lastUsed}: ${suggestion.getLastUsedFormatted(context)}',
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
      ],
    );
  }

  Widget _buildTrailing(BuildContext context, AppLocalizations l10n) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'delete') {
          onDelete();
        }
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder:
          (context) => [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red[600], size: 20),
                  const SizedBox(width: 12),
                  Text(
                    l10n.deleteSuggestion,
                    style: TextStyle(color: Colors.red[600]),
                  ),
                ],
              ),
            ),
          ],
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.more_vert, color: Colors.grey[600], size: 18),
      ),
    );
  }
}
