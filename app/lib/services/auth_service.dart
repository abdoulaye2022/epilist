// auth_service.dart - VERSION CORRIGÉE POUR LA VERIFICATION EMAIL
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

  // CORRIGÉ: Méthode pour vérifier l'email - ne retourne pas d'utilisateur car pas de tokens
  Future<void> confirmEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/confirm-email',
        data: {'email': email, 'code': code},
        options: Options(validateStatus: (status) => status! < 500),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Succès - l'email est maintenant vérifié
        // Ne pas essayer de créer un utilisateur car pas de tokens dans la réponse
        return;
      } else {
        final errorMessage =
            response.data['message'] ?? 'Code de vérification invalide';
        throw AuthenticationException(errorMessage);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['success'] == false) {
          throw AuthenticationException(
            errorData['message'] ??
                'Erreur lors de la confirmation de l\'email',
          );
        }
        final message =
            errorData is Map
                ? errorData['message'] ??
                    'Erreur lors de la confirmation de l\'email'
                : 'Erreur de serveur';
        throw AuthenticationException(message);
      } else {
        throw AuthenticationException(_getDioErrorMessage(e));
      }
    } catch (e) {
      throw AuthenticationException(
        'Erreur inattendue lors de la confirmation de l\'email',
      );
    }
  }

  Future<void> resendVerificationCode(String email) async {
    try {
      final response = await _dio.post(
        '/auth/resend-confirm-email',
        data: {'email': email},
        options: Options(validateStatus: (status) => status! < 500),
      );

      if (response.data['success'] != true) {
        throw AuthenticationException(
          response.data['message'] ??
              'Échec de l\'envoi du code de vérification',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData['success'] == false) {
          throw AuthenticationException(
            errorData['message'] ?? 'Échec de l\'envoi du code de vérification',
          );
        }
        final message =
            errorData is Map
                ? errorData['message'] ??
                    'Échec de l\'envoi du code de vérification'
                : 'Erreur de serveur';
        throw AuthenticationException(message);
      } else {
        throw AuthenticationException(_getDioErrorMessage(e));
      }
    } catch (e) {
      throw AuthenticationException(
        'Erreur inattendue lors de l\'envoi du code de vérification',
      );
    }
  }

  Future<User> login(String email, String password) async {
    print('🔑 AuthService.login appelé pour: $email');

    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
        options: Options(validateStatus: (status) => status! < 500),
      );

      print('📥 Réponse reçue - Status: ${response.statusCode}');
      print('📄 Données de réponse: ${response.data}');

      if (response.data != null && response.data is Map) {
        final responseData = response.data as Map<String, dynamic>;

        // NOUVELLE GESTION: Vérifier d'abord si success = false
        if (responseData['success'] == false) {
          final errorCode = responseData['code'];
          final errorMessage = responseData['message'] ?? 'Erreur de connexion';

          print(
            '❌ Erreur API détectée - Code: $errorCode, Message: $errorMessage',
          );

          // Gestion spécifique du code EMAIL_NOT_VERIFIED
          if (errorCode == 'EMAIL_NOT_VERIFIED') {
            print('📧 Email non vérifié détecté');
            throw AuthenticationException(
              'Veuillez vérifier votre email avant de vous connecter',
            );
          }

          // Autres erreurs
          throw AuthenticationException(errorMessage);
        }

        // Si success = true, traitement normal
        if (responseData['success'] == true && responseData['data'] != null) {
          print('✅ Connexion réussie - Création de l\'utilisateur');

          final userData = responseData['data'] as Map<String, dynamic>;

          // Double vérification de l'email (au cas où)
          if (userData['email_verified'] != true) {
            print('⚠️ Email non vérifié selon les données utilisateur');
            throw AuthenticationException(
              'Veuillez vérifier votre email avant de vous connecter',
            );
          }

          final user = User(
            id: userData['id'],
            firstName: userData['first_name'],
            lastName: userData['last_name'],
            email: userData['email'],
            emailVerified: userData['email_verified'] ?? false,
            accessToken: responseData['access_token'],
            refreshToken: responseData['refresh_token'],
            emailVerifiedAt:
                userData['email_verified_at'] != null
                    ? DateTime.parse(userData['email_verified_at'])
                    : null,
            createdAt:
                userData['created_at'] != null
                    ? DateTime.parse(userData['created_at'])
                    : null,
            updatedAt:
                userData['updated_at'] != null
                    ? DateTime.parse(userData['updated_at'])
                    : null,
          );

          try {
            await _saveUserData(user, responseData['access_token']);
            print('💾 Données utilisateur sauvegardées');
          } catch (e) {
            print('⚠️ Erreur lors de la sauvegarde: $e');
          }

          return user;
        }
      }

      // Si on arrive ici, la réponse est inattendue
      print('❓ Format de réponse inattendu');
      throw AuthenticationException('Format de réponse inattendu du serveur');
    } on DioException catch (e) {
      print('🌐 DioException capturée: ${e.type}');
      print('📄 Response data: ${e.response?.data}');

      if (e.response != null) {
        final errorData = e.response?.data;
        if (errorData is Map) {
          // Gestion spécifique des codes d'erreur API
          if (errorData['success'] == false) {
            final errorCode = errorData['code'];
            final message = errorData['message'] ?? 'Erreur de connexion';

            print(
              '❌ Erreur API via DioException - Code: $errorCode, Message: $message',
            );

            if (errorCode == 'EMAIL_NOT_VERIFIED') {
              throw AuthenticationException(
                'Veuillez vérifier votre email avant de vous connecter',
              );
            }

            throw AuthenticationException(message);
          }

          final message = errorData['message'] ?? 'Erreur de serveur';
          throw AuthenticationException(message);
        } else {
          throw AuthenticationException('Erreur de serveur');
        }
      } else {
        throw AuthenticationException(_getDioErrorMessage(e));
      }
    } on AuthenticationException catch (e) {
      print('🔄 AuthenticationException relancée: ${e.message}');
      rethrow;
    } catch (e) {
      print('💥 Erreur inattendue: $e');
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
        } catch (e) {}
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
          emailVerified: userData['email_verified'],
          accessToken: token!,
          refreshToken: await getRefreshToken(),
          emailVerifiedAt:
              userData['email_verified_at'] != null
                  ? DateTime.parse(userData['email_verified_at'])
                  : null,
          createdAt:
              userData['created_at'] != null
                  ? DateTime.parse(userData['created_at'])
                  : null,
          updatedAt:
              userData['updated_at'] != null
                  ? DateTime.parse(userData['updated_at'])
                  : null,
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

  Future<void> requestPasswordChangeCode(String email) async {
    try {
      final response = await _dio.post(
        '/auth/request-password-change',
        data: {'email': email},
        options: Options(validateStatus: (status) => status! < 500),
      );

      if (response.data['success'] != true) {
        throw AuthenticationException(
          response.data['message'] ?? 'Failed to send password change code',
        );
      }
    } on DioException catch (e) {
      throw AuthenticationException(
        e.response?.data['message'] ?? 'Failed to send password change code',
      );
    } catch (e) {
      throw AuthenticationException('Failed to send password change code');
    }
  }

  Future<void> verifyPasswordChangeCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/verify-password-change-code',
        data: {'email': email, 'code': code, 'new_password': newPassword},
        options: Options(validateStatus: (status) => status! < 500),
      );

      if (response.data['success'] != true) {
        throw AuthenticationException(
          response.data['message'] ?? 'Failed to change password',
        );
      }
    } on DioException catch (e) {
      throw AuthenticationException(
        e.response?.data['message'] ?? 'Failed to change password',
      );
    } catch (e) {
      throw AuthenticationException('Failed to change password');
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
