// Le magasin, depuis la migration 012 : son adresse, ses horaires, son
// etoile.
//
// Le favori a QUITTE l'appareil. Il vivait dans les preferences locales
// — perdu au changement de telephone, et invisible pour les autres
// membres de l'espace. Il vient maintenant du serveur, comme le reste.
//
// Ce qui se teste ici est la LECTURE de la reponse : un jour inconnu
// qui passerait, une plage mal formee qui ferait planter l'ecran, une
// adresse a trous qui sortirait « , , ».
import 'package:epilist/models/store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Store depuis(Map<String, dynamic> json) =>
      Store.fromJson({'id': 1, 'name': 'Metro', 'slug': 'metro', ...json});

  group('Les heures d ouverture', () {
    test('une plage se lit, un dimanche nul reste ferme', () {
      final s = depuis({
        'opening_hours': {
          'mon': ['08:00', '21:00'],
          'sun': null,
        },
      });
      expect(s.hoursFor(DateTime.monday)!.open, '08:00');
      expect(s.hoursFor(DateTime.monday)!.close, '21:00');
      expect(s.hoursFor(DateTime.sunday), isNull);
      expect(s.hasOpeningHours, isTrue);
    });

    test('un jour que l API ne connait pas est ignore', () {
      // Mieux vaut perdre un jour que porter une clef que personne
      // d'autre ne saura relire.
      final s = depuis({
        'opening_hours': {
          'lundi': ['08:00', '21:00'],
        },
      });
      expect(s.openingHours, isEmpty);
      expect(s.hasOpeningHours, isFalse);
    });

    test('une plage mal formee ne fait pas tomber l ecran', () {
      for (final mauvaise in [
        ['08:00'],
        'ouvert',
        42,
        ['08:00', '21:00', '23:00'],
      ]) {
        final s = depuis({
          'opening_hours': {'mon': mauvaise},
        });
        expect(s.hoursFor(DateTime.monday), isNull, reason: '$mauvaise');
      }
    });

    test('aucun horaire du tout : rien ne s affiche', () {
      expect(depuis({}).hasOpeningHours, isFalse);
      expect(depuis({'opening_hours': null}).hasOpeningHours, isFalse);
    });

    test('un jour hors bornes ne leve rien', () {
      final s = depuis({
        'opening_hours': {
          'mon': ['08:00', '21:00'],
        },
      });
      expect(s.hoursFor(0), isNull);
      expect(s.hoursFor(8), isNull);
    });
  });

  group('L adresse', () {
    test('les trois morceaux font une ligne', () {
      final s = depuis({
        'address': '1200 rue Sainte-Catherine Ouest',
        'city': 'Montréal',
        'postal_code': 'H3B 1A1',
      });
      expect(
        s.addressLine,
        '1200 rue Sainte-Catherine Ouest, Montréal, H3B 1A1',
      );
    });

    test('les morceaux manquants ne laissent pas de virgules vides', () {
      expect(depuis({'city': 'Montréal'}).addressLine, 'Montréal');
      expect(depuis({'address': '  ', 'city': 'Laval'}).addressLine, 'Laval');
    });

    test('sans adresse, la ligne est nulle et rien ne s affiche', () {
      expect(depuis({}).addressLine, isNull);
      expect(depuis({'address': '', 'city': '  '}).addressLine, isNull);
    });
  });

  group('L etoile et les coordonnees', () {
    test('le favori vient du serveur', () {
      expect(depuis({'is_favorite': true}).isFavorite, isTrue);
      expect(depuis({'is_favorite': false}).isFavorite, isFalse);
      // Absent = pas favori, jamais une exception.
      expect(depuis({}).isFavorite, isFalse);
    });

    test('les coordonnees se lisent en nombre, meme ecrites en chaine', () {
      // MySQL rend un DECIMAL en chaine selon le pilote : une latitude
      // qui resterait du texte casserait tout calcul de distance.
      final s = depuis({'latitude': '45.5017', 'longitude': -73.5673});
      expect(s.latitude, closeTo(45.5017, 0.0001));
      expect(s.longitude, closeTo(-73.5673, 0.0001));
    });

    test('des coordonnees illisibles valent nul, pas zero', () {
      // Zero est un POINT sur Terre, au large du golfe de Guinee :
      // rendre zero ferait croire a une position connue.
      final s = depuis({'latitude': 'nord', 'longitude': null});
      expect(s.latitude, isNull);
      expect(s.longitude, isNull);
    });
  });

  group('Ouvert maintenant', () {
    // La question qu'on se pose devant une carte de magasin, et a
    // laquelle rien ne repondait : les horaires du jour etaient
    // affiches, a charge de comparer avec sa montre.
    Store avecHeures(Map<String, dynamic> heures) =>
        depuis({'opening_hours': heures});

    test('dans la plage : ouvert', () {
      final s = avecHeures({
        'tue': ['08:00', '21:00'],
      });
      // Un mardi, a 14 h.
      expect(s.isOpenAt(DateTime(2026, 10, 20, 14)), isTrue);
    });

    test('avant l ouverture et apres la fermeture : ferme', () {
      final s = avecHeures({
        'tue': ['08:00', '21:00'],
      });
      expect(s.isOpenAt(DateTime(2026, 10, 20, 7, 59)), isFalse);
      expect(s.isOpenAt(DateTime(2026, 10, 20, 21)), isFalse);
    });

    test('pile a l ouverture : ouvert', () {
      final s = avecHeures({
        'tue': ['08:00', '21:00'],
      });
      expect(s.isOpenAt(DateTime(2026, 10, 20, 8)), isTrue);
    });

    test('un jour ferme repond non, pas « on ne sait pas »', () {
      final s = avecHeures({
        'tue': ['08:00', '21:00'],
        'sun': null,
      });
      // Un dimanche.
      expect(s.isOpenAt(DateTime(2026, 10, 25, 14)), isFalse);
    });

    test('sans aucun horaire, on ne sait pas', () {
      // Et « Ferme » affiche faute d'horaires ferait renoncer a une
      // sortie : la reponse est nulle, et l'ecran n'ecrit rien.
      expect(depuis({}).isOpenAt(DateTime(2026, 10, 20, 14)), isNull);
    });

    test('une plage qui passe minuit se lit a l envers', () {
      final s = avecHeures({
        'tue': ['22:00', '02:00'],
      });
      expect(s.isOpenAt(DateTime(2026, 10, 20, 23)), isTrue);
      expect(s.isOpenAt(DateTime(2026, 10, 20, 1)), isTrue);
      expect(s.isOpenAt(DateTime(2026, 10, 20, 12)), isFalse);
    });

    test('une heure mal formee ne fait pas planter', () {
      final s = avecHeures({
        'tue': ['huit heures', '21:00'],
      });
      expect(s.isOpenAt(DateTime(2026, 10, 20, 14)), isNull);
    });
  });

  test('aller-retour JSON : ce qui sort se relit', () {
    final avant = depuis({
      'address': '1200 rue Sainte-Catherine',
      'city': 'Montréal',
      'postal_code': 'H3B 1A1',
      'latitude': 45.5017,
      'longitude': -73.5673,
      'opening_hours': {
        'mon': ['08:00', '21:00'],
        'sun': null,
      },
      'is_favorite': true,
    });
    final apres = Store.fromJson(avant.toJson());
    expect(apres.addressLine, avant.addressLine);
    expect(apres.isFavorite, isTrue);
    expect(apres.hoursFor(DateTime.monday)!.close, '21:00');
    expect(apres.latitude, avant.latitude);
  });
}
