// test/receipt_parser_service_test.dart - Le parseur de reçus est pur
// Dart : on le teste sur des fixtures représentatives de vrais tickets.
import 'package:epilist/services/receipt_parser_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = ReceiptParserService();

  group('Reçu style Walmart', () {
    final lines = [
      'WALMART',
      '123 RUE PRINCIPALE',
      'QUEBEC QC',
      '2026-09-20 14:32',
      'TRANS # 4482',
      'MLK 2% 4L 6.49 H',
      'PAIN BLE ENT 3.50',
      'BANANES 1.98',
      '1.245 kg @ 1.59/kg',
      'SOUS-TOTAL 11.97',
      'TPS 5% 0.32',
      'TVQ 9.975% 0.65',
      'TOTAL 12.94',
      'VISA 12.94',
      'APPROUVEE AUTH 003921',
      'MERCI DE MAGASINER CHEZ NOUS',
    ];

    test('extrait magasin, date, numéro et totaux', () {
      final r = parser.parse(lines, knownStoreNames: ['Walmart', 'Maxi']);
      expect(r.storeName, 'Walmart');
      expect(r.purchaseDate, DateTime(2026, 9, 20));
      expect(r.receiptNumber, '4482');
      expect(r.subtotal, 11.97);
      expect(r.taxes, closeTo(0.97, 0.001)); // TPS + TVQ additionnées
      expect(r.total, 12.94);
    });

    test('extrait les articles et rattache le détail au poids', () {
      final r = parser.parse(lines);
      expect(r.items.length, 3);
      expect(r.items[0].rawLabel, 'MLK 2% 4L');
      expect(r.items[0].linePrice, 6.49);
      final bananes = r.items[2];
      expect(bananes.rawLabel, 'BANANES');
      expect(bananes.quantity, closeTo(1.245, 0.001));
      expect(bananes.unit, 'kg');
      expect(bananes.unitPrice, 1.59);
    });

    test('ignore paiement et messages', () {
      final r = parser.parse(lines);
      final labels = r.items.map((i) => i.rawLabel.toUpperCase()).toList();
      expect(labels.any((l) => l.contains('VISA')), isFalse);
      expect(labels.any((l) => l.contains('MERCI')), isFalse);
    });
  });

  group('Reçu style Costco (multi-quantité, rabais)', () {
    final lines = [
      'COSTCO WHOLESALE',
      'MEMBRE 111986543210',
      '9482 POULET ROTI 8.99',
      '1234 YOGOURT GRECS 12.49',
      'RABAIS COUPON 2.00-',
      'ESSUIE-TOUT 2 X 9.99 19.98',
      'SOUS-TOTAL 39.46',
      'TVH 13% 2.60',
      'TOTAL 42.06',
      '26/09/2026',
    ];

    test('détecte le rabais comme ligne négative exclue', () {
      final r = parser.parse(lines);
      final discount = r.items.where((i) => i.isDiscount).toList();
      expect(discount.length, 1);
      expect(discount.first.linePrice, -2.00);
      // La somme des articles hors rabais ne compte pas le rabais
      expect(r.itemsSum, closeTo(8.99 + 12.49 + 19.98, 0.01));
    });

    test('multi-quantité 2 X 9.99', () {
      final r = parser.parse(lines);
      final essuie = r.items.firstWhere(
        (i) => i.rawLabel.toUpperCase().contains('ESSUIE'),
      );
      expect(essuie.quantity, 2);
      expect(essuie.unitPrice, 9.99);
      expect(essuie.linePrice, 19.98);
    });

    test('date dd/mm/yyyy', () {
      final r = parser.parse(lines);
      expect(r.purchaseDate, DateTime(2026, 9, 26));
    });
  });

  group('Reçu style Superstore (livre -> kg, quantité @ prix)', () {
    final lines = [
      'REAL CANADIAN SUPERSTORE',
      'POMMES GALA 4.37',
      '2.15 lb @ 2.03/lb',
      'OEUFS GROS 12 3.29',
      '2 @ 3.29',
      'TOTAL 11.02',
    ];

    test('convertit les livres en kilogrammes', () {
      final r = parser.parse(lines);
      final pommes = r.items.first;
      expect(pommes.unit, 'kg');
      expect(pommes.quantity, closeTo(2.15 * 0.4536, 0.01));
      expect(pommes.unitPrice, closeTo(2.03 / 0.4536, 0.01));
    });

    test('quantité « 2 @ 3.29 » rattachée aux oeufs', () {
      final r = parser.parse(lines);
      final oeufs = r.items[1];
      expect(oeufs.quantity, 2);
      expect(oeufs.unit, 'un');
      expect(oeufs.unitPrice, 3.29);
    });
  });

  group('Cohérence des totaux et lignes inconnues', () {
    test('signale un écart entre somme des lignes et total lu', () {
      final r = parser.parse([
        'LAIT 5.00',
        'PAIN 3.00',
        'TOTAL 9.50', // 1.50 d'écart (article raté par l'OCR ?)
      ]);
      expect(r.totalMismatch, closeTo(-1.50, 0.001));
    });

    test('les lignes illisibles vont dans unrecognizedLines, jamais en article', () {
      final r = parser.parse([
        'LAIT 5.00',
        '~~~###~~~',
        'xQ zz',
        'TOTAL 5.00',
      ]);
      expect(r.items.length, 1);
      expect(r.unrecognizedLines, containsAll(['~~~###~~~', 'xQ zz']));
    });

    test('reçu vide -> aucun article, aucune erreur', () {
      final r = parser.parse([]);
      expect(r.items, isEmpty);
      expect(r.total, isNull);
    });

    test('libellé court ou sans lettres = confiance basse (à valider)', () {
      final r = parser.parse(['4011 1.98']);
      expect(r.items.length, 1);
      expect(r.items.first.isUncertain, isTrue);
    });
  });

  group('Formats de montants', () {
    test('virgule décimale et signe négatif en préfixe', () {
      final r = parser.parse(['FROMAGE 5,99', 'RETOUR LAIT -4,50']);
      expect(r.items[0].linePrice, 5.99);
      expect(r.items[1].isDiscount, isTrue);
      expect(r.items[1].linePrice, -4.50);
    });

    test('code taxe collé au montant (6.49 H)', () {
      final r = parser.parse(['MLK 2% 4L 6.49 H']);
      expect(r.items.single.linePrice, 6.49);
      expect(r.items.single.rawLabel, 'MLK 2% 4L');
    });
  });

  group('Magasin', () {
    test('reconnaît un magasin connu de l\'utilisateur, avec accents', () {
      final r = parser.parse(
        ['ÉPICERIE CHEZ MAXIME', 'LAIT 5.00', 'TOTAL 5.00'],
        knownStoreNames: ['Épicerie Chez Maxime'],
      );
      expect(r.storeName, 'Épicerie Chez Maxime');
    });

    test('sinon, prend une ligne d\'en-tête plausible', () {
      final r = parser.parse(['MARCHE DU COIN', 'LAIT 5.00', 'TOTAL 5.00']);
      expect(r.storeName, 'Marche Du Coin');
    });
  });
}
