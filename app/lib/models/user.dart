class User {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? accessToken; // Ajout du token d'accès
  final String? refreshToken; // Ajout du token de rafraîchissement

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.accessToken,
    this.refreshToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      // Les tokens sont généralement dans l'objet racine, pas dans 'data'
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      // On n'inclut généralement pas les tokens dans le toJson()
    };
  }
}
