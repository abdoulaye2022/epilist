// models/parsed_receipt.dart - Résultat du parsing d'un reçu (OCR ou saisie).
// Tout est modifiable par l'utilisateur avant l'import : rien n'est
// enregistré automatiquement.

/// Ligne d'article extraite d'un reçu.
class ParsedReceiptItem {
  /// Libellé brut tel que lu sur le reçu (ex. « MLK 2% 4L »).
  String rawLabel;

  /// Produit canonique choisi/confirmé par l'utilisateur (null = pas encore).
  String? productName;

  double quantity;

  /// kg, g, L, ml, un — null si inconnu.
  String? unit;

  /// Prix unitaire lu sur le reçu (ex. 1.59 $/kg), si présent.
  double? unitPrice;

  /// Montant de la ligne.
  double linePrice;

  /// 0-100 : confiance du parsing (libellé + prix bien séparés, etc.).
  int confidence;

  /// Ligne négative (rabais/retour) : exclue de l'import par défaut.
  bool isDiscount;

  ParsedReceiptItem({
    required this.rawLabel,
    this.productName,
    this.quantity = 1,
    this.unit,
    this.unitPrice,
    required this.linePrice,
    this.confidence = 50,
    this.isDiscount = false,
  });

  bool get isUncertain => confidence < 70;

  Map<String, dynamic> toImportJson() => {
    'raw_label': rawLabel,
    if (productName != null && productName!.trim().isNotEmpty)
      'product_name': productName!.trim(),
    'quantity': quantity,
    if (unit != null) 'unit': unit,
    if (unitPrice != null) 'unit_price': unitPrice,
    'line_price': linePrice,
    'confidence': confidence,
  };
}

/// Reçu parsé complet, avant validation par l'utilisateur.
class ParsedReceipt {
  String? storeName;
  DateTime? purchaseDate;
  double? subtotal;
  double? taxes;
  double? total;
  String? receiptNumber;
  final List<ParsedReceiptItem> items;

  /// Lignes que le parseur n'a pas su classer (affichées à titre indicatif).
  final List<String> unrecognizedLines;

  ParsedReceipt({
    this.storeName,
    this.purchaseDate,
    this.subtotal,
    this.taxes,
    this.total,
    this.receiptNumber,
    List<ParsedReceiptItem>? items,
    List<String>? unrecognizedLines,
  }) : items = items ?? [],
       unrecognizedLines = unrecognizedLines ?? [];

  /// Somme des lignes d'articles retenues (hors rabais exclus).
  double get itemsSum => items
      .where((i) => !i.isDiscount)
      .fold(0.0, (s, i) => s + i.linePrice);

  /// Écart entre la somme des lignes et le total lu — sert d'avertissement
  /// dans l'écran de validation, jamais de blocage.
  double? get totalMismatch => total == null ? null : (itemsSum - total!);
}

/// Suggestion de correspondance renvoyée par POST /receipts/resolve-labels.
class LabelResolution {
  final String label;
  final String? match;
  final String? method; // barcode | alias | exact | fuzzy
  final int confidence;

  const LabelResolution({
    required this.label,
    this.match,
    this.method,
    this.confidence = 0,
  });

  factory LabelResolution.fromJson(Map<String, dynamic> json) =>
      LabelResolution(
        label: json['label'] as String,
        match: json['match'] as String?,
        method: json['method'] as String?,
        confidence: (json['confidence'] as num?)?.toInt() ?? 0,
      );
}
