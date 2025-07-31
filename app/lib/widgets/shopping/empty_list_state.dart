import 'package:epilist/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class EmptyListState extends StatelessWidget {
  final VoidCallback onCreateList;

  const EmptyListState({super.key, required this.onCreateList});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 150, // Hauteur minimale réduite
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize:
                MainAxisSize.min, // ✅ IMPORTANT: Utilise la taille minimale
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 64, // ✅ Taille réduite
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12), // ✅ Espacement réduit
              Text(
                l10n.noShoppingLists,
                style: TextStyle(
                  fontSize: 18, // ✅ Taille réduite
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6), // ✅ Espacement réduit
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.createFirstListToStart,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14, // ✅ Taille réduite
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2, // ✅ Limite le nombre de lignes
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 20), // ✅ Espacement réduit
              ElevatedButton.icon(
                onPressed: onCreateList,
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  l10n.createList,
                  style: const TextStyle(fontSize: 14), // ✅ Taille réduite
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ), // ✅ Padding réduit
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
