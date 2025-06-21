import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:epilist/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final Dio _dio;
  final SharedPreferences _sharedPreferences;

  static const String _userKey = 'current_user';
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  AuthService({required Dio dio, required SharedPreferences sharedPreferences})
    : _dio = dio,
      _sharedPreferences = sharedPreferences;

  Future<User> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
        options: Options(validateStatus: (status) => status! < 500),
      );

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        if (response.data['data'] != null) {
          final userData = response.data['data'] as Map<String, dynamic>;

          final user = User(
            id: userData['id'],
            firstName: userData['first_name'],
            lastName: userData['last_name'],
            email: userData['email'],
            accessToken: response.data['access_token'],
            refreshToken: response.data['refresh_token'],
          );

          try {
            await _saveUserData(user, response.data['access_token']);
          } catch (e) {
            // On continue quand même car l'authentification a réussi
            // mais il faut notifier qu'il y a eu un problème de persistance
          }

          return user;
        } else {
          throw FormatException('User data missing in response');
        }
      } else {
        final errorMessage = response.data['message'] ?? 'Login failed';
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
        '/auth/register',
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
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey) != null;
  }

  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString(_userKey);
      if (userString != null) {
        return User.fromJson(json.decode(userString));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveUserData(User user, String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convertir l'utilisateur en JSON
      final userJson = user.toJson();

      // Sauvegarder les données
      await prefs.setString(_userKey, json.encode(userJson));
      await prefs.setString(_tokenKey, token);

      // debugPrint('User data saved: ${user.toJson()}');
    } catch (e) {
      // debugPrint('Failed to save user data: $e');
      throw Exception('Failed to persist user data');
    }
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Map<String, String>> refreshToken(String refreshToken) async {
    final response = await _dio.post(
      '/auth/refresh-token',
      data: {'refresh_token': refreshToken},
    );

    await _sharedPreferences.setString(
      _tokenKey,
      response.data['access_token'],
    );
    await _sharedPreferences.setString(
      _refreshTokenKey,
      response.data['refresh_token'],
    );

    return {
      'access_token': response.data['access_token'],
      'refresh_token': response.data['refresh_token'],
    };
  }

  Future<User> updateProfile({
    required String firstName,
    required String lastName,
    String? phone,
    String? avatar,
  }) async {
    try {
      final token = await getToken();
      final response = await _dio.put(
        '/auth/me',
        data: {'first_name': firstName, 'last_name': lastName},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Créer un objet User depuis la réponse API
        final userData = response.data['data'];
        final updatedUser = User(
          id: userData['id'],
          firstName: userData['first_name'],
          lastName: userData['last_name'],
          email: userData['email'],
          accessToken: token!, // Garder le token actuel
          refreshToken:
              await getRefreshToken(), // Garder le refresh token actuel
        );

        // Sauvegarder les nouvelles données utilisateur
        await _sharedPreferences.setString(
          _userKey,
          json.encode(updatedUser.toJson()),
        );

        return updatedUser;
      } else {
        throw AuthenticationException(
          response.data['message'] ?? 'Erreur lors de la mise à jour du profil',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response?.data;
        final message =
            errorData is Map
                ? errorData['message'] ??
                    'Erreur lors de la mise à jour du profil'
                : 'Erreur de serveur';
        throw AuthenticationException(message);
      } else {
        throw AuthenticationException(_getDioErrorMessage(e));
      }
    } catch (e) {
      throw AuthenticationException(
        'Erreur inattendue lors de la mise à jour du profil',
      );
    }
  }

  Future<String?> getRefreshToken() async =>
      _sharedPreferences.getString(_refreshTokenKey);
}

class AuthenticationException implements Exception {
  final String message;
  AuthenticationException(this.message);

  @override
  String toString() => message;
}
