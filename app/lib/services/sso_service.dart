// services/sso_service.dart - VERSION ANDROID UNIQUEMENT (APPLE COMMENTÉ)
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart'; // ❌ COMMENTÉ
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

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
  // ✅ Configuration Google
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email', 'profile'],
  );

  // ===================== GOOGLE SIGN-IN (inchangé) =====================

  /// Connexion avec Google
  static Future<SSOResult> signInWithGoogle() async {
    try {
      print('🔵 [SSOService] Début de la connexion Google...');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('🔵 [SSOService] Connexion Google annulée par l\'utilisateur');
        return SSOResult.error('Connexion annulée par l\'utilisateur');
      }

      print('🔵 [SSOService] Utilisateur Google connecté: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw SSOException('Token d\'identification Google manquant', 'google');
      }

      print('🔵 [SSOService] Tokens Google obtenus avec succès');

      final SSOUserInfo userInfo = SSOUserInfo(
        id: googleUser.id,
        email: googleUser.email,
        firstName: googleUser.displayName?.split(' ').first,
        lastName: googleUser.displayName?.split(' ').skip(1).join(' '),
        displayName: googleUser.displayName,
        photoUrl: googleUser.photoUrl,
        provider: 'google',
      );

      print(
        '✅ [SSOService] Informations utilisateur Google récupérées: ${userInfo.email}',
      );

      return SSOResult.success(
        idToken: idToken,
        accessToken: accessToken,
        userInfo: userInfo,
      );
    } catch (e) {
      print('❌ [SSOService] Erreur lors de la connexion Google: $e');

      if (e is SSOException) {
        rethrow;
      }

      if (e.toString().contains('canceled') ||
          e.toString().contains('cancelled')) {
        return SSOResult.error('Connexion annulée par l\'utilisateur');
      }

      return SSOResult.error(
        'Erreur lors de la connexion Google: ${e.toString()}',
      );
    }
  }

  /// Déconnexion Google
  static Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
      print('✅ [SSOService] Déconnexion Google réussie');
    } catch (e) {
      print('❌ [SSOService] Erreur lors de la déconnexion Google: $e');
    }
  }

  /// Vérifier si connecté Google
  static Future<bool> isSignedInWithGoogle() async {
    try {
      return _googleSignIn.isSignedIn();
    } catch (e) {
      print('❌ [SSOService] Erreur lors de la vérification Google: $e');
      return false;
    }
  }

  /// Obtenir l'utilisateur actuel Google
  static Future<SSOUserInfo?> getCurrentGoogleUser() async {
    try {
      final GoogleSignInAccount? googleUser = _googleSignIn.currentUser;

      if (googleUser == null) {
        return null;
      }

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
      print(
        '❌ [SSOService] Erreur lors de la récupération utilisateur Google: $e',
      );
      return null;
    }
  }

  // ===================== APPLE SIGN-IN COMMENTÉ =====================

  /* ❌ APPLE SIGN-IN COMMENTÉ POUR ANDROID
  /// CONNEXION AVEC APPLE CORRIGÉE (gestion des nullable)
  static Future<SSOResult> signInWithApple() async {
    try {
      print('🍎 [SSOService] Début de la connexion Apple...');

      // Vérifier la disponibilité
      if (!Platform.isIOS) {
        return SSOResult.error(
          'Apple Sign-In est uniquement disponible sur iOS',
        );
      }

      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        return SSOResult.error(
          'Apple Sign-In n\'est pas disponible sur cet appareil',
        );
      }

      print('🍎 [SSOService] Apple Sign-In disponible, démarrage...');

      // Générer un nonce pour la sécurité
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Demander les credentials Apple
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      print('🍎 [SSOService] Credentials Apple reçus');

      // GESTION SÉCURISÉE DES VALEURS NULLABLE
      final userIdentifier = credential.userIdentifier;
      if (userIdentifier == null || userIdentifier.isEmpty) {
        throw SSOException('Apple UserIdentifier manquant', 'apple');
      }

      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw SSOException('Apple Identity Token manquant', 'apple');
      }

      print('  User ID: $userIdentifier');
      print('  Email: ${credential.email ?? "privé"}');
      print(
        '  Nom: ${credential.givenName ?? ""} ${credential.familyName ?? ""}',
      );

      // Construire les informations utilisateur
      final email = credential.email ?? '';
      final firstName = credential.givenName ?? '';
      final lastName = credential.familyName ?? '';
      final displayName = '$firstName $lastName'.trim();

      // GESTION SÉCURISÉE DE L'EMAIL APPLE
      final userEmail =
          email.isNotEmpty
              ? email
              : '${userIdentifier}@privaterelay.appleid.com';

      final userInfo = SSOUserInfo(
        id: userIdentifier,
        email: userEmail,
        firstName: firstName.isNotEmpty ? firstName : null,
        lastName: lastName.isNotEmpty ? lastName : null,
        displayName: displayName.isNotEmpty ? displayName : null,
        photoUrl: null, // Apple ne fournit pas de photo
        provider: 'apple',
      );

      print('✅ [SSOService] Informations utilisateur Apple préparées');
      print('  ID final: ${userInfo.id}');
      print('  Email final: ${userInfo.email}');

      return SSOResult.success(
        idToken: identityToken,
        accessToken: credential.authorizationCode,
        userInfo: userInfo,
      );
    } catch (e) {
      print('❌ [SSOService] Erreur lors de la connexion Apple: $e');

      // Gestion des erreurs spécifiques Apple
      if (e is SignInWithAppleAuthorizationException) {
        switch (e.code) {
          case AuthorizationErrorCode.canceled:
            return SSOResult.error(
              'Connexion Apple annulée par l\'utilisateur',
            );
          case AuthorizationErrorCode.failed:
            return SSOResult.error('Connexion Apple échouée');
          case AuthorizationErrorCode.invalidResponse:
            return SSOResult.error('Réponse Apple invalide');
          case AuthorizationErrorCode.notHandled:
            return SSOResult.error('Connexion Apple non gérée');
          case AuthorizationErrorCode.unknown:
          default:
            return SSOResult.error('Erreur Apple inconnue: ${e.message}');
        }
      }

      // Gestion des erreurs SSOException
      if (e is SSOException) {
        return SSOResult.error(e.message);
      }

      if (e.toString().contains('canceled') ||
          e.toString().contains('cancelled')) {
        return SSOResult.error('Connexion annulée par l\'utilisateur');
      }

      return SSOResult.error(
        'Erreur lors de la connexion Apple: ${e.toString()}',
      );
    }
  }
  */

  /// ❌ MÉTHODES APPLE COMMENTÉES
  /// Déconnexion Apple (pas nécessaire, Apple gère automatiquement)
  static Future<void> signOutApple() async {
    // Apple ne nécessite pas de déconnexion explicite
    print('🍎 [SSOService] Apple Sign-Out (non disponible sur Android)');
  }

  // ===================== MÉTHODES UTILITAIRES APPLE COMMENTÉES =====================

  /* ❌ COMMENTÉ POUR ANDROID
  /// Générer un nonce aléatoire pour Apple
  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Hash SHA256 du nonce
  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  */

  // ===================== MÉTHODES UTILITAIRES GÉNÉRALES =====================

  static Future<void> signOutAll() async {
    try {
      await signOutGoogle();
      await signOutApple(); // Juste un print, pas de vraie déconnexion
      print('✅ [SSOService] Déconnexion de tous les services SSO');
    } catch (e) {
      print('❌ [SSOService] Erreur lors de la déconnexion SSO: $e');
    }
  }

  static Future<String?> getCurrentSSOProvider() async {
    try {
      if (await isSignedInWithGoogle()) {
        return 'google';
      }
      // Apple ne maintient pas d'état de connexion sur Android
      return null;
    } catch (e) {
      return null;
    }
  }

  /// ❌ VÉRIFICATION DISPONIBILITÉ APPLE POUR ANDROID
  static Future<bool> isAppleSignInAvailable() async {
    try {
      if (!Platform.isIOS) {
        print('🍎 [SSOService] Apple Sign-In non disponible sur Android');
        return false;
      }
      // return await SignInWithApple.isAvailable(); // ❌ COMMENTÉ
      return false; // ✅ TOUJOURS FALSE SUR ANDROID
    } catch (e) {
      print('❌ [SSOService] Erreur vérification Apple: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> getDebugInfo() async {
    try {
      final bool isGoogleSignedIn = await isSignedInWithGoogle();
      final bool isAppleAvailable = await isAppleSignInAvailable();
      final String? currentProvider = await getCurrentSSOProvider();
      final SSOUserInfo? googleUser = await getCurrentGoogleUser();

      return {
        'platform': Platform.operatingSystem,
        'google_sign_in_version': '6.2.1',
        'apple_sign_in_version': 'N/A (Android)',
        'api_version': 'v6_android_only',
        'google': {
          'is_signed_in': isGoogleSignedIn,
          'current_user': googleUser?.toMap(),
        },
        'apple': {
          'is_available': isAppleAvailable,
          'platform_supported': Platform.isIOS,
          'status': 'Désactivé pour Android',
        },
        'current_provider': currentProvider,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  static Future<void> initialize() async {
    print('✅ [SSOService] Google Sign-In prêt (Android uniquement)');
  }

  static bool get isInitialized => true;

  static Future<void> diagnoseProblem() async {
    print('🔍 === DIAGNOSTIC SSO ANDROID ===');

    try {
      // Diagnostic Google
      final bool isGoogleSignedIn = await _googleSignIn.isSignedIn();
      print('📱 Google - État de connexion: $isGoogleSignedIn');

      final GoogleSignInAccount? currentGoogleUser = _googleSignIn.currentUser;
      print(
        '📱 Google - Utilisateur actuel: ${currentGoogleUser?.email ?? "Aucun"}',
      );

      // Diagnostic Apple pour Android
      print('📱 Apple - Non disponible sur Android');
      print('📱 Apple - Configuration: N/A');
    } catch (e) {
      print('❌ DIAGNOSTIC ÉCHOUÉ: $e');
    }

    print('🔍 === FIN DIAGNOSTIC ===');
  }
}
