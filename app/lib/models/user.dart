import 'dart:convert';

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
  });

  bool get isEmailVerified => emailVerified && emailVerifiedAt != null;

  // NOUVEAU: Getter pour compatibilité avec le système de partage
  String get name => fullName;

  // Factory pour la réponse de login
  factory User.fromLoginResponse(Map<String, dynamic> response) {
    final data = response['data'] ?? {};
    return User(
      id: data['id'] as int? ?? 0,
      firstName: data['first_name'] as String? ?? '',
      lastName: data['last_name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      emailVerified: (data['email_verified'] == 1),
      accessToken: response['access_token'] as String?,
      refreshToken: response['refresh_token'] as String?,
      emailVerifiedAt:
          data['email_verified_at'] != null
              ? DateTime.tryParse(data['email_verified_at'].toString())
              : null,
      createdAt: null, // Pas dans la réponse de login
      updatedAt: null, // Pas dans la réponse de login
    );
  }

  // Factory pour getCurrentUser et autres endpoints
  factory User.fromMap(Map<String, dynamic> map) {
    // Gestion de la structure imbriquée
    final data = map['data'] ?? map;

    return User(
      id: data['id'] as int? ?? 0,
      firstName: data['first_name'] as String? ?? '',
      lastName: data['last_name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      emailVerified: (data['email_verified'] == 1),
      accessToken: map['access_token'] as String?, // Au niveau racine
      refreshToken: map['refresh_token'] as String?, // Au niveau racine
      emailVerifiedAt:
          data['email_verified_at'] != null
              ? DateTime.tryParse(data['email_verified_at'].toString())
              : null,
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
      'email_verified': emailVerified ? 1 : 0,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
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
      'email_verified': emailVerified ? 1 : 0,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Alias pour compatibilité
  Map<String, dynamic> toJson() => toMap();

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
    );
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
    return 'User(id: $id, name: $fullName, email: $email, verified: $emailVerified)';
  }
}
