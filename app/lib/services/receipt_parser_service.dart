// services/receipt_parser_service.dart - Classification des lignes d'un
// reçu (texte OCR) en articles / totaux / taxes / rabais / métadonnées.
//
// Pur Dart, sans dépendance Flutter : testable unitairement.
// Aucun nom de magasin n'est codé en dur : la liste des magasins connus de
// l'utilisateur est injectée et sert uniquement d'aide à la détection.
//
// Principe : le parseur PROPOSE, l'utilisateur DISPOSE. Toute ligne
// incertaine reçoit une confiance basse et sera signalée dans l'écran de
// validation ; rien n'est enregistré sans passage par cet écran.
import 'package:epilist/models/parsed_receipt.dart';

class ReceiptParserService {
  /// [knownStoreNames] : noms des magasins de l'utilisateur (facultatif),
  /// utilisés pour reconnaître l'en-tête du reçu.
  ParsedReceipt parse(List<String> lines, {List<String> knownStoreNames = const []}) {
    final receipt = ParsedReceipt();
    final cleaned = lines
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    for (var i = 0; i < cleaned.length; i++) {
      final line = cleaned[i];
      final upper = _stripAccents(line.toUpperCase());

      // 1. Métadonnées ---------------------------------------------------
      if (receipt.storeName == null) {
        final store = _matchKnownStore(upper, knownStoreNames);
        if (store != null) {
          receipt.storeName = store;
          continue;
        }
      }

      final date = _parseDate(line);
      if (date != null && receipt.purchaseDate == null) {
        receipt.purchaseDate = date;
        // La ligne peut aussi contenir un numéro de facture : on continue.
      }

      final receiptNo = _parseReceiptNumber(upper);
      if (receiptNo != null && receipt.receiptNumber == null) {
        receipt.receiptNumber = receiptNo;
      }

      // 2. Totaux et taxes ----------------------------------------------
      final amount = _trailingAmount(line);
      if (amount != null) {
        if (_isSubtotalLine(upper)) {
          receipt.subtotal = amount.value;
          continue;
        }
        if (_isTaxLine(upper)) {
          receipt.taxes = (receipt.taxes ?? 0) + amount.value;
          continue;
        }
        if (_isTotalLine(upper)) {
          // Certains reçus ont plusieurs lignes TOTAL (avant/après
          // arrondi) : on garde la dernière.
          receipt.total = amount.value;
          continue;
        }
      }

      // 3. Lignes à ignorer (paiement, en-têtes, pieds de page) ----------
      if (_isNoiseLine(upper)) {
        continue;
      }

      // 4. Ligne de détail poids/quantité rattachée à l'article précédent
      //    « 1.245 kg @ 1.59/kg »  ou  « 2 @ 3.50 »
      final detail = _parseQuantityDetail(line);
      if (detail != null && receipt.items.isNotEmpty) {
        final last = receipt.items.last;
        last.quantity = detail.quantity;
        last.unit = detail.unit ?? last.unit;
        last.unitPrice = detail.unitPrice;
        if (last.confidence < 90) last.confidence += 10;
        continue;
      }

      // 5. Ligne d'article : libellé + montant en fin de ligne ------------
      if (amount != null) {
        final label = line.substring(0, amount.start).trim();
        if (label.length < 2) {
          receipt.unrecognizedLines.add(line);
          continue;
        }
        final isDiscount = amount.negative || _isDiscountLabel(upper);

        // Format multi-quantité inclus dans la ligne : « 2 X 3.49 » devant
        // le montant.
        double qty = 1;
        double? unitPrice;
        String cleanLabel = label;
        final multi = RegExp(
          r'(\d{1,3})\s*[xX@]\s*(\d{1,4}[.,]\d{2})\s*$',
        ).firstMatch(label);
        if (multi != null) {
          qty = double.parse(multi.group(1)!);
          unitPrice = _toDouble(multi.group(2)!);
          cleanLabel = label.substring(0, multi.start).trim();
        }
        if (cleanLabel.length < 2) cleanLabel = label;

        receipt.items.add(
          ParsedReceiptItem(
            rawLabel: cleanLabel,
            quantity: qty,
            unit: qty > 1 ? 'un' : null,
            unitPrice: unitPrice,
            linePrice: amount.value.abs() * (isDiscount ? -1 : 1),
            confidence: _confidenceFor(cleanLabel, amount.value),
            isDiscount: isDiscount,
          ),
        );
        continue;
      }

      // 6. Peut-être le nom du magasin en tête de reçu --------------------
      if (receipt.storeName == null &&
          receipt.items.isEmpty &&
          i < 3 &&
          _looksLikeStoreName(upper)) {
        receipt.storeName = _titleCase(line);
        continue;
      }

      receipt.unrecognizedLines.add(line);
    }

    // Retours/rabais : gardés mais exclus par défaut (linePrice négatif).
    receipt.items.removeWhere((it) => it.isDiscount && it.linePrice == 0);
    return receipt;
  }

