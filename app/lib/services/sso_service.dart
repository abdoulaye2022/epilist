// services/sso_service.dart - VERSION AVEC APPLE COMMENTÉ POUR ANDROID
import 'dart:io';
import 'dart:math';
import 'package:google_sign_in/google_sign_in.dart';
// ❌ APPLE IMPORT COMMENTÉ POUR ANDROID
// import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class SSOException implements Exception {
  final String message;
  final String provider;
  final String? details;

  SSOException(this.message, this.provider, {this.details});

  @override
  String toString() => '$provider SSO Error: $message';
}

class SSOUserInfo {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final String? photoUrl;
  final String provider;

  SSOUserInfo({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.displayName,
    this.photoUrl,
    required this.provider,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'display_name': displayName,
      'photo_url': photoUrl,
      'provider': provider,
    };
  }
}

class SSOResult {
  final bool success;
  final String? idToken;
  final String? accessToken;
  final SSOUserInfo? userInfo;
  final String? error;

  SSOResult({
    required this.success,
    this.idToken,
    this.accessToken,
    this.userInfo,
    this.error,
  });

  factory SSOResult.success({
    required String idToken,
    String? accessToken,
    required SSOUserInfo userInfo,
  }) {
    return SSOResult(
      success: true,
      idToken: idToken,
      accessToken: accessToken,
      userInfo: userInfo,
    );
  }

  factory SSOResult.error(String error) {
    return SSOResult(success: false, error: error);
  }
}

class SSOService {
  static GoogleSignIn? _googleSignIn;

  // ✅ Configuration Google Sign-In pour iOS/Android
  static GoogleSignIn _getGoogleSignIn() {
    if (_googleSignIn == null) {
      print('🔵 [SSOService] Initialisation GoogleSignIn...');

      try {
        _googleSignIn = GoogleSignIn(
          scopes: <String>['email', 'profile'], // ✅ Scopes basiques
          signInOption: SignInOption.standard,

          // ✅ FORCE Android Client ID explicitement
          serverClientId:
              '695717834998-kshi4umfi4asq3ubna6s3es9ti0ij8d6.apps.googleusercontent.com',
        );

        print(
          '✅ [SSOService] GoogleSignIn initialisé AVEC Android Client ID forcé',
        );
        print(
          '🔧 [DEBUG] ServerClientId configuré: ${_googleSignIn!.serverClientId}',
        );
      } catch (e) {
        print('❌ [SSOService] Erreur initialisation: $e');
        rethrow;
      }
    }
    return _googleSignIn!;
  }

  // ===================== GOOGLE SIGN-IN =====================

