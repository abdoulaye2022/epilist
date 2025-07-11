// auth_service.dart - VERSION CORRIGÉE POUR JWT 1 AN
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:epilist/models/user.dart';
import 'dart:convert';

class AuthenticationException implements Exception {
  final String message;
  final String code;
  final String? email;

  AuthenticationException(this.message, this.code, {this.email});

  @override
  String toString() => message;
}

class AuthService {
  final Dio dio;
  final SharedPreferences sharedPreferences;

  // Clés pour le stockage
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  static const String _tokenExpiryKey = 'token_expiry';

  AuthService({required this.dio, required this.sharedPreferences});

  // === GESTION DES TOKENS CORRIGÉE ===

  /// Décoder le JWT pour extraire la vraie date d'expiration
  DateTime? _getTokenExpiration(String token) {
    try {
      // Séparer le token JWT en parties
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Décoder le payload (partie 2)
      String payload = parts[1];

      // Ajouter le padding nécessaire pour base64
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }

      // Décoder le JSON
      final decoded = utf8.decode(base64Url.decode(payload));
      final Map<String, dynamic> payloadMap = json.decode(decoded);

      // Récupérer 'exp' (expiration timestamp)
      final exp = payloadMap['exp'];
      if (exp != null) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }
    } catch (e) {
      print('Erreur lors du décodage du token: $e');
    }
    return null;
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    try {
      // Extraire la vraie date d'expiration du JWT
      final tokenExpiry = _getTokenExpiration(accessToken);

      await Future.wait([
        sharedPreferences.setString(_accessTokenKey, accessToken),
        sharedPreferences.setString(_refreshTokenKey, refreshToken),
        // Sauvegarder la vraie date d'expiration du JWT ou par défaut 1 an
        sharedPreferences.setInt(
          _tokenExpiryKey,
          (tokenExpiry ?? DateTime.now().add(const Duration(days: 365)))
              .millisecondsSinceEpoch,
        ),
      ]);

      print(
        'Token sauvegardé avec expiration: ${tokenExpiry ?? "1 an par défaut"}',
      );
    } catch (e) {
      throw Exception('Impossible de sauvegarder les tokens: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      final token = sharedPreferences.getString(_accessTokenKey);
      if (token != null && token.isNotEmpty) {
        // Vérifier si le token n'est pas expiré
        if (await isTokenExpired()) {
          print('Token expiré, tentative de refresh automatique');

          // Essayer de rafraîchir automatiquement
          final refreshToken = await getRefreshToken();
          if (refreshToken != null && refreshToken.isNotEmpty) {
            try {
              final newTokens = await this.refreshToken(refreshToken);
              await saveTokens(
                newTokens['access_token']!,
                newTokens['refresh_token']!,
              );
              return newTokens['access_token'];
            } catch (e) {
              print('Échec du refresh automatique: $e');
              await clearUserData();
              return null;
            }
          }
          return null;
        }
        return token;
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération du token: $e');
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return sharedPreferences.getString(_refreshTokenKey);
    } catch (e) {
      return null;
    }
  }

  Future<bool> isTokenExpired() async {
    try {
      final expiry = sharedPreferences.getInt(_tokenExpiryKey);
      if (expiry == null) return true;

      final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiry);
      final isExpired = DateTime.now().isAfter(expiryDate);

      if (isExpired) {
        print('Token expiré: $expiryDate');
      } else {
        final timeLeft = expiryDate.difference(DateTime.now());
        print(
          'Token valide, expire dans: ${timeLeft.inDays} jours, ${timeLeft.inHours % 24} heures',
        );
      }

      return isExpired;
    } catch (e) {
      print('Erreur lors de la vérification d\'expiration: $e');
      return true;
    }
  }

  /// Vérifier si le token expire bientôt (dans les 7 jours)
  Future<bool> shouldRefreshSoon() async {
    try {
      final expiry = sharedPreferences.getInt(_tokenExpiryKey);
      if (expiry == null) return true;

      final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiry);
      final daysLeft = expiryDate.difference(DateTime.now()).inDays;

      return daysLeft <= 7; // Refresh si moins de 7 jours
    } catch (e) {
      return true;
    }
  }

  // === AUTHENTIFICATION ===

  Future<Map<String, String>> login(String email, String password) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final user = User.fromLoginResponse(response.data);

        final accessToken = data['access_token'] as String?;
        final refreshToken = data['refresh_token'] as String?;

        if (accessToken == null || refreshToken == null) {
          throw AuthenticationException(
            'Tokens manquants dans la réponse',
            'MISSING_TOKENS',
          );
        }

        // Afficher l'expiration du token reçu
        final expiry = _getTokenExpiration(accessToken);
        print('Nouveau token reçu, expire le: $expiry');

        return {'access_token': accessToken, 'refresh_token': refreshToken};
      } else {
        throw AuthenticationException('Erreur de connexion', 'LOGIN_FAILED');
      }
    } on DioException catch (e) {
      // [Votre gestion d'erreur existante reste la même]
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        final errorData = e.response?.data;
        if (errorData != null && errorData['code'] == 'EMAIL_NOT_VERIFIED') {
          String emailFromResponse = email;

          if (errorData['data'] != null && errorData['data']['email'] != null) {
            emailFromResponse = errorData['data']['email'];
          }

          throw AuthenticationException(
            'Email non vérifié',
            'EMAIL_NOT_VERIFIED',
            email: emailFromResponse,
          );
        }

        throw AuthenticationException(
          'Email ou mot de passe incorrect',
          'INVALID_CREDENTIALS',
        );
      } else if (e.response?.statusCode == 404) {
        throw AuthenticationException(
          'Aucun compte trouvé avec cet email',
          'USER_NOT_FOUND',
        );
      } else {
        throw AuthenticationException(
          'Erreur de connexion: ${e.message}',
          'NETWORK_ERROR',
        );
      }
    } catch (e) {
      throw AuthenticationException(
        'Une erreur inattendue est survenue',
        'UNKNOWN_ERROR',
      );
    }
  }

  Future<Map<String, String>> refreshToken(String refreshToken) async {
    try {
      print('Tentative de refresh du token...');

      final response = await dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        final newAccessToken = data['access_token'] as String?;
        final newRefreshToken = data['refresh_token'] as String?;

        if (newAccessToken == null || newRefreshToken == null) {
          throw Exception('Nouveaux tokens manquants dans la réponse');
        }

        // Afficher l'expiration du nouveau token
        final expiry = _getTokenExpiration(newAccessToken);
        print('Token refreshé avec succès, expire le: $expiry');

        return {
          'access_token': newAccessToken,
          'refresh_token': newRefreshToken,
        };
      } else {
        throw Exception('Échec du rafraîchissement du token');
      }
    } on DioException catch (e) {
      print('Erreur lors du refresh: ${e.response?.statusCode} - ${e.message}');
      if (e.response?.statusCode == 401) {
        throw Exception('Refresh token invalide ou expiré');
      }
      throw Exception('Erreur réseau lors du refresh: ${e.message}');
    } catch (e) {
      print('Erreur inattendue lors du refresh: $e');
      rethrow;
    }
  }

  Future<bool> isAuthenticated() async {
    try {
      final accessToken =
          await getToken(); // getToken() gère déjà le refresh automatique
      return accessToken != null && accessToken.isNotEmpty;
    } catch (e) {
      print('Erreur lors de la vérification d\'authentification: $e');
      return false;
    }
  }

  // [Le reste de votre code reste identique]
  Future<void> saveUserToCache(User user) async {
    try {
      await sharedPreferences.setString(_userKey, user.toJsonString());
    } catch (e) {
      print('Erreur lors de la sauvegarde utilisateur: $e');
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      // D'abord vérifier si on a l'utilisateur en cache
      final cachedUserData = sharedPreferences.getString(_userKey);
      if (cachedUserData != null) {
        final userData = User.fromJsonString(cachedUserData);
        return userData;
      }

      // Sinon, récupérer depuis l'API
      final token = await getToken(); // getToken() gère le refresh automatique
      if (token == null) {
        return null;
      }

      final response = await dio.get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final user = User.fromMap(response.data);
        await sharedPreferences.setString(_userKey, user.toJsonString());
        return user;
      }

      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await clearUserData();
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération utilisateur: $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await dio.post(
          '/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }
    } catch (e) {
      print('Erreur lors de la déconnexion côté serveur: $e');
    }

    await clearUserData();
  }

  Future<void> clearUserData() async {
    try {
      final keysToRemove = [
        _accessTokenKey,
        _refreshTokenKey,
        _userKey,
        _tokenExpiryKey,
      ];

      for (final key in keysToRemove) {
        await sharedPreferences.remove(key);
      }

      print('Données utilisateur effacées');
    } catch (e) {
      print('Erreur lors du nettoyage: $e');
      try {
        await sharedPreferences.clear();
      } catch (clearError) {
        print('Erreur lors du clear global: $clearError');
      }
    }
  }

  // === AUTRES MÉTHODES ===

  Future<void> register(
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    try {
      final response = await dio.post(
        '/auth/register',
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode != 201) {
        throw AuthenticationException(
          'Erreur lors de l\'inscription',
          'REGISTRATION_FAILED',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409 || e.response?.statusCode == 400) {
        final errorData = e.response?.data;

        // Vérifier le code d'erreur spécifique
        if (errorData != null && errorData['code'] == 'EMAIL_ALREADY_EXISTS') {
          throw AuthenticationException(
            'Un compte avec cet email existe déjà',
            'EMAIL_ALREADY_EXISTS',
          );
        }

        // Autres erreurs de conflit
        throw AuthenticationException(
          'Un compte avec cet email existe déjà',
          'EMAIL_CONFLICT',
        );
      } else if (e.response?.statusCode == 422) {
        // Erreurs de validation
        final errorData = e.response?.data;
        String errorMessage = 'Données invalides';

        if (errorData != null && errorData['message'] != null) {
          errorMessage = errorData['message'].toString();
        }

        throw AuthenticationException(errorMessage, 'VALIDATION_ERROR');
      } else {
        throw AuthenticationException(
          'Erreur lors de l\'inscription: ${e.message}',
          'NETWORK_ERROR',
        );
      }
    } catch (e) {
      throw AuthenticationException(
        'Une erreur inattendue est survenue lors de l\'inscription',
        'UNKNOWN_ERROR',
      );
    }
  }

  Future<User> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    try {
      final token = await getToken();
      final response = await dio.put(
        '/auth/me',
        data: {'first_name': firstName, 'last_name': lastName},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final updatedUser = User.fromMap(response.data);

      // Mettre à jour le cache
      await sharedPreferences.setString(_userKey, updatedUser.toJsonString());

      return updatedUser;
    } on DioException catch (e) {
      throw Exception('Erreur lors de la mise à jour: ${e.message}');
    }
  }

  Future<void> requestPasswordChangeCode(String email) async {
    try {
      await dio.post('/auth/request-password-change', data: {'email': email});
    } on DioException catch (e) {
      throw Exception('Erreur lors de la demande: ${e.message}');
    }
  }

  Future<void> verifyPasswordChangeCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await dio.post(
        '/auth/verify-password-change-code',
        data: {'email': email, 'code': code, 'new_password': newPassword},
      );
    } on DioException catch (e) {
      throw Exception('Erreur lors de la vérification: ${e.message}');
    }
  }

  Future<Map<String, String>?> confirmEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await dio.post(
        '/auth/confirm-email',
        data: {'email': email, 'code': code},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Vérifier si la réponse contient des tokens (nouvelle API)
        final accessToken = data['access_token'] as String?;
        final refreshToken = data['refresh_token'] as String?;

        if (accessToken != null && refreshToken != null) {
          return {'access_token': accessToken, 'refresh_token': refreshToken};
        } else {
          // Ancienne API - pas de tokens
          return null;
        }
      } else {
        throw AuthenticationException(
          'Erreur lors de la confirmation de l\'email',
          'EMAIL_CONFIRMATION_FAILED',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;

        // Vérifier les codes d'erreur spécifiques
        if (errorData != null && errorData is Map) {
          final errorCode = errorData['code'] as String?;
          final errorMessage = errorData['message'] as String?;

          switch (errorCode) {
            case 'INVALID_CODE':
            case 'CODE_INVALID':
              throw AuthenticationException(
                'Le code de vérification est invalide',
                'INVALID_VERIFICATION_CODE',
              );
            case 'CODE_EXPIRED':
            case 'EXPIRED_CODE':
              throw AuthenticationException(
                'Le code de vérification a expiré',
                'EXPIRED_VERIFICATION_CODE',
              );
            case 'USER_NOT_FOUND':
              throw AuthenticationException(
                'Aucun compte trouvé avec cet email',
                'USER_NOT_FOUND',
              );
            case 'EMAIL_ALREADY_VERIFIED':
              throw AuthenticationException(
                'Cet email est déjà vérifié',
                'EMAIL_ALREADY_VERIFIED',
              );
            default:
              throw AuthenticationException(
                errorMessage ??
                    'Le code de vérification est incorrect ou expiré',
                'VERIFICATION_ERROR',
              );
          }
        } else {
          throw AuthenticationException(
            'Le code de vérification est incorrect ou expiré',
            'INVALID_VERIFICATION_CODE',
          );
        }
      } else if (e.response?.statusCode == 422) {
        // Erreurs de validation
        throw AuthenticationException(
          'Données de vérification invalides',
          'VALIDATION_ERROR',
        );
      } else if (e.response?.statusCode == 404) {
        throw AuthenticationException(
          'Service de vérification non disponible',
          'SERVICE_UNAVAILABLE',
        );
      } else {
        throw AuthenticationException(
          'Erreur de réseau lors de la confirmation: ${e.message}',
          'NETWORK_ERROR',
        );
      }
    } catch (e) {
      throw AuthenticationException(
        'Une erreur inattendue est survenue lors de la confirmation',
        'UNKNOWN_ERROR',
      );
    }
  }

  Future<void> resendVerificationCode(String email) async {
    try {
      final response = await dio.post(
        '/auth/resend-verification',
        data: {'email': email},
      );

      if (response.statusCode != 200) {
        throw AuthenticationException(
          'Erreur lors du renvoi du code',
          'RESEND_FAILED',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;

        if (errorData != null && errorData['errors'] != null) {
          // Erreur de validation spécifique
          final errors = errorData['errors'] as Map<String, dynamic>;
          if (errors['code'] != null) {
            throw AuthenticationException(
              'Erreur de configuration du serveur',
              'SERVER_CONFIG_ERROR',
            );
          }
          if (errors['email'] != null) {
            throw AuthenticationException(
              'Format d\'email invalide',
              'INVALID_EMAIL_FORMAT',
            );
          }
        }

        // Erreur générale de validation
        throw AuthenticationException(
          'Données de requête invalides',
          'VALIDATION_ERROR',
        );
      } else if (e.response?.statusCode == 404) {
        throw AuthenticationException(
          'Aucun compte trouvé avec cet email',
          'USER_NOT_FOUND',
        );
      } else if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData != null &&
            errorData['message'] == 'Email already verified') {
          throw AuthenticationException(
            'Cet email est déjà vérifié',
            'EMAIL_ALREADY_VERIFIED',
          );
        }
      } else {
        throw AuthenticationException(
          'Erreur lors du renvoi: ${e.message}',
          'NETWORK_ERROR',
        );
      }
    } catch (e) {
      throw AuthenticationException(
        'Une erreur inattendue est survenue lors du renvoi',
        'UNKNOWN_ERROR',
      );
    }
  }
}
