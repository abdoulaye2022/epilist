class User {
  final String firstName;
  final String lastName;
  final String email;
  final String? token; // Optionnel pour la réponse

  User({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      token: json['token'], // Si votre API retourne un token
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'token': token, // À utiliser uniquement pour l'envoi
    };
  }
}