  /// ✅ Connexion Google optimisée pour iOS/Android
  static Future<SSOResult> signInWithGoogle() async {
    print('🔵 [SSOService] === DÉBUT CONNEXION GOOGLE ===');

    try {
      // ✅ ÉTAPE 1: Vérification plateforme
      print('🔵 [SSOService] Plateforme détectée: ${Platform.operatingSystem}');

      // ✅ ÉTAPE 2: Nettoyage OBLIGATOIRE
      print('🔵 [SSOService] Nettoyage Google Sign-In...');
      await _forceCleanGoogleSignIn();

      // ✅ ÉTAPE 3: Nouvelle instance avec config
      print('🔵 [SSOService] Création nouvelle instance GoogleSignIn...');
      final googleSignIn = _getGoogleSignIn();

      // ✅ ÉTAPE 4: Vérification de la disponibilité
      print('🔵 [SSOService] Vérification disponibilité Google Sign-In...');

      // Sur iOS, vérifier que l'app Google est installée ou utiliser web view
      if (Platform.isIOS) {
        print(
          '🔵 [SSOService] Configuration iOS - vérification des schemes URL...',
        );
      }

      // ✅ ÉTAPE 5: Tentative de connexion avec timeout adapté
      final timeoutDuration =
          Platform.isIOS
              ? const Duration(minutes: 3) // Plus long sur iOS
              : const Duration(minutes: 2); // Standard sur Android

      print(
        '🔵 [SSOService] Lancement connexion Google (timeout: ${timeoutDuration.inMinutes}min)...',
      );

      final GoogleSignInAccount?
      googleUser = await googleSignIn.signIn().timeout(
        timeoutDuration,
        onTimeout: () {
          throw Exception(
            'Timeout Google Sign-In après ${timeoutDuration.inMinutes} minutes. '
            'Vérifiez votre connexion internet.',
          );
        },
      );

      if (googleUser == null) {
        print('❌ [SSOService] Connexion annulée par l\'utilisateur');
        return SSOResult.error('Connexion annulée par l\'utilisateur');
      }

      print('✅ [SSOService] Utilisateur Google connecté: ${googleUser.email}');
      print('🔵 [SSOService] ID utilisateur: ${googleUser.id}');
      print(
        '🔵 [SSOService] Nom affiché: ${googleUser.displayName ?? "Non fourni"}',
      );

      // ✅ ÉTAPE 6: Récupération tokens avec stratégie de retry
      print('🔵 [SSOService] Récupération des tokens d\'authentification...');

      GoogleSignInAuthentication? googleAuth;
      String? validIdToken;
      String? validAccessToken;

      // ✅ STRATÉGIE DE RETRY
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          print('🔵 [SSOService] Tentative $attempt/3 récupération tokens...');

          // ✅ Clear auth cache avant chaque tentative sur iOS
          if (Platform.isIOS && attempt > 1) {
            print('🔵 [SSOService] Nettoyage cache auth iOS...');
            await googleUser.clearAuthCache();
            await Future.delayed(Duration(seconds: attempt));
          }

          googleAuth = await googleUser.authentication.timeout(
            const Duration(minutes: 2),
            onTimeout: () => throw Exception('Timeout récupération tokens'),
          );

          print('🔵 [SSOService] Tokens récupérés:');
          print(
            '  - ID Token: ${googleAuth.idToken?.isNotEmpty == true ? "✅ Présent" : "❌ Manquant"}',
          );
          print(
            '  - Access Token: ${googleAuth.accessToken?.isNotEmpty == true ? "✅ Présent" : "❌ Manquant"}',
          );

          // ✅ VALIDATION STRICTE DU TOKEN
          if (googleAuth.idToken != null && googleAuth.idToken!.isNotEmpty) {
            // Validation format JWT
            if (_isValidJWT(googleAuth.idToken!)) {
              print('✅ [SSOService] Format JWT valide');

              // Validation expiration
              if (_isTokenNotExpired(googleAuth.idToken!)) {
                print('✅ [SSOService] Token non expiré');

                // ✅ VALIDATION SPÉCIFIQUE iOS
                if (Platform.isIOS &&
                    _validateTokenForIOS(googleAuth.idToken!)) {
                  validIdToken = googleAuth.idToken!;
                  validAccessToken = googleAuth.accessToken;
                  print(
                    '✅ [SSOService] Token iOS validé avec succès (tentative $attempt)',
                  );
                  break;
                } else if (!Platform.isIOS) {
                  validIdToken = googleAuth.idToken!;
                  validAccessToken = googleAuth.accessToken;
                  print(
                    '✅ [SSOService] Token Android validé avec succès (tentative $attempt)',
                  );
                  break;
                } else {
                  print(
                    '⚠️ [SSOService] Token iOS non valide (tentative $attempt) - Retry...',
                  );
                }
              } else {
                print(
                  '⚠️ [SSOService] Token expiré (tentative $attempt) - Retry...',
                );
              }
            } else {
              print(
                '⚠️ [SSOService] Format JWT invalide (tentative $attempt) - Retry...',
              );
            }
          } else {
            print('⚠️ [SSOService] Token vide (tentative $attempt) - Retry...');
          }

          // ✅ Attente progressive avant retry
          if (attempt < 3) {
            final waitTime = Duration(seconds: attempt * 2);
            print(
              '🔵 [SSOService] Attente ${waitTime.inSeconds}s avant retry...',
            );
            await Future.delayed(waitTime);
          }
        } catch (authError) {
          print('❌ [SSOService] Erreur tentative $attempt: $authError');
          if (attempt == 3) {
            rethrow;
          }
        }
      }

      // ✅ Vérification finale
      if (validIdToken == null || validIdToken.isEmpty) {
        print(
          '❌ [SSOService] ÉCHEC: Impossible de récupérer un token Google valide',
        );
        return SSOResult.error(
          'Impossible de récupérer un token Google valide après 3 tentatives. '
          'Essayez de redémarrer l\'application ou vérifiez votre configuration.',
        );
      }

