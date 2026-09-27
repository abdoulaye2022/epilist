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

class MlKitReceiptOcrService implements ReceiptOcrService {
  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  @override
  Future<List<String>> extractLines(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final result = await _recognizer.processImage(input);

    // ML Kit regroupe le texte en blocs qui ne suivent pas toujours l'ordre
    // visuel, et sur un reçu le libellé et le prix d'une même ligne
    // atterrissent souvent dans deux blocs (colonne gauche / colonne
    // droite). On réassemble donc par position verticale : les lignes dont
    // les centres se chevauchent sont fusionnées, triées par x.
    final entries = <({double top, double bottom, double left, String text})>[];
    for (final block in result.blocks) {
      for (final line in block.lines) {
        final box = line.boundingBox;
        entries.add((
          top: box.top,
          bottom: box.bottom,
          left: box.left,
          text: line.text.trim(),
        ));
      }
    }
    entries.sort((a, b) => a.top.compareTo(b.top));

    final rows = <List<({double top, double bottom, double left, String text})>>[];
    for (final e in entries) {
      if (e.text.isEmpty) continue;
      final centerY = (e.top + e.bottom) / 2;
      final row = rows.isEmpty ? null : rows.last;
      if (row != null) {
        final rowTop = row.map((r) => r.top).reduce((a, b) => a < b ? a : b);
        final rowBottom =
            row.map((r) => r.bottom).reduce((a, b) => a > b ? a : b);
        if (centerY >= rowTop && centerY <= rowBottom) {
          row.add(e);
          continue;
        }
      }
      rows.add([e]);
    }

    return rows.map((row) {
      row.sort((a, b) => a.left.compareTo(b.left));
      return row.map((e) => e.text).join(' ');
    }).toList();
  }

  @override
  void dispose() {
    _recognizer.close();
  }
}
