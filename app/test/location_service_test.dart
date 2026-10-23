// La distance jusqu'a un magasin.
//
// Elle se CALCULE, et ne s'enregistre jamais : une distance en base
// serait une distance depuis un point qui n'a plus de sens des qu'on
// bouge. Ce qui se teste ici est le calcul et son ECRITURE — personne
// ne lit « 1.2345 km ».
//
// Les points de reference sont reels : le metro Berri-UQAM et le Centre
// Eaton, a Montreal, separes d'environ 1,2 km a pied.
import 'package:epilist/services/location_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('La distance', () {
    test('deux points de Montreal, a 1,2 km', () {
      final km = LocationService.distanceKm(
        45.5152, // Berri-UQAM
        -73.5616,
        45.5020, // Centre Eaton
        -73.5700,
      );
      // A vol d'oiseau : entre 1,4 et 1,8 km.
      expect(km, greaterThan(1.2));
      expect(km, lessThan(2.0));
    });

    test('le meme point : zero', () {
      expect(
        LocationService.distanceKm(45.5017, -73.5673, 45.5017, -73.5673),
        closeTo(0, 0.001),
      );
    });

    test('Montreal - Quebec : environ 230 km', () {
      final km = LocationService.distanceKm(
        45.5017,
        -73.5673,
        46.8139,
        -71.2080,
      );
      expect(km, greaterThan(220));
      expect(km, lessThan(250));
    });
  });

  group('La distance ecrite', () {
    test('sous le kilometre, en metres arrondis a 50', () {
      expect(LocationService.distanceEcrite(0.42, anglais: false), '400 m');
      expect(LocationService.distanceEcrite(0.63, anglais: false), '650 m');
    });

    test('jamais zero metre : une position « medium » ne vaut pas mieux', () {
      expect(LocationService.distanceEcrite(0.004, anglais: false), '50 m');
    });

    test('au-dela, une seule decimale', () {
      expect(LocationService.distanceEcrite(1.2345, anglais: false), '1,2 km');
      expect(LocationService.distanceEcrite(12.98, anglais: false), '13,0 km');
    });

    test('la virgule en francais, le point en anglais', () {
      expect(LocationService.distanceEcrite(1.5, anglais: false), '1,5 km');
      expect(LocationService.distanceEcrite(1.5, anglais: true), '1.5 km');
    });
  });

  group('Le secteur d un code postal', () {
    test('les trois premiers caracteres, espaces et casse compris', () {
      expect(LocationService.secteur('H3B 1A1'), 'H3B');
      expect(LocationService.secteur('h3b1a1'), 'H3B');
      expect(LocationService.secteur('  g1r 2l3 '), 'G1R');
    });

    test('un code trop court ne donne pas de secteur', () {
      expect(LocationService.secteur('H3'), isNull);
      expect(LocationService.secteur(''), isNull);
      expect(LocationService.secteur(null), isNull);
    });
  });
}
