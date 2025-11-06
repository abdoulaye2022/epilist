// widgets/suggestions/suggestion_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/models/smart_suggestion.dart';
import 'package:epilist/blocs/suggestion/suggestion_bloc.dart';
import 'package:epilist/blocs/suggestion/suggestion_event.dart';
import 'package:epilist/blocs/suggestion/suggestion_state.dart';
import 'package:epilist/widgets/suggestions/suggestion_card.dart';
import 'package:epilist/l10n/app_localizations.dart';

class SuggestionList extends StatefulWidget {
  final String currencySymbol;
  final Function(SmartSuggestion) onSuggestionAccepted;
  final bool compact;

  const SuggestionList({
    super.key,
    required this.currencySymbol,
    required this.onSuggestionAccepted,
    this.compact = false,
  });

  @override
  State<SuggestionList> createState() => _SuggestionListState();
}

class _SuggestionListState extends State<SuggestionList> {
  @override
  void initState() {
    super.initState();
    // Load suggestions when widget is created
    context.read<SuggestionBloc>().add(const LoadSuggestions());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<SuggestionBloc, SuggestionState>(
      listener: (context, state) {
        // Show snackbar when suggestion is accepted
        if (state is SuggestionAccepted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.suggestionAdded ?? 'Suggestion added to list',
              ),
              backgroundColor: theme.colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is SuggestionLoading) {
          return _buildLoadingState();
        }

        if (state is SuggestionError) {
          return _buildErrorState(state.message);
        }

        if (state is SuggestionLoaded) {
          if (state.suggestions.isEmpty) {
            return _buildEmptyState();
          }

          return _buildSuggestionsList(state);
        }

        // Initial state
        return _buildEmptyState();
      },
    );
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading suggestions...'),
          ],
        ),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(String message) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.errorLoadingSuggestions ?? 'Failed to load suggestions',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                context.read<SuggestionBloc>().add(const LoadSuggestions());
              },
              icon: const Icon(Icons.refresh),
              label: Text(l10n?.retry ?? 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: theme.colorScheme.secondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.noSuggestionsYet ?? 'No suggestions yet',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.noSuggestionsDescription ??
                  'Start shopping to get personalized suggestions',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build suggestions list
  Widget _buildSuggestionsList(SuggestionLoaded state) {
    final l10n = AppLocalizations.of(context);

    if (widget.compact) {
      // Compact mode: show only top suggestions
      final topSuggestions = state.suggestions.take(5).toList();
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: topSuggestions
            .map((suggestion) => CompactSuggestionCard(
                  suggestion: suggestion,
                  onTap: () => _handleAcceptSuggestion(suggestion),
                ))
            .toList(),
      );
    }

    // Full mode: show all suggestions grouped by confidence
    return RefreshIndicator(
      onRefresh: () async {
        context.read<SuggestionBloc>().add(const LoadSuggestions());
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n?.smartSuggestions ?? 'Smart Suggestions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => _showSuggestionsInfo(context),
                  tooltip: l10n?.information ?? 'Information',
                ),
              ],
            ),
          ),

          // High confidence suggestions
          if (state.highConfidence.isNotEmpty) ...[
            _buildSectionHeader(
              l10n?.highConfidence ?? 'Highly Recommended',
              Icons.verified,
              Colors.green,
            ),
            ...state.highConfidence.map(
              (suggestion) => _buildSuggestionCard(suggestion),
            ),
          ],

          // Medium confidence suggestions
          if (state.mediumConfidence.isNotEmpty) ...[
            _buildSectionHeader(
              l10n?.mediumConfidence ?? 'Good Matches',
              Icons.thumb_up_outlined,
              Colors.orange,
            ),
            ...state.mediumConfidence.map(
              (suggestion) => _buildSuggestionCard(suggestion),
            ),
          ],

          // Low confidence suggestions
          if (state.lowConfidence.isNotEmpty) ...[
            _buildSectionHeader(
              l10n?.lowConfidence ?? 'You Might Like',
              Icons.info_outline,
              Colors.grey,
            ),
            ...state.lowConfidence.map(
              (suggestion) => _buildSuggestionCard(suggestion),
            ),
          ],
        ],
      ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual suggestion card
  Widget _buildSuggestionCard(SmartSuggestion suggestion) {
    return SuggestionCard(
      suggestion: suggestion,
      currencySymbol: widget.currencySymbol,
      onAccept: () => _handleAcceptSuggestion(suggestion),
      onReject: () => _handleRejectSuggestion(suggestion),
    );
  }

  /// Handle accepting a suggestion
  void _handleAcceptSuggestion(SmartSuggestion suggestion) {
    // Notify parent widget
    widget.onSuggestionAccepted(suggestion);

    // Record acceptance in bloc
    context.read<SuggestionBloc>().add(
          AcceptSuggestion(
            suggestion.productName,
            suggestion.suggestedQuantity,
          ),
        );
  }

  /// Handle rejecting a suggestion
  void _handleRejectSuggestion(SmartSuggestion suggestion) {
    context.read<SuggestionBloc>().add(
          RejectSuggestion(suggestion.productName),
        );
  }

  /// Show information dialog about suggestions
  void _showSuggestionsInfo(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(l10n?.smartSuggestions ?? 'Smart Suggestions'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.suggestionsInfoDescription ??
                    'We analyze your shopping history to suggest products you might need.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _buildInfoItem(
                Icons.auto_graph,
                l10n?.patternBased ?? 'Pattern-based',
                l10n?.patternBasedDescription ??
                    'Based on how often you buy items',
              ),
              const SizedBox(height: 12),
              _buildInfoItem(
                Icons.calendar_today,
                l10n?.seasonal ?? 'Seasonal',
                l10n?.seasonalDescription ??
                    'Products you buy during specific periods',
              ),
              const SizedBox(height: 12),
              _buildInfoItem(
                Icons.link,
                l10n?.associations ?? 'Associations',
                l10n?.associationsDescription ??
                    'Items often bought together',
              ),
              const SizedBox(height: 12),
              _buildInfoItem(
                Icons.trending_up,
                l10n?.trending ?? 'Trending',
                l10n?.trendingDescription ?? 'Popular items right now',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n?.close ?? 'Close'),
          ),
        ],
      ),
    );
  }

  /// Build info item for dialog
  Widget _buildInfoItem(IconData icon, String title, String description) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.secondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
