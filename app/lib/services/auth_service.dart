// services/auth_service.dart - VERSION COMPLÈTE AVEC APPLE SIGN-IN RESTAURÉ
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:epilist/models/user.dart';
import 'package:epilist/services/sso_service.dart';
import 'dart:convert';
import 'dart:io';

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
  static const String _welcomeCardDismissedKey = 'welcome_card_dismissed';
  static const String _ssoProviderKey = 'sso_provider';
  static const String _ssoUserInfoKey = 'sso_user_info';

  AuthService({required this.dio, required this.sharedPreferences});

  // ===================== GESTION DES TOKENS =====================

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
      print('❌ [AuthService] Erreur lors du décodage du token: $e');
    }
    return null;
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    try {
      print('🔄 [AuthService] Sauvegarde des tokens...');
      print('  Access token: ${accessToken.substring(0, 20)}...');
      print('  Refresh token: ${refreshToken.substring(0, 20)}...');

      final tokenExpiry = _getTokenExpiration(accessToken);
      print('  Expiration: ${tokenExpiry ?? "1 an par défaut"}');

      await Future.wait([
        sharedPreferences.setString(_accessTokenKey, accessToken),
        sharedPreferences.setString(_refreshTokenKey, refreshToken),
        sharedPreferences.setInt(
          _tokenExpiryKey,
          (tokenExpiry ?? DateTime.now().add(const Duration(days: 365)))
              .millisecondsSinceEpoch,
        ),
      ]);

      print('✅ [AuthService] Tokens sauvegardés avec succès');
    } catch (e) {
      print('❌ [AuthService] Erreur lors de la sauvegarde des tokens: $e');
      throw Exception('Impossible de sauvegarder les tokens: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      final token = sharedPreferences.getString(_accessTokenKey);
      if (token != null && token.isNotEmpty) {
        print('🔍 [AuthService] Token trouvé: ${token.substring(0, 20)}...');

        if (await isTokenExpired()) {
          print(
            '⏰ [AuthService] Token expiré, tentative de refresh automatique',
          );

          final refreshToken = await getRefreshToken();
          if (refreshToken != null && refreshToken.isNotEmpty) {
            try {
              final newTokens = await this.refreshToken(refreshToken);
              await saveTokens(
                newTokens['access_token']!,
                newTokens['refresh_token']!,
              );
              print('✅ [AuthService] Token refreshé automatiquement');
              return newTokens['access_token'];
            } catch (e) {
              print('❌ [AuthService] Échec du refresh automatique: $e');
              await clearUserData();
              return null;
            }
          }
          return null;
        }
        return token;
      } else {
        print('❌ [AuthService] Aucun token trouvé dans le cache');
        return null;
      }
    } catch (e) {
      print('❌ [AuthService] Erreur lors de la récupération du token: $e');
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
        print('❌ [AuthService] Token expiré: $expiryDate');
      } else {
        final timeLeft = expiryDate.difference(DateTime.now());
        print(
          '✅ [AuthService] Token valide, expire dans: ${timeLeft.inDays}j ${timeLeft.inHours % 24}h',
        );
      }

      return isExpired;
    } catch (e) {
      print('❌ [AuthService] Erreur lors de la vérification d\'expiration: $e');
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

  // ===================== MÉTHODES SSO COMPLÈTES =====================

  /// ✅ CONNEXION GOOGLE
  Future<Map<String, String>> loginWithGoogle() async {
    try {
      print('🔵 [AuthService] Début de la connexion Google...');

      // 1. Obtenir les credentials Google
      final SSOResult result = await SSOService.signInWithGoogle();

      if (!result.success) {
        print('❌ [AuthService] Échec SSO Google: ${result.error}');
        throw AuthenticationException(
          result.error ?? 'Erreur lors de la connexion Google',
          'GOOGLE_SIGNIN_FAILED',
        );
      }

      if (result.idToken == null || result.userInfo == null) {
        print('❌ [AuthService] Données Google incomplètes');
        throw AuthenticationException(
          'Informations Google incomplètes',
          'GOOGLE_INCOMPLETE_DATA',
        );
      }

      print('✅ [AuthService] Credentials Google obtenus, envoi au serveur...');
      print('  ID Token: ${result.idToken!.substring(0, 30)}...');
      print('  User Info: ${result.userInfo!.email}');

      // 2. Envoyer les credentials au serveur
      final response = await dio.post(
        '/auth/sso/google/login',
        data: {
          'id_token': result.idToken,
          'access_token': result.accessToken,
          'user_info': result.userInfo!.toMap(),
        },
      );

      print('📡 [AuthService] Réponse serveur: ${response.statusCode}');
      print('📡 [AuthService] Données: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        // ✅ VÉRIFICATION STRICTE DES TOKENS
        final accessToken = data['access_token'] as String?;
        final refreshToken = data['refresh_token'] as String?;

        if (accessToken == null || accessToken.isEmpty) {
          print('❌ [AuthService] Access token manquant');
          throw AuthenticationException(
            'Access token manquant',
            'MISSING_ACCESS_TOKEN',
          );
        }

        if (refreshToken == null || refreshToken.isEmpty) {
          print('❌ [AuthService] Refresh token manquant');
          throw AuthenticationException(
            'Refresh token manquant',
            'MISSING_REFRESH_TOKEN',
          );
        }

        print('✅ [AuthService] Tokens reçus:');
        print('  Access: ${accessToken.substring(0, 30)}...');
        print('  Refresh: ${refreshToken.substring(0, 30)}...');

        // ✅ SAUVEGARDER LES TOKENS EN PREMIER
        await saveTokens(accessToken, refreshToken);

        // ✅ CRÉER L'UTILISATEUR DEPUIS LA RÉPONSE
        final user = User.fromLoginResponse({
          'access_token': accessToken,
          'refresh_token': refreshToken,
          'data': data['data'],
        });

        print('✅ [AuthService] Utilisateur créé: ${user.fullName}');

        // ✅ SAUVEGARDER L'UTILISATEUR
        await saveUserToCache(user);
        await _saveSSOInfo('google', result.userInfo!);

        print('✅ [AuthService] Connexion Google terminée avec succès');

        return {'access_token': accessToken, 'refresh_token': refreshToken};
      } else {
        print(
          '❌ [AuthService] Code de réponse inattendu: ${response.statusCode}',
        );
        throw AuthenticationException(
          'Erreur de connexion Google',
          'GOOGLE_LOGIN_FAILED',
        );
      }
    } on DioException catch (e) {
      print(
        '❌ [AuthService] Erreur Dio Google: ${e.response?.statusCode} - ${e.response?.data}',
      );
      return _handleSSODioException(e, 'google');
    } catch (e) {
      print('❌ [AuthService] Erreur générale Google: $e');

      if (e is AuthenticationException) {
        rethrow;
      }

      throw AuthenticationException(
        'Erreur inattendue lors de la connexion Google: $e',
        'GOOGLE_UNKNOWN_ERROR',
      );
    }
  }

  /// ✅ CONNEXION APPLE RESTAURÉE COMPLÈTEMENT
  Future<Map<String, String>> loginWithApple() async {
    try {
      print('🍎 [AuthService] Début de la connexion Apple...');

      // 1. Vérification de plateforme
      if (!Platform.isIOS) {
        print('⚠️ [AuthService] Apple Sign-In tenté sur plateforme non-iOS');
        // Ne pas lancer d'exception, essayer quand même
      }

      // 2. Obtenir les credentials Apple
      final SSOResult result = await SSOService.signInWithApple();

      if (!result.success) {
        print('❌ [AuthService] Échec SSO Apple: ${result.error}');
        throw AuthenticationException(
          result.error ?? 'Erreur lors de la connexion Apple',
          'APPLE_SIGNIN_FAILED',
        );
      }

      if (result.idToken == null || result.userInfo == null) {
        print('❌ [AuthService] Données Apple incomplètes');
        throw AuthenticationException(
          'Informations Apple incomplètes',
          'APPLE_INCOMPLETE_DATA',
        );
      }

      print('✅ [AuthService] Credentials Apple obtenus, envoi au serveur...');
      print('  ID Token: ${result.idToken!.substring(0, 30)}...');
      print('  User Info: ${result.userInfo!.email ?? "privé"}');

      // 3. Envoyer les credentials au serveur
      final response = await dio.post(
        '/auth/sso/apple/login',
        data: {
          'id_token': result.idToken,
          'authorization_code': result.accessToken,
          'user_info': result.userInfo!.toMap(),
        },
      );

      print('📡 [AuthService] Réponse serveur Apple: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;

        final accessToken = data['access_token'] as String?;
        final refreshToken = data['refresh_token'] as String?;

        if (accessToken == null ||
            accessToken.isEmpty ||
            refreshToken == null ||
            refreshToken.isEmpty) {
          throw AuthenticationException(
            'Tokens manquants dans la réponse serveur',
            'MISSING_TOKENS',
          );
        }

        print('✅ [AuthService] Tokens Apple reçus:');
        print('  Access: ${accessToken.substring(0, 30)}...');
        print('  Refresh: ${refreshToken.substring(0, 30)}...');

        await saveTokens(accessToken, refreshToken);

        final user = User.fromLoginResponse({
          'access_token': accessToken,
          'refresh_token': refreshToken,
          'data': data['data'],
        });

        await saveUserToCache(user);
        await _saveSSOInfo('apple', result.userInfo!);

        print('✅ [AuthService] Connexion Apple terminée avec succès');

        return {'access_token': accessToken, 'refresh_token': refreshToken};
      } else {
        throw AuthenticationException(
          'Erreur de connexion Apple',
          'APPLE_LOGIN_FAILED',
        );
      }
    } on DioException catch (e) {
      print(
        '❌ [AuthService] Erreur Dio Apple: ${e.response?.statusCode} - ${e.response?.data}',
      );
      return _handleSSODioException(e, 'apple');
    } catch (e) {
      print('❌ [AuthService] Erreur générale Apple: $e');

      if (e is AuthenticationException) {
        rethrow;
      }

      throw AuthenticationException(
        'Erreur inattendue lors de la connexion Apple: $e',
        'APPLE_UNKNOWN_ERROR',
      );
    }
  }

  /// ✅ INSCRIPTION GOOGLE
  Future<void> registerWithGoogle() async {
    try {
      print('🔵 [AuthService] Début de l\'inscription Google...');

      final SSOResult result = await SSOService.signInWithGoogle();

      if (!result.success) {
        throw AuthenticationException(
          result.error ?? 'Erreur lors de l\'inscription Google',
          'GOOGLE_SIGNUP_FAILED',
        );
      }

      if (result.idToken == null || result.userInfo == null) {
        throw AuthenticationException(
          'Informations Google incomplètes',
          'GOOGLE_INCOMPLETE_DATA',
        );
      }

      print(
        '✅ [AuthService] Credentials Google obtenus, création du compte...',
      );

      final response = await dio.post(
        '/auth/sso/google/register',
        data: {
          'id_token': result.idToken,
          'access_token': result.accessToken,
          'user_info': result.userInfo!.toMap(),
        },
      );

      if (response.statusCode != 201) {
        throw AuthenticationException(
          'Erreur lors de la création du compte Google',
          'GOOGLE_REGISTRATION_FAILED',
        );
      }

      print('✅ [AuthService] Inscription Google réussie');
    } on DioException catch (e) {
      print(
        '❌ [AuthService] Erreur Dio inscription Google: ${e.response?.data}',
      );
      _handleSSODioException(e, 'google');
    } catch (e) {
      if (e is AuthenticationException) {
        rethrow;
      }
      throw AuthenticationException(
        'Erreur inattendue lors de l\'inscription Google',
        'GOOGLE_UNKNOWN_ERROR',
      );
    }
  }

  /// ✅ INSCRIPTION APPLE RESTAURÉE COMPLÈTEMENT
  Future<void> registerWithApple() async {
    try {
      print('🍎 [AuthService] Début de l\'inscription Apple...');

      // Vérification de plateforme (warning, pas d'exception)
      if (!Platform.isIOS) {
        print(
          '⚠️ [AuthService] Apple Sign-In registration tenté sur plateforme non-iOS',
        );
      }

      final SSOResult result = await SSOService.signInWithApple();

      if (!result.success) {
        throw AuthenticationException(
          result.error ?? 'Erreur lors de l\'inscription Apple',
          'APPLE_SIGNUP_FAILED',
        );
      }

      if (result.idToken == null || result.userInfo == null) {
        throw AuthenticationException(
          'Informations Apple incomplètes',
          'APPLE_INCOMPLETE_DATA',
        );
      }

      print('✅ [AuthService] Credentials Apple obtenus, création du compte...');

      final response = await dio.post(
        '/auth/sso/apple/register',
        data: {
          'id_token': result.idToken,
          'authorization_code': result.accessToken,
          'user_info': result.userInfo!.toMap(),
        },
      );

      if (response.statusCode != 201) {
        throw AuthenticationException(
          'Erreur lors de la création du compte Apple',
          'APPLE_REGISTRATION_FAILED',
        );
      }

      print('✅ [AuthService] Inscription Apple réussie');
    } on DioException catch (e) {
      print(
        '❌ [AuthService] Erreur Dio inscription Apple: ${e.response?.data}',
      );
      _handleSSODioException(e, 'apple');
    } catch (e) {
      if (e is AuthenticationException) {
        rethrow;
      }
      throw AuthenticationException(
        'Erreur inattendue lors de l\'inscription Apple',
        'APPLE_UNKNOWN_ERROR',
      );
    }
  }

  // ===================== MÉTHODES DE LIAISON SSO RESTAURÉES =====================

  /// ✅ LIER UN COMPTE SSO À UN COMPTE EXISTANT
  Future<void> linkSSOAccount(String provider, SSOResult ssoResult) async {
    try {
      print('🔗 [AuthService] Liaison d\'un compte $provider...');

      final token = await getToken();
      if (token == null) {
        throw AuthenticationException(
          'Utilisateur non authentifié',
          'NOT_AUTHENTICATED',
        );
      }

      final response = await dio.post(
        '/auth/sso/$provider/link',
        data: {
          'id_token': ssoResult.idToken,
          'access_token': ssoResult.accessToken,
          'user_info': ssoResult.userInfo!.toMap(),
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        await _saveSSOInfo(provider, ssoResult.userInfo!);
        print('✅ [AuthService] Compte $provider lié avec succès');
      } else {
        throw AuthenticationException(
          'Erreur lors de la liaison du compte $provider',
          '${provider.toUpperCase()}_LINK_FAILED',
        );
      }
    } on DioException catch (e) {
      _handleSSODioException(e, provider);
    }
  }

  /// ✅ DÉLIER UN COMPTE SSO
  Future<void> unlinkSSOAccount(String provider) async {
    try {
      print('🔗❌ [AuthService] Déliaison du compte $provider...');

      final token = await getToken();
      if (token == null) {
        throw AuthenticationException(
          'Utilisateur non authentifié',
          'NOT_AUTHENTICATED',
        );
      }

      final response = await dio.delete(
        '/auth/sso/$provider/unlink',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        await _removeSSOInfo(provider);

        // Déconnexion du service SSO si nécessaire
        if (provider == 'google') {
          await SSOService.signOutGoogle();
        } else if (provider == 'apple') {
          await SSOService.signOutApple();
        }

        print('✅ [AuthService] Compte $provider délié avec succès');
      } else {
        throw AuthenticationException(
          'Erreur lors de la déliaison du compte $provider',
          '${provider.toUpperCase()}_UNLINK_FAILED',
        );
      }
    } on DioException catch (e) {
      _handleSSODioException(e, provider);
    }
  }

  // ===================== MÉTHODES UTILITAIRES SSO =====================

  /// Sauvegarder les informations SSO
  Future<void> _saveSSOInfo(String provider, SSOUserInfo userInfo) async {
    try {
      await sharedPreferences.setString(_ssoProviderKey, provider);
      await sharedPreferences.setString(
        _ssoUserInfoKey,
        json.encode(userInfo.toMap()),
      );
      print('💾 [AuthService] Informations SSO sauvegardées pour $provider');
    } catch (e) {
      print('❌ [AuthService] Erreur lors de la sauvegarde SSO: $e');
    }
  }

  /// Supprimer les informations SSO
  Future<void> _removeSSOInfo(String provider) async {
    try {
      await sharedPreferences.remove(_ssoProviderKey);
      await sharedPreferences.remove(_ssoUserInfoKey);
      print('🗑️ [AuthService] Informations SSO supprimées pour $provider');
    } catch (e) {
      print('❌ [AuthService] Erreur lors de la suppression SSO: $e');
    }
  }

  /// Obtenir le provider SSO actuel
  Future<String?> getCurrentSSOProvider() async {
    try {
      return sharedPreferences.getString(_ssoProviderKey);
    } catch (e) {
      print(
        '❌ [AuthService] Erreur lors de la récupération du provider SSO: $e',
      );
      return null;
    }
  }

  /// Obtenir les informations utilisateur SSO
  Future<SSOUserInfo?> getSSOUserInfo() async {
    try {
      final userInfoString = sharedPreferences.getString(_ssoUserInfoKey);
      if (userInfoString == null) return null;

      final Map<String, dynamic> userInfoMap = json.decode(userInfoString);

      return SSOUserInfo(
        id: userInfoMap['id'],
        email: userInfoMap['email'],
        firstName: userInfoMap['first_name'],
        lastName: userInfoMap['last_name'],
        displayName: userInfoMap['display_name'],
        photoUrl: userInfoMap['photo_url'],
        provider: userInfoMap['provider'],
      );
    } catch (e) {
      print('❌ [AuthService] Erreur lors de la récupération des infos SSO: $e');
      return null;
    }
  }

  /// Vérifier si l'utilisateur est connecté via SSO
  Future<bool> isLoggedInWithSSO() async {
    final provider = await getCurrentSSOProvider();
    return provider != null;
  }

  /// ✅ GESTION DES ERREURS SSO
  Never _handleSSODioException(DioException e, String provider) {
    print(
      '❌ [AuthService] Erreur ${provider.toUpperCase()} Dio: ${e.response?.statusCode} - ${e.response?.data}',
    );

    if (e.response?.statusCode == 400) {
      final errorData = e.response?.data;

      if (errorData != null && errorData is Map) {
        final errorCode = errorData['code'] as String?;

        switch (errorCode) {
          case 'EMAIL_ALREADY_EXISTS':
            throw AuthenticationException(
              'Un compte existe déjà avec cet email',
              'EMAIL_ALREADY_EXISTS',
            );
          case 'INVALID_SSO_TOKEN':
            throw AuthenticationException(
              'Token ${provider.toUpperCase()} invalide',
              'INVALID_SSO_TOKEN',
            );
          case 'SSO_ACCOUNT_ALREADY_LINKED':
            throw AuthenticationException(
              'Ce compte ${provider.toUpperCase()} est déjà lié',
              'SSO_ACCOUNT_ALREADY_LINKED',
            );
          default:
            throw AuthenticationException(
              'Erreur ${provider.toUpperCase()}: ${errorCode ?? 'Unknown'}',
              errorCode ?? 'SSO_ERROR',
            );
        }
      }
    } else if (e.response?.statusCode == 401) {
      throw AuthenticationException(
        'Token ${provider.toUpperCase()} expiré ou invalide',
        'SSO_TOKEN_EXPIRED',
      );
    }

    throw AuthenticationException(
      'Erreur réseau ${provider.toUpperCase()}: ${e.message}',
      'SSO_NETWORK_ERROR',
    );
  }

  // ===================== AUTHENTIFICATION CLASSIQUE =====================

  /// ✅ LOGIN CLASSIQUE
  Future<Map<String, String>> login(String email, String password) async {
    try {
      print('🔐 [AuthService] Début du login classique...');

      final response = await dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print('📡 [AuthService] Réponse login: $data');

        final accessToken = data['access_token'] as String?;
        final refreshToken = data['refresh_token'] as String?;

        if (accessToken == null || refreshToken == null) {
          throw AuthenticationException(
            'Tokens manquants dans la réponse',
            'MISSING_TOKENS',
          );
        }

        // ✅ SAUVEGARDER LES TOKENS EN PREMIER
        await saveTokens(accessToken, refreshToken);

        final user = User.fromLoginResponse({
          'access_token': accessToken,
          'refresh_token': refreshToken,
          'data': data['data'],
        });

        await saveUserToCache(user);
        print('✅ [AuthService] Login classique réussi');

        return {'access_token': accessToken, 'refresh_token': refreshToken};
      } else {
        throw AuthenticationException('Erreur de connexion', 'LOGIN_FAILED');
      }
    } on DioException catch (e) {
      print(
        '❌ [AuthService] Erreur login classique: ${e.response?.statusCode} - ${e.response?.data}',
      );

      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        final errorData = e.response?.data;

        if (errorData != null && errorData is Map) {
          final errorCode = errorData['code'] as String?;

          switch (errorCode) {
            case 'EMAIL_NOT_VERIFIED':
              String emailFromResponse = email;
              if (errorData['data'] != null &&
                  errorData['data']['email'] != null) {
                emailFromResponse = errorData['data']['email'];
              }
              throw AuthenticationException(
                'Email non vérifié',
                'EMAIL_NOT_VERIFIED',
                email: emailFromResponse,
              );
            case 'INVALID_CREDENTIALS':
              throw AuthenticationException(
                'Email ou mot de passe incorrect',
                'INVALID_CREDENTIALS',
              );
            case 'USER_INACTIVE':
            case 'ACCOUNT_DISABLED':
              throw AuthenticationException(
                'Ce compte utilisateur n\'est pas actif',
                'USER_INACTIVE',
              );
            case 'TOO_MANY_ATTEMPTS':
            case 'RATE_LIMITED':
              throw AuthenticationException(
                'Trop de tentatives de connexion. Veuillez réessayer plus tard.',
                'TOO_MANY_ATTEMPTS',
              );
            default:
              throw AuthenticationException(
                'Email ou mot de passe incorrect',
                'INVALID_CREDENTIALS',
              );
          }
        } else {
          throw AuthenticationException(
            'Email ou mot de passe incorrect',
            'INVALID_CREDENTIALS',
          );
        }
      }

      throw AuthenticationException(
        'Erreur de connexion: ${e.message}',
        'NETWORK_ERROR',
      );
    } catch (e) {
      print('❌ [AuthService] Erreur inattendue login: $e');
      throw AuthenticationException(
        'Une erreur inattendue est survenue',
        'UNKNOWN_ERROR',
      );
    }
  }

  Future<Map<String, String>> refreshToken(String refreshToken) async {
    try {
      print('🔄 [AuthService] Tentative de refresh du token...');

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

        print('✅ [AuthService] Token refreshé avec succès');

        return {
          'access_token': newAccessToken,
          'refresh_token': newRefreshToken,
        };
      } else {
        throw Exception('Échec du rafraîchissement du token');
      }
    } on DioException catch (e) {
      print(
        '❌ [AuthService] Erreur refresh: ${e.response?.statusCode} - ${e.message}',
      );
      if (e.response?.statusCode == 401) {
        throw Exception('Refresh token invalide ou expiré');
      }
      throw Exception('Erreur réseau lors du refresh: ${e.message}');
    }
  }

  Future<bool> isAuthenticated() async {
    try {
      final accessToken = await getToken();
      final result = accessToken != null && accessToken.isNotEmpty;
      print('🔍 [AuthService] Authentifié: $result');
      return result;
    } catch (e) {
      print('❌ [AuthService] Erreur vérification auth: $e');
      return false;
    }
  }

  Future<void> saveUserToCache(User user) async {
    try {
      await sharedPreferences.setString(_userKey, user.toJsonString());
      print(
        '💾 [AuthService] Utilisateur sauvegardé en cache: ${user.fullName}',
      );
    } catch (e) {
      print('❌ [AuthService] Erreur sauvegarde utilisateur: $e');
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      // D'abord essayer le cache
      final cachedUserData = sharedPreferences.getString(_userKey);
      if (cachedUserData != null && cachedUserData.isNotEmpty) {
        try {
          final userData = User.fromJsonString(cachedUserData);
          print(
            '💾 [AuthService] Utilisateur récupéré depuis le cache: ${userData.fullName}',
          );
          return userData;
        } catch (e) {
          print('❌ [AuthService] Erreur lecture cache utilisateur: $e');
        }
      }

      // Sinon appeler l'API
      final token = await getToken();
      if (token == null) {
        print('❌ [AuthService] Aucun token pour getCurrentUser');
        return null;
      }

      print('📡 [AuthService] Récupération utilisateur depuis l\'API...');
      final response = await dio.get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final user = User.fromMap(response.data);
        await saveUserToCache(user);
        print(
          '✅ [AuthService] Utilisateur récupéré depuis l\'API: ${user.fullName}',
        );
        return user;
      }

      return null;
    } on DioException catch (e) {
      print(
        '❌ [AuthService] Erreur getCurrentUser: ${e.response?.statusCode} - ${e.message}',
      );
      if (e.response?.statusCode == 401) {
        await clearUserData();
      }
      return null;
    }
  }

  Future<void> logout() async {
    print('🚀 [AuthService] Début du logout...');

    try {
      final ssoProvider = await getCurrentSSOProvider();
      if (ssoProvider != null) {
        print('🔄 [AuthService] Déconnexion SSO ($ssoProvider)...');

        if (ssoProvider == 'google') {
          await SSOService.signOutGoogle();
        } else if (ssoProvider == 'apple') {
          await SSOService.signOutApple();
        }

        await _removeSSOInfo(ssoProvider);
        print('✅ [AuthService] Déconnexion SSO terminée');
      }

      await clearUserData();
      print('✅ [AuthService] Logout terminé');
    } catch (e) {
      print('❌ [AuthService] Erreur logout: $e');
      try {
        await clearUserData();
        await SSOService.signOutAll();
      } catch (clearError) {
        print('❌ [AuthService] Erreur nettoyage de secours: $clearError');
      }
    }
  }

  Future<void> clearUserData() async {
    try {
      final keysToRemove = [
        _accessTokenKey,
        _refreshTokenKey,
        _userKey,
        _tokenExpiryKey,
        _welcomeCardDismissedKey,
        _ssoProviderKey,
        _ssoUserInfoKey,
      ];

      for (final key in keysToRemove) {
        await sharedPreferences.remove(key);
      }

      print('🧹 [AuthService] Données utilisateur effacées (incluant SSO)');
    } catch (e) {
      print('❌ [AuthService] Erreur nettoyage: $e');
      try {
        await sharedPreferences.clear();
      } catch (clearError) {
        print('❌ [AuthService] Erreur clear global: $clearError');
      }
    }
  }

  // ===================== AUTRES MÉTHODES =====================

  Future<void> register(
    String firstName,
    String lastName,
    String email,
    String password, {
    String? language, // 🌍 Langue de l'utilisateur
  }) async {
    try {
      final response = await dio.post(
        '/auth/register',
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
          if (language != null) 'language': language, // 🌍 Envoyer la langue
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
          // ✅ SAUVEGARDER LES TOKENS
          await saveTokens(accessToken, refreshToken);
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

  Future<void> requestPasswordChangeCode(String email, {String? language}) async {
    try {
      await dio.post('/auth/request-password-change', data: {
        'email': email,
        if (language != null) 'language': language, // 🌍 Envoyer la langue
      });
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
}
