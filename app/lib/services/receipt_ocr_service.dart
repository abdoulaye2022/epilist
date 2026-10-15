// services/receipt_ocr_service.dart - Extraction du texte d'un reçu.
//
// Abstraction volontaire : le parseur ne connaît que des lignes de texte.
// Implémentation V1 : ML Kit Text Recognition (Google), 100 % local,
// gratuit et hors ligne, disponible Android + iOS. Remplaçable plus tard
// (Apple Vision natif, autre moteur) sans toucher au reste du pipeline.
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

abstract class ReceiptOcrService {
  /// Extrait les lignes de texte d'une image de reçu, dans l'ordre de
  /// lecture (haut vers bas). Lance une exception si l'OCR échoue.
  Future<List<String>> extractLines(String imagePath);

  void dispose() {}
}

/// Un morceau de texte reconnu, avec sa position dans l'image.
///
/// Type volontairement indépendant de ML Kit : le regroupement en lignes
/// est ainsi testable sans appareil ni moteur OCR.
class OcrFragment {
  final double top;
  final double bottom;
  final double left;
  final String text;

  const OcrFragment({
    required this.top,
    required this.bottom,
    required this.left,
    required this.text,
  });

  double get centerY => (top + bottom) / 2;
  double get height => bottom - top;
}

/// Réassemble les fragments en lignes de lecture.
///
/// ML Kit regroupe le texte en blocs qui ne suivent pas l'ordre visuel, et
/// sur un reçu le libellé et le prix d'une même ligne atterrissent souvent
/// dans deux blocs (colonne gauche / colonne droite). On regroupe donc par
/// position verticale.
///
/// La tolérance vient de la hauteur MÉDIANE des fragments : elle s'adapte
/// à la résolution de la photo, qui diffère fortement entre Android et
/// iOS. Et chaque fragment est comparé au CENTRE de la ligne en cours,
/// jamais à une boîte englobante — sinon un seul fragment haut (un nom de
/// magasin en gros caractères) élargit la ligne, qui avale alors les
/// suivantes. C'est ce défaut qui, sur iPhone, fusionnait le reçu entier
/// en quelques lignes géantes : le parseur n'y lisait plus qu'un seul
/// montant, celui du total.
List<String> groupFragmentsIntoLines(List<OcrFragment> fragments) {
  final entries = fragments.where((f) => f.text.trim().isNotEmpty).toList();
  if (entries.isEmpty) return const [];

  entries.sort((a, b) => a.centerY.compareTo(b.centerY));

  final heights = entries.map((e) => e.height).where((h) => h > 0).toList()
    ..sort();
  final medianHeight =
      heights.isEmpty ? 0.0 : heights[heights.length ~/ 2];
  // 60 % de la hauteur d'une ligne : assez pour tolérer un reçu
  // légèrement incliné, trop peu pour fusionner deux lignes voisines.
  final tolerance = medianHeight > 0 ? medianHeight * 0.6 : 1.0;

  final rows = <List<OcrFragment>>[];
  var currentCenter = entries.first.centerY;

  for (final e in entries) {
    if (rows.isEmpty || (e.centerY - currentCenter).abs() > tolerance) {
      rows.add([e]);
      currentCenter = e.centerY;
      continue;
    }
    rows.last.add(e);
    // Centre glissant : la ligne suit une légère inclinaison du reçu sans
    // jamais s'élargir.
    currentCenter =
        rows.last.map((f) => f.centerY).reduce((a, b) => a + b) /
            rows.last.length;
  }

  return rows.map((row) {
    row.sort((a, b) => a.left.compareTo(b.left));
    return row.map((e) => e.text.trim()).join(' ');
  }).toList();
}

class MlKitReceiptOcrService implements ReceiptOcrService {
  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  @override
  Future<List<String>> extractLines(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final result = await _recognizer.processImage(input);

    final fragments = <OcrFragment>[];
    for (final block in result.blocks) {
      for (final line in block.lines) {
        final box = line.boundingBox;
        fragments.add(OcrFragment(
          top: box.top.toDouble(),
          bottom: box.bottom.toDouble(),
          left: box.left.toDouble(),
          text: line.text.trim(),
        ));
      }
    }

    return groupFragmentsIntoLines(fragments);
  }

  @override
  void dispose() {
    _recognizer.close();
  }
}
