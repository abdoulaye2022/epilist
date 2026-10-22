// L'etoile « favori » d'un magasin : locale, et persistante.
//
// Il n'y a aucun champ favori cote serveur. Ce choix vit donc dans les
// preferences de l'appareil — et doit survivre au redemarrage, sinon
// l'etoile ne sert a rien. Un echec de lecture ne doit jamais empecher
// l'ecran des magasins de s'afficher.
import 'package:epilist/services/store_favorites.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => storeFavorites.value = const <int>{});

  test('aucun favori au depart', () async {
    await storeFavorites.load();
    expect(storeFavorites.value, isEmpty);
    expect(storeFavorites.isFavorite(7), isFalse);
  });

  test('la bascule allume puis eteint', () async {
    await storeFavorites.load();
    await storeFavorites.toggle(7);
    expect(storeFavorites.isFavorite(7), isTrue);
    await storeFavorites.toggle(7);
    expect(storeFavorites.isFavorite(7), isFalse);
  });

  test('le choix survit au redemarrage', () async {
    await storeFavorites.load();
    await storeFavorites.toggle(7);
    await storeFavorites.toggle(12);

    // Un nouveau demarrage : on relit depuis les preferences.
    storeFavorites.value = const <int>{};
    await storeFavorites.load();
    expect(storeFavorites.value, {7, 12});
  });

  test('des valeurs illisibles sont ignorees, pas fatales', () async {
    SharedPreferences.setMockInitialValues({
      'favorite_store_ids': ['3', 'pas un nombre', '9'],
    });
    await storeFavorites.load();
    expect(storeFavorites.value, {3, 9});
  });
}