  // --- Montants -------------------------------------------------------

  /// Montant en fin de ligne : « 6.49 », « 6,49 », « 6.49- », « $6.49 »,
  /// éventuellement suivi d'un code taxe court (« H », « MRJ », « F »).
  ({double value, bool negative, int start})? _trailingAmount(String line) {
    final m = RegExp(
      r'(-?)\$?\s*(\d{1,5}[.,]\d{2})\s*(-?)\s*([A-Z]{0,3})$',
    ).firstMatch(line);
    if (m == null) return null;
    final value = _toDouble(m.group(2)!);
    // Garde-fou : un montant seul sans libellé n'est pas un article.
    final negative = m.group(1) == '-' || m.group(3) == '-';
    return (value: value, negative: negative, start: m.start);
  }

  double _toDouble(String s) => double.parse(s.replaceAll(',', '.'));

  // --- Classification de lignes ----------------------------------------

  bool _isTotalLine(String upper) =>
      RegExp(r'(^|\s)TOTAL(\s|$)').hasMatch(upper) &&
      !upper.contains('SOUS') &&
      !upper.contains('SUB');

  bool _isSubtotalLine(String upper) =>
      upper.contains('SOUS-TOTAL') ||
      upper.contains('SOUS TOTAL') ||
      upper.contains('SUBTOTAL') ||
      upper.contains('SUB-TOTAL') ||
      upper.contains('SUB TOTAL');

  bool _isTaxLine(String upper) => RegExp(
        r'(^|\s)(TPS|TVQ|TVH|GST|QST|HST|PST|TAXE?S?)(\s|/|$)',
      ).hasMatch(upper);

  bool _isDiscountLabel(String upper) =>
      upper.contains('RABAIS') ||
      upper.contains('COUPON') ||
      upper.contains('ECON') ||
      upper.contains('DISCOUNT') ||
      upper.contains('SAVING') ||
      upper.contains('REMBOURS') ||
      upper.contains('REFUND') ||
      upper.contains('RETOUR');

  /// Paiement, solde de carte, messages : jamais des articles.
  bool _isNoiseLine(String upper) => RegExp(
        r'(^|\s)(VISA|MASTERCARD|INTERAC|DEBIT|CREDIT|COMPTANT|CASH|'
        r'MONNAIE|CHANGE|APPROUV|APPROVED|AUTORIS|AUTH|CARTE|CARD|'
        r'SOLDE|BALANCE|MERCI|THANK|BIENVENUE|WELCOME|CAISSE|CASHIER|'
        r'TEL|WWW\.|HTTP|POINTS?|AIRMILES|OPTIMUM)(\s|:|$)',
      ).hasMatch(upper);

  bool _looksLikeStoreName(String upper) =>
      upper.length >= 3 &&
      upper.length <= 40 &&
      !RegExp(r'\d{3,}').hasMatch(upper) &&
      RegExp(r"^[A-Z0-9&\- .']+$").hasMatch(upper);

  String? _matchKnownStore(String upper, List<String> knownStoreNames) {
    for (final name in knownStoreNames) {
      final n = _stripAccents(name.toUpperCase());
      if (n.length >= 3 && upper.contains(n)) return name;
    }
    return null;
  }

