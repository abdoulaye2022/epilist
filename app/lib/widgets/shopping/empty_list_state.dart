import 'package:epilist/theme/app_theme.dart';
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
                color: AppColors.textDisabled,
              ),
              const SizedBox(height: 12), // ✅ Espacement réduit
              Text(
                l10n.noShoppingLists,
                style: TextStyle(
                  fontSize: 18, // ✅ Taille réduite
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6), // ✅ Espacement réduit
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.createFirstListToStart,
                  style: TextStyle(
                    color: AppColors.textDisabled,
                    fontSize: 16, // ✅ Taille réduite
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2, // ✅ Limite le nombre de lignes
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 20), // ✅ Espacement réduit
              // Le bouton du thème : 60 dp de haut, en gélule, sur
              // toute la largeur. Il était rétréci a la main — et
              // c'est le seul geste de cet écran.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onCreateList,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.createList),
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