      // ✅ ÉTAPE 7: Validation finale et informations utilisateur
      print('🔵 [SSOService] Création informations utilisateur...');

      final tokenInfo = _decodeJWT(validIdToken);
      print('🔵 [SSOService] Informations token:');
      print('  - Issuer: ${tokenInfo?['iss']}');
      print('  - Audience: ${tokenInfo?['aud']}');
      print('  - Email: ${tokenInfo?['email']}');
      print('  - Vérifié: ${tokenInfo?['email_verified']}');

      final SSOUserInfo userInfo = SSOUserInfo(
        id: googleUser.id,
        email: googleUser.email,
        firstName: googleUser.displayName?.split(' ').first,
        lastName: googleUser.displayName?.split(' ').skip(1).join(' '),
        displayName: googleUser.displayName,
        photoUrl: googleUser.photoUrl,
        provider: 'google',
      );

      print('✅ [SSOService] === CONNEXION GOOGLE RÉUSSIE ===');
      print('🔵 [SSOService] Email: ${userInfo.email}');
      print('🔵 [SSOService] Nom: ${userInfo.displayName ?? "Non fourni"}');
      print('🔵 [SSOService] Token longueur: ${validIdToken.length} chars');

      return SSOResult.success(
        idToken: validIdToken,
        accessToken: validAccessToken,
        userInfo: userInfo,
      );
    } catch (e) {
      print('❌ [SSOService] ERREUR CRITIQUE GOOGLE: $e');

      // ✅ Messages d'erreur spécifiques
      String errorMessage = 'Erreur lors de la connexion Google';

      if (e.toString().contains('network')) {
        errorMessage =
            'Problème de connexion réseau. Vérifiez votre connexion internet.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'La connexion a pris trop de temps. Réessayez.';
      } else if (e.toString().contains('cancelled')) {
        errorMessage = 'Connexion annulée.';
      } else if (Platform.isIOS && e.toString().contains('configuration')) {
        errorMessage = 'Problème de configuration Google Sign-In sur iOS.';
      }

      return SSOResult.error(errorMessage);
    }
  }

  // ✅ MÉTHODES DE VALIDATION

  /// Nettoyage complet forcé
  static Future<void> _forceCleanGoogleSignIn() async {
    try {
      print('🧹 [SSOService] Nettoyage complet Google Sign-In...');

      if (_googleSignIn != null) {
        try {
          // ✅ Déconnexion complète
          await _googleSignIn!.signOut();
          await _googleSignIn!.disconnect();
          print('🧹 [SSOService] Déconnexion Google terminée');
        } catch (e) {
          print('⚠️ [SSOService] Erreur déconnexion Google (normale): $e');
        }
      }

      // ✅ Reset instance
      _googleSignIn = null;

      // ✅ Attente plus longue sur iOS pour la propagation
      final waitTime =
          Platform.isIOS
              ? const Duration(seconds: 3)
              : const Duration(seconds: 1);
      await Future.delayed(waitTime);

      print('✅ [SSOService] Nettoyage terminé');
    } catch (e) {
      print('⚠️ [SSOService] Erreur nettoyage (peut être ignorée): $e');
    }
  }

  /// Validation spécifique iOS
  static bool _validateTokenForIOS(String token) {
    if (!Platform.isIOS) return true;

    try {
      final payload = _decodeJWT(token);
      if (payload == null) return false;

      // ✅ Vérifications spécifiques iOS
      final audience = payload['aud'] as String?;
      final issuer = payload['iss'] as String?;
      final email = payload['email'] as String?;
      final emailVerified = payload['email_verified'];

      // Vérifier audience (doit contenir votre client ID)
      if (audience == null ||
          !audience.contains('695717834998-s125mgv17n96b59d9u7jh4eham2kp9lo')) {
        print('❌ [SSOService] Audience iOS invalide: $audience');
        return false;
      }

      // Vérifier issuer Google
      if (issuer != 'https://accounts.google.com' &&
          issuer != 'accounts.google.com') {
        print('❌ [SSOService] Issuer iOS invalide: $issuer');
        return false;
      }

      // Vérifier email vérifié
      if (emailVerified != true && emailVerified != 'true') {
        print('❌ [SSOService] Email non vérifié iOS: $emailVerified');
        return false;
      }

      print('✅ [SSOService] Token iOS valide pour serveur');
      return true;
    } catch (e) {
      print('❌ [SSOService] Erreur validation iOS: $e');
      return false;
    }
  }

  /// Validation JWT améliorée
  static bool _isValidJWT(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        print(
          '❌ [SSOService] JWT: nombre de parties incorrect (${parts.length})',
        );
        return false;
      }

      // Vérification header
      final header = _decodeBase64(parts[0]);
      if (header == null || !header.containsKey('alg')) {
        print('❌ [SSOService] JWT: header invalide');
        return false;
      }

      // Vérification payload
      final payload = _decodeBase64(parts[1]);
      if (payload == null || !payload.containsKey('iss')) {
        print('❌ [SSOService] JWT: payload invalide');
        return false;
      }

      return true;
    } catch (e) {
      print('❌ [SSOService] Erreur validation JWT: $e');
      return false;
    }
  }

  /// Vérification expiration token
  static bool _isTokenNotExpired(String token) {
    try {
      final payload = _decodeJWT(token);
      if (payload == null || !payload.containsKey('exp')) return false;

      final exp = payload['exp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Buffer de 5 minutes
      final isValid = exp > (now + 300);

      if (!isValid) {
        final expTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        print(
          '❌ [SSOService] Token expiré à: $expTime (maintenant: ${DateTime.now()})',
        );
      }

      return isValid;
    } catch (e) {
      print('❌ [SSOService] Erreur vérification expiration: $e');
      return false;
    }
  }

  /// Décoder JWT payload
  static Map<String, dynamic>? _decodeJWT(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      return _decodeBase64(parts[1]);
    } catch (e) {
      return null;
    }
  }

  /// Décoder base64
  static Map<String, dynamic>? _decodeBase64(String str) {
    try {
      // Padding correct
      String normalized = str.replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }

      final decoded = base64Decode(normalized);
      final jsonStr = utf8.decode(decoded);

      return json.decode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// ✅ Déconnexion améliorée
  static Future<void> signOutGoogle() async {
    try {
      print('🔵 [SSOService] Déconnexion Google complète...');
      await _forceCleanGoogleSignIn();
      print('✅ [SSOService] Déconnexion Google terminée');
    } catch (e) {
      print('❌ [SSOService] Erreur déconnexion Google: $e');
    }
  }

  // ===================== APPLE SIGN-IN COMMENTÉ POUR ANDROID =====================

  // ❌ APPLE SIGN-IN COMPLÈTEMENT COMMENTÉ
  /*
  static Future<SSOResult> signInWithApple() async {
    try {
      print('🍎 [SSOService] Début connexion Apple...');

      if (!Platform.isIOS) {
        return SSOResult.error('Apple Sign-In uniquement disponible sur iOS');
      }

      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        return SSOResult.error('Apple Sign-In non disponible sur cet appareil');
      }

      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final timeoutDuration =
          kDebugMode ? const Duration(minutes: 3) : const Duration(seconds: 60);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      ).timeout(timeoutDuration);

      final userIdentifier = credential.userIdentifier;
      final identityToken = credential.identityToken;

      if (userIdentifier == null || identityToken == null) {
        throw SSOException('Apple credentials manquants', 'apple');
      }

      final email =
          credential.email ?? '${userIdentifier}@privaterelay.appleid.com';
      final firstName = credential.givenName ?? '';
      final lastName = credential.familyName ?? '';
      final displayName = '$firstName $lastName'.trim();

      final userInfo = SSOUserInfo(
        id: userIdentifier,
        email: email,
        firstName: firstName.isNotEmpty ? firstName : null,
        lastName: lastName.isNotEmpty ? lastName : null,
        displayName: displayName.isNotEmpty ? displayName : null,
        photoUrl: null,
        provider: 'apple',
      );

      return SSOResult.success(
        idToken: identityToken,
        accessToken: credential.authorizationCode,
        userInfo: userInfo,
      );
    } catch (e) {
      print('❌ [SSOService] Erreur Apple: $e');
      return SSOResult.error('Erreur Apple: ${e.toString()}');
    }
  }

  static Future<void> signOutApple() async {
    print('🍎 [SSOService] Apple Sign-Out (géré automatiquement)');
  }
  */

  // ✅ MÉTHODES APPLE STUB POUR COMPATIBILITÉ ANDROID
  static Future<SSOResult> signInWithApple() async {
    print('❌ [SSOService] Apple Sign-In non disponible sur Android');
    return SSOResult.error('Apple Sign-In non disponible sur Android');
  }

  static Future<void> signOutApple() async {
    print('❌ [SSOService] Apple Sign-Out non disponible sur Android');
  }

  // ===================== MÉTHODES UTILITAIRES =====================

  // ❌ MÉTHODES UTILITAIRES APPLE COMMENTÉES
  /*
  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  */

  // ✅ STUBS POUR COMPATIBILITÉ
  static String _generateNonce([int length = 32]) {
    // Méthode stub pour compatibilité
    return '';
  }

  static String _sha256ofString(String input) {
    // Méthode stub pour compatibilité
    return '';
  }

  static Future<void> signOutAll() async {
    try {
      await signOutGoogle();
      await signOutApple(); // Stub pour Android
      print('✅ [SSOService] Déconnexion complète SSO');
    } catch (e) {
      print('❌ [SSOService] Erreur déconnexion SSO: $e');
    }
  }

  // ✅ MÉTHODES DE DIAGNOSTIC

  /// Diagnostic général (iOS/Android)
  static Future<void> diagnoseGoogleProblem() async {
    print('🔍 === DIAGNOSTIC SSO GOOGLE ===');

    try {
      print('📱 Plateforme: ${Platform.operatingSystem}');
      print('📱 Version: ${Platform.operatingSystemVersion}');
      print('📱 Mode debug: $kDebugMode');

      // Test configuration
      print('\n🔧 === TEST CONFIGURATION ===');
      final googleSignIn = _getGoogleSignIn();
      print('✅ GoogleSignIn initialisé');
      print('📱 Scopes: ${googleSignIn.scopes}');
      print(
        '📱 Server Client ID configuré: ${googleSignIn.serverClientId != null}',
      );

      // Test disponibilité
      print('\n🔵 === TEST DISPONIBILITÉ ===');
      try {
        final isSignedIn = await googleSignIn.isSignedIn();
        print('📱 État actuel: $isSignedIn');

        if (isSignedIn) {
          final user = googleSignIn.currentUser;
          if (user != null) {
            print('📱 Utilisateur actuel: ${user.email}');

            try {
              final auth = await user.authentication;
              if (auth.idToken != null) {
                print('📱 Token présent: ${auth.idToken!.length} chars');

                final isValid = _isValidJWT(auth.idToken!);
                final notExpired = _isTokenNotExpired(auth.idToken!);
                final tokenValid =
                    Platform.isIOS ? _validateTokenForIOS(auth.idToken!) : true;

                print('📱 JWT valide: $isValid');
                print('📱 Non expiré: $notExpired');
                print('📱 Compatible serveur: $tokenValid');

                if (!tokenValid) {
                  final payload = _decodeJWT(auth.idToken!);
                  print('📱 Token details: $payload');
                }
              }
            } catch (tokenError) {
              print('❌ Erreur récupération token: $tokenError');
            }
          }
        }
      } catch (e) {
        print('❌ Erreur test disponibilité: $e');
      }

      print('\n💡 === RECOMMANDATIONS ===');
      if (Platform.isAndroid) {
        print('📱 1. Vérifiez google-services.json dans android/app/');
        print('📱 2. Vérifiez SHA-1 fingerprints dans Firebase Console');
        print('📱 3. Vérifiez les permissions dans AndroidManifest.xml');
      } else if (Platform.isIOS) {
        print('📱 1. Vérifiez GoogleService-Info.plist dans Bundle Resources');
        print('📱 2. Vérifiez URL Schemes dans Info.plist');
        print('📱 3. Vérifiez serverClientId dans la configuration');
      }
      print('📱 4. Testez après nettoyage complet et redémarrage app');
      print('📱 5. Vérifiez la connexion internet');
    } catch (e) {
      print('❌ ERREUR DIAGNOSTIC: $e');
    }

    print('🔍 === FIN DIAGNOSTIC ===');
  }

  /// Diagnostic spécifique iOS (commenté mais gardé pour référence)
  // ❌ DIAGNOSTIC iOS COMMENTÉ
  /*
  static Future<void> diagnoseIOSProblem() async {
    print('🔍 === DIAGNOSTIC SSO GOOGLE IOS ===');

    try {
      print('📱 Plateforme: ${Platform.operatingSystem}');
      print('📱 Version iOS: ${Platform.operatingSystemVersion}');
      print('📱 Mode debug: $kDebugMode');

      // Test configuration
      print('\n🔧 === TEST CONFIGURATION IOS ===');
      final googleSignIn = _getGoogleSignIn();
      print('✅ GoogleSignIn initialisé');
      print('📱 Scopes: ${googleSignIn.scopes}');
      print(
        '📱 Server Client ID configuré: ${googleSignIn.serverClientId != null}',
      );

      // Test disponibilité
      print('\n🔵 === TEST DISPONIBILITÉ IOS ===');
      try {
        final isSignedIn = await googleSignIn.isSignedIn();
        print('📱 État actuel: $isSignedIn');

        if (isSignedIn) {
          final user = googleSignIn.currentUser;
          if (user != null) {
            print('📱 Utilisateur actuel: ${user.email}');

            try {
              final auth = await user.authentication;
              if (auth.idToken != null) {
                print('📱 Token présent: ${auth.idToken!.length} chars');

                final isValid = _isValidJWT(auth.idToken!);
                final notExpired = _isTokenNotExpired(auth.idToken!);
                final iosValid = _validateTokenForIOS(auth.idToken!);

                print('📱 JWT valide: $isValid');
                print('📱 Non expiré: $notExpired');
                print('📱 iOS compatible: $iosValid');

                if (!iosValid) {
                  final payload = _decodeJWT(auth.idToken!);
                  print('📱 Token details: $payload');
                }
              }
            } catch (tokenError) {
              print('❌ Erreur récupération token: $tokenError');
            }
          }
        }
      } catch (e) {
        print('❌ Erreur test disponibilité: $e');
      }

      print('\n💡 === RECOMMANDATIONS IOS ===');
      print('📱 1. Vérifiez GoogleService-Info.plist dans Bundle Resources');
      print('📱 2. Vérifiez URL Schemes dans Info.plist');
      print('📱 3. Vérifiez serverClientId dans la configuration');
      print('📱 4. Testez après nettoyage complet et redémarrage app');
      print(
        '📱 5. Vérifiez que Google app est installée ou autorisez web view',
      );
    } catch (e) {
      print('❌ ERREUR DIAGNOSTIC IOS: $e');
    }

    print('🔍 === FIN DIAGNOSTIC IOS ===');
  }
  */

  // Méthodes existantes inchangées...
  static Future<bool> isSignedInWithGoogle() async {
    try {
      final googleSignIn = _getGoogleSignIn();
      return await googleSignIn.isSignedIn();
    } catch (e) {
      return false;
    }
  }

  static Future<SSOUserInfo?> getCurrentGoogleUser() async {
    try {
      final googleSignIn = _getGoogleSignIn();
      final GoogleSignInAccount? googleUser = googleSignIn.currentUser;

      if (googleUser == null) return null;

      return SSOUserInfo(
        id: googleUser.id,
        email: googleUser.email,
        firstName: googleUser.displayName?.split(' ').first,
        lastName: googleUser.displayName?.split(' ').skip(1).join(' '),
        displayName: googleUser.displayName,
        photoUrl: googleUser.photoUrl,
        provider: 'google',
      );
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getCurrentSSOProvider() async {
    try {
      if (await isSignedInWithGoogle()) return 'google';
      return null;
    } catch (e) {
      return null;
    }
  }

  // ❌ APPLE AVAILABILITY STUB POUR ANDROID
  static Future<bool> isAppleSignInAvailable() async {
    // ❌ TOUJOURS FALSE SUR ANDROID
    /*
    try {
      if (!Platform.isIOS) return false;
      return await SignInWithApple.isAvailable();
    } catch (e) {
      return false;
    }
    */

    // ✅ STUB POUR ANDROID
    return false;
  }

  static Future<void> initialize() async {
    print(
      '✅ [SSOService] Services SSO initialisés (Google seulement pour Android)',
    );
  }

  static bool get isInitialized => true;
}
