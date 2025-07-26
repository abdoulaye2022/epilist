// widgets/suggestion/suggestion_empty_state.dart
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/screens/shopping_list_screen.dart';
import 'package:flutter/material.dart';

class SuggestionEmptyState extends StatelessWidget {
  final String?
  query; // Optionnel pour différencier recherche vs suggestions populaires

  const SuggestionEmptyState({super.key, this.query});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool isSearch = query != null && query!.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône principale - style cohérent avec EmptyListState
          Icon(
            isSearch ? Icons.search_off : Icons.lightbulb_outline,
            size: 80,
            color: Colors.grey[400],
          ),

          const SizedBox(height: 16),

          // Titre principal
          Text(
            isSearch
                ? l10n
                    .noSearchResults // "Aucun résultat trouvé"
                : l10n.noSuggestionsYet, // "Aucune suggestion pour le moment"
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 8),

          // Description
          Text(
            isSearch
                ? l10n
                    .tryDifferentKeywords // "Essayez avec d'autres mots-clés"
                : l10n
                    .suggestionsWillAppearAfterShopping, // "Les suggestions apparaîtront après vos achats"
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Bouton d'action pour aller vers les listes de courses
          if (!isSearch)
            ElevatedButton(
              onPressed: () => _navigateToShoppingLists(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: Text(l10n.startShopping), // "Commencer mes achats"
            ),

          // Message d'aide pour les recherches
          if (isSearch) ...[
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tips_and_updates,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.searchTips, // "Essayez des termes plus généraux ou vérifiez l'orthographe"
                      style: TextStyle(color: Colors.blue[700], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Message d'encouragement pour les suggestions vides
          if (!isSearch) ...[
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.green[600], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.suggestionsBasedOnUsage, // "Les suggestions se basent sur vos habitudes d'achat"
                      style: TextStyle(color: Colors.green[700], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Méthode pour naviguer vers l'écran des listes de courses
  void _navigateToShoppingLists(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ShoppingListScreen()),
    );
  }
}
