// models/user.dart - VERSION AVEC DEVISES D'AFFICHAGE SEULEMENT
import 'dart:convert';
import 'package:epilist/models/currency.dart';

class User {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final bool emailVerified;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? emailVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Currency? currency;
  final bool isActive;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.emailVerified,
    this.accessToken,
    this.refreshToken,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.currency,
    this.isActive = true,
  });

  bool get isEmailVerified => emailVerified && emailVerifiedAt != null;

  // Getter pour compatibilité avec le système de partage
  String get name => fullName;

  // ✅ DEVISE D'AFFICHAGE - Pas de conversion, juste l'affichage
  Currency get displayCurrency => currency ?? Currency.cad;

  // ✅ FORMATAGE SANS CONVERSION - Le montant reste identique
  String formatAmount(double amount, {bool showCode = false}) {
    return displayCurrency.formatAmount(amount, showCode: showCode);
  }

  // Parser le champ booléen avec gestion robuste
  static bool _parseBooleanField(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lowercaseValue = value.toLowerCase();
      return lowercaseValue == 'true' || lowercaseValue == '1';
    }
    if (value is double) return value == 1.0;
    return false;
  }

  // Factory pour la réponse de login
  factory User.fromLoginResponse(Map<String, dynamic> response) {
    try {
      // ✅ STRUCTURE ATTENDUE:
      // {
      //   'access_token': '...',
      //   'refresh_token': '...',
      //   'data': { ... }
      // }

      final data = response['data'] as Map<String, dynamic>? ?? {};
      final accessToken = response['access_token'] as String?;
      final refreshToken = response['refresh_token'] as String?;

      print('=== User.fromLoginResponse DEBUG ===');
      print('Data reçue: $data');
      print('Access token présent: ${accessToken != null}');
      print('Refresh token présent: ${refreshToken != null}');

      // ✅ PARSING SÉCURISÉ DES BOOLÉENS
      final emailVerified = _parseBooleanField(data['email_verified']);
      final isActive = _parseBooleanField(data['is_active']);

      print('Email vérifié: $emailVerified');
      print('Utilisateur actif: $isActive');

      // ✅ PARSING SÉCURISÉ DE LA DEVISE
      Currency? parsedCurrency;
      try {
        if (data['currency'] != null) {
          print('Données de devise trouvées: ${data['currency']}');
          parsedCurrency = Currency.fromJson(
            data['currency'] as Map<String, dynamic>,
          );
          print(
            'Devise parsée avec succès: ${parsedCurrency.code} (${parsedCurrency.symbol})',
          );
        } else {
          print('Aucune devise dans les données utilisateur');
        }
      } catch (e) {
        print('❌ Erreur lors du parsing de la devise: $e');
        print('Données de devise brutes: ${data['currency']}');
        parsedCurrency = null;
      }

      final user = User(
        id: data['id'] as int? ?? 0,
        firstName: data['first_name'] as String? ?? '',
        lastName: data['last_name'] as String? ?? '',
        email: data['email'] as String? ?? '',
        emailVerified: emailVerified,
        accessToken: accessToken,
        refreshToken: refreshToken,
        emailVerifiedAt:
            data['email_verified_at'] != null
                ? DateTime.tryParse(data['email_verified_at'].toString())
                : null,
        currency: parsedCurrency, // ✅ DEVISE PARSÉE
        isActive: isActive,
        createdAt:
            data['created_at'] != null
                ? DateTime.tryParse(data['created_at'].toString())
                : null,
        updatedAt:
            data['updated_at'] != null
                ? DateTime.tryParse(data['updated_at'].toString())
                : null,
      );

      print('Utilisateur créé avec succès:');
      print('- Nom: ${user.fullName}');
      print('- Email: ${user.email}');
      print('- Devise: ${user.currency?.code ?? 'null'}');
      print('================================');

      return user;
    } catch (e, stackTrace) {
      print('❌ ERREUR CRITIQUE dans User.fromLoginResponse: $e');
      print('Stack trace: $stackTrace');
      print('Response complète: $response');

      // ✅ FALLBACK: Créer un utilisateur minimal en cas d'erreur
      return User(
        id: 0,
        firstName: 'Erreur',
        lastName: 'Parsing',
        email: response['data']?['email'] ?? 'unknown@email.com',
        emailVerified: false,
        accessToken: response['access_token'] as String?,
        refreshToken: response['refresh_token'] as String?,
        currency: Currency.cad, // Devise par défaut en cas d'erreur
        isActive: true,
      );
    }
  }

  // Factory pour getCurrentUser et autres endpoints
  factory User.fromMap(Map<String, dynamic> map) {
    final data = map['data'] ?? map;

    String firstName = data['first_name'] as String? ?? '';
    String lastName = data['last_name'] as String? ?? '';

    // Si l'API renvoie un champ 'name' au lieu de first_name/last_name
    if (firstName.isEmpty && lastName.isEmpty && data['name'] != null) {
      final fullName = data['name'] as String;
      final nameParts = fullName.trim().split(' ');
      if (nameParts.isNotEmpty) {
        firstName = nameParts.first;
        if (nameParts.length > 1) {
          lastName = nameParts.sublist(1).join(' ');
        }
      }
    }

    final emailVerified = _parseBooleanField(data['email_verified']);
    final isActive = _parseBooleanField(data['is_active']);

    Currency? parsedCurrency;
    try {
      if (data['currency'] != null) {
        parsedCurrency = Currency.fromJson(data['currency']);
      }
    } catch (e) {
      parsedCurrency = null;
    }

    return User(
      id: data['id'] as int? ?? 0,
      firstName: firstName,
      lastName: lastName,
      email: data['email'] as String? ?? '',
      emailVerified: emailVerified,
      accessToken: map['access_token'] as String?,
      refreshToken: map['refresh_token'] as String?,
      emailVerifiedAt:
          data['email_verified_at'] != null
              ? DateTime.tryParse(data['email_verified_at'].toString())
              : null,
      currency: parsedCurrency,
      isActive: isActive,
      createdAt:
          data['created_at'] != null
              ? DateTime.tryParse(data['created_at'].toString())
              : null,
      updatedAt:
          data['updated_at'] != null
              ? DateTime.tryParse(data['updated_at'].toString())
              : null,
    );
  }

  // Factory spécifiquement pour l'API de partage
  factory User.fromSharedApiMap(Map<String, dynamic> map) {
    final fullName = map['name'] as String? ?? '';
    final nameParts = fullName.trim().split(' ');

    String firstName = '';
    String lastName = '';

    if (nameParts.isNotEmpty) {
      firstName = nameParts.first;
      if (nameParts.length > 1) {
        lastName = nameParts.sublist(1).join(' ');
      }
    }

    Currency? parsedCurrency;
    try {
      if (map['currency'] != null) {
        parsedCurrency = Currency.fromJson(map['currency']);
      }
    } catch (e) {
      parsedCurrency = null;
    }

    return User(
      id: map['id'] as int? ?? 0,
      firstName: firstName,
      lastName: lastName,
      email: map['email'] as String? ?? '',
      emailVerified: false,
      currency: parsedCurrency,
      isActive: true,
    );
  }

  // Alias pour compatibilité
  factory User.fromJson(Map<String, dynamic> json) => User.fromMap(json);

  // Désérialisation depuis une chaîne JSON
  factory User.fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> data = json.decode(jsonString);
      return User.fromMap(data);
    } catch (e) {
      throw FormatException('Failed to parse user JSON: $e');
    }
  }

  // Sérialisation pour le cache local (inclut les tokens)
  Map<String, dynamic> toCacheMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'email_verified': emailVerified,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'currency': currency?.toJson(),
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Sérialisation standard (sans tokens)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'email_verified': emailVerified,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'currency': currency?.toJson(),
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Sérialisation avec le champ 'name' pour compatibilité API
  Map<String, dynamic> toJson() {
    final map = toMap();
    map['name'] = fullName;
    return map;
  }

  // Sérialisation en chaîne JSON
  String toJsonString() => json.encode(toCacheMap());

  // Getters utilitaires
  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    }
    if (firstName.isNotEmpty) return firstName[0].toUpperCase();
    if (lastName.isNotEmpty) return lastName[0].toUpperCase();
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }

  bool get hasValidTokens =>
      accessToken != null &&
      accessToken!.isNotEmpty &&
      refreshToken != null &&
      refreshToken!.isNotEmpty;

  // ✅ GETTERS POUR LA DEVISE D'AFFICHAGE (PAS DE CONVERSION)
  bool get hasCurrency => currency != null;
  String get currencyCode => currency?.code ?? 'CAD';
  String get currencySymbol => currency?.symbol ?? '\$';
  String get currencyDisplayName =>
      currency?.displayName ?? 'Dollar Canadien (CAD)';

  // ✅ SUPPRIMÉ: Toutes les méthodes de conversion
  // Plus besoin de convertFromCAD, convertToCAD, exchangeRateToCAD, etc.

  // Vérifier si l'utilisateur utilise une devise spécifique
  bool usesCurrency(String currencyCode) {
    return this.currencyCode.toUpperCase() == currencyCode.toUpperCase();
  }

  bool get usesCAD => usesCurrency('CAD');
  bool get usesUSD => usesCurrency('USD');
  bool get usesEUR => usesCurrency('EUR');

  // Copie avec modifications
  User copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    bool? emailVerified,
    String? accessToken,
    String? refreshToken,
    DateTime? emailVerifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Currency? currency,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
    );
  }

  // Copie avec nouvelle devise d'affichage
  User withDisplayCurrency(Currency newCurrency) {
    return copyWith(currency: newCurrency);
  }

  // Copie sans devise (retour au CAD par défaut)
  User withoutCurrency() {
    return copyWith(currency: null);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ email.hashCode;

  @override
  String toString() {
    return 'User(id: $id, name: $fullName, email: $email, verified: $emailVerified, currency: ${currency?.code ?? 'CAD'})';
  }
}

// Extension pour les informations de devise d'affichage
extension UserCurrencyDisplay on User {
  /// Formater un montant dans la devise d'affichage de l'utilisateur (SANS CONVERSION)
  String formatAmountAdvanced(
    double amount, {
    bool showCode = false,
    bool showSymbol = true,
    int decimals = 2,
  }) {
    final curr = displayCurrency;
    final formatted = amount.toStringAsFixed(decimals);

    String result = '';

    if (showSymbol) {
      result += curr.symbol;
    }

    result += formatted;

    if (showCode) {
      result += ' ${curr.code}';
    }

    return result;
  }

  /// Vérifier si la devise d'affichage est populaire
  bool get usesPopularCurrency {
    return currency?.isPopular ??
        true; // CAD est considéré populaire par défaut
  }

  /// Obtenir des informations de devise d'affichage formatées pour l'UI
  Map<String, String> get currencyDisplayInfo {
    final curr = displayCurrency;
    return {
      'code': curr.code,
      'name': curr.name,
      'symbol': curr.symbol,
      'displayName': curr.displayName,
      'isPopular': curr.isPopular.toString(),
      'type':
          'display_only', // ✅ NOUVEAU: Indiquer que c'est pour l'affichage seulement
    };
  }
}
