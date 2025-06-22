class User {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final bool emailVerified; // Champ pour la vérification d'email
  final String? accessToken;
  final String? refreshToken;
  final DateTime? emailVerifiedAt; // Date de vérification de l'email
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

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      emailVerified: json['email_verified'] ?? false,
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      emailVerifiedAt:
          json['email_verified_at'] != null
              ? DateTime.parse(json['email_verified_at'])
              : null,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'email_verified': emailVerified,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      // On exclut les tokens pour la sérialisation
    };
  }

  // Méthode pour créer une copie avec des valeurs mises à jour
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

  // Méthode utilitaire pour vérifier si l'email est confirmé
  bool get isEmailVerified => emailVerifiedAt != null;
}
