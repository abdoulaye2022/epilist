// La photo d'un reçu : savoir qu'elle existe sans savoir où elle est.
//
// Le serveur ne renvoie plus d'URL publique pour un reçu — l'objet est
// privé, et son URL se demande au moment de l'afficher. L'application a
// donc besoin d'un champ qui dise « il y a une photo », indépendamment
// de la façon dont elle est rangée : c'est `has_image`.
//
// Ce qui se teste ici est la BASCULE, et elle compte : pendant que le
// parc d'applications tourne, trois formes de charge utile circulent.
// Si l'une d'elles est mal lue, des reçus perdent leur photo à l'écran
// alors qu'elle existe toujours.
import 'package:epilist/models/receipt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> base() => {
    'id': 7,
    'list_id': 3,
    'store_name': 'Metro Sainte-Catherine',
    'total_amount': 42.5,
    'purchase_date': '2026-10-29',
    'formatted_amount': r'42,50 $',
    'created_at': '2026-10-29T10:00:00Z',
    'updated_at': '2026-10-29T10:00:00Z',
  };

  group('Un reçu sait s il a une photo', () {
    test('serveur à jour : has_image fait foi', () {
      final avec = Receipt.fromJson({...base(), 'has_image': true, 'image_url': null});
      final sans = Receipt.fromJson({...base(), 'has_image': false, 'image_url': null});

      expect(avec.hasImage, isTrue);
      expect(sans.hasImage, isFalse);
      // La nouveauté : une photo existe, et aucune URL ne circule.
      expect(avec.imageUrl, isNull);
    });

    test('serveur ancien : l URL reste le seul indice', () {
      // Avant la migration 015, `has_image` n'existe pas. Une application
      // à jour qui parlerait à un serveur en retard doit malgré tout
      // afficher les photos.
      final json = base()
        ..['image_url'] =
            'https://storage.googleapis.com/epilist-storage/prod/receipts/abc.jpg';

      expect(Receipt.fromJson(json).hasImage, isTrue);
    });

    test('serveur ancien, aucune photo : rien à afficher', () {
      expect(Receipt.fromJson(base()).hasImage, isFalse);
      expect(Receipt.fromJson({...base(), 'image_url': ''}).hasImage, isFalse);
    });

    test('has_image l emporte sur une URL résiduelle', () {
      // Un reçu dont la photo vient d'être retirée : le serveur dit non,
      // même si une vieille URL traîne encore dans la charge utile.
      final json = base()
        ..['has_image'] = false
        ..['image_url'] = 'https://storage.googleapis.com/epilist-storage/x.jpg';

      expect(Receipt.fromJson(json).hasImage, isFalse);
    });
  });

  group('Le reste du reçu ne bouge pas', () {
    test('copyWith conserve la photo quand on ne la touche pas', () {
      final recu = Receipt.fromJson({...base(), 'has_image': true});
      expect(recu.copyWith(storeName: 'IGA').hasImage, isTrue);
    });

    test('copyWith sait retirer la photo', () {
      final recu = Receipt.fromJson({...base(), 'has_image': true});
      expect(recu.copyWith(hasImage: false).hasImage, isFalse);
    });

    test('deux reçus ne sont égaux que si la photo l est aussi', () {
      final avec = Receipt.fromJson({...base(), 'has_image': true});
      final sans = Receipt.fromJson({...base(), 'has_image': false});
      expect(avec, isNot(equals(sans)));
    });
  });
}
