// Décodage d'une facture : il doit survivre à des données inattendues.
// Avant, un seul champ au mauvais type faisait échouer le décodage de
// TOUTE la liste et la page Factures restait vide, sans message.
import 'package:epilist/models/receipt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Receipt.fromJson', () {
    test('décode une charge utile normale', () {
      final r = Receipt.fromJson({
        'id': 7,
        'list_id': 3,
        'store_name': 'Walmart',
        'total_amount': 42.5,
        'notes': 'courses',
        'purchase_date': '2026-10-15',
        'formatted_amount': r'$42.50',
        'created_at': '2026-10-15T10:00:00.000Z',
        'updated_at': '2026-10-15T10:00:00.000Z',
        'image_url': 'https://example.test/recu.jpg',
      });

      expect(r.id, 7);
      expect(r.totalAmount, 42.5);
      expect(r.storeName, 'Walmart');
      expect(r.imageUrl, 'https://example.test/recu.jpg');
    });

    test('accepte un montant renvoyé en chaîne (DECIMAL SQL)', () {
      final r = Receipt.fromJson({
        'id': '7',
        'list_id': '3',
        'store_name': 'IGA',
        'total_amount': '42.50',
        'purchase_date': '2026-10-15',
        'created_at': '2026-10-15T10:00:00.000Z',
        'updated_at': '2026-10-15T10:00:00.000Z',
      });

      expect(r.id, 7);
      expect(r.totalAmount, 42.5);
      // Pas de formatted_amount : repli calculé, et non une exception.
      expect(r.formattedAmount, '42.50');
    });

    test('survit à des champs manquants', () {
      final r = Receipt.fromJson({'id': 1});

      expect(r.id, 1);
      expect(r.storeName, '');
      expect(r.totalAmount, 0);
      expect(r.imageUrl, isNull);
    });

    // GET /receipts (onglet Factures) renvoie le nom de la liste
    // porteuse ; les routes par liste ne le renvoient pas, puisqu'on la
    // connait deja. Les deux doivent se decoder.
    test('retient le nom de la liste quand le serveur le donne', () {
      final r = Receipt.fromJson({
        'id': 12,
        'list_id': 160,
        'list_name': 'Diag factures',
        'store_name': 'Maxi',
        'total_amount': 18.75,
        'purchase_date': '2026-10-14',
        'created_at': '2026-10-14T10:00:00.000Z',
        'updated_at': '2026-10-14T10:00:00.000Z',
      });

      expect(r.listName, 'Diag factures');
      expect(r.toJson()['list_name'], 'Diag factures');
    });

    test('accepte une facture sans nom de liste', () {
      final r = Receipt.fromJson({
        'id': 12,
        'list_id': 160,
        'store_name': 'Maxi',
        'total_amount': 18.75,
        'purchase_date': '2026-10-14',
        'created_at': '2026-10-14T10:00:00.000Z',
        'updated_at': '2026-10-14T10:00:00.000Z',
      });

      expect(r.listName, isNull);
    });

  });
}
