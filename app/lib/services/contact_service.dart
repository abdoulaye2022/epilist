// services/contact_service.dart - VERSION AVEC LANGUE
import 'package:dio/dio.dart';
import 'package:epilist/blocs/contact/contact_bloc.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'dart:ui' as ui;

import '../models/feedback_models.dart';

class ContactValidationException implements Exception {
  final String message;
  final Map<String, List<String>>? validationErrors;

  ContactValidationException(this.message, {this.validationErrors});

  @override
  String toString() => message;
}

class ContactService {
  final Dio dio;
  final AuthService authService;

  ContactService({required this.dio, required this.authService});

  /// ✅ NOUVEAU: Obtient la langue actuelle du device
  String _getCurrentLanguage() {
    try {
      final locale = ui.PlatformDispatcher.instance.locale;
      final languageCode = locale.languageCode.toLowerCase();

      // Mapping des codes de langue supportés
      switch (languageCode) {
        case 'fr':
          return 'fr';
        case 'en':
          return 'en';
        default:
          // Par défaut, utiliser français
          return 'fr';
      }
    } catch (e) {
      print('⚠️ Erreur lors de la détection de la langue: $e');
      return 'fr'; // Fallback
    }
  }

  /// ✅ NOUVEAU: Crée les headers avec la langue
  Map<String, String> _createHeaders({String? authToken}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Language': _getCurrentLanguage(), // ✅ ENVOI DE LA LANGUE
    };

    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    return headers;
  }

  Future<Map<String, dynamic>> getFeedbackTypes() async {
    try {
      final currentLanguage = _getCurrentLanguage();
      print('🌐 Requesting feedback types in language: $currentLanguage');

      final response = await dio.get(
        '/contact/feedback-types',
        options: Options(
          headers: _createHeaders(), // ✅ HEADERS AVEC LANGUE
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final serverLanguage = data['language'] ?? currentLanguage;

        print('📋 Server returned data in language: $serverLanguage');

        final feedbackTypes =
            (data['feedback_types'] as List)
                .map((item) => FeedbackType.fromJson(item))
                .toList();

        final priorities =
            (data['priorities'] as List)
                .map((item) => PriorityLevel.fromJson(item))
                .toList();

        print(
          '✅ Loaded ${feedbackTypes.length} feedback types and ${priorities.length} priorities',
        );

        return {
          'feedbackTypes': feedbackTypes,
          'priorities': priorities,
          'language': serverLanguage,
        };
      } else {
        throw Exception('Erreur lors du chargement des types de feedback');
      }
    } on DioException catch (e) {
      print('❌ Erreur réseau getFeedbackTypes: ${e.message}');
      throw Exception('Erreur réseau : ${e.message}');
    } catch (e) {
      print('❌ Erreur inattendue getFeedbackTypes: $e');
      throw Exception('Erreur inattendue : $e');
    }
  }

  Future<Map<String, dynamic>> sendFeedback({
    required String subject,
    required String message,
    required String feedbackType,
    required String priority,
    String? appVersion,
    String? platform,
    String? deviceInfo,
  }) async {
    try {
      final currentLanguage = _getCurrentLanguage();
      print('🚀 Sending feedback in language: $currentLanguage');

      // Récupérer les informations de l'appareil automatiquement
      final deviceData = await _getDeviceInfo();
      final packageInfo = await PackageInfo.fromPlatform();

      // Préparer les données
      final data = {
        'subject': subject,
        'message': message,
        'feedback_type': feedbackType,
        'priority': priority,
        'app_version': appVersion ?? packageInfo.version,
        'platform': platform ?? deviceData['platform'],
        'device_info': deviceInfo ?? deviceData['device_info'],
      };

      // Vérifier si l'utilisateur est connecté
      final token = await authService.getToken();
      final endpoint =
          token != null ? '/contact/feedback' : '/contact/feedback-anonymous';

      // Si utilisateur non connecté, ajouter les champs obligatoires
      if (token == null) {
        data['name'] = 'Utilisateur Anonyme';
        data['email'] = 'anonymous@example.com';
      }

      print('📤 Sending to endpoint: $endpoint');
      print('📊 Feedback data: ${data.keys.join(', ')}');

      // Configurer les headers avec la langue
      final headers = _createHeaders(authToken: token);

      final response = await dio.post(
        endpoint,
        data: data,
        options: Options(headers: headers), // ✅ HEADERS AVEC LANGUE
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        print('✅ Feedback envoyé avec succès');
        return {
          'message': response.data['message'],
          'feedbackId': response.data['data']?['feedback_id'] ?? '',
        };
      } else {
        throw Exception(response.data['message'] ?? 'Erreur lors de l\'envoi');
      }
    } on DioException catch (e) {
      print(
        '❌ Erreur réseau sendFeedback: ${e.response?.statusCode} - ${e.message}',
      );

      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData != null && errorData['code'] == 'VALIDATION_ERROR') {
          throw ContactValidationException(
            errorData['message'] ?? 'Erreurs de validation',
            validationErrors: Map<String, List<String>>.from(
              errorData['errors']?.map(
                    (key, value) => MapEntry(key, List<String>.from(value)),
                  ) ??
                  {},
            ),
          );
        }
      }

      throw Exception(
        e.response?.data?['message'] ??
            'Erreur réseau lors de l\'envoi : ${e.message}',
      );
    } catch (e) {
      print('❌ Erreur inattendue sendFeedback: $e');
      if (e is ContactValidationException) {
        rethrow;
      }
      throw Exception('Erreur inattendue : $e');
    }
  }

  Future<Map<String, String>> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String platform = 'unknown';
      String deviceInfoString = 'Unknown Device';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        platform = 'android';
        deviceInfoString =
            '${androidInfo.brand} ${androidInfo.model} (Android ${androidInfo.version.release})';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        platform = 'ios';
        deviceInfoString = '${iosInfo.name} (iOS ${iosInfo.systemVersion})';
      }

      return {'platform': platform, 'device_info': deviceInfoString};
    } catch (e) {
      return {
        'platform':
            Platform.isAndroid
                ? 'android'
                : Platform.isIOS
                ? 'ios'
                : 'unknown',
        'device_info': 'Device info unavailable',
      };
    }
  }
}
