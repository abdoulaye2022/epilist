// services/app_version_service.dart - L'app demande au serveur ce qu'il
// pense de sa propre version ; il répond par deux booléens.
//
// L'échec est silencieux et volontaire : pas de réseau, serveur en
// panne, réponse mal formée -> aucune fenêtre. Un contrôle de version
// qui empêche de travailler parce qu'il n'a pas pu s'exécuter serait
// pire que le problème qu'il résout.
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionResult {
  final bool updateAvailable;
  final bool updateRequired;
  final String? messageFr;
  final String? messageEn;
  final String? storeUrl;

  const AppVersionResult({
    required this.updateAvailable,
    required this.updateRequired,
    this.messageFr,
    this.messageEn,
    this.storeUrl,
  });

  static const none =
      AppVersionResult(updateAvailable: false, updateRequired: false);
}

class AppVersionService {
  final Dio _dio;

  AppVersionService({required Dio dio}) : _dio = dio;

  // Repli si le serveur ne fournit pas store_url (normalement il le fait :
  // l'URL est pilotée depuis l'espace admin, corrigeable sans republier).
  static const _fallbackAppStore =
      'https://apps.apple.com/ca/app/epilist/id6748285596';
  static const _fallbackPlayStore =
      'https://play.google.com/store/apps/details?id=com.m2atech.epilist';

  static String get platform => Platform.isIOS ? 'ios' : 'android';

  static String get fallbackStoreUrl =>
      Platform.isIOS ? _fallbackAppStore : _fallbackPlayStore;

  /// Interroge le serveur avec la version réellement installée
  /// (celle du binaire, pas une constante à oublier).
  Future<AppVersionResult> check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final response = await _dio.get(
        '/app/version-check',
        queryParameters: {'platform': platform, 'version': info.version},
      );
      final data = response.data as Map<String, dynamic>;
      return AppVersionResult(
        updateAvailable: data['update_available'] as bool? ?? false,
        updateRequired: data['update_required'] as bool? ?? false,
        messageFr: data['message_fr'] as String?,
        messageEn: data['message_en'] as String?,
        storeUrl: data['store_url'] as String?,
      );
    } catch (_) {
      return AppVersionResult.none;
    }
  }

  /// Statistique indicative : updated | dismissed. Jamais bloquant.
  Future<void> sendStat(String action) async {
    try {
      await _dio.post(
        '/app/version-stat',
        data: {'platform': platform, 'action': action},
      );
    } catch (_) {}
  }
}
