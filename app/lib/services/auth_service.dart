// auth_service.dart - VERSION CORRIGÉE POUR success:false
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
    print('🔄 AuthService.login() - Début de la connexion pour: $email');

    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
        options: Options(validateStatus: (status) => status! < 500),
      );

      print('🔄 AuthService.login() - Response reçue: ${response.data}');
      print('🔄 AuthService.login() - Status Code: ${response.statusCode}');

      // CORRECTION PRINCIPALE: Vérifier d'abord le champ success
      if (response.data != null && response.data is Map) {
        final responseData = response.data as Map<String, dynamic>;

        // ⚠️ IMPORTANT: Si success est false, lancer immédiatement l'exception
        if (responseData['success'] == false) {
          final errorMessage =
              responseData['message'] ?? 'Identifiants invalides';
          print(
            '❌ AuthService.login() - success:false détecté, message: $errorMessage',
          );
          throw AuthenticationException(errorMessage);
        }

        // Si success est true et qu'on a les données
        if (responseData['success'] == true && responseData['data'] != null) {
          print('✅ AuthService.login() - success:true détecté');
          final userData = responseData['data'] as Map<String, dynamic>;

          final user = User(
            id: userData['id'],
            firstName: userData['first_name'],
            lastName: userData['last_name'],
            email: userData['email'],
            accessToken: responseData['access_token'],
            refreshToken: responseData['refresh_token'],
          );

          try {
            await _saveUserData(user, responseData['access_token']);
            print('✅ AuthService.login() - Données utilisateur sauvegardées');
          } catch (e) {
            print('⚠️ AuthService.login() - Erreur sauvegarde: $e');
          }

          return user;
        }
      }

      // Si on arrive ici, la réponse n'a pas le format attendu
      print('❌ AuthService.login() - Format de réponse inattendu');
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        throw AuthenticationException('Format de réponse inattendu du serveur');
      } else {
        final errorMessage = response.data?['message'] ?? 'Erreur de connexion';
        throw AuthenticationException(errorMessage);
      }
    } on DioException catch (e) {
      print('❌ AuthService.login() - DioException: ${e.type} - ${e.message}');
      print('❌ AuthService.login() - Response Data: ${e.response?.data}');

      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map) {
          // Vérifier si c'est une erreur d'API avec success: false
          if (errorData['success'] == false) {
            final message = errorData['message'] ?? 'Identifiants invalides';
            print(
              '❌ AuthService.login() - DioException avec success:false, message: $message',
            );
            throw AuthenticationException(message);
          }
          // Sinon utiliser le message générique
          final message = errorData['message'] ?? 'Erreur de serveur';
          throw AuthenticationException(message);
        } else {
          throw AuthenticationException('Erreur de serveur');
        }
      } else {
        throw AuthenticationException(_getDioErrorMessage(e));
      }
    } on AuthenticationException catch (e) {
      print('❌ AuthService.login() - AuthenticationException: ${e.message}');
      rethrow; // Relancer les exceptions d'authentification telles quelles
    } catch (e) {
      print('❌ AuthService.login() - Exception générale: $e');
      throw AuthenticationException('Erreur inattendue: ${e.toString()}');
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

      print('Register - Response: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map && responseData['success'] == true) {
          return; // Inscription réussie
        } else {
          final errorMessage =
              responseData['message'] ?? 'Erreur lors de l\'inscription';
          throw AuthenticationException(errorMessage);
        }
      } else {
        final errorMessage =
            response.data is Map
                ? response.data['message'] ?? 'Échec de l\'inscription'
                : 'Échec de l\'inscription';
        throw AuthenticationException(errorMessage);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['success'] == false) {
          throw AuthenticationException(
            errorData['message'] ?? 'Erreur lors de l\'inscription',
          );
        }
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
    try {
      final token = await getToken();
      if (token != null) {
        try {
          await _dio.post(
            '/auth/logout',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
        } catch (e) {
          print('Erreur lors de la déconnexion côté serveur: $e');
        }
      }

      await clearUserData();
      await _sharedPreferences.remove(_refreshTokenKey);
    } catch (e) {
      await clearUserData();
      await _sharedPreferences.remove(_refreshTokenKey);
      throw AuthenticationException('Erreur lors de la déconnexion');
    }
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
      final userJson = user.toJson();
      await prefs.setString(_userKey, json.encode(userJson));
      await prefs.setString(_tokenKey, token);
    } catch (e) {
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
        final userData = response.data['data'];
        final updatedUser = User(
          id: userData['id'],
          firstName: userData['first_name'],
          lastName: userData['last_name'],
          email: userData['email'],
          accessToken: token!,
          refreshToken: await getRefreshToken(),
        );

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
