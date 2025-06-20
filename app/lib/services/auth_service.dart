import 'package:dio/dio.dart';
import 'package:epilist/models/user.dart';

class AuthService {
  final Dio _dio = Dio();

  Future<User> login(String email, String password) async {
    try {
      final response = await _dio.post(
        'http://10.0.2.2:8000/auth/login',
        data: {'email': email, 'password': password},
        options: Options(validateStatus: (status) => status! < 500),
      );

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        if (response.data['data'] != null) {
          return User.fromJson(response.data['data']);
        } else {
          throw FormatException(
            'Données utilisateur manquantes dans la réponse',
          );
        }
      } else {
        final errorMessage =
            response.data['message'] ?? 'Échec de la connexion';
        throw AuthenticationException(errorMessage);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response?.data;
        final message =
            errorData is Map
                ? errorData['message'] ?? 'Erreur inconnue'
                : 'Erreur de serveur';
        throw AuthenticationException(message);
      } else {
        throw AuthenticationException(_getDioErrorMessage(e));
      }
    } on FormatException catch (e) {
      throw AuthenticationException(
        'Erreur de format des données: ${e.message}',
      );
    } catch (e) {
      throw AuthenticationException(
        'Identifiants incorrects. Veuillez réessayer.',
      );
    }
  }

  String _getDioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Timeout de connexion';
      case DioExceptionType.sendTimeout:
        return 'Timeout d\'envoi';
      case DioExceptionType.receiveTimeout:
        return 'Timeout de réception';
      case DioExceptionType.badCertificate:
        return 'Certificat invalide';
      case DioExceptionType.badResponse:
        return 'Réponse invalide du serveur';
      case DioExceptionType.cancel:
        return 'Requête annulée';
      case DioExceptionType.connectionError:
        return 'Erreur de connexion';
      case DioExceptionType.unknown:
        return 'Erreur réseau inconnue';
    }
  }

  Future<void> register(
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        'http://10.0.2.2:8000/auth/register',
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
        },
        options: Options(validateStatus: (status) => status! < 500),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Vérifier que la réponse indique un succès
        final responseData = response.data;
        if (responseData is Map && responseData['success'] == true) {
          // Inscription réussie
          return;
        } else {
          // Réponse inattendue
          throw AuthenticationException(
            responseData['message'] ?? 'Erreur lors de l\'inscription',
          );
        }
      } else {
        // Erreur HTTP
        final errorMessage =
            response.data is Map
                ? response.data['message'] ?? 'Échec de l\'inscription'
                : 'Échec de l\'inscription';
        throw AuthenticationException(errorMessage);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response?.data;
        final message =
            errorData is Map
                ? errorData['message'] ?? 'Erreur lors de l\'inscription'
                : 'Erreur de serveur';
        throw AuthenticationException(message);
      } else {
        throw AuthenticationException(_getDioErrorMessage(e));
      }
    } catch (e) {
      if (e is AuthenticationException) {
        rethrow;
      }
      throw AuthenticationException('Erreur inattendue lors de l\'inscription');
    }
  }

  Future<void> logout() async {
    // Implémentez votre logique de déconnexion ici
    // Par exemple, supprimer le token, effacer le cache, etc.
  }

  Future<bool> isAuthenticated() async {
    // Implémentez la logique pour vérifier si l'utilisateur est authentifié
    return false; // Temporaire
  }

  Future<User> getCurrentUser() async {
    // Implémentez la récupération des informations de l'utilisateur
    throw UnimplementedError();
  }
}

class AuthenticationException implements Exception {
  final String message;
  AuthenticationException(this.message);

  @override
  String toString() => message;
}
