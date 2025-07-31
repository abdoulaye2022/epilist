// screens/suggestion_management_widget.dart - CORRECTION AVEC BACKGROUND GRIS UNIFORME
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
      // ✅ BACKGROUND GRIS UNIFORME (comme les autres pages)
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

          // ✅ CORRECTION: Gestion correcte de l'état vide
          if (state is ProductSuggestionEmpty) {
            return SuggestionEmptyState(
              query: state.query.isNotEmpty ? state.query : null,
            );
          }

          if (state is ProductSuggestionPopularLoaded) {
            if (state.suggestions.isEmpty) {
              return const SuggestionEmptyState();
            }
            return _buildSuggestionsList(state.suggestions, l10n);
          }

          // ✅ CORRECTION: Gestion de l'état initial et autres états
          if (state is ProductSuggestionInitial) {
            return const SuggestionEmptyState();
          }

          // État par défaut - ne devrait jamais arriver
          return SuggestionErrorState(
            message: l10n.anErrorOccurred,
            onRetry: () {
              context.read<ProductSuggestionBloc>().add(
                const LoadPopularSuggestions(),
              );
            },
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
            // ✅ FOND BLANC POUR LES DIALOGUES
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_outline, color: Colors.red[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.deleteSuggestion,
                    style: const TextStyle(color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            content: Text(
              l10n.deleteSuggestionConfirm,
              style: const TextStyle(color: Colors.black87),
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
                    DeleteSuggestion(suggestion.id),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.suggestionDeleted,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
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
            // ✅ FOND BLANC POUR LES DIALOGUES
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_sweep, color: Colors.orange[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.clearAllSuggestions,
                    style: const TextStyle(color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.clearAllSuggestionsConfirm,
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Colors.orange[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.localeName == 'fr'
                              ? "Cette action est irréversible"
                              : "This action is irreversible",
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.suggestionsCleared,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
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
