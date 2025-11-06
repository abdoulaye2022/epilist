// widgets/suggestions/suggestion_card.dart
import 'package:flutter/material.dart';
import 'package:epilist/models/smart_suggestion.dart';
import 'package:epilist/l10n/app_localizations.dart';

class SuggestionCard extends StatelessWidget {
  final SmartSuggestion suggestion;
  final String currencySymbol;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final Function(int quantity)? onQuantityChanged;

  const SuggestionCard({
    super.key,
    required this.suggestion,
    required this.currencySymbol,
    required this.onAccept,
    required this.onReject,
    this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onAccept,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Product name and confidence badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      suggestion.productName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildConfidenceBadge(context),
                ],
              ),

              const SizedBox(height: 12),

              // Reason for suggestion
              Row(
                children: [
                  Icon(
                    _getIconForType(suggestion.type),
                    size: 16,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      suggestion.reason,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Details row: quantity, price, "buy soon" indicator
              Row(
                children: [
                  // Quantity
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_basket_outlined,
                          size: 16,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${suggestion.suggestedQuantity}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Price (if available)
                  if (suggestion.avgPrice != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.euro,
                            size: 16,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            suggestion.avgPrice!.toStringAsFixed(2),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Spacer(),

                  // "Buy soon" indicator
                  if (suggestion.shouldBuySoon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n?.buySoon ?? 'Buy Soon',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  // Reject button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, size: 18),
                      label: Text(l10n?.reject ?? 'Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Accept button
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: onAccept,
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      label: Text(l10n?.addToList ?? 'Add to List'),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build confidence badge based on confidence level
  Widget _buildConfidenceBadge(BuildContext context) {
    final theme = Theme.of(context);
    final level = suggestion.confidenceLevel;

    Color backgroundColor;
    Color textColor;
    String label;
    IconData icon;

    switch (level) {
      case ConfidenceLevel.high:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        label = 'High';
        icon = Icons.verified;
        break;
      case ConfidenceLevel.medium:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        label = 'Medium';
        icon = Icons.thumb_up_outlined;
        break;
      case ConfidenceLevel.low:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        label = 'Low';
        icon = Icons.info_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Get icon based on suggestion type
  IconData _getIconForType(SuggestionType type) {
    switch (type) {
      case SuggestionType.pattern:
        return Icons.auto_graph;
      case SuggestionType.seasonal:
        return Icons.calendar_today;
      case SuggestionType.association:
        return Icons.link;
      case SuggestionType.trending:
        return Icons.trending_up;
    }
  }
}

/// Compact version of suggestion card for smaller displays
class CompactSuggestionCard extends StatelessWidget {
  final SmartSuggestion suggestion;
  final VoidCallback onTap;

  const CompactSuggestionCard({
    super.key,
    required this.suggestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _getColorForConfidence(suggestion.confidenceLevel),
          child: Text(
            '${suggestion.suggestedQuantity}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          suggestion.productName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          suggestion.reason,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ),
        trailing: Icon(
          suggestion.shouldBuySoon
              ? Icons.notification_important
              : Icons.arrow_forward_ios,
          size: 16,
        ),
      ),
    );
  }

  Color _getColorForConfidence(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.high:
        return Colors.green;
      case ConfidenceLevel.medium:
        return Colors.orange;
      case ConfidenceLevel.low:
        return Colors.grey;
    }
  }
}
