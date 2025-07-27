// auth_service.dart - CORRECTION : Gestion correcte de la réponse de login
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

  // === GESTION DES TOKENS (INCHANGÉE) ===

  DateTime? _getTokenExpiration(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      String payload = parts[1];
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }

      final decoded = utf8.decode(base64Url.decode(payload));
      final Map<String, dynamic> payloadMap = json.decode(decoded);

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
      final tokenExpiry = _getTokenExpiration(accessToken);

      await Future.wait([
        sharedPreferences.setString(_accessTokenKey, accessToken),
        sharedPreferences.setString(_refreshTokenKey, refreshToken),
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
        if (await isTokenExpired()) {
          print('Token expiré, tentative de refresh automatique');

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

  Future<bool> shouldRefreshSoon() async {
    try {
      final expiry = sharedPreferences.getInt(_tokenExpiryKey);
      if (expiry == null) return true;

      final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiry);
      final daysLeft = expiryDate.difference(DateTime.now()).inDays;

      return daysLeft <= 7;
    } catch (e) {
      return true;
    }
  }

  // === LOGIN - CORRIGÉ POUR GÉRER LA STRUCTURE DE RÉPONSE ===

  Future<Map<String, String>> login(String email, String password) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // ✅ CORRECTION : Vérifier que nous avons la bonne structure
        print('Réponse complète de login: $data');

        final accessToken = data['access_token'] as String?;
        final refreshToken = data['refresh_token'] as String?;

        if (accessToken == null || refreshToken == null) {
          throw AuthenticationException(
            'Tokens manquants dans la réponse',
            'MISSING_TOKENS',
          );
        }

        // ✅ CORRECTION CRITIQUE : Créer l'utilisateur avec les tokens ET les données
        final user = User.fromLoginResponse({
          'access_token': accessToken,
          'refresh_token': refreshToken,
          'data': data['data'], // ✅ IMPORTANT: Passer les données utilisateur
        });

        // ✅ DEBUG: Vérifier que la devise est bien parsée
        print('Utilisateur créé: ${user.fullName} (${user.email})');
        print(
          'Devise utilisateur: ${user.currency?.code ?? 'null'} - ${user.currency?.symbol ?? 'null'}',
        );
        if (user.currency != null) {
          print(
            'Devise complète: ${user.currency!.name} (${user.currency!.symbol})',
          );
        }

        // ✅ NOUVEAU : Sauvegarder l'utilisateur en cache immédiatement
        await saveUserToCache(user);

        final expiry = _getTokenExpiration(accessToken);
        print('Nouveau token reçu, expire le: $expiry');

        return {'access_token': accessToken, 'refresh_token': refreshToken};
      } else {
        throw AuthenticationException('Erreur de connexion', 'LOGIN_FAILED');
      }
    } on DioException catch (e) {
      print(
        'DioException lors du login: ${e.response?.statusCode} - ${e.response?.data}',
      );

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
      print('Erreur inattendue lors du login: $e');
      throw AuthenticationException(
        'Une erreur inattendue est survenue',
        'UNKNOWN_ERROR',
      );
    }
  }

  // === REGISTER (INCHANGÉ) ===

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
          'REGISTRATION_FAILED',
          'REGISTRATION_FAILED',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;

        if (errorData != null && errorData is Map) {
          final errorCode = errorData['code'] as String?;

          switch (errorCode) {
            case 'EMAIL_ALREADY_EXISTS':
              throw AuthenticationException(
                'EMAIL_ALREADY_EXISTS',
                'EMAIL_ALREADY_EXISTS',
              );
            case 'VALIDATION_ERROR':
              throw AuthenticationException(
                'VALIDATION_ERROR',
                'VALIDATION_ERROR',
              );
            default:
              throw AuthenticationException(
                errorCode ?? 'REGISTRATION_ERROR',
                errorCode ?? 'REGISTRATION_ERROR',
              );
          }
        }
      } else if (e.response?.statusCode == 409) {
        throw AuthenticationException('EMAIL_CONFLICT', 'EMAIL_CONFLICT');
      } else if (e.response?.statusCode == 422) {
        throw AuthenticationException('VALIDATION_ERROR', 'VALIDATION_ERROR');
      } else if (e.response?.statusCode == 500) {
        throw AuthenticationException('SERVER_ERROR', 'SERVER_ERROR');
      } else {
        throw AuthenticationException('NETWORK_ERROR', 'NETWORK_ERROR');
      }
    } catch (e) {
      if (e is AuthenticationException) {
        rethrow;
      }

      throw AuthenticationException('UNKNOWN_ERROR', 'UNKNOWN_ERROR');
    }
  }

  // === AUTRES MÉTHODES (INCHANGÉES) ===

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
      final accessToken = await getToken();
      return accessToken != null && accessToken.isNotEmpty;
    } catch (e) {
      print('Erreur lors de la vérification d\'authentification: $e');
      return false;
    }
  }

  Future<void> saveUserToCache(User user) async {
    try {
      await sharedPreferences.setString(_userKey, user.toJsonString());
      print('Utilisateur sauvegardé en cache: ${user.fullName}');
    } catch (e) {
      print('Erreur lors de la sauvegarde utilisateur: $e');
    }
  }

  // ✅ CORRECTION : getCurrentUser amélioré pour gérer le cache et les appels API
  Future<User?> getCurrentUser() async {
    try {
      // D'abord, essayer de récupérer depuis le cache
      final cachedUserData = sharedPreferences.getString(_userKey);
      if (cachedUserData != null && cachedUserData.isNotEmpty) {
        try {
          final userData = User.fromJsonString(cachedUserData);
          print('Utilisateur récupéré depuis le cache: ${userData.fullName}');
          return userData;
        } catch (e) {
          print('Erreur lors de la lecture du cache utilisateur: $e');
          // Si le cache est corrompu, continuer avec l'appel API
        }
      }

      // Si pas de cache ou cache corrompu, faire un appel API
      final token = await getToken();
      if (token == null) {
        print('Aucun token disponible pour getCurrentUser');
        return null;
      }

      print('Récupération des informations utilisateur depuis l\'API...');
      final response = await dio.get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        print('Réponse /auth/me: ${response.data}');
        final user = User.fromMap(response.data);

        // Sauvegarder en cache
        await saveUserToCache(user);

        print('Utilisateur récupéré depuis l\'API: ${user.fullName}');
        return user;
      }

      print('Réponse inattendue de /auth/me: ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      print(
        'Erreur DioException dans getCurrentUser: ${e.response?.statusCode} - ${e.message}',
      );

      if (e.response?.statusCode == 401) {
        print('Token expiré, nettoyage des données utilisateur');
        await clearUserData();
      }
      return null;
    } catch (e) {
      print('Erreur inattendue lors de la récupération utilisateur: $e');
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
      await saveUserToCache(updatedUser);

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
      final response = await dio.post(
        '/auth/verify-password-change-code',
        data: {'email': email, 'code': code, 'new_password': newPassword},
      );

      if (response.statusCode != 200) {
        throw AuthenticationException(
          'PASSWORD_CHANGE_ERROR',
          'PASSWORD_CHANGE_ERROR',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;

        if (errorData != null && errorData is Map) {
          final errorCode = errorData['code'] as String?;

          switch (errorCode) {
            case 'INVALID_CODE':
              throw AuthenticationException('INVALID_CODE', 'INVALID_CODE');
            case 'CODE_EXPIRED':
              throw AuthenticationException('CODE_EXPIRED', 'CODE_EXPIRED');
            case 'VALIDATION_ERROR':
              throw AuthenticationException(
                'VALIDATION_ERROR',
                'VALIDATION_ERROR',
              );
            case 'USER_INACTIVE':
              throw AuthenticationException('USER_INACTIVE', 'USER_INACTIVE');
            default:
              throw AuthenticationException(
                'VERIFICATION_ERROR',
                'VERIFICATION_ERROR',
              );
          }
        } else {
          throw AuthenticationException('INVALID_CODE', 'INVALID_CODE');
        }
      } else if (e.response?.statusCode == 404) {
        throw AuthenticationException('USER_NOT_FOUND', 'USER_NOT_FOUND');
      } else if (e.response?.statusCode == 422) {
        throw AuthenticationException('VALIDATION_ERROR', 'VALIDATION_ERROR');
      } else if (e.response?.statusCode == 500) {
        throw AuthenticationException('SERVER_ERROR', 'SERVER_ERROR');
      } else {
        throw AuthenticationException('NETWORK_ERROR', 'NETWORK_ERROR');
      }
    } catch (e) {
      if (e is AuthenticationException) {
        rethrow;
      }

      throw AuthenticationException('UNKNOWN_ERROR', 'UNKNOWN_ERROR');
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

        final accessToken = data['access_token'] as String?;
        final refreshToken = data['refresh_token'] as String?;

        if (accessToken != null && refreshToken != null) {
          return {'access_token': accessToken, 'refresh_token': refreshToken};
        } else {
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
