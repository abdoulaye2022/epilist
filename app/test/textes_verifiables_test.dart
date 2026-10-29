// Ce que les textes de l'application n'ont pas le droit de dire.
//
// L'audit marketing a trouvé une série d'affirmations invérifiables :
// « synchronisation temps réel » alors qu'aucun websocket n'existe dans
// le dépôt, « 70 % de temps économisé », « 30 % d'économies », une note
// de 4,9 sur 1247 avis. Elles avaient toutes un point commun : personne
// ne les avait inventées de mauvaise foi, elles étaient juste restées là
// pendant que le produit changeait.
//
// Ce test est le garde-fou. Il lit les deux fichiers de traduction et
// échoue si l'une de ces formulations revient — dans une nouvelle clé,
// dans un copier-coller, dans un texte d'écran. Il vérifie aussi que les
// deux langues restent à égalité : une politique de confidentialité à
// moitié traduite n'est pas une politique de confidentialité.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _charger(String langue) {
  final fichier = File('lib/l10n/app_$langue.arb');

  // Chargé AVANT tout test : pas d'expect ici, il n'aurait pas de test
  // auquel se rattacher. Une erreur claire vaut mieux qu'une pile.
  if (!fichier.existsSync()) {
    throw StateError(
      'app_$langue.arb introuvable — lancer les tests depuis le dossier app/',
    );
  }

  return jsonDecode(fichier.readAsStringSync()) as Map<String, dynamic>;
}

/// Les clés de traduction, sans les métadonnées « @… ».
Iterable<MapEntry<String, String>> _chaines(Map<String, dynamic> arb) =>
    arb.entries
        .where((e) => !e.key.startsWith('@') && e.value is String)
        .map((e) => MapEntry(e.key, e.value as String));

void main() {
  final fr = _charger('fr');
  final en = _charger('en');

  group('Les deux langues vont ensemble', () {
    test('mêmes clés de part et d autre', () {
      final manquantEn = fr.keys.where((k) => !en.containsKey(k)).toList();
      final manquantFr = en.keys.where((k) => !fr.containsKey(k)).toList();

      expect(manquantEn, isEmpty, reason: 'absentes de app_en.arb');
      expect(manquantFr, isEmpty, reason: 'absentes de app_fr.arb');
    });

    test('aucune traduction vide', () {
      for (final arb in [fr, en]) {
        for (final e in _chaines(arb)) {
          expect(e.value.trim(), isNotEmpty, reason: 'clé vide : ${e.key}');
        }
      }
    });
  });

  group('Aucune affirmation invérifiable', () {
    // Chaque motif a une raison, et elle est écrite : un test qui
    // interdit sans dire pourquoi finit par être contourné.
    const interdits = <String, String>{
      'temps réel':
          'aucun websocket dans le dépôt : le push est plafonné à un par '
          'liste toutes les trois minutes. Écrire « notification instantanée ».',
      'real-time':
          'no websocket in the repository: push is capped at one per list '
          'every three minutes. Say "instant notification".',
      'real time':
          'idem : « instant notification ».',
      '70 %': 'chiffre jamais mesuré (temps économisé)',
      '70%': 'chiffre jamais mesuré (temps économisé)',
      '30 %': 'chiffre jamais mesuré (économies moyennes)',
      '50 000': 'nombre de familles jamais compté',
      '50,000': 'nombre de familles jamais compté',
      'AES-256': 'aucun chiffrement applicatif de ce type dans le code',
      '4,9 sur 5': 'note inventée',
      '150 devises': 'le nombre réel est en base, pas dans le code',
      '150+ devises': 'le nombre réel est en base, pas dans le code',
    };

    for (final entree in interdits.entries) {
      test('« ${entree.key} » n apparaît nulle part', () {
        final fautives = <String>[];

        for (final arb in [fr, en]) {
          for (final e in _chaines(arb)) {
            if (e.value.toLowerCase().contains(entree.key.toLowerCase())) {
              fautives.add(e.key);
            }
          }
        }

        expect(
          fautives,
          isEmpty,
          reason:
              'clés fautives : ${fautives.join(', ')}\nPourquoi : ${entree.value}',
        );
      });
    }
  });

  group('La politique de confidentialité est complète', () {
    // Les douze sections, dans l'ordre où l'écran les affiche
    // (screens/privacy_policy_screen.dart). Trois sont arrivées avec la
    // phase 3 : les reçus, la suppression du compte, la mesure
    // d'audience. Si l'une disparaît, l'écran affiche un trou.
    const sections = [
      'privacyCollection',
      'privacyUsage',
      'privacyReceipts',
      'privacyStorage',
      'privacySharing',
      'privacyRights',
      'privacyAccountDeletion',
      'privacyFeatures',
      'privacyMeasurement',
      'privacyCookies',
      'privacyChanges',
      'privacyContact',
    ];

    test('chaque section a son titre et son texte, dans les deux langues', () {
      for (final section in sections) {
        for (final arb in [fr, en]) {
          expect(arb['${section}Title'], isA<String>(), reason: section);
          expect(arb['${section}Text'], isA<String>(), reason: section);
        }
      }
    });

    test('les sections sont numérotées de 1 à 12, sans trou', () {
      for (final arb in [fr, en]) {
        final numeros = sections
            .map((s) => (arb['${s}Title'] as String).split('.').first.trim())
            .toList();

        expect(numeros, List.generate(12, (i) => '${i + 1}'));
      }
    });

    test('la date de mise à jour est présente et datée', () {
      expect(fr['privacyLastUpdated'], contains('2026'));
      expect(en['privacyLastUpdated'], contains('2026'));
    });

    test('les reçus disent où va la photo, et ce qui reste sur l appareil', () {
      final texteFr = fr['privacyReceiptsText'] as String;
      final texteEn = en['privacyReceiptsText'] as String;

      // Le point de confidentialité du produit : la lecture est locale.
      expect(texteFr, contains('SUR votre téléphone'));
      expect(texteEn, contains('ON your phone'));

      // Et le fournisseur reste générique : pas de nom de produit.
      for (final marque in ['Google', 'Firebase', 'GCS', 'Amazon', 'Azure']) {
        expect(texteFr.contains(marque), isFalse, reason: marque);
        expect(texteEn.contains(marque), isFalse, reason: marque);
      }
    });
  });
}
