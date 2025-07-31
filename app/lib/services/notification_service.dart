// services/notification_service.dart - VERSION PRODUCTION

import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:epilist/config/app_config.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService.instance() => _instance;

  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static BuildContext? _context;
  static String? _currentToken;
  static String? _apnsToken;
  static bool _isInitialized = false;
  static String? _lastRegisteredToken;
  static bool _deviceRegistrationInProgress = false;
  static bool _isSimulator = false;

  static const String _channelBudgetAlerts = 'budget_alerts';
  static const String _channelListUpdates = 'list_updates';
  static const String _channelReminders = 'reminders';
  static const String _channelGeneral = 'general';

  static Future<void> initialize([BuildContext? context]) async {
    try {
      _context = context;

      await _detectSimulator();
      await _initializeLocalNotifications();
      await _setupMessageHandlers();
      await _requestPermissions();

      if (_isSimulator) {
        _handleSimulatorToken();
      } else {
        _handlePushNotificationsToken();
      }

      await _checkInitialMessage();

      _isInitialized = true;
    } catch (e, stackTrace) {
      // Log error in production monitoring system
      if (kDebugMode) {
        print('❌ Error initializing NotificationService: $e');
        print('Stack trace: $stackTrace');
      }
    }
  }

  static void _handlePushNotificationsToken() {
    try {
      _firebaseMessaging.onTokenRefresh
          .listen((fcmToken) async {
            _currentToken = fcmToken;
            await _saveTokenToPreferences(fcmToken);

            if (Platform.isIOS && !_isSimulator && _apnsToken == null) {
              await _tryGetAPNSTokenSafe();
            }

            await _tryRegisterIfAuthenticated();
          })
          .onError((error) {
            // Log error in production monitoring
          });

      _getInitialTokenSafe();
    } catch (e, stackTrace) {
      // Log error in production monitoring
    }
  }

  static void _getInitialTokenSafe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedToken = prefs.getString('fcm_token');

      if (cachedToken != null && cachedToken.isNotEmpty) {
        _currentToken = cachedToken;
        await _tryRegisterIfAuthenticated();
      }

      if (Platform.isIOS && !_isSimulator) {
        await _prepareAPNSForIPhone();
      }

      await Future.delayed(const Duration(milliseconds: 8000));
      await _tryGetTokenSafely();
    } catch (e, stackTrace) {
      // Log error in production monitoring
    }
  }

  static Future<void> _prepareAPNSForIPhone() async {
    try {
      await Future.delayed(const Duration(milliseconds: 5000));

      try {
        final apnsToken = await _firebaseMessaging.getAPNSToken().timeout(
          const Duration(seconds: 10),
          onTimeout: () => null,
        );

        if (apnsToken != null && apnsToken.isNotEmpty) {
          _apnsToken = apnsToken;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('apns_token', apnsToken);
        }
      } catch (e) {
        // Continue without APNS
      }
    } catch (e) {
      // Continue without APNS
    }
  }

  static Future<void> _tryGetTokenSafely() async {
    const maxAttempts = 3;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final tokenFuture = _firebaseMessaging.getToken();
        final token = await tokenFuture.timeout(
          const Duration(seconds: 15),
          onTimeout: () => null,
        );

        if (token != null && token.isNotEmpty) {
          _currentToken = token;
          await _saveTokenToPreferences(token);

          if (Platform.isIOS && !_isSimulator && _apnsToken == null) {
            await _tryGetAPNSTokenSafe();
          }

          await _tryRegisterIfAuthenticated();
          return;
        }
      } catch (e) {
        if (e.toString().contains('apns-token-not-set')) {
          // Continue without APNS
          if (attempt == maxAttempts) {
            break;
          }
        }
      }

      if (attempt < maxAttempts) {
        await Future.delayed(const Duration(milliseconds: 3000));
      }
    }
  }

  static Future<void> _tryGetAPNSTokenSafe() async {
    if (_isSimulator) return;

    try {
      await Future.delayed(const Duration(milliseconds: 2000));

      final apnsToken = await _firebaseMessaging.getAPNSToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );

      if (apnsToken != null && apnsToken.isNotEmpty) {
        _apnsToken = apnsToken;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('apns_token', apnsToken);

        await _tryRegisterIfAuthenticated();
      }
    } catch (e) {
      // Continue without APNS
    }
  }

  static void _handleSimulatorToken() {
    try {
      _firebaseMessaging.onTokenRefresh
          .listen((fcmToken) async {
            _currentToken = fcmToken;
            await _saveTokenToPreferences(fcmToken);
            await _tryRegisterIfAuthenticated();
          })
          .onError((error) {
            // Log error in production monitoring
          });

      _getSimulatorTokenAlternative();
    } catch (e, stackTrace) {
      // Log error in production monitoring
    }
  }

  static void _getSimulatorTokenAlternative() async {
    try {
      await Future.delayed(const Duration(milliseconds: 5000));

      final tokenFuture = _firebaseMessaging.getToken();
      final timeoutFuture = Future.delayed(
        const Duration(seconds: 10),
        () => throw TimeoutException('Token timeout'),
      );

      final token = await Future.any([tokenFuture, timeoutFuture]);

      if (token != null && token is String && token.isNotEmpty) {
        _currentToken = token;
        await _saveTokenToPreferences(token);
        await _tryRegisterIfAuthenticated();
      }
    } catch (e) {
      if (e is TimeoutException) {
        // Expected timeout
      } else if (e.toString().contains('apns-token-not-set')) {
        // Expected APNS error on simulator
      }
      _generateSimulatorFallbackToken();
    }
  }

  static void _generateSimulatorFallbackToken() async {
    try {
      await Future.delayed(const Duration(milliseconds: 3000));

      final prefs = await SharedPreferences.getInstance();
      final cachedToken = prefs.getString('fcm_token');

      if (cachedToken != null && cachedToken.isNotEmpty) {
        _currentToken = cachedToken;
        await _tryRegisterIfAuthenticated();
        return;
      }

      if (kDebugMode && _isSimulator) {
        final deviceInfo = await _getDeviceInfo();
        final simulatorToken =
            'simulator_token_${deviceInfo['device_id']}_${DateTime.now().millisecondsSinceEpoch}';

        _currentToken = simulatorToken;
        await _saveTokenToPreferences(simulatorToken);
        await _tryRegisterIfAuthenticated();
      }
    } catch (e) {
      // Log error in production monitoring
    }
  }

  static Future<void> _setupMessageHandlers() async {
    try {
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        // Handle foreground messages
      });

      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpened);
    } catch (e, stackTrace) {
      // Log error in production monitoring
    }
  }

  static Future<void> _requestPermissions() async {
    try {
      if (Platform.isIOS) {
        final result = await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          announcement: false,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
        );

        await _firebaseMessaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } else if (Platform.isAndroid) {
        final status = await Permission.notification.request();
      }
    } catch (e, stackTrace) {
      // Log error in production monitoring
    }
  }

  static Future<void> _tryRegisterIfAuthenticated() async {
    if (_deviceRegistrationInProgress) {
      return;
    }

    if (_currentToken == null || _currentToken!.isEmpty) {
      return;
    }

    _deviceRegistrationInProgress = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('access_token');

      if (authToken == null) {
        return;
      }

      final deviceInfo = await _getDeviceInfo();
      final dio = Dio();
      dio.options.baseUrl = AppConfig.baseUrl;
      dio.options.headers['Authorization'] = 'Bearer $authToken';
      dio.options.headers['Content-Type'] = 'application/json';
      dio.options.connectTimeout = const Duration(seconds: 15);
      dio.options.receiveTimeout = const Duration(seconds: 15);

      final deviceData = {
        'device_id': deviceInfo['device_id'],
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'push_token': _currentToken,
        'app_version': deviceInfo['app_version'],
        'os_version': deviceInfo['os_version'],
        'device_model': deviceInfo['device_model'],
      };

      if (Platform.isIOS && !_isSimulator && _apnsToken != null) {
        deviceData['apns_token'] = _apnsToken!;
      }

      final response = await dio.post('/devices/register', data: deviceData);

      if (response.statusCode == 201) {
        await prefs.setString('last_registered_token', _currentToken!);
        await prefs.setString('device_registered', 'true');
        _lastRegisteredToken = _currentToken;
      }
    } catch (e, stackTrace) {
      // Log error in production monitoring
    } finally {
      _deviceRegistrationInProgress = false;
    }
  }

  // Méthodes publiques
  static String? getCurrentToken() => _currentToken;
  static bool get isSimulator => _isSimulator;
  static bool get isInitialized => _isInitialized;

  static void updateContext(BuildContext context) {
    _context = context;
  }

  static Future<bool> isDeviceRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    final isRegistered = prefs.getBool('device_registered') ?? false;
    final lastToken = prefs.getString('last_registered_token');
    return isRegistered && lastToken == _currentToken && _currentToken != null;
  }

  static Future<void> ensureDeviceIsRegistered() async {
    if (_currentToken == null || _currentToken!.isEmpty) {
      return;
    }

    final isRegistered = await isDeviceRegistered();
    if (!isRegistered) {
      await _tryRegisterIfAuthenticated();
    }
  }

  static Future<void> forceTokenRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_registered_token');
    await prefs.remove('device_registered');

    if (Platform.isAndroid) {
      await _firebaseMessaging.deleteToken();
      await Future.delayed(const Duration(milliseconds: 1000));
      final newToken = await _firebaseMessaging.getToken();
      if (newToken != null) {
        _currentToken = newToken;
        await _saveTokenToPreferences(newToken);
      }
    }
    await _tryRegisterIfAuthenticated();
  }

  static Future<void> reRegisterDeviceWithTokenRefresh() async {
    await forceTokenRefresh();
  }

  static Future<void> reRegisterDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_registered_token');
    await prefs.remove('device_registered');
    _deviceRegistrationInProgress = false;
    await _tryRegisterIfAuthenticated();
  }

  static Future<void> clearDeviceData() async {
    final prefs = await SharedPreferences.getInstance();
    final keysToRemove = [
      'fcm_token',
      'device_registered',
      'device_id',
      'last_registered_token',
      'apns_token',
      'last_apns_token',
    ];

    for (final key in keysToRemove) {
      await prefs.remove(key);
    }

    _currentToken = null;
    _apnsToken = null;
    _lastRegisteredToken = null;
    _isInitialized = false;
    _deviceRegistrationInProgress = false;

    if (Platform.isAndroid) {
      try {
        await _firebaseMessaging.deleteToken();
      } catch (e) {
        // Continue cleanup
      }
    }
  }

  // Méthodes privées de support
  static Future<void> _detectSimulator() async {
    try {
      if (Platform.isIOS) {
        final deviceInfo = DeviceInfoPlugin();
        final iosInfo = await deviceInfo.iosInfo;
        _isSimulator = !iosInfo.isPhysicalDevice;
      } else {
        _isSimulator = false;
      }
    } catch (e) {
      _isSimulator = false;
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  static Future<void> _createNotificationChannels() async {
    final channels = [
      const AndroidNotificationChannel(
        _channelGeneral,
        'Général',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        _channelBudgetAlerts,
        'Alertes Budget',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        _channelListUpdates,
        'Mises à jour de listes',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        _channelReminders,
        'Rappels',
        importance: Importance.high,
      ),
    ];

    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  static Future<Map<String, String>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();

    String deviceId = '';
    String osVersion = '';
    String deviceModel = '';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
      osVersion = androidInfo.version.release;
      deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? '';
      osVersion = iosInfo.systemVersion;
      deviceModel =
          _isSimulator ? '${iosInfo.model} (Simulator)' : iosInfo.model;
    }

    return {
      'device_id': deviceId,
      'app_version': packageInfo.version,
      'os_version': osVersion,
      'device_model': deviceModel,
    };
  }

  static Future<void> _saveTokenToPreferences(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  static Future<void> _checkInitialMessage() async {
    try {
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        // Handle initial message
      }
    } catch (e) {
      // Log error in production monitoring
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Handle foreground messages
  }

  static Future<void> _handleNotificationOpened(RemoteMessage message) async {
    // Handle notification opened
  }

  static Future<void> _onNotificationTapped(
    NotificationResponse response,
  ) async {
    // Handle local notification tapped
  }

  static void dispose() {
    _isInitialized = false;
    _deviceRegistrationInProgress = false;
  }
}

@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  // Handle background messages
}