  // --- Détails quantité/poids -------------------------------------------

  /// « 1.245 kg @ 1.59/kg », « 0.680 kg @ $2.18 / kg », « 2 @ 3.50 »
  ({double quantity, String? unit, double unitPrice})? _parseQuantityDetail(
    String line,
  ) {
    final weight = RegExp(
      r'^(\d{1,3}[.,]\d{1,3})\s*(kg|g|lb|l|L|ml)\s*[@xX]\s*\$?\s*'
      r'(\d{1,4}[.,]\d{2})',
    ).firstMatch(line.trim());
    if (weight != null) {
      var qty = _toDouble(weight.group(1)!);
      var unit = weight.group(2)!.toLowerCase();
      var price = _toDouble(weight.group(3)!);
      if (unit == 'lb') {
        // Normalisation en kg (1 lb = 0.4536 kg)
        qty *= 0.4536;
        price /= 0.4536;
        unit = 'kg';
      }
      if (unit == 'l') unit = 'L';
      return (quantity: qty, unit: unit, unitPrice: price);
    }

    final count = RegExp(
      r'^(\d{1,3})\s*[@xX]\s*\$?\s*(\d{1,4}[.,]\d{2})\s*$',
    ).firstMatch(line.trim());
    if (count != null) {
      return (
        quantity: double.parse(count.group(1)!),
        unit: 'un',
        unitPrice: _toDouble(count.group(2)!),
      );
    }
    return null;
  }

  // --- Métadonnées -------------------------------------------------------

  DateTime? _parseDate(String line) {
    // yyyy-mm-dd ou yyyy/mm/dd
    var m = RegExp(r'(20\d{2})[-/](\d{1,2})[-/](\d{1,2})').firstMatch(line);
    if (m != null) {
      return _safeDate(
        int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!),
      );
    }
    // dd/mm/yyyy ou dd-mm-yyyy (interprétation jour d'abord, usage canadien
    // francophone ; l'utilisateur corrige dans l'écran de validation)
    m = RegExp(r'(\d{1,2})[-/](\d{1,2})[-/](20\d{2})').firstMatch(line);
    if (m != null) {
      final a = int.parse(m.group(1)!);
      final b = int.parse(m.group(2)!);
      final y = int.parse(m.group(3)!);
      // Si le premier nombre ne peut pas être un jour valide en mois b,
      // on suppose mm/dd.
      return a > 12 ? _safeDate(y, b, a) : _safeDate(y, b > 12 ? a : b, b > 12 ? b : a);
    }
    return null;
  }

  DateTime? _safeDate(int y, int mo, int d) {
    if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
    final date = DateTime(y, mo, d);
    if (date.isAfter(DateTime.now().add(const Duration(days: 1)))) return null;
    return date;
  }

  String? _parseReceiptNumber(String upper) {
    final m = RegExp(
      r'(?:FACTURE|RECU|RECEIPT|TRANS(?:ACTION)?|INV(?:OICE)?)\s*'
      r'(?:NO|N°|#|:)?\s*(\d{3,})',
    ).firstMatch(upper);
    return m?.group(1);
  }

  // --- Divers --------------------------------------------------------------

  int _confidenceFor(String label, double amount) {
    var score = 85;
    if (label.length < 4) score -= 20;
    if (amount > 500) score -= 25; // montant improbable pour une épicerie
    if (RegExp(r'[^\w\s%&.\-]').hasMatch(_stripAccents(label))) score -= 10;
    if (!RegExp(r'[A-Za-z]{2,}').hasMatch(label)) score -= 30;
    return score.clamp(10, 95);
  }

  String _stripAccents(String s) {
    const from = 'ÀÂÄÉÈÊËÎÏÔÖÙÛÜÇàâäéèêëîïôöùûüç';
    const to = 'AAAEEEEIIOOUUUCaaaeeeeiioouuuc';
    var out = s;
    for (var i = 0; i < from.length; i++) {
      out = out.replaceAll(from[i], to[i]);
    }
    return out;
  }

  String _titleCase(String s) => s
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}
