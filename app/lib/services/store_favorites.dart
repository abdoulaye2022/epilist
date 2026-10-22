// services/store_favorites.dart - Les magasins marqués favoris.
//
// La planche demande une étoile sur chaque magasin, avec son état écrit.
// Il n'y a AUCUN champ « favori » côté serveur, et en inventer un
// demanderait une migration : ce choix reste donc local à l'appareil,
// dans les préférences, et c'est honnête — il sert à remonter les
// magasins qu'on fréquente, pas à être partagé avec l'espace.
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Les identifiants des magasins favoris, observables.
final storeFavorites = StoreFavorites();

class StoreFavorites extends ValueNotifier<Set<int>> {
  StoreFavorites() : super(const <int>{});

  static const _key = 'favorite_store_ids';

  /// Appelé au démarrage. Un échec de lecture ne doit jamais empêcher
  /// l'écran des magasins de s'afficher : on repart d'un ensemble vide.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_key) ?? const [];
      value = ids.map(int.tryParse).whereType<int>().toSet();
    } catch (_) {
      value = const <int>{};
    }
  }

  bool isFavorite(int storeId) => value.contains(storeId);

  Future<void> toggle(int storeId) async {
    final suivant = Set<int>.of(value);
    if (!suivant.remove(storeId)) suivant.add(storeId);
    value = suivant;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _key,
        suivant.map((e) => e.toString()).toList(),
      );
    } catch (_) {
      // L'étoile reste allumée pour cette session ; elle ne survivra
      // pas au redémarrage, ce qui est préférable à un refus muet.
    }
  }
}
