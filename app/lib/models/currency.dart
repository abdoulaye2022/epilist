// models/currency.dart - VERSION AVEC DEVISES PRÉDÉFINIES
class Currency {
  final int id;
  final String code;
  final String name;
  final String symbol;
  final bool isActive;
  final bool isPopular;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Currency({
    required this.id,
    required this.code,
    required this.name,
    required this.symbol,
    required this.isActive,
    required this.isPopular,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    try {
      return Currency(
        id: json['id'] as int,
        code: json['code'] as String,
        name: json['name'] as String,
        symbol: json['symbol'] as String,
        // ✅ CASTING SÉCURISÉ avec fallback
        isActive: _safeBoolCast(json['is_active']) ?? true,
        isPopular: _safeBoolCast(json['is_popular']) ?? false,
        displayOrder: json['display_order'] as int? ?? 999,
        // ✅ DATES AVEC FALLBACK
        createdAt:
            json['created_at'] != null
                ? DateTime.tryParse(json['created_at'] as String) ??
                    DateTime.now()
                : DateTime.now(),
        updatedAt:
            json['updated_at'] != null
                ? DateTime.tryParse(json['updated_at'] as String) ??
                    DateTime.now()
                : DateTime.now(),
      );
    } catch (e, stackTrace) {
      print('❌ Erreur parsing Currency: $e');
      print('JSON reçu: $json');
      print('Stack trace: $stackTrace');

      // ✅ FALLBACK: Retourner une devise par défaut en cas d'erreur
      return Currency.cad;
    }
  }

  // ✅ MÉTHODE UTILITAIRE: Casting sécurisé pour les booléens
  static bool? _safeBoolCast(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'symbol': symbol,
      'is_active': isActive,
      'is_popular': isPopular,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Nom d'affichage complet (généré)
  String get displayName => '$name ($code)';

  /// Formater un montant avec cette devise (AFFICHAGE SEULEMENT)
  String formatAmount(double amount, {bool showCode = false}) {
    final formatted = amount.toStringAsFixed(2);
    if (showCode) {
      return '$symbol$formatted $code';
    }
    return '$symbol$formatted';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Currency && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Currency($code - $name)';

  Currency copyWith({
    int? id,
    String? code,
    String? name,
    String? symbol,
    bool? isActive,
    bool? isPopular,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Currency(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      isActive: isActive ?? this.isActive,
      isPopular: isPopular ?? this.isPopular,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ✅ DEVISES PRÉDÉFINIES BASÉES SUR VOTRE BASE DE DONNÉES
  static final DateTime _now = DateTime.now();

  // Top 10 des devises mondiales (populaires)
  static final Currency cad = Currency(
    id: 1,
    code: 'CAD',
    name: 'Dollar canadien',
    symbol: '\$',
    isActive: true,
    isPopular: true,
    displayOrder: 1,
    createdAt: _now,
    updatedAt: _now,
  );

  static final Currency usd = Currency(
    id: 2,
    code: 'USD',
    name: 'Dollar américain',
    symbol: '\$',
    isActive: true,
    isPopular: true,
    displayOrder: 2,
    createdAt: _now,
    updatedAt: _now,
  );

  static final Currency eur = Currency(
    id: 3,
    code: 'EUR',
    name: 'Euro',
    symbol: '€',
    isActive: true,
    isPopular: true,
    displayOrder: 3,
    createdAt: _now,
    updatedAt: _now,
  );

  static final Currency gbp = Currency(
    id: 4,
    code: 'GBP',
    name: 'Livre sterling',
    symbol: '£',
    isActive: true,
    isPopular: true,
    displayOrder: 4,
    createdAt: _now,
    updatedAt: _now,
  );

  static final Currency jpy = Currency(
    id: 5,
    code: 'JPY',
    name: 'Yen japonais',
    symbol: '¥',
    isActive: true,
    isPopular: true,
    displayOrder: 5,
    createdAt: _now,
    updatedAt: _now,
  );

  static final Currency aud = Currency(
    id: 6,
    code: 'AUD',
    name: 'Dollar australien',
    symbol: 'A\$',
    isActive: true,
    isPopular: true,
    displayOrder: 6,
    createdAt: _now,
    updatedAt: _now,
  );

  static final Currency chf = Currency(
    id: 7,
    code: 'CHF',
    name: 'Franc suisse',
    symbol: 'CHF',
    isActive: true,
    isPopular: true,
    displayOrder: 7,
    createdAt: _now,
    updatedAt: _now,
  );

  static final Currency cny = Currency(
    id: 8,
    code: 'CNY',
    name: 'Yuan chinois',
    symbol: '¥',
    isActive: true,
    isPopular: true,
    displayOrder: 8,
    createdAt: _now,
    updatedAt: _now,
  );

  static final Currency hkd = Currency(
    id: 9,
    code: 'HKD',
    name: 'Dollar de Hong Kong',
    symbol: 'HK\$',
    isActive: true,
    isPopular: true,
    displayOrder: 9,
    createdAt: _now,
    updatedAt: _now,
  );

  static final Currency sgd = Currency(
    id: 10,
    code: 'SGD',
    name: 'Dollar de Singapour',
    symbol: 'S\$',
    isActive: true,
    isPopular: true,
    displayOrder: 10,
    createdAt: _now,
    updatedAt: _now,
  );

  // Devises africaines (actives)
  static final Currency zar = Currency(
    id: 11,
    code: 'ZAR',
    name: 'Rand sud-africain',
    symbol: 'R',
    isActive: true,
    isPopular: true,
    displayOrder: 11,
    createdAt: _now,
    updatedAt: _now,
  );

  static final Currency ngn = Currency(
    id: 12,
    code: 'NGN',
    name: 'Naira nigérian',
    symbol: '₦',
    isActive: true,
    isPopular: false,
    displayOrder: 12,
    createdAt: _now,
    updatedAt: _now,
  );

  static final Currency egp = Currency(
    id: 13,
    code: 'EGP',
    name: 'Livre égyptienne',
    symbol: '£',
    isActive: true,
    isPopular: false,
    displayOrder: 13,
    createdAt: _now,
    updatedAt: _now,
  );

  static final Currency mad = Currency(
    id: 14,
    code: 'MAD',
    name: 'Dirham marocain',
    symbol: 'د.م.',
    isActive: true,
    isPopular: false,
    displayOrder: 14,
    createdAt: _now,
    updatedAt: _now,
  );

  static final Currency xof = Currency(
    id: 15,
    code: 'XOF',
    name: 'Franc CFA (BCEAO)',
    symbol: 'CFA',
    isActive: true,
    isPopular: false,
    displayOrder: 15,
    createdAt: _now,
    updatedAt: _now,
  );

  static final Currency xaf = Currency(
    id: 16,
    code: 'XAF',
    name: 'Franc CFA (BEAC)',
    symbol: 'FCFA',
    isActive: true,
    isPopular: false,
    displayOrder: 16,
    createdAt: _now,
    updatedAt: _now,
  );

  static final Currency kes = Currency(
    id: 17,
    code: 'KES',
    name: 'Shilling kényan',
    symbol: 'KSh',
    isActive: true,
    isPopular: false,
    displayOrder: 17,
    createdAt: _now,
    updatedAt: _now,
  );

  static final Currency ghs = Currency(
    id: 18,
    code: 'GHS',
    name: 'Cedi ghanéen',
    symbol: 'GH₵',
    isActive: true,
    isPopular: false,
    displayOrder: 18,
    createdAt: _now,
    updatedAt: _now,
  );

  static final Currency etb = Currency(
    id: 19,
    code: 'ETB',
    name: 'Birr éthiopien',
    symbol: 'Br',
    isActive: true,
    isPopular: false,
    displayOrder: 19,
    createdAt: _now,
    updatedAt: _now,
  );

  static final Currency tnd = Currency(
    id: 20,
    code: 'TND',
    name: 'Dinar tunisien',
    symbol: 'د.ت',
    isActive: true,
    isPopular: false,
    displayOrder: 20,
    createdAt: _now,
    updatedAt: _now,
  );

  static final Currency dzd = Currency(
    id: 21,
    code: 'DZD',
    name: 'Dinar algérien',
    symbol: 'د.ج',
    isActive: true,
    isPopular: false,
    displayOrder: 21,
    createdAt: _now,
    updatedAt: _now,
  );

  static final Currency ugx = Currency(
    id: 22,
    code: 'UGX',
    name: 'Shilling ougandais',
    symbol: 'USh',
    isActive: true,
    isPopular: false,
    displayOrder: 22,
    createdAt: _now,
    updatedAt: _now,
  );

  static final Currency mur = Currency(
    id: 23,
    code: 'MUR',
    name: 'Roupie mauricienne',
    symbol: '₨',
    isActive: true,
    isPopular: false,
    displayOrder: 23,
    createdAt: _now,
    updatedAt: _now,
  );

  static final Currency bwp = Currency(
    id: 24,
    code: 'BWP',
    name: 'Pula botswanais',
    symbol: 'P',
    isActive: true,
    isPopular: false,
    displayOrder: 24,
    createdAt: _now,
    updatedAt: _now,
  );

  static final Currency nad = Currency(
    id: 25,
    code: 'NAD',
    name: 'Dollar namibien',
    symbol: 'N\$',
    isActive: true,
    isPopular: false,
    displayOrder: 25,
    createdAt: _now,
    updatedAt: _now,
  );

  // ✅ LISTE COMPLÈTE DES DEVISES PRÉDÉFINIES
  static final List<Currency> predefinedCurrencies = [
    cad, usd, eur, gbp, jpy, aud, chf, cny, hkd, sgd, // Populaires
    zar, ngn, egp, mad, xof, xaf, kes, ghs, etb, tnd, // Africaines
    dzd, ugx, mur, bwp, nad, // Autres africaines
  ];

  // ✅ MÉTHODES UTILITAIRES
  static Currency? findById(int id) {
    try {
      return predefinedCurrencies.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  static Currency? findByCode(String code) {
    try {
      return predefinedCurrencies.firstWhere(
        (c) => c.code.toUpperCase() == code.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  static List<Currency> getPopular() {
    return predefinedCurrencies.where((c) => c.isPopular).toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  static List<Currency> getAll() {
    return List.from(predefinedCurrencies)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  static List<Currency> getActive() {
    return predefinedCurrencies.where((c) => c.isActive).toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }
}
