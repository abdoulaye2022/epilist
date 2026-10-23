// La dictee : une phrase, plusieurs articles.
//
// L'ecran proposait lui-meme ses exemples — « 3 pommes »,
// « 5 kilogrammes de tomates », « 2 litres de lait » — et le resultat ne
// les respectait pas : « viande croissant 2 kg » donnait UN article
// nomme « Viande croissant 2 kg » avec la quantite 1,0.
//
// Les phrases de « a tester avant livraison » sont ici, telles quelles.
import 'package:epilist/services/voice_list_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('les exemples que l ecran promet', () {
    test('3 pommes', () {
      final items = parseDictation('3 pommes');
      expect(items, hasLength(1));
      expect(items.first.name, 'Pommes');
      expect(items.first.quantity, 3);
      expect(items.first.unit, isNull);
      expect(items.first.quantityStated, isTrue);
    });

    test('5 kilogrammes de tomates : l unite sort du nom', () {
      final items = parseDictation('5 kilogrammes de tomates');
      expect(items, hasLength(1));
      expect(items.first.name, 'Tomates');
      expect(items.first.quantity, 5);
      expect(items.first.unit, 'kg');
    });

    test('2 litres de lait', () {
      final items = parseDictation('2 litres de lait');
      expect(items, hasLength(1));
      expect(items.first.name, 'Lait');
      expect(items.first.quantity, 2);
      expect(items.first.unit, 'L');
    });
  });

  group('les phrases a tester avant livraison', () {
    test('deux litres de lait et trois pommes', () {
      final items = parseDictation('deux litres de lait et trois pommes');
      expect(items, hasLength(2));
      expect(items[0].name, 'Lait');
      expect(items[0].quantity, 2);
      expect(items[0].unit, 'L');
      expect(items[1].name, 'Pommes');
      expect(items[1].quantity, 3);
      expect(items[1].unit, isNull);
    });

    test('pain de ble, beurre, 500 grammes de boeuf hache', () {
      final items = parseDictation(
        'pain de blé, beurre, 500 grammes de bœuf haché',
      );
      expect(items, hasLength(3));
      // « pain de ble » ne doit PAS se couper en deux.
      expect(items[0].name, 'Pain de blé');
      expect(items[0].quantity, 1);
      expect(items[0].quantityStated, isFalse);
      expect(items[1].name, 'Beurre');
      expect(items[2].name, 'Bœuf haché');
      expect(items[2].quantity, 500);
      expect(items[2].unit, 'g');
    });
  });

  group('la quantite se dit aussi derriere', () {
    test('viande hachee 2 kg', () {
      final items = parseDictation('viande hachée 2 kg');
      expect(items, hasLength(1));
      expect(items.first.name, 'Viande hachée');
      expect(items.first.quantity, 2);
      expect(items.first.unit, 'kg');
    });

    test('un nombre suivi d un mot inconnu n est pas une quantite', () {
      // « lait 2 pour cent » ne doit pas devenir « lait, 2 cent ».
      final items = parseDictation('lait 2 pour cent');
      expect(items, hasLength(1));
      expect(items.first.quantity, 1);
      expect(items.first.quantityStated, isFalse);
    });
  });

  group('les nombres ecrits en lettres', () {
    test('une douzaine d oeufs', () {
      final items = parseDictation("une douzaine d'œufs");
      expect(items, hasLength(1));
      expect(items.first.name, 'Œufs');
      expect(items.first.quantity, 12);
    });

    test('une demi-douzaine', () {
      final items = parseDictation("une demi-douzaine d'œufs");
      expect(items.first.quantity, 6);
    });

    test('douze oeufs', () {
      final items = parseDictation('douze œufs');
      expect(items.first.quantity, 12);
      expect(items.first.name, 'Œufs');
    });
  });

  group('le decoupage', () {
    test('virgule, et, puis', () {
      final items = parseDictation('lait, pain et beurre puis café');
      expect(items.map((i) => i.name), ['Lait', 'Pain', 'Beurre', 'Café']);
    });

    test('les morceaux vides disparaissent', () {
      final items = parseDictation('lait,,  et  , pain');
      expect(items.map((i) => i.name), ['Lait', 'Pain']);
    });

    test('une amorce ne devient pas un article', () {
      final items = parseDictation('ajoute du pain et des pommes');
      expect(items.map((i) => i.name), ['Pain', 'Pommes']);
    });

    test('une phrase vide ne rend rien', () {
      expect(parseDictation(''), isEmpty);
      expect(parseDictation('   '), isEmpty);
      expect(parseDictation(',,,'), isEmpty);
    });
  });

  group('ce que le parseur ne peut pas faire', () {
    test('sans separateur prononce, un seul article', () {
      // « Tomate Igname Pain Arachide » dicte d'un trait : rien, dans le
      // texte, ne dit ou couper. L'ecran de verification est la pour ca.
      final items = parseDictation('tomate igname pain arachide');
      expect(items, hasLength(1));
      expect(items.first.name, 'Tomate igname pain arachide');
    });
  });

  group('la quantite absente vaut 1, et le dit', () {
    test('pain', () {
      final items = parseDictation('pain');
      expect(items.first.quantity, 1);
      expect(items.first.quantityStated, isFalse);
    });
  });

  group('en anglais aussi', () {
    test('two liters of milk and three apples', () {
      final items = parseDictation('two liters of milk and three apples');
      expect(items, hasLength(2));
      expect(items[0].name, 'Milk');
      expect(items[0].quantity, 2);
      expect(items[0].unit, 'L');
      expect(items[1].name, 'Apples');
      expect(items[1].quantity, 3);
    });

    test('500 grams of ground beef', () {
      final items = parseDictation('500 grams of ground beef');
      expect(items.first.name, 'Ground beef');
      expect(items.first.quantity, 500);
      expect(items.first.unit, 'g');
    });
  });
}
