// widgets/suggestion_management_widget.dart - VERSION REFACTORISÉE
import 'package:epilist/blocs/product_suggestion/product_suggestion_bloc.dart';
import 'package:epilist/models/product_suggestion.dart';
import 'package:epilist/widgets/suggestion/suggestion_app_bar.dart';
import 'package:epilist/widgets/suggestion/suggestion_header_card.dart';
import 'package:epilist/widgets/suggestion/suggestion_card.dart';
import 'package:epilist/widgets/suggestion/suggestion_empty_state.dart';
import 'package:epilist/widgets/suggestion/suggestion_loading_state.dart';
import 'package:epilist/widgets/suggestion/suggestion_error_state.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SuggestionManagementWidget extends StatefulWidget {
  const SuggestionManagementWidget({super.key});

  @override
  State<SuggestionManagementWidget> createState() =>
      _SuggestionManagementWidgetState();
}

class _SuggestionManagementWidgetState
    extends State<SuggestionManagementWidget> {
  @override
  void initState() {
    super.initState();
    context.read<ProductSuggestionBloc>().add(const LoadPopularSuggestions());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: SuggestionAppBar(
        onClearAll: () => _showClearConfirmation(context, l10n),
      ),
      body: BlocBuilder<ProductSuggestionBloc, ProductSuggestionState>(
        builder: (context, state) {
          if (state is ProductSuggestionLoading) {
            return const SuggestionLoadingState();
          }

          if (state is ProductSuggestionError) {
            return SuggestionErrorState(
              message: state.message,
              onRetry: () {
                context.read<ProductSuggestionBloc>().add(
                  const LoadPopularSuggestions(),
                );
              },
            );
          }

          if (state is ProductSuggestionPopularLoaded) {
            if (state.suggestions.isEmpty) {
              return const SuggestionEmptyState();
            }

            return _buildSuggestionsList(state.suggestions, l10n);
          }

          return Center(
            child: Text(
              l10n.anErrorOccurred,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuggestionsList(
    List<ProductSuggestion> suggestions,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        SuggestionHeaderCard(suggestionsCount: suggestions.length),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return SuggestionCard(
                suggestion: suggestion,
                onDelete: () => _deleteSuggestion(suggestion, l10n),
              );
            },
          ),
        ),
      ],
    );
  }

  void _deleteSuggestion(ProductSuggestion suggestion, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.red[600]),
                const SizedBox(width: 8),
                Text(l10n.deleteSuggestion),
              ],
            ),
            content: Text(l10n.deleteSuggestionConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<ProductSuggestionBloc>().add(
                    DeleteSuggestion(suggestion.id),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(l10n.suggestionDeleted),
                        ],
                      ),
                      backgroundColor: Colors.green[600],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(l10n.delete),
              ),
            ],
          ),
    );
  }

  void _showClearConfirmation(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.delete_sweep, color: Colors.orange[600]),
                const SizedBox(width: 8),
                Text(l10n.clearAllSuggestions),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.clearAllSuggestionsConfirm),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Colors.orange[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Cette action est irréversible",
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<ProductSuggestionBloc>().add(
                    const ClearSuggestions(),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(l10n.suggestionsCleared),
                        ],
                      ),
                      backgroundColor: Colors.green[600],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(l10n.clearAllSuggestions),
              ),
            ],
          ),
    );
  }
}
