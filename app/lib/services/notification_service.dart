// services/notification_service.dart - CORRECTION FINALE

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
    print('🚀 [EPILIST] Starting NotificationService initialization...');

    try {
      _context = context;

      // 1. Détecter le simulateur
      await _detectSimulator();
      print(
        '📱 [EPILIST] Device type: ${_isSimulator ? "Simulator" : "Physical"}',
      );

      // 2. Initialiser les notifications locales
      print('🔔 [EPILIST] Initializing local notifications...');
      await _initializeLocalNotifications();

      // 3. Configurer les handlers de messages
      print('📨 [EPILIST] Setting up message handlers...');
      await _setupMessageHandlers();

      // 4. Demander les permissions
      print('🔒 [EPILIST] Requesting permissions...');
      await _requestPermissions();

      // 5. Gérer le token FCM
      print('🔑 [EPILIST] Handling FCM token...');
      await _handlePushNotificationsToken();

      // 6. Vérifier les messages initiaux
      print('📬 [EPILIST] Checking initial messages...');
      await _checkInitialMessage();

      _isInitialized = true;
      print('✅ [EPILIST] NotificationService initialized successfully!');
    } catch (e, stackTrace) {
      print('❌ [EPILIST] Error initializing NotificationService: $e');
      print('📍 [EPILIST] Stack trace: $stackTrace');
    }
  }

  static Future<void> _handlePushNotificationsToken() async {
    try {
      print('🔄 [EPILIST] Setting up token refresh listener...');

      // Écouter les changements de token
      _firebaseMessaging.onTokenRefresh
          .listen((fcmToken) async {
            print(
              '🔄 [EPILIST] FCM Token refreshed: ${fcmToken.substring(0, 20)}...',
            );
            _currentToken = fcmToken;
            await _saveTokenToPreferences(fcmToken);

            if (Platform.isIOS && !_isSimulator && _apnsToken == null) {
              await _tryGetAPNSTokenSafe();
            }

            await _tryRegisterIfAuthenticated();
          })
          .onError((error) {
            print('❌ [EPILIST] Token refresh error: $error');
          });

      await _getInitialTokenSafe();
    } catch (e, stackTrace) {
      print('❌ [EPILIST] Error in _handlePushNotificationsToken: $e');
    }
  }

  static Future<void> _getInitialTokenSafe() async {
    try {
      print('🔍 [EPILIST] Getting initial FCM token...');

      // D'abord, vérifier le token en cache
      final prefs = await SharedPreferences.getInstance();
      final cachedToken = prefs.getString('fcm_token');

      if (cachedToken != null && cachedToken.isNotEmpty) {
        _currentToken = cachedToken;
        print(
          '📱 [EPILIST] Using cached FCM token: ${cachedToken.substring(0, 20)}...',
        );
      }

      // Traitement spécial iOS pour APNS
      if (Platform.isIOS && !_isSimulator) {
        print('🍎 [EPILIST] Preparing APNS for iOS...');
        await _prepareAPNSForIPhone();
      }

      // Attendre un délai puis essayer d'obtenir un nouveau token
      print('⏳ [EPILIST] Waiting before token request...');
      await Future.delayed(
        Duration(milliseconds: Platform.isAndroid ? 2000 : 8000),
      );

      await _tryGetTokenSafely();
    } catch (e, stackTrace) {
      print('❌ [EPILIST] Error in _getInitialTokenSafe: $e');
    }
  }

  static Future<void> _tryGetTokenSafely() async {
    const maxAttempts = 3;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        print(
          '🔄 [EPILIST] Attempting to get FCM token (attempt $attempt/$maxAttempts)',
        );

        final tokenFuture = _firebaseMessaging.getToken();
        final token = await tokenFuture.timeout(
          Duration(seconds: Platform.isAndroid ? 15 : 20),
          onTimeout: () {
            print('⏰ [EPILIST] Token request timeout on attempt $attempt');
            return null;
          },
        );

        if (token != null && token.isNotEmpty) {
          _currentToken = token;
          await _saveTokenToPreferences(token);

          print('✅ [EPILIST] FCM token obtained: ${token.substring(0, 20)}...');
          print('📱 [EPILIST] Full token length: ${token.length}');

          if (Platform.isIOS && !_isSimulator && _apnsToken == null) {
            await _tryGetAPNSTokenSafe();
          }

          await _tryRegisterIfAuthenticated();
          return;
        } else {
          print(
            '⚠️ [EPILIST] Empty or null token received on attempt $attempt',
          );
        }
      } catch (e) {
        print('❌ [EPILIST] Error getting token (attempt $attempt): $e');

        if (e.toString().contains('apns-token-not-set')) {
          print('ℹ️ [EPILIST] APNS token not set, this is normal for Android');
          if (attempt == maxAttempts) {
            break;
          }
        }
      }

      if (attempt < maxAttempts) {
        final delay = Duration(milliseconds: Platform.isAndroid ? 2000 : 3000);
        print('⏳ [EPILIST] Waiting ${delay.inMilliseconds}ms before retry...');
        await Future.delayed(delay);
      }
    }

    print('❌ [EPILIST] Failed to get FCM token after $maxAttempts attempts');
  }

  static Future<void> _prepareAPNSForIPhone() async {
    if (_isSimulator || Platform.isAndroid) return;

    try {
      print('🍎 [EPILIST] Preparing APNS token...');
      await Future.delayed(const Duration(milliseconds: 5000));

      final apnsToken = await _firebaseMessaging.getAPNSToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );

      if (apnsToken != null && apnsToken.isNotEmpty) {
        _apnsToken = apnsToken;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('apns_token', apnsToken);
        print(
          '✅ [EPILIST] APNS token obtained: ${apnsToken.substring(0, 20)}...',
        );
      } else {
        print('⚠️ [EPILIST] APNS token is null or empty');
      }
    } catch (e) {
      print('❌ [EPILIST] Error getting APNS token: $e');
    }
  }

  static Future<void> _tryGetAPNSTokenSafe() async {
    if (_isSimulator || Platform.isAndroid) return;

    try {
      print('🍎 [EPILIST] Trying to get APNS token safely...');
      await Future.delayed(const Duration(milliseconds: 2000));

      final apnsToken = await _firebaseMessaging.getAPNSToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏰ [EPILIST] APNS token request timeout');
          return null;
        },
      );

      if (apnsToken != null && apnsToken.isNotEmpty) {
        _apnsToken = apnsToken;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('apns_token', apnsToken);

        await _tryRegisterIfAuthenticated();

        print(
          '✅ [EPILIST] APNS token updated: ${apnsToken.substring(0, 20)}...',
        );
      } else {
        print('⚠️ [EPILIST] APNS token is null or empty');
      }
    } catch (e) {
      print('❌ [EPILIST] Error getting APNS token safely: $e');
    }
  }

  static Future<void> _setupMessageHandlers() async {
    try {
      // Handler pour les messages en arrière-plan
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Handler pour les messages en premier plan
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print(
          '📨 [EPILIST] Foreground message received: ${message.notification?.title}',
        );
        print('📨 [EPILIST] Message data: ${message.data}');
        await _handleForegroundMessage(message);
      });

      // Handler pour l'ouverture de notification
      FirebaseMessaging.onMessageOpenedApp.listen((
        RemoteMessage message,
      ) async {
        print(
          '👆 [EPILIST] Notification opened app: ${message.notification?.title}',
        );
        await _handleNotificationOpened(message);
      });

      print('✅ [EPILIST] Message handlers configured');
    } catch (e, stackTrace) {
      print('❌ [EPILIST] Error setting up message handlers: $e');
    }
  }

  static Future<void> _requestPermissions() async {
    try {
      if (Platform.isIOS) {
        print('🍎 [EPILIST] Requesting iOS permissions...');
        final result = await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          announcement: false,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
        );

        print(
          '🍎 [EPILIST] iOS notification permission: ${result.authorizationStatus}',
        );

        await _firebaseMessaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } else if (Platform.isAndroid) {
        print('🤖 [EPILIST] Requesting Android permissions...');

        // Permission pour les notifications (Android 13+)
        final notificationStatus = await Permission.notification.request();
        print(
          '🤖 [EPILIST] Android notification permission: $notificationStatus',
        );

        // Permission pour ignorer l'optimisation de batterie
        final batteryStatus =
            await Permission.ignoreBatteryOptimizations.request();
        print('🤖 [EPILIST] Battery optimization permission: $batteryStatus');

        // Vérifier les permissions des notifications
        final isGranted = await Permission.notification.isGranted;
        print('🤖 [EPILIST] Notification permission granted: $isGranted');
      }
    } catch (e, stackTrace) {
      print('❌ [EPILIST] Error requesting permissions: $e');
    }
  }

  static Future<void> _tryRegisterIfAuthenticated() async {
    if (_deviceRegistrationInProgress) {
      print('⏳ [EPILIST] Device registration already in progress');
      return;
    }

    if (_currentToken == null || _currentToken!.isEmpty) {
      print('⚠️ [EPILIST] No FCM token available for registration');
      return;
    }

    _deviceRegistrationInProgress = true;

    try {
      print('🔄 [EPILIST] Starting device registration...');

      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('access_token');

      if (authToken == null) {
        print('⚠️ [EPILIST] No auth token, skipping device registration');
        return;
      }

      print(
        '🔄 [EPILIST] Registering device with FCM token: ${_currentToken!.substring(0, 20)}...',
      );

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

      print('📡 [EPILIST] Sending registration request...');
      print('📡 [EPILIST] Device data: $deviceData');

      final response = await dio.post('/devices/register', data: deviceData);

      print('📡 [EPILIST] Registration response: ${response.statusCode}');
      print('📡 [EPILIST] Response data: ${response.data}');

      if (response.statusCode == 201) {
        await prefs.setString('last_registered_token', _currentToken!);
        // ✅ FIX PRINCIPAL: Enregistrer comme string 'true' au lieu de bool
        await prefs.setString('device_registered', 'true');
        _lastRegisteredToken = _currentToken;

        print('✅ [EPILIST] Device registered successfully!');
      } else {
        print('⚠️ [EPILIST] Unexpected response code: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ [EPILIST] Device registration failed: $e');
      print('📍 [EPILIST] Stack trace: $stackTrace');
    } finally {
      _deviceRegistrationInProgress = false;
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    try {
      print('🔔 [EPILIST] Initializing local notifications...');

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

      final initialized = await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      print('🔔 [EPILIST] Local notifications initialized: $initialized');

      if (Platform.isAndroid) {
        await _createNotificationChannels();
      }
    } catch (e) {
      print('❌ [EPILIST] Error initializing local notifications: $e');
    }
  }

  static Future<void> _createNotificationChannels() async {
    try {
      print('📺 [EPILIST] Creating Android notification channels...');

      final androidPlugin =
          _localNotifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidPlugin == null) {
        print('❌ [EPILIST] Android notification plugin not available');
        return;
      }

      final channels = [
        const AndroidNotificationChannel(
          _channelGeneral,
          'Général',
          description: 'Notifications générales',
          importance: Importance.defaultImportance,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFF4CAF50),
        ),
        const AndroidNotificationChannel(
          _channelBudgetAlerts,
          'Alertes Budget',
          description: 'Notifications de budget',
          importance: Importance.high,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFFFF5722),
        ),
        const AndroidNotificationChannel(
          _channelListUpdates,
          'Mises à jour de listes',
          description: 'Notifications de listes partagées',
          importance: Importance.defaultImportance,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFF2196F3),
        ),
        const AndroidNotificationChannel(
          _channelReminders,
          'Rappels',
          description: 'Rappels et alertes importantes',
          importance: Importance.high,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFFFFC107),
        ),
      ];

      for (final channel in channels) {
        await androidPlugin.createNotificationChannel(channel);
        print('📺 [EPILIST] Created channel: ${channel.id}');
      }

      print(
        '✅ [EPILIST] Android notification channels created: ${channels.length}',
      );
    } catch (e) {
      print('❌ [EPILIST] Error creating notification channels: $e');
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📨 [EPILIST] Handling foreground message...');
    print('📨 [EPILIST] Title: ${message.notification?.title}');
    print('📨 [EPILIST] Body: ${message.notification?.body}');
    print('📨 [EPILIST] Data: ${message.data}');

    // Afficher la notification locale sur Android en foreground
    if (Platform.isAndroid && message.notification != null) {
      await _showLocalNotification(message);
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      print('🔔 [EPILIST] Showing local notification...');

      final notification = message.notification;
      if (notification == null) {
        print('⚠️ [EPILIST] No notification data in message');
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        _channelGeneral,
        'Général',
        channelDescription: 'Notifications générales',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF4CAF50),
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFF4CAF50),
        ledOnMs: 1000, // ✅ Fix pour éviter l'erreur LED
        ledOffMs: 500, // ✅ Fix pour éviter l'erreur LED
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
        100000,
      );

      await _localNotifications.show(
        notificationId,
        notification.title ?? 'EpiList',
        notification.body ?? 'Nouvelle notification',
        details,
        payload: jsonEncode(message.data),
      );

      print('✅ [EPILIST] Local notification shown with ID: $notificationId');
    } catch (e) {
      print('❌ [EPILIST] Error showing local notification: $e');
    }
  }

  // Méthodes publiques et utilitaires
  static String? getCurrentToken() => _currentToken;
  static bool get isSimulator => _isSimulator;
  static bool get isInitialized => _isInitialized;

  static void updateContext(BuildContext context) {
    _context = context;
  }

  // ✅ FIX PRINCIPAL: Correction complète de la méthode isDeviceRegistered
  static Future<bool> isDeviceRegistered() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ Gérer les deux cas: bool et string de manière robuste
      final registeredValue = prefs.get('device_registered');
      bool isRegistered = false;

      if (registeredValue is bool) {
        // Cas normal: valeur stockée comme bool
        isRegistered = registeredValue;
      } else if (registeredValue is String) {
        // Cas alternatif: valeur stockée comme string
        isRegistered = registeredValue.toLowerCase() == 'true';
      } else if (registeredValue == null) {
        // Cas où la clé n'existe pas
        isRegistered = false;
      } else {
        // Cas inattendu: forcer false et nettoyer
        print(
          '⚠️ [EPILIST] Unexpected type for device_registered: ${registeredValue.runtimeType}',
        );
        await prefs.remove('device_registered');
        isRegistered = false;
      }

      final lastToken = prefs.getString('last_registered_token');

      final result =
          isRegistered && lastToken == _currentToken && _currentToken != null;

      print('🔍 [EPILIST] Device registration check: $result');
      print(
        '🔍 [EPILIST] - Registered: $isRegistered (type: ${registeredValue?.runtimeType})',
      );
      print('🔍 [EPILIST] - Token match: ${lastToken == _currentToken}');
      print('🔍 [EPILIST] - Current token present: ${_currentToken != null}');

      return result;
    } catch (e) {
      print('❌ [EPILIST] Error checking device registration: $e');
      // En cas d'erreur, nettoyer les préférences corrompues
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('device_registered');
        await prefs.remove('last_registered_token');
      } catch (cleanupError) {
        print('❌ [EPILIST] Error cleaning up preferences: $cleanupError');
      }
      return false;
    }
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
        print(
          '📱 [EPILIST] App opened from notification: ${initialMessage.notification?.title}',
        );
        await _handleNotificationOpened(initialMessage);
      }
    } catch (e) {
      print('❌ [EPILIST] Error checking initial message: $e');
    }
  }

  static Future<void> _handleNotificationOpened(RemoteMessage message) async {
    print('👆 [EPILIST] Notification opened: ${message.data}');
    // Handle notification opened
  }

  static Future<void> _onNotificationTapped(
    NotificationResponse response,
  ) async {
    print('👆 [EPILIST] Local notification tapped: ${response.payload}');
    // Handle local notification tapped
  }

  static void dispose() {
    _isInitialized = false;
    _deviceRegistrationInProgress = false;
  }
}

@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  print('📨 [EPILIST] Background message: ${message.notification?.title}');
  // Handle background messages
}
