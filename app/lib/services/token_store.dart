// services/token_store.dart - Stockage sécurisé des jetons JWT :
// Keychain sur iOS, Keystore (EncryptedSharedPreferences) sur Android.
//
// Migration douce : si le trousseau est vide mais que les anciens jetons
// existent encore en SharedPreferences (versions précédentes de l'app),
// ils sont déplacés une fois vers le trousseau puis effacés du stockage
// en clair. Personne n'est déconnecté par la mise à jour.
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static bool _migrated = false;

  /// Déplace les jetons hérités des SharedPreferences vers le trousseau
  /// (une seule fois par lancement, silencieux en cas d'échec).
  static Future<void> _migrateIfNeeded() async {
    if (_migrated) return;
    _migrated = true;
    try {
      final existing = await _storage.read(key: _accessKey);
      if (existing != null && existing.isNotEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final legacyAccess = prefs.getString(_accessKey);
      final legacyRefresh = prefs.getString(_refreshKey);
      if (legacyAccess == null || legacyAccess.isEmpty) return;

      await _storage.write(key: _accessKey, value: legacyAccess);
      if (legacyRefresh != null && legacyRefresh.isNotEmpty) {
        await _storage.write(key: _refreshKey, value: legacyRefresh);
      }
      await prefs.remove(_accessKey);
      await prefs.remove(_refreshKey);
      debugPrint('🔐 [TokenStore] Jetons migrés vers le stockage sécurisé');
    } catch (e) {
      debugPrint('🔐 [TokenStore] Migration ignorée: $e');
    }
  }

  static Future<String?> readAccess() async {
    await _migrateIfNeeded();
    try {
      return await _storage.read(key: _accessKey);
    } catch (e) {
      // Distinguer « jeton absent » (déconnexion normale) de « stockage
      // illisible » (Keystore invalidé, accès concurrent depuis l'isolate
      // FCM...) : ce second cas est la piste des déconnexions aléatoires.
      debugPrint('🔐 [TokenStore] LECTURE IMPOSSIBLE (access): $e');
      return null;
    }
  }

  static Future<String?> readRefresh() async {
    await _migrateIfNeeded();
    try {
      return await _storage.read(key: _refreshKey);
    } catch (e) {
      debugPrint('🔐 [TokenStore] LECTURE IMPOSSIBLE (refresh): $e');
      return null;
    }
  }

  static Future<void> write(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  static Future<void> clear() async {
    try {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
    } catch (_) {}
  }
}
