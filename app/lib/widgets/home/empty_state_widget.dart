// widgets/home/empty_state_widget.dart
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';

class EmptyStateWidget extends StatelessWidget {
  final VoidCallback onCreateNew;

  const EmptyStateWidget({super.key, required this.onCreateNew});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // ✅ AJOUTÉ: Taille minimale
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 60, // ✅ RÉDUIT: 80 -> 60
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12), // ✅ RÉDUIT: 16 -> 12
            Text(
              l10n.noGroceryLists,
              style: TextStyle(
                fontSize: 16, // ✅ RÉDUIT: 18 -> 16
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center, // ✅ AJOUTÉ: Centrage du texte
            ),
            const SizedBox(height: 6), // ✅ RÉDUIT: 8 -> 6
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ), // ✅ AJOUTÉ: Padding horizontal
              child: Text(
                l10n.createFirstList,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14, // ✅ AJOUTÉ: Taille explicite
                ),
                textAlign: TextAlign.center, // ✅ AJOUTÉ: Centrage du texte
                maxLines: 2, // ✅ AJOUTÉ: Limite de lignes
                overflow: TextOverflow.ellipsis, // ✅ AJOUTÉ: Gestion overflow
              ),
            ),
            const SizedBox(height: 16), // ✅ RÉDUIT: 24 -> 16
            ElevatedButton.icon(
              onPressed: onCreateNew,
              icon: const Icon(Icons.add, size: 18), // ✅ AJOUTÉ: Taille icône
              label: Text(
                l10n.createList,
                style: const TextStyle(fontSize: 14), // ✅ AJOUTÉ: Taille texte
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20, // ✅ RÉDUIT: 24 -> 20
                  vertical: 10, // ✅ RÉDUIT: 12 -> 10
                ),
                minimumSize: const Size(120, 40), // ✅ AJOUTÉ: Taille minimale
              ),
            ),
          ],
        ),
      ),
    );
  }
}
