// widgets/suggestions/smart_suggestions_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/models/smart_suggestion.dart';
import 'package:epilist/blocs/suggestion/suggestion_bloc.dart';
import 'package:epilist/blocs/suggestion/suggestion_event.dart';
import 'package:epilist/blocs/suggestion/suggestion_state.dart';
import 'package:epilist/widgets/suggestions/suggestion_card.dart';
import 'package:epilist/l10n/app_localizations.dart';

/// Compact widget for showing smart suggestions in dialogs or small spaces
class SmartSuggestionsWidget extends StatefulWidget {
  final String currencySymbol;
  final Function(SmartSuggestion) onSuggestionSelected;
  final List<String> currentListItems;
  final int maxSuggestions;

  const SmartSuggestionsWidget({
    super.key,
    required this.currencySymbol,
    required this.onSuggestionSelected,
    this.currentListItems = const [],
    this.maxSuggestions = 3,
  });

  @override
  State<SmartSuggestionsWidget> createState() => _SmartSuggestionsWidgetState();
}

class _SmartSuggestionsWidgetState extends State<SmartSuggestionsWidget> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Load suggestions when widget is created
    _loadSuggestions();
  }

  void _loadSuggestions() {
    context.read<SuggestionBloc>().add(
          LoadSuggestions(
            includeAssociations: true,
            currentListItems: widget.currentListItems,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<SuggestionBloc, SuggestionState>(
      builder: (context, state) {
        if (state is SuggestionLoading) {
          return _buildLoadingState();
        }

        if (state is SuggestionLoaded) {
          if (state.suggestions.isEmpty) {
            return const SizedBox.shrink(); // Don't show anything if no suggestions
          }

          return _buildSuggestionsCard(state);
        }

        // Don't show for error or initial state
        return const SizedBox.shrink();
      },
    );
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)?.loadingSuggestions ??
                  'Loading suggestions...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  /// Build suggestions card
  Widget _buildSuggestionsCard(SuggestionLoaded state) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // Get top suggestions (prioritize high confidence and "buy soon")
    final topSuggestions = _getTopSuggestions(state.suggestions);

    if (topSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n?.smartSuggestions ?? 'Smart Suggestions',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  if (topSuggestions.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${topSuggestions.length}',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // Divider
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant,
          ),

          // Suggestions list
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? _buildExpandedSuggestions(topSuggestions)
                : _buildCollapsedSuggestions(topSuggestions),
          ),
        ],
      ),
    );
  }

  /// Build collapsed view (show only first suggestion)
  Widget _buildCollapsedSuggestions(List<SmartSuggestion> suggestions) {
    final firstSuggestion = suggestions.first;

    return InkWell(
      onTap: () => _handleSuggestionTap(firstSuggestion),
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Confidence indicator
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: _getColorForConfidence(firstSuggestion.confidenceLevel),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          firstSuggestion.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (firstSuggestion.shouldBuySoon)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            AppLocalizations.of(context)?.buySoon ?? 'Soon',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    firstSuggestion.reason,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Add button
            IconButton.filled(
              onPressed: () => _handleSuggestionTap(firstSuggestion),
              icon: const Icon(Icons.add, size: 20),
              iconSize: 20,
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                minimumSize: const Size(36, 36),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build expanded view (show all suggestions)
  Widget _buildExpandedSuggestions(List<SmartSuggestion> suggestions) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: suggestions.map((suggestion) {
        return CompactSuggestionCard(
          suggestion: suggestion,
          onTap: () => _handleSuggestionTap(suggestion),
        );
      }).toList(),
    );
  }

  /// Get top suggestions sorted by priority
  List<SmartSuggestion> _getTopSuggestions(List<SmartSuggestion> suggestions) {
    // Sort by: 1) Should buy soon, 2) Confidence score
    final sorted = List<SmartSuggestion>.from(suggestions);
    sorted.sort((a, b) {
      // Priority 1: Should buy soon
      if (a.shouldBuySoon != b.shouldBuySoon) {
        return a.shouldBuySoon ? -1 : 1;
      }
      // Priority 2: Confidence score
      return b.confidenceScore.compareTo(a.confidenceScore);
    });

    return sorted.take(widget.maxSuggestions).toList();
  }

  /// Handle suggestion tap
  void _handleSuggestionTap(SmartSuggestion suggestion) {
    widget.onSuggestionSelected(suggestion);

    // Record acceptance
    context.read<SuggestionBloc>().add(
          AcceptSuggestion(
            suggestion.productName,
            suggestion.suggestedQuantity,
          ),
        );
  }

  /// Get color for confidence level
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
