// auth_service.dart - VERSION AVEC NETTOYAGE COMPLET
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:epilist/models/user.dart';
import 'package:flutter/foundation.dart';

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

  // === GESTION DES TOKENS ===

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    try {
      await Future.wait([
        sharedPreferences.setString(_accessTokenKey, accessToken),
        sharedPreferences.setString(_refreshTokenKey, refreshToken),
        // Calculer et sauvegarder l'heure d'expiration (1 heure)
        sharedPreferences.setInt(
          _tokenExpiryKey,
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
        ),
      ]);

      debugPrint('✅ Tokens sauvegardés avec succès');
      debugPrint('🔑 Access Token: ${accessToken.substring(0, 20)}...');
      debugPrint('🔄 Refresh Token: ${refreshToken.substring(0, 20)}...');
    } catch (e) {
      debugPrint('❌ Erreur lors de la sauvegarde des tokens: $e');
      throw Exception('Impossible de sauvegarder les tokens');
    }
  }

  Future<String?> getToken() async {
    try {
      final token = sharedPreferences.getString(_accessTokenKey);
      if (token != null && token.isNotEmpty) {
        // Vérifier si le token n'est pas expiré
        final expiry = sharedPreferences.getInt(_tokenExpiryKey);
        if (expiry != null) {
          final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiry);
          if (DateTime.now().isBefore(expiryDate)) {
            return token;
          } else {
            debugPrint('⚠️ Token expiré, refresh nécessaire');
            return null;
          }
        }
        return token;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération du token: $e');
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return sharedPreferences.getString(_refreshTokenKey);
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération du refresh token: $e');
      return null;
    }
  }

  Future<bool> isTokenExpired() async {
    try {
      final expiry = sharedPreferences.getInt(_tokenExpiryKey);
      if (expiry == null) return true;

      final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiry);
      return DateTime.now().isAfter(expiryDate);
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification d\'expiration: $e');
      return true;
    }
  }

  // === AUTHENTIFICATION ===

  Future<Map<String, String>> login(String email, String password) async {
    try {
      debugPrint('🔐 Tentative de connexion pour: $email');

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

        debugPrint('✅ Connexion réussie');
        return {'access_token': accessToken, 'refresh_token': refreshToken};
      } else {
        throw AuthenticationException('Erreur de connexion', 'LOGIN_FAILED');
      }
    } on DioException catch (e) {
      debugPrint('❌ Erreur DioException: ${e.response?.data}');

      // CORRECTION: Gérer les codes 401 ET 403 pour EMAIL_NOT_VERIFIED
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        final errorData = e.response?.data;
        if (errorData != null && errorData['code'] == 'EMAIL_NOT_VERIFIED') {
          // Extraire l'email de la réponse API
          String emailFromResponse =
              email; // Par défaut, utiliser l'email du login

          // Essayer d'extraire l'email de la structure data
          if (errorData['data'] != null && errorData['data']['email'] != null) {
            emailFromResponse = errorData['data']['email'];
            debugPrint(
              '📧 Email extrait de la réponse API: $emailFromResponse',
            );
          }

          throw AuthenticationException(
            'Email non vérifié',
            'EMAIL_NOT_VERIFIED',
            email: emailFromResponse,
          );
        }

        // Autres erreurs 401/403
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
      debugPrint('❌ Erreur inattendue: $e');
      throw AuthenticationException(
        'Une erreur inattendue est survenue',
        'UNKNOWN_ERROR',
      );
    }
  }

  Future<Map<String, String>> refreshToken(String refreshToken) async {
    try {
      debugPrint('🔄 Rafraîchissement du token...');

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

        debugPrint('✅ Token rafraîchi avec succès');
        return {
          'access_token': newAccessToken,
          'refresh_token': newRefreshToken,
        };
      } else {
        throw Exception('Échec du rafraîchissement du token');
      }
    } on DioException catch (e) {
      debugPrint('❌ Erreur lors du refresh: ${e.response?.data}');
      if (e.response?.statusCode == 401) {
        throw Exception('Refresh token invalide ou expiré');
      }
      throw Exception('Erreur réseau lors du refresh: ${e.message}');
    } catch (e) {
      debugPrint('❌ Erreur inattendue lors du refresh: $e');
      rethrow;
    }
  }

  Future<bool> isAuthenticated() async {
    try {
      final accessToken = await getToken();
      final refreshToken = await getRefreshToken();

      if (accessToken != null && accessToken.isNotEmpty) {
        return true;
      }

      // Si pas de access token mais refresh token présent, essayer de rafraîchir
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          final tokens = await this.refreshToken(refreshToken);
          await saveTokens(tokens['access_token']!, tokens['refresh_token']!);
          return true;
        } catch (e) {
          debugPrint('❌ Impossible de rafraîchir le token: $e');
          await clearUserData();
          return false;
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification d\'authentification: $e');
      return false;
    }
  }

  // Méthode pour sauvegarder l'utilisateur en cache
  Future<void> saveUserToCache(User user) async {
    try {
      await sharedPreferences.setString(_userKey, user.toJsonString());
      debugPrint('👤 Utilisateur sauvegardé en cache: ${user.fullName}');
    } catch (e) {
      debugPrint('❌ Erreur lors de la sauvegarde utilisateur: $e');
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      // D'abord vérifier si on a l'utilisateur en cache
      final cachedUserData = sharedPreferences.getString(_userKey);
      if (cachedUserData != null) {
        final userData = User.fromJsonString(cachedUserData);
        debugPrint('👤 Utilisateur récupéré du cache');
        return userData;
      }

      // Sinon, récupérer depuis l'API
      final token = await getToken();
      if (token == null) {
        debugPrint('❌ Aucun token disponible pour getCurrentUser');
        return null;
      }

      final response = await dio.get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final user = User.fromMap(response.data);

        // Sauvegarder l'utilisateur en cache
        await sharedPreferences.setString(_userKey, user.toJsonString());

        debugPrint('👤 Utilisateur récupéré de l\'API');
        return user;
      }

      return null;
    } on DioException catch (e) {
      debugPrint(
        '❌ Erreur lors de la récupération de l\'utilisateur: ${e.response?.data}',
      );
      if (e.response?.statusCode == 401) {
        // Token invalide, nettoyer les données
        await clearUserData();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur inattendue getCurrentUser: $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        debugPrint('📡 Déconnexion côté serveur...');
        await dio.post(
          '/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        debugPrint('✅ Déconnexion serveur réussie');
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lors de la déconnexion côté serveur: $e');
      // Continuer avec la déconnexion locale même si l'API échoue
    }

    // TOUJOURS nettoyer les données locales
    await clearUserData();
  }

  Future<void> clearUserData() async {
    try {
      debugPrint('🧹 Début du nettoyage des données...');

      // Supprimer toutes les clés une par une pour s'assurer qu'elles sont supprimées
      final keysToRemove = [
        _accessTokenKey,
        _refreshTokenKey,
        _userKey,
        _tokenExpiryKey,
      ];

      for (final key in keysToRemove) {
        final removed = await sharedPreferences.remove(key);
        debugPrint('🗑️ Suppression $key: ${removed ? 'OK' : 'ÉCHEC'}');
      }

      // Vérification que les clés ont bien été supprimées
      final accessToken = sharedPreferences.getString(_accessTokenKey);
      final refreshToken = sharedPreferences.getString(_refreshTokenKey);
      final userData = sharedPreferences.getString(_userKey);
      final tokenExpiry = sharedPreferences.getInt(_tokenExpiryKey);

      if (accessToken == null &&
          refreshToken == null &&
          userData == null &&
          tokenExpiry == null) {
        debugPrint('✅ Toutes les données utilisateur ont été supprimées');
      } else {
        debugPrint('⚠️ Certaines données n\'ont pas été supprimées:');
        if (accessToken != null) debugPrint('  - Access token encore présent');
        if (refreshToken != null)
          debugPrint('  - Refresh token encore présent');
        if (userData != null)
          debugPrint('  - Données utilisateur encore présentes');
        if (tokenExpiry != null)
          debugPrint('  - Expiration token encore présente');
      }

      debugPrint('🧹 Nettoyage des données terminé');
    } catch (e) {
      debugPrint('❌ Erreur lors du nettoyage: $e');
      // En cas d'erreur, essayer de forcer la suppression
      try {
        await sharedPreferences.clear();
        debugPrint('🔥 Nettoyage forcé effectué (clear total)');
      } catch (clearError) {
        debugPrint('❌ Impossible de nettoyer les données: $clearError');
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
      debugPrint('📝 Tentative d\'inscription pour: $email');

      final response = await dio.post(
        '/auth/register',
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 201) {
        debugPrint('✅ Inscription réussie pour: $email');
      } else {
        throw AuthenticationException(
          'Erreur lors de l\'inscription',
          'REGISTRATION_FAILED',
        );
      }
    } on DioException catch (e) {
      debugPrint('❌ Erreur DioException inscription: ${e.response?.data}');

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
      debugPrint('❌ Erreur inattendue inscription: $e');
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
      await dio.post('/auth/password-reset-request', data: {'email': email});
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
        '/auth/password-reset-verify',
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
      debugPrint(
        '📧 Tentative de confirmation email pour: $email avec code: ${code.substring(0, 2)}...',
      );

      final response = await dio.post(
        '/auth/confirm-email',
        data: {'email': email, 'code': code},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Email confirmé avec succès pour: $email');

        final data = response.data;

        // Vérifier si la réponse contient des tokens (nouvelle API)
        final accessToken = data['access_token'] as String?;
        final refreshToken = data['refresh_token'] as String?;

        if (accessToken != null && refreshToken != null) {
          debugPrint('🔑 Tokens reçus lors de la confirmation email');
          return {'access_token': accessToken, 'refresh_token': refreshToken};
        } else {
          // Ancienne API - pas de tokens
          debugPrint('✅ Confirmation sans tokens (ancienne API)');
          return null;
        }
      } else {
        throw AuthenticationException(
          'Erreur lors de la confirmation de l\'email',
          'EMAIL_CONFIRMATION_FAILED',
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '❌ Erreur DioException confirmation email: ${e.response?.data}',
      );

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
      debugPrint('❌ Erreur inattendue confirmation email: $e');
      throw AuthenticationException(
        'Une erreur inattendue est survenue lors de la confirmation',
        'UNKNOWN_ERROR',
      );
    }
  }

  Future<void> resendVerificationCode(String email) async {
    try {
      debugPrint('📧 Tentative de renvoi du code de vérification pour: $email');

      final response = await dio.post(
        '/auth/resend-verification',
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Code de vérification renvoyé avec succès');
      } else {
        throw AuthenticationException(
          'Erreur lors du renvoi du code',
          'RESEND_FAILED',
        );
      }
    } on DioException catch (e) {
      debugPrint('❌ Erreur DioException renvoi code: ${e.response?.data}');

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
      debugPrint('❌ Erreur inattendue renvoi code: $e');
      throw AuthenticationException(
        'Une erreur inattendue est survenue lors du renvoi',
        'UNKNOWN_ERROR',
      );
    }
  }
}
