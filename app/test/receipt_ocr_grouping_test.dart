// Regroupement des fragments OCR en lignes de lecture.
//
// Le bug corrigé ici : la version précédente comparait chaque fragment à
// la BOÎTE ENGLOBANTE de la ligne en cours, qui grandissait à mesure
// qu'on y ajoutait du texte. Un seul fragment haut (nom du magasin en
// gros) suffisait à élargir la ligne, qui avalait ensuite les suivantes.
// Sur iPhone — où ML Kit renvoie des hauteurs plus grandes et des blocs
// plus larges — le reçu entier fusionnait en quelques lignes géantes, et
// le parseur n'y lisait plus qu'un montant : le total.
import 'package:epilist/services/receipt_ocr_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fragment d'une hauteur de ligne standard, centré sur [centerY].
OcrFragment frag(String text, double centerY, double left,
        {double height = 20}) =>
    OcrFragment(
      top: centerY - height / 2,
      bottom: centerY + height / 2,
      left: left,
      text: text,
    );

void main() {
  group('Regroupement en lignes', () {
    test('réunit le libellé et le prix d\'une même ligne', () {
      final lines = groupFragmentsIntoLines([
        frag('LAIT 2%', 100, 10),
        frag('4.99', 100, 300),
        frag('PAIN', 140, 10),
        frag('3.49', 140, 300),
      ]);

      expect(lines, ['LAIT 2% 4.99', 'PAIN 3.49']);
    });

    test('garde les lignes séparées malgré un titre en gros caractères', () {
      // Le piège : le nom du magasin est deux fois plus haut qu'une ligne
      // normale. L'ancienne version élargissait la ligne à sa hauteur,
      // puis y absorbait les articles suivants.
      final lines = groupFragmentsIntoLines([
        frag('SUPERMARCHE', 60, 10, height: 60),
        frag('LAIT 2%', 100, 10),
        frag('4.99', 100, 300),
        frag('PAIN', 140, 10),
        frag('3.49', 140, 300),
        frag('TOTAL', 180, 10),
        frag('8.48', 180, 300),
      ]);

      expect(lines, [
        'SUPERMARCHE',
        'LAIT 2% 4.99',
        'PAIN 3.49',
        'TOTAL 8.48',
      ]);
    });

    test('un fragment plus haut que sa ligne n\'avale pas la suivante', () {
      // LE défaut corrigé. ML Kit renvoie parfois, pour un même texte, une
      // boîte bien plus haute que la ligne (glyphes hauts, symbole de
      // devise, bruit de compression). L'ancienne version l'ajoutait à la
      // ligne en cours, dont la boîte englobante s'étirait alors vers le
      // bas — et la ligne suivante, dont le centre tombait dans cette
      // boîte élargie, y était absorbée. De proche en proche, le reçu
      // fusionnait. Le parseur ne lisant que le DERNIER montant d'une
      // ligne, tout le détail disparaissait au profit du total.
      final lines = groupFragmentsIntoLines([
        frag('ARTICLE A', 100, 10),
        frag('9.99', 100, 300, height: 60), // boîte anormalement haute
        frag('ARTICLE B', 125, 10),
        frag('4.50', 125, 300),
      ]);

      expect(lines, ['ARTICLE A 9.99', 'ARTICLE B 4.50']);
    });

    test('tolère un reçu légèrement incliné', () {
      // Photo prise de travers : chaque ligne dérive de quelques pixels.
      final lines = groupFragmentsIntoLines([
        frag('LAIT 2%', 100, 10),
        frag('4.99', 104, 300),
        frag('PAIN', 140, 10),
        frag('3.49', 145, 300),
      ]);

      expect(lines, ['LAIT 2% 4.99', 'PAIN 3.49']);
    });

    test('ordonne de gauche à droite quel que soit l\'ordre des blocs', () {
      // ML Kit rend souvent la colonne des prix avant celle des libellés.
      final lines = groupFragmentsIntoLines([
        frag('4.99', 100, 300),
        frag('3.49', 140, 300),
        frag('LAIT 2%', 100, 10),
        frag('PAIN', 140, 10),
      ]);

      expect(lines, ['LAIT 2% 4.99', 'PAIN 3.49']);
    });

    test('un reçu dense reste ligne par ligne', () {
      // 12 articles serrés : aucune fusion ne doit se produire.
      final fragments = <OcrFragment>[];
      for (var i = 0; i < 12; i++) {
        final y = 100 + i * 26.0;
        fragments.add(frag('ARTICLE $i', y, 10));
        fragments.add(frag('${i + 1}.00', y, 300));
      }

      final lines = groupFragmentsIntoLines(fragments);

      expect(lines.length, 12);
      expect(lines.first, 'ARTICLE 0 1.00');
      expect(lines.last, 'ARTICLE 11 12.00');
    });

    test('ignore les fragments vides et accepte une liste vide', () {
      expect(groupFragmentsIntoLines([]), isEmpty);
      expect(
        groupFragmentsIntoLines([frag('   ', 100, 10), frag('OK', 100, 50)]),
        ['OK'],
      );
    });
  });
}
