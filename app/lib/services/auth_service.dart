import 'package:flutter/foundation.dart';
// services/auth_service.dart - VERSION COMPLÈTE AVEC APPLE SIGN-IN RESTAURÉ
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:epilist/services/notification_service.dart';
import 'package:epilist/services/screen_cache.dart';
import 'package:epilist/services/space_service.dart';
import 'package:epilist/services/token_store.dart';
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

  /// Refresh en cours : tous les getToken() concurrents attendent le même
  /// appel (voir le commentaire dans getToken).
  Future<Map<String, String>>? _refreshInFlight;
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
      debugPrint('❌ [AuthService] Erreur lors du décodage du token: $e');
    }
    return null;
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    try {
      debugPrint('🔄 [AuthService] Sauvegarde des tokens...');
      debugPrint('  Access token: ${accessToken.substring(0, 20)}...');
      debugPrint('  Refresh token: ${refreshToken.substring(0, 20)}...');

      final tokenExpiry = _getTokenExpiration(accessToken);
      debugPrint('  Expiration: ${tokenExpiry ?? "1 an par défaut"}');

      await TokenStore.write(accessToken, refreshToken);
      await Future.wait([
        sharedPreferences.setInt(
          _tokenExpiryKey,
          (tokenExpiry ?? DateTime.now().add(const Duration(days: 365)))
              .millisecondsSinceEpoch,
        ),
      ]);

      debugPrint('✅ [AuthService] Tokens sauvegardés avec succès');
    } catch (e) {
      debugPrint('❌ [AuthService] Erreur lors de la sauvegarde des tokens: $e');
      throw Exception('Impossible de sauvegarder les tokens: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      final token = await TokenStore.readAccess();
      if (token != null && token.isNotEmpty) {
        debugPrint('🔍 [AuthService] Token trouvé: ${token.substring(0, 20)}...');

        if (await isTokenExpired()) {
          debugPrint(
            '⏰ [AuthService] Token expiré, tentative de refresh automatique',
          );

          final refreshToken = await getRefreshToken();
          if (refreshToken != null && refreshToken.isNotEmpty) {
            try {
              // MUTEX indispensable : au démarrage, des dizaines d'appels
              // getToken() partent en parallèle. Avec la ROTATION côté
              // serveur, deux refresh concurrents = le second part avec un
              // refresh token déjà révoqué → 401 → déconnexion aléatoire.
              // Tous les appelants attendent donc le MÊME refresh.
              _refreshInFlight ??= this
                  .refreshToken(refreshToken)
                  .then((newTokens) async {
                    await saveTokens(
                      newTokens['access_token']!,
                      newTokens['refresh_token']!,
                    );
                    debugPrint('✅ [AuthService] Token refreshé automatiquement');
                    return newTokens;
                  })
                  .whenComplete(() => _refreshInFlight = null);
              final newTokens = await _refreshInFlight!;
              return newTokens['access_token'];
            } catch (e) {
              debugPrint('❌ [AuthService] Échec du refresh automatique: $e');
              // Ne purger la session que sur un refus explicite du serveur
              // (token révoqué/expiré). Un échec réseau transitoire ne doit
              // pas déconnecter l'utilisateur.
              if (e.toString().contains('Refresh token invalide')) {
                await clearUserData();
              }
              return null;
            }
          }
          return null;
        }
        return token;
      } else {
        debugPrint('❌ [AuthService] Aucun token trouvé dans le cache');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [AuthService] Erreur lors de la récupération du token: $e');
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await TokenStore.readRefresh();
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
        debugPrint('❌ [AuthService] Token expiré: $expiryDate');
      } else {
        final timeLeft = expiryDate.difference(DateTime.now());
        debugPrint(
          '✅ [AuthService] Token valide, expire dans: ${timeLeft.inDays}j ${timeLeft.inHours % 24}h',
        );
      }

      return isExpired;
    } catch (e) {
      debugPrint('❌ [AuthService] Erreur lors de la vérification d\'expiration: $e');
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
      debugPrint('🔵 [AuthService] Début de la connexion Google...');

      // 1. Obtenir les credentials Google
      final SSOResult result = await SSOService.signInWithGoogle();

      if (!result.success) {
        debugPrint('❌ [AuthService] Échec SSO Google: ${result.error}');
        throw AuthenticationException(
          result.error ?? 'Erreur lors de la connexion Google',
          'GOOGLE_SIGNIN_FAILED',
        );
      }

      if (result.idToken == null || result.userInfo == null) {
        debugPrint('❌ [AuthService] Données Google incomplètes');
        throw AuthenticationException(
          'Informations Google incomplètes',
          'GOOGLE_INCOMPLETE_DATA',
        );
      }

      // Ne jamais logguer le token ni l'email : visibles en release via `adb logcat`
      debugPrint('✅ [AuthService] Credentials Google obtenus, envoi au serveur...');

      // 2. Envoyer les credentials au serveur
      final response = await dio.post(
        '/auth/sso/google/login',
        data: {
          'id_token': result.idToken,
          'access_token': result.accessToken,
          'user_info': result.userInfo!.toMap(),
        },
      );

      // La réponse contient access_token et refresh_token : ne pas la logguer
      debugPrint('📡 [AuthService] Réponse serveur: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;

        // ✅ VÉRIFICATION STRICTE DES TOKENS
        final accessToken = data['access_token'] as String?;
        final refreshToken = data['refresh_token'] as String?;

        if (accessToken == null || accessToken.isEmpty) {
          debugPrint('❌ [AuthService] Access token manquant');
          throw AuthenticationException(
            'Access token manquant',
            'MISSING_ACCESS_TOKEN',
          );
        }

        if (refreshToken == null || refreshToken.isEmpty) {
          debugPrint('❌ [AuthService] Refresh token manquant');
          throw AuthenticationException(
            'Refresh token manquant',
            'MISSING_REFRESH_TOKEN',
          );
        }

        debugPrint('✅ [AuthService] Tokens reçus:');
        debugPrint('  Access: ${accessToken.substring(0, 30)}...');
        debugPrint('  Refresh: ${refreshToken.substring(0, 30)}...');

        // ✅ SAUVEGARDER LES TOKENS EN PREMIER
        await saveTokens(accessToken, refreshToken);

        // ✅ CRÉER L'UTILISATEUR DEPUIS LA RÉPONSE
        final user = User.fromLoginResponse({
          'access_token': accessToken,
          'refresh_token': refreshToken,
          'data': data['data'],
        });

        debugPrint('✅ [AuthService] Utilisateur créé: ${user.fullName}');

        // ✅ SAUVEGARDER L'UTILISATEUR
        await saveUserToCache(user);
        await _saveSSOInfo('google', result.userInfo!);

        debugPrint('✅ [AuthService] Connexion Google terminée avec succès');

        return {'access_token': accessToken, 'refresh_token': refreshToken};
      } else {
        debugPrint(
          '❌ [AuthService] Code de réponse inattendu: ${response.statusCode}',
        );
        throw AuthenticationException(
          'Erreur de connexion Google',
          'GOOGLE_LOGIN_FAILED',
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '❌ [AuthService] Erreur Dio Google: ${e.response?.statusCode} - ${e.response?.data}',
      );
      return _handleSSODioException(e, 'google');
    } catch (e) {
      debugPrint('❌ [AuthService] Erreur générale Google: $e');

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
      debugPrint('🍎 [AuthService] Début de la connexion Apple...');

      // 1. Vérification de plateforme
      if (!Platform.isIOS) {
        debugPrint('⚠️ [AuthService] Apple Sign-In tenté sur plateforme non-iOS');
        // Ne pas lancer d'exception, essayer quand même
      }

      // 2. Obtenir les credentials Apple
      final SSOResult result = await SSOService.signInWithApple();

      if (!result.success) {
        debugPrint('❌ [AuthService] Échec SSO Apple: ${result.error}');
        throw AuthenticationException(
          result.error ?? 'Erreur lors de la connexion Apple',
          'APPLE_SIGNIN_FAILED',
        );
      }

      if (result.idToken == null || result.userInfo == null) {
        debugPrint('❌ [AuthService] Données Apple incomplètes');
        throw AuthenticationException(
          'Informations Apple incomplètes',
          'APPLE_INCOMPLETE_DATA',
        );
      }

      // Ne jamais logguer le token ni l'email : visibles en release via `adb logcat`
      debugPrint('✅ [AuthService] Credentials Apple obtenus, envoi au serveur...');

      // 3. Envoyer les credentials au serveur
      final response = await dio.post(
        '/auth/sso/apple/login',
        data: {
          'id_token': result.idToken,
          'authorization_code': result.accessToken,
          'user_info': result.userInfo!.toMap(),
        },
      );

      debugPrint('📡 [AuthService] Réponse serveur Apple: ${response.statusCode}');

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

        debugPrint('✅ [AuthService] Tokens Apple reçus:');
        debugPrint('  Access: ${accessToken.substring(0, 30)}...');
        debugPrint('  Refresh: ${refreshToken.substring(0, 30)}...');

        await saveTokens(accessToken, refreshToken);

        final user = User.fromLoginResponse({
          'access_token': accessToken,
          'refresh_token': refreshToken,
          'data': data['data'],
        });

        await saveUserToCache(user);
        await _saveSSOInfo('apple', result.userInfo!);

        debugPrint('✅ [AuthService] Connexion Apple terminée avec succès');

        return {'access_token': accessToken, 'refresh_token': refreshToken};
      } else {
        throw AuthenticationException(
          'Erreur de connexion Apple',
          'APPLE_LOGIN_FAILED',
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '❌ [AuthService] Erreur Dio Apple: ${e.response?.statusCode} - ${e.response?.data}',
      );
      return _handleSSODioException(e, 'apple');
    } catch (e) {
      debugPrint('❌ [AuthService] Erreur générale Apple: $e');

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
      debugPrint('🔵 [AuthService] Début de l\'inscription Google...');

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

      debugPrint(
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

      debugPrint('✅ [AuthService] Inscription Google réussie');
    } on DioException catch (e) {
      debugPrint(
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
      debugPrint('🍎 [AuthService] Début de l\'inscription Apple...');

      // Vérification de plateforme (warning, pas d'exception)
      if (!Platform.isIOS) {
        debugPrint(
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

      debugPrint('✅ [AuthService] Credentials Apple obtenus, création du compte...');

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

      debugPrint('✅ [AuthService] Inscription Apple réussie');
    } on DioException catch (e) {
      debugPrint(
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
      debugPrint('🔗 [AuthService] Liaison d\'un compte $provider...');

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
        debugPrint('✅ [AuthService] Compte $provider lié avec succès');
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
      debugPrint('🔗❌ [AuthService] Déliaison du compte $provider...');

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

        debugPrint('✅ [AuthService] Compte $provider délié avec succès');
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
      debugPrint('💾 [AuthService] Informations SSO sauvegardées pour $provider');
    } catch (e) {
      debugPrint('❌ [AuthService] Erreur lors de la sauvegarde SSO: $e');
    }
  }

  /// Supprimer les informations SSO
  Future<void> _removeSSOInfo(String provider) async {
    try {
      await sharedPreferences.remove(_ssoProviderKey);
      await sharedPreferences.remove(_ssoUserInfoKey);
      debugPrint('🗑️ [AuthService] Informations SSO supprimées pour $provider');
    } catch (e) {
      debugPrint('❌ [AuthService] Erreur lors de la suppression SSO: $e');
    }
  }

  /// Obtenir le provider SSO actuel
  Future<String?> getCurrentSSOProvider() async {
    try {
      return sharedPreferences.getString(_ssoProviderKey);
    } catch (e) {
      debugPrint(
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
      debugPrint('❌ [AuthService] Erreur lors de la récupération des infos SSO: $e');
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
    debugPrint(
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
  /// Deuxième étape de connexion (2FA par email) : échange le code à
  /// 6 chiffres contre les jetons, puis met le cache à jour comme un
  /// login normal.
  Future<Map<String, String>> verifyTwoFactor(String email, String code) async {
    try {
      final response = await dio.post(
        '/auth/2fa/verify',
        data: {'email': email, 'code': code},
      );

      final data = response.data;
      final accessToken = data['access_token'] as String?;
      final refreshToken = data['refresh_token'] as String?;
      if (accessToken == null || refreshToken == null) {
        throw AuthenticationException('Tokens manquants', 'MISSING_TOKENS');
      }

      await saveTokens(accessToken, refreshToken);
      await saveUserToCache(User.fromLoginResponse({
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'data': data['data'],
      }));

      return {'access_token': accessToken, 'refresh_token': refreshToken};
    } on DioException catch (e) {
      final code = (e.response?.data is Map)
          ? e.response?.data['code'] as String?
          : null;
      if (e.response?.statusCode == 429) {
        throw AuthenticationException(
          'Trop de tentatives. Réessayez plus tard.', 'TOO_MANY_ATTEMPTS');
      }
      throw AuthenticationException(
        code == 'INVALID_CODE' ? 'Code invalide ou expiré' : 'Vérification impossible',
        code ?? 'VERIFY_FAILED',
      );
    }
  }

  /// Réglage « vérification en deux étapes » du compte connecté.
  Future<bool> getTwoFactorEnabled() async {
    final res = await dio.get('/auth/2fa');
    return res.data['data']['enabled'] as bool? ?? false;
  }

  /// Active ou désactive le 2FA. Le mot de passe courant est exigé par
  /// le serveur : un appareil déverrouillé ne suffit pas.
  Future<void> setTwoFactorEnabled(bool enabled, String password) async {
    await dio.post('/auth/2fa', data: {'enabled': enabled, 'password': password});
  }

  Future<Map<String, String>> login(String email, String password) async {
    try {
      debugPrint('🔐 [AuthService] Début du login classique...');

      final response = await dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // La réponse contient les tokens : ne pas la logguer

        // Vérification en deux étapes activée sur ce compte : le serveur
        // répond 200 SANS jeton, un code vient de partir par email.
        if (data['code'] == 'TWO_FACTOR_REQUIRED') {
          throw AuthenticationException(
            'Code de vérification requis',
            'TWO_FACTOR_REQUIRED',
            email: (data['data']?['email'] as String?) ?? email,
          );
        }

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
        debugPrint('✅ [AuthService] Login classique réussi');

        return {'access_token': accessToken, 'refresh_token': refreshToken};
      } else {
        throw AuthenticationException('Erreur de connexion', 'LOGIN_FAILED');
      }
    } on DioException catch (e) {
      debugPrint(
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
      debugPrint('❌ [AuthService] Erreur inattendue login: $e');
      throw AuthenticationException(
        'Une erreur inattendue est survenue',
        'UNKNOWN_ERROR',
      );
    }
  }

  Future<Map<String, String>> refreshToken(String refreshToken) async {
    try {
      debugPrint('🔄 [AuthService] Tentative de refresh du token...');

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

        debugPrint('✅ [AuthService] Token refreshé avec succès');

        return {
          'access_token': newAccessToken,
          'refresh_token': newRefreshToken,
        };
      } else {
        throw Exception('Échec du rafraîchissement du token');
      }
    } on DioException catch (e) {
      debugPrint(
        '❌ [AuthService] Erreur refresh: ${e.response?.statusCode} - ${e.message}',
      );
      if (e.response?.statusCode == 401) {
        throw Exception('Refresh token invalide ou expiré');
      }
      throw Exception('Erreur réseau lors du refresh: ${e.message}');
    }
  }

  /// Profil mis en cache, lecture STRICTEMENT locale (aucun réseau).
  /// Sert au démarrage : afficher l'application sans attendre le serveur.
  User? cachedUser() {
    try {
      final raw = sharedPreferences.getString(_userKey);
      if (raw == null || raw.isEmpty) return null;
      return User.fromJsonString(raw);
    } catch (e) {
      debugPrint('❌ [AuthService] Cache utilisateur illisible: $e');
      return null;
    }
  }

  /// Une session est-elle stockée sur l'appareil ? Ne déclenche AUCUN
  /// rafraîchissement : on veut juste savoir s'il y a de quoi continuer.
  Future<bool> hasStoredSession() async {
    try {
      final access = await TokenStore.readAccess();
      if (access != null && access.isNotEmpty) return true;
      final refresh = await TokenStore.readRefresh();
      return refresh != null && refresh.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isAuthenticated() async {
    try {
      final accessToken = await getToken();
      final result = accessToken != null && accessToken.isNotEmpty;
      debugPrint('🔍 [AuthService] Authentifié: $result');
      return result;
    } catch (e) {
      debugPrint('❌ [AuthService] Erreur vérification auth: $e');
      return false;
    }
  }

  Future<void> saveUserToCache(User user) async {
    try {
      await sharedPreferences.setString(_userKey, user.toJsonString());
      debugPrint(
        '💾 [AuthService] Utilisateur sauvegardé en cache: ${user.fullName}',
      );
    } catch (e) {
      debugPrint('❌ [AuthService] Erreur sauvegarde utilisateur: $e');
    }
  }

  /// [forceRefresh] : ignore le cache et interroge /auth/me (puis met le
  /// cache a jour). Indispensable apres un changement serveur (avatar,
  /// profil) — sinon le cache ecrit au login ne se rafraichit JAMAIS.
  Future<User?> getCurrentUser({bool forceRefresh = false}) async {
    try {
      // D'abord essayer le cache (sauf rafraichissement force)
      final cachedUserData =
          forceRefresh ? null : sharedPreferences.getString(_userKey);
      if (cachedUserData != null && cachedUserData.isNotEmpty) {
        try {
          final userData = User.fromJsonString(cachedUserData);
          debugPrint(
            '💾 [AuthService] Utilisateur récupéré depuis le cache: ${userData.fullName}',
          );
          return userData;
        } catch (e) {
          debugPrint('❌ [AuthService] Erreur lecture cache utilisateur: $e');
        }
      }

      // Sinon appeler l'API
      final token = await getToken();
      if (token == null) {
        debugPrint('❌ [AuthService] Aucun token pour getCurrentUser');
        return null;
      }

      debugPrint('📡 [AuthService] Récupération utilisateur depuis l\'API...');
      final response = await dio.get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final user = User.fromMap(response.data);
        await saveUserToCache(user);
        debugPrint(
          '✅ [AuthService] Utilisateur récupéré depuis l\'API: ${user.fullName}',
        );
        return user;
      }

      return null;
    } on DioException catch (e) {
      debugPrint(
        '❌ [AuthService] Erreur getCurrentUser: ${e.response?.statusCode} - ${e.message}',
      );
      if (e.response?.statusCode == 401) {
        await clearUserData();
      }
      return null;
    }
  }

  Future<void> logout() async {
    debugPrint('🚀 [AuthService] Début du logout...');

    try {
      // Révocation serveur du refresh token : la déconnexion n'est plus
      // seulement locale. Jamais bloquant (hors ligne = nettoyage local).
      try {
        final refreshToken = await TokenStore.readRefresh();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await dio
              .post('/auth/logout', data: {'refresh_token': refreshToken})
              .timeout(const Duration(seconds: 4));
        }
      } catch (_) {}

      final ssoProvider = await getCurrentSSOProvider();
      if (ssoProvider != null) {
        debugPrint('🔄 [AuthService] Déconnexion SSO ($ssoProvider)...');

        if (ssoProvider == 'google') {
          await SSOService.signOutGoogle();
        } else if (ssoProvider == 'apple') {
          await SSOService.signOutApple();
        }

        await _removeSSOInfo(ssoProvider);
        debugPrint('✅ [AuthService] Déconnexion SSO terminée');
      }

      await clearUserData();
      debugPrint('✅ [AuthService] Logout terminé');
    } catch (e) {
      debugPrint('❌ [AuthService] Erreur logout: $e');
      try {
        await clearUserData();
        await SSOService.signOutAll();
      } catch (clearError) {
        debugPrint('❌ [AuthService] Erreur nettoyage de secours: $clearError');
      }
    }
  }

  Future<void> clearUserData() async {
    try {
      // Couper le push AVANT d'effacer la session : il faut encore le
      // jeton pour que le serveur accepte la désactivation. Sans cela,
      // l'appareil continue de recevoir les notifications du compte
      // précédent (constat C3 de l'audit des notifications).
      await NotificationService.deactivateDeviceOnServer();

      await TokenStore.clear();
      // Retour à l'espace personnel : l'espace actif appartient à la
      // session de CE compte, pas au suivant.
      await ActiveSpaceStore.clear();
      // Les données affichées par les écrans appartiennent à CE compte.
      ScreenCache.clear();
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

      debugPrint('🧹 [AuthService] Données utilisateur effacées (incluant SSO)');
    } catch (e) {
      debugPrint('❌ [AuthService] Erreur nettoyage: $e');
      try {
        await sharedPreferences.clear();
      } catch (clearError) {
        debugPrint('❌ [AuthService] Erreur clear global: $clearError');
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
