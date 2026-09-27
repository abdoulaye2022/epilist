import 'package:flutter/foundation.dart';
// models/user_currency.dart - VERSION CORRIGÉE POUR L'API
import 'package:epilist/models/currency.dart';

/// Modèle représentant la devise d'affichage de l'utilisateur
class UserCurrency {
  final int userId;
  final Currency currency;
  final DateTime setAt;

  const UserCurrency({
    required this.userId,
    required this.currency,
    required this.setAt,
  });

  factory UserCurrency.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('=== UserCurrency.fromJson DEBUG ===');
      debugPrint('JSON reçu: $json');

      // ✅ PROTECTION: Vérifier que 'data' existe et est un Map
      final data = json['data'];
      if (data == null || data is! Map<String, dynamic>) {
        throw Exception(
          'Invalid JSON structure: missing or invalid "data" field',
        );
      }

      debugPrint('Data extraite: $data');

      // ✅ PROTECTION: Vérifier que 'currency' existe et est un Map
      final currencyData = data['currency'];
      if (currencyData == null || currencyData is! Map<String, dynamic>) {
        throw Exception(
          'Invalid JSON structure: missing or invalid "currency" field',
        );
      }

      debugPrint('Currency data: $currencyData');

      // ✅ NOUVEAU: Essayer de récupérer la devise prédéfinie par ID d'abord
      Currency? currency;
      final currencyId = currencyData['id'] as int?;

      if (currencyId != null) {
        currency = Currency.findById(currencyId);
        debugPrint('Devise trouvée par ID $currencyId: ${currency?.code}');
      }

      // Si pas trouvée par ID, essayer par code
      if (currency == null) {
        final currencyCode = currencyData['code'] as String?;
        if (currencyCode != null) {
          currency = Currency.findByCode(currencyCode);
          debugPrint('Devise trouvée par code $currencyCode: ${currency?.code}');
        }
      }

      // Si toujours pas trouvée, parser depuis le JSON (avec fallback)
      if (currency == null) {
        debugPrint('Parsing devise depuis JSON...');
        try {
          currency = Currency.fromJson(currencyData);
        } catch (e) {
          debugPrint('Erreur parsing JSON, utilisation de la devise par défaut: $e');
          currency = Currency.cad;
        }
      }

      // ✅ PROTECTION: Parsing sécurisé avec validation
      final userCurrency = UserCurrency(
        userId: data['user_id'] as int,
        currency: currency,
        setAt: DateTime.parse(data['set_at'] as String),
      );

      debugPrint('UserCurrency créé avec succès:');
      debugPrint('- User ID: ${userCurrency.userId}');
      debugPrint(
        '- Currency: ${userCurrency.currency.code} (${userCurrency.currency.symbol})',
      );
      debugPrint('- Set at: ${userCurrency.setAt}');
      debugPrint('================================');

      return userCurrency;
    } catch (e, stackTrace) {
      // ✅ DEBUG: Afficher les détails de l'erreur
      debugPrint('❌ UserCurrency.fromJson error: $e');
      debugPrint('📄 Raw JSON: $json');
      debugPrint('Stack trace: $stackTrace');

      // ✅ FALLBACK: Créer un UserCurrency minimal en cas d'erreur
      final fallbackUserId = json['data']?['user_id'] as int? ?? 0;
      final fallbackCurrency = Currency.cad; // Devise par défaut

      debugPrint('🔄 Création d\'un UserCurrency de fallback');
      return UserCurrency(
        userId: fallbackUserId,
        currency: fallbackCurrency,
        setAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'currency': currency.toJson(),
      'set_at': setAt.toIso8601String(),
    };
  }

  /// Formater un montant avec la devise d'affichage (SANS CONVERSION)
  String formatAmount(double amount, {bool showCode = false}) {
    return currency.formatAmount(amount, showCode: showCode);
  }

  /// Obtenir le symbole de la devise
  String get symbol => currency.symbol;

  /// Obtenir le code de la devise
  String get code => currency.code;

  /// Obtenir le nom de la devise
  String get name => currency.name;

  /// Obtenir le nom d'affichage complet
  String get displayName => currency.displayName;

  /// Vérifier si c'est une devise populaire
  bool get isPopular => currency.isPopular;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserCurrency &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          currency == other.currency;

  @override
  int get hashCode => userId.hashCode ^ currency.hashCode;

  @override
  String toString() =>
      'UserCurrency(userId: $userId, currency: ${currency.code})';

  UserCurrency copyWith({int? userId, Currency? currency, DateTime? setAt}) {
    return UserCurrency(
      userId: userId ?? this.userId,
      currency: currency ?? this.currency,
      setAt: setAt ?? this.setAt,
    );
  }
}
