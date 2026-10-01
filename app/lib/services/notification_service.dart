// services/notification_service.dart - VERSION OPTIMISÉE POUR LOGIN UNIQUEMENT

import 'package:epilist/blocs/chat/chat_bloc.dart';
import 'package:epilist/config/app_navigator.dart';
import 'package:epilist/screens/budget_screen.dart';
import 'package:epilist/screens/chat_screen.dart';
import 'package:epilist/screens/list_detail_screen.dart';
import 'package:epilist/screens/price_alerts_screen.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:epilist/services/chat_service.dart';
import 'package:epilist/services/shopping_list_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:epilist/config/app_config.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:epilist/services/token_store.dart';
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

  static String? _currentToken;
  static String? _apnsToken;
  static bool _isBasicInitialized = false;
  static bool _isFullyInitialized = false;
  static bool _deviceRegistrationInProgress = false;
  static bool _isSimulator = false;

  static const String _channelBudgetAlerts = 'budget_alerts';
  static const String _channelListUpdates = 'list_updates';
  static const String _channelReminders = 'reminders';
  static const String _channelMessages = 'messages';
  static const String _channelGeneral = 'general';

  // ✅ NOUVELLE MÉTHODE: Initialisation basique au démarrage (sans permissions)
  static Future<void> initializeBasic([BuildContext? context]) async {
    if (_isBasicInitialized) return;

    if (kDebugMode) {
      debugPrint('🔔 [EPILIST] Initialisation basique des notifications...');
    }

    try {
      // La navigation passe par appNavigatorKey (valable même quand
      // aucun écran n'est monté) : inutile de mémoriser un contexte ici.

      // 1. Détecter le simulateur
      await _detectSimulator();
      if (kDebugMode) {
        debugPrint(
          '📱 [EPILIST] Device type: ${_isSimulator ? "Simulator" : "Physical"}',
        );
      }

      // 2. Initialiser les notifications locales
      if (kDebugMode) {
        debugPrint('🔔 [EPILIST] Initializing local notifications...');
      }
      await _initializeLocalNotifications();

      // 3. Configurer les handlers de messages
      if (kDebugMode) {
        debugPrint('📨 [EPILIST] Setting up message handlers...');
      }
      await _setupMessageHandlers();

      _isBasicInitialized = true;
      if (kDebugMode) {
        debugPrint('✅ [EPILIST] Initialisation basique terminée (sans token)');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [EPILIST] Erreur lors de l\'initialisation basique: $e');
        debugPrint('📍 [EPILIST] Stack trace: $stackTrace');
      }
    }
  }

  // ✅ NOUVELLE MÉTHODE: Initialisation complète après connexion
  static Future<void> initializeAfterLogin() async {
    if (_isFullyInitialized) {
      if (kDebugMode) {
        debugPrint('ℹ️ [EPILIST] Notifications déjà complètement initialisées');
      }
      return;
    }

    if (!_isBasicInitialized) {
      await initializeBasic();
    }

    if (kDebugMode) {
      debugPrint(
        '🔔 [EPILIST] Initialisation complète des notifications après connexion...',
      );
    }

    try {
      // 1. Demander les permissions
      if (kDebugMode) {
        debugPrint('🔒 [EPILIST] Requesting permissions...');
      }
      await _requestPermissions();

      // 2. Gérer le token FCM
      if (kDebugMode) {
        debugPrint('🔑 [EPILIST] Handling FCM token...');
      }
      await _handlePushNotificationsToken();

      // 3. Vérifier les messages initiaux
      if (kDebugMode) {
        debugPrint('📬 [EPILIST] Checking initial messages...');
      }
      await _checkInitialMessage();

      _isFullyInitialized = true;
      if (kDebugMode) {
        debugPrint('✅ [EPILIST] Initialisation complète terminée!');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [EPILIST] Erreur lors de l\'initialisation complète: $e');
        debugPrint('📍 [EPILIST] Stack trace: $stackTrace');
      }
    }
  }

  // ✅ MÉTHODE OPTIMISÉE: Token refresh uniquement lors de la connexion
  static Future<void> _handlePushNotificationsToken() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 [EPILIST] Setting up token refresh listener...');
      }

      // Écouter les changements de token SEULEMENT si l'utilisateur est connecté
      _firebaseMessaging.onTokenRefresh
          .listen((fcmToken) async {
            if (kDebugMode) {
              debugPrint(
                '🔄 [EPILIST] FCM Token refreshed: ${fcmToken.substring(0, 20)}...',
              );
            }
            _currentToken = fcmToken;
            await _saveTokenToPreferences(fcmToken);

            if (Platform.isIOS && !_isSimulator && _apnsToken == null) {
              await _tryGetAPNSTokenSafe();
            }

            // ✅ OPTIMISATION: Enregistrer le token SEULEMENT si l'utilisateur est connecté
            final authToken = await TokenStore.readAccess();
            if (authToken != null && authToken.isNotEmpty) {
              await _registerDeviceWithToken();
            }
          })
          .onError((error) {
            if (kDebugMode) {
              debugPrint('❌ [EPILIST] Token refresh error: $error');
            }
          });

      await _getInitialTokenSafe();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EPILIST] Error in _handlePushNotificationsToken: $e');
      }
    }
  }

  static Future<void> _getInitialTokenSafe() async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 [EPILIST] Getting initial FCM token...');
      }

      // Traitement spécial iOS pour APNS
      if (Platform.isIOS && !_isSimulator) {
        if (kDebugMode) {
          debugPrint('🍎 [EPILIST] Preparing APNS for iOS...');
        }
        await _prepareAPNSForIPhone();
      }

      // Attendre un délai puis essayer d'obtenir un nouveau token
      if (kDebugMode) {
        debugPrint('⏳ [EPILIST] Waiting before token request...');
      }
      await Future.delayed(
        Duration(milliseconds: Platform.isAndroid ? 2000 : 8000),
      );

      await _tryGetTokenSafely();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EPILIST] Error in _getInitialTokenSafe: $e');
      }
    }
  }

  static Future<void> _tryGetTokenSafely() async {
    const maxAttempts = 3;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        if (kDebugMode) {
          debugPrint(
            '🔄 [EPILIST] Attempting to get FCM token (attempt $attempt/$maxAttempts)',
          );
        }

        final tokenFuture = _firebaseMessaging.getToken();
        final token = await tokenFuture.timeout(
          Duration(seconds: Platform.isAndroid ? 15 : 20),
          onTimeout: () {
            if (kDebugMode) {
              debugPrint('⏰ [EPILIST] Token request timeout on attempt $attempt');
            }
            return null;
          },
        );

        if (token != null && token.isNotEmpty) {
          _currentToken = token;
          await _saveTokenToPreferences(token);

          if (kDebugMode) {
            debugPrint('✅ [EPILIST] FCM token obtained: ${token.substring(0, 20)}...');
            debugPrint('📱 [EPILIST] Full token length: ${token.length}');
          }

          if (Platform.isIOS && !_isSimulator && _apnsToken == null) {
            await _tryGetAPNSTokenSafe();
          }

          // ✅ OPTIMISATION: Enregistrer le token SEULEMENT si l'utilisateur est connecté
          // Lance l'enregistrement en arrière-plan après un délai de 3 secondes
          final authToken = await TokenStore.readAccess();
          if (authToken != null && authToken.isNotEmpty) {
            // Attendre 3 secondes avant d'enregistrer pour ne pas bloquer le démarrage
            Future.delayed(const Duration(seconds: 3), () {
              // ignore: unawaited_futures
              _registerDeviceWithToken().then((_) {
                if (kDebugMode) {
                  debugPrint('✅ [EPILIST] Device registration completed in background');
                }
              }).catchError((e) {
                if (kDebugMode) {
                  debugPrint('⚠️ [EPILIST] Background device registration failed: $e');
                }
                // Réessayer dans 60 secondes
                Future.delayed(const Duration(seconds: 60), () {
                  _registerDeviceWithToken();
                });
              });
            });
            if (kDebugMode) {
              debugPrint('⏰ [EPILIST] Device registration scheduled in 3 seconds');
            }
          } else {
            if (kDebugMode) {
              debugPrint(
                'ℹ️ [EPILIST] Utilisateur non connecté, token stocké pour plus tard',
              );
            }
          }
          return;
        } else {
          if (kDebugMode) {
            debugPrint(
              '⚠️ [EPILIST] Empty or null token received on attempt $attempt',
            );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ [EPILIST] Error getting token (attempt $attempt): $e');
        }

        if (e.toString().contains('apns-token-not-set')) {
          if (kDebugMode) {
            debugPrint('ℹ️ [EPILIST] APNS token not set, this is normal for Android');
          }
          if (attempt == maxAttempts) {
            break;
          }
        }
      }

      if (attempt < maxAttempts) {
        final delay = Duration(milliseconds: Platform.isAndroid ? 2000 : 3000);
        if (kDebugMode) {
          debugPrint('⏳ [EPILIST] Waiting ${delay.inMilliseconds}ms before retry...');
        }
        await Future.delayed(delay);
      }
    }

    if (kDebugMode) {
      debugPrint('❌ [EPILIST] Failed to get FCM token after $maxAttempts attempts');
    }
  }

  static Future<void> _prepareAPNSForIPhone() async {
    if (_isSimulator || Platform.isAndroid) return;

    try {
      if (kDebugMode) {
        debugPrint('🍎 [EPILIST] Preparing APNS token...');
      }
      await Future.delayed(const Duration(milliseconds: 5000));

      final apnsToken = await _firebaseMessaging.getAPNSToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );

      if (apnsToken != null && apnsToken.isNotEmpty) {
        _apnsToken = apnsToken;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('apns_token', apnsToken);
        if (kDebugMode) {
          debugPrint(
            '✅ [EPILIST] APNS token obtained: ${apnsToken.substring(0, 20)}...',
          );
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ [EPILIST] APNS token is null or empty');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EPILIST] Error getting APNS token: $e');
      }
    }
  }

  static Future<void> _tryGetAPNSTokenSafe() async {
    if (_isSimulator || Platform.isAndroid) return;

    try {
      if (kDebugMode) {
        debugPrint('🍎 [EPILIST] Trying to get APNS token safely...');
      }
      await Future.delayed(const Duration(milliseconds: 2000));

      final apnsToken = await _firebaseMessaging.getAPNSToken().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('⏰ [EPILIST] APNS token request timeout');
          }
          return null;
        },
      );

      if (apnsToken != null && apnsToken.isNotEmpty) {
        _apnsToken = apnsToken;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('apns_token', apnsToken);

        // ✅ OPTIMISATION: Enregistrer seulement si connecté
        final authToken = await TokenStore.readAccess();
        if (authToken != null && authToken.isNotEmpty) {
          await _registerDeviceWithToken();
        }

        if (kDebugMode) {
          debugPrint(
            '✅ [EPILIST] APNS token updated: ${apnsToken.substring(0, 20)}...',
          );
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ [EPILIST] APNS token is null or empty');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EPILIST] Error getting APNS token safely: $e');
      }
    }
  }

  // ✅ NOUVELLE MÉTHODE: Enregistrement du device optimisé
  static Future<void> _registerDeviceWithToken() async {
    if (_deviceRegistrationInProgress) {
      if (kDebugMode) {
        debugPrint('⏳ [EPILIST] Device registration already in progress');
      }
      return;
    }

    if (_currentToken == null || _currentToken!.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ [EPILIST] No FCM token available for registration');
      }
      return;
    }

    _deviceRegistrationInProgress = true;

    try {
      if (kDebugMode) {
        debugPrint('🔄 [EPILIST] Starting device registration...');
      }

      final prefs = await SharedPreferences.getInstance();
      final authToken = await TokenStore.readAccess();

      if (authToken == null) {
        if (kDebugMode) {
          debugPrint('⚠️ [EPILIST] No auth token, skipping device registration');
        }
        return;
      }

      if (kDebugMode) {
        debugPrint(
          '🔄 [EPILIST] Registering device with FCM token: ${_currentToken!.substring(0, 20)}...',
        );
      }

      final deviceInfo = await _getDeviceInfo();
      final dio = Dio();
      dio.options.baseUrl = AppConfig.baseUrl;
      dio.options.headers['Authorization'] = 'Bearer $authToken';
      dio.options.headers['Content-Type'] = 'application/json';
      dio.options.connectTimeout = const Duration(seconds: 20);
      dio.options.receiveTimeout = const Duration(seconds: 120); // TEMPORARY: Very high for debugging
      dio.options.sendTimeout = const Duration(seconds: 20);

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

      if (kDebugMode) {
        debugPrint('📡 [EPILIST] Sending registration request...');
        debugPrint('📡 [EPILIST] Device data: $deviceData');
      }

      final response = await dio.post('/devices/register', data: deviceData);

      if (kDebugMode) {
        debugPrint('📡 [EPILIST] Registration response: ${response.statusCode}');
        debugPrint('📡 [EPILIST] Response data: ${response.data}');
      }

      if (response.statusCode == 201) {
        await prefs.setString('last_registered_token', _currentToken!);
        await prefs.setString('device_registered', 'true');

        if (kDebugMode) {
          debugPrint('✅ [EPILIST] Device registered successfully!');
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ [EPILIST] Unexpected response code: ${response.statusCode}');
        }
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        if (e.type == DioExceptionType.receiveTimeout) {
          debugPrint('⏱️ [EPILIST] Device registration timeout - Server is slow, will retry later');
        } else if (e.type == DioExceptionType.connectionTimeout) {
          debugPrint('⏱️ [EPILIST] Connection timeout - Network is slow');
        } else if (e.type == DioExceptionType.connectionError) {
          debugPrint('📡 [EPILIST] Connection error - Network unavailable');
        } else {
          debugPrint('❌ [EPILIST] Device registration failed: ${e.message}');
        }
        // Don't print full stack trace for timeout errors to avoid log spam
        if (e.type != DioExceptionType.receiveTimeout &&
            e.type != DioExceptionType.connectionTimeout) {
          debugPrint('📍 [EPILIST] Error details: ${e.response?.data}');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [EPILIST] Device registration failed: $e');
        debugPrint('📍 [EPILIST] Stack trace: $stackTrace');
      }
    } finally {
      _deviceRegistrationInProgress = false;
    }
  }

  static Future<void> _setupMessageHandlers() async {
    try {
      // Handler pour les messages en arrière-plan
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Handler pour les messages en premier plan
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        if (kDebugMode) {
          debugPrint(
            '📨 [EPILIST] Foreground message received: ${message.notification?.title}',
          );
          debugPrint('📨 [EPILIST] Message data: ${message.data}');
        }
        await _handleForegroundMessage(message);
      });

      // Handler pour l'ouverture de notification
      FirebaseMessaging.onMessageOpenedApp.listen((
        RemoteMessage message,
      ) async {
        if (kDebugMode) {
          debugPrint(
            '👆 [EPILIST] Notification opened app: ${message.notification?.title}',
          );
        }
        await _handleNotificationOpened(message);
      });

      if (kDebugMode) {
        debugPrint('✅ [EPILIST] Message handlers configured');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EPILIST] Error setting up message handlers: $e');
      }
    }
  }

  static Future<void> _requestPermissions() async {
    try {
      if (Platform.isIOS) {
        if (kDebugMode) {
          debugPrint('🍎 [EPILIST] Requesting iOS permissions...');
        }
        final result = await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          announcement: false,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
        );

        if (kDebugMode) {
          debugPrint(
            '🍎 [EPILIST] iOS notification permission: ${result.authorizationStatus}',
          );
        }

        await _firebaseMessaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } else if (Platform.isAndroid) {
        if (kDebugMode) {
          debugPrint('🤖 [EPILIST] Requesting Android permissions...');
        }

        // Permission pour les notifications (Android 13+)
        final notificationStatus = await Permission.notification.request();
        if (kDebugMode) {
          debugPrint(
            '🤖 [EPILIST] Android notification permission: $notificationStatus',
          );
        }

        // NOTE : on ne demande PAS ignoreBatteryOptimizations. FCM reveille
        // l'appareil pour les push et les rappels locaux utilisent des
        // alarmes systeme qui sonnent en Doze ; la permission etait inutile
        // et son usage injustifie est un motif de rejet Google Play.

        // Vérifier les permissions des notifications
        final isGranted = await Permission.notification.isGranted;
        if (kDebugMode) {
          debugPrint('🤖 [EPILIST] Notification permission granted: $isGranted');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EPILIST] Error requesting permissions: $e');
      }
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    try {
      if (kDebugMode) {
        debugPrint('🔔 [EPILIST] Initializing local notifications...');
      }

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

      if (kDebugMode) {
        debugPrint('🔔 [EPILIST] Local notifications initialized: $initialized');
      }

      if (Platform.isAndroid) {
        await _createNotificationChannels();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EPILIST] Error initializing local notifications: $e');
      }
    }
  }

  static Future<void> _createNotificationChannels() async {
    try {
      if (kDebugMode) {
        debugPrint('📺 [EPILIST] Creating Android notification channels...');
      }

      final androidPlugin =
          _localNotifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidPlugin == null) {
        if (kDebugMode) {
          debugPrint('❌ [EPILIST] Android notification plugin not available');
        }
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
          _channelMessages,
          'Messages',
          description: 'Notifications de nouveaux messages',
          importance: Importance.high,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFF9C27B0),
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
        if (kDebugMode) {
          debugPrint('📺 [EPILIST] Created channel: ${channel.id}');
        }
      }

      if (kDebugMode) {
        debugPrint(
          '✅ [EPILIST] Android notification channels created: ${channels.length}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EPILIST] Error creating notification channels: $e');
      }
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint('📨 [EPILIST] Handling foreground message...');
      debugPrint('📨 [EPILIST] Title: ${message.notification?.title}');
      debugPrint('📨 [EPILIST] Body: ${message.notification?.body}');
      debugPrint('📨 [EPILIST] Data: ${message.data}');
    }

    // Afficher la notification locale sur Android en foreground
    if (Platform.isAndroid && message.notification != null) {
      await _showLocalNotification(message);
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      if (kDebugMode) {
        debugPrint('🔔 [EPILIST] Showing local notification...');
      }

      final notification = message.notification;
      if (notification == null) {
        if (kDebugMode) {
          debugPrint('⚠️ [EPILIST] No notification data in message');
        }
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
        ledOnMs: 1000,
        ledOffMs: 500,
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

      if (kDebugMode) {
        debugPrint('✅ [EPILIST] Local notification shown with ID: $notificationId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EPILIST] Error showing local notification: $e');
      }
    }
  }

  // ✅ MÉTHODES PUBLIQUES OPTIMISÉES

  static String? getCurrentToken() => _currentToken;
  static bool get isSimulator => _isSimulator;
  static bool get isBasicInitialized => _isBasicInitialized;
  static bool get isFullyInitialized => _isFullyInitialized;

  /// Signale que l'application est prête (ou revenue au premier plan).
  static void updateContext(BuildContext context) {
    // L'application vient d'être prête (ou de revenir au premier plan) :
    // c'est le moment d'honorer une notification touchée plus tôt.
    final pending = _pendingNotification;
    if (pending != null) {
      _pendingNotification = null;
      _openFromNotification(pending);
    }
  }

  static Future<bool> isDeviceRegistered() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final registeredValue = prefs.get('device_registered');
      bool isRegistered = false;

      if (registeredValue is bool) {
        isRegistered = registeredValue;
      } else if (registeredValue is String) {
        isRegistered = registeredValue.toLowerCase() == 'true';
      } else if (registeredValue == null) {
        isRegistered = false;
      } else {
        if (kDebugMode) {
          debugPrint(
            '⚠️ [EPILIST] Unexpected type for device_registered: ${registeredValue.runtimeType}',
          );
        }
        await prefs.remove('device_registered');
        isRegistered = false;
      }

      final lastToken = prefs.getString('last_registered_token');
      final result =
          isRegistered && lastToken == _currentToken && _currentToken != null;

      if (kDebugMode) {
        debugPrint('🔍 [EPILIST] Device registration check: $result');
        debugPrint(
          '🔍 [EPILIST] - Registered: $isRegistered (type: ${registeredValue?.runtimeType})',
        );
        debugPrint('🔍 [EPILIST] - Token match: ${lastToken == _currentToken}');
        debugPrint('🔍 [EPILIST] - Current token present: ${_currentToken != null}');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EPILIST] Error checking device registration: $e');
      }
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('device_registered');
        await prefs.remove('last_registered_token');
      } catch (cleanupError) {
        if (kDebugMode) {
          debugPrint('❌ [EPILIST] Error cleaning up preferences: $cleanupError');
        }
      }
      return false;
    }
  }

  // ✅ NOUVELLE MÉTHODE: Enregistrement lors de la connexion UNIQUEMENT
  static Future<void> registerAfterLogin() async {
    if (!_isFullyInitialized) {
      await initializeAfterLogin();
    }

    if (_currentToken == null || _currentToken!.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ [EPILIST] No FCM token available for registration after login');
      }
      return;
    }

    await _registerDeviceWithToken();
  }

  static Future<void> ensureDeviceIsRegistered() async {
    if (_currentToken == null || _currentToken!.isEmpty) {
      return;
    }

    final isRegistered = await isDeviceRegistered();
    if (!isRegistered) {
      await _registerDeviceWithToken();
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
    await _registerDeviceWithToken();
  }

  static Future<void> reRegisterDeviceWithTokenRefresh() async {
    await forceTokenRefresh();
  }

  static Future<void> reRegisterDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_registered_token');
    await prefs.remove('device_registered');
    _deviceRegistrationInProgress = false;
    await _registerDeviceWithToken();
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
    _isBasicInitialized = false;
    _isFullyInitialized = false;
    _deviceRegistrationInProgress = false;

    if (Platform.isAndroid) {
      try {
        await _firebaseMessaging.deleteToken();
      } catch (e) {
        // Continue cleanup
      }
    }
  }

  // ✅ MÉTHODES UTILITAIRES (INCHANGÉES)

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
        if (kDebugMode) {
          debugPrint(
            '📱 [EPILIST] App opened from notification: ${initialMessage.notification?.title}',
          );
        }
        await _handleNotificationOpened(initialMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EPILIST] Error checking initial message: $e');
      }
    }
  }

  // =====================================================================
  // OUVERTURE DE L'ÉCRAN CONCERNÉ PAR LA NOTIFICATION
  //
  // Trois chemins mènent ici : application au premier plan (notification
  // locale touchée), en arrière-plan (onMessageOpenedApp), ou fermée
  // (getInitialMessage au lancement). Dans ce dernier cas le navigateur
  // n'existe pas encore : l'ouverture est MÉMORISÉE puis rejouée dès que
  // l'application est prête (updateContext).
  // =====================================================================

  /// Ouverture différée en attente (démarrage à froid, ou session pas
  /// encore ouverte).
  static Map<String, dynamic>? _pendingNotification;

  static Future<void> _handleNotificationOpened(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint('👆 [EPILIST] Notification ouverte: ${message.data}');
    }
    await _openFromNotification(Map<String, dynamic>.from(message.data));
  }

  static Future<void> _onNotificationTapped(
    NotificationResponse response,
  ) async {
    if (kDebugMode) {
      debugPrint('👆 [EPILIST] Notification locale touchée: ${response.payload}');
    }
    try {
      if (response.payload == null) return;
      final decoded = jsonDecode(response.payload!);
      if (decoded is Map) {
        await _openFromNotification(Map<String, dynamic>.from(decoded));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EPILIST] Charge utile illisible: $e');
      }
    }
  }

  /// Aiguillage : quel écran ouvrir pour cette notification ?
  static Future<void> _openFromNotification(Map<String, dynamic> data) async {
    final navigator = appNavigatorKey.currentState;
    final context = appNavigatorKey.currentContext;

    // Application pas encore prête : on rejouera (voir updateContext).
    if (navigator == null || context == null) {
      _pendingNotification = data;
      return;
    }

    // Services lus AVANT toute attente : un BuildContext ne doit pas
    // traverser un « await » (il peut ne plus être valide après).
    final authService = context.read<AuthService>();
    final listService = context.read<ShoppingListService>();

    // Jamais par-dessus l'écran de connexion : sans session, on garde
    // l'ouverture en attente jusqu'à ce que l'utilisateur se connecte.
    final token = await TokenStore.readAccess();
    if (token == null || token.isEmpty) {
      _pendingNotification = data;
      return;
    }

    _pendingNotification = null;

    final action = (data['action'] ?? '').toString();
    final type = (data['type'] ?? '').toString();
    final listId = int.tryParse((data['list_id'] ?? '').toString());
    final listName = (data['list_name'] ?? '').toString();

    try {
      if (action == 'open_chat' && listId != null) {
        await _openChat(navigator, authService, listId, listName);
        return;
      }

      final opensList = action == 'open_list' ||
          action == 'add_receipt' ||
          type == 'list_updated' ||
          type == 'list_shared' ||
          type == 'list_completed';
      if (opensList && listId != null) {
        await _openList(navigator, listService, listId);
        return;
      }

      if (type.startsWith('budget')) {
        navigator.push(
            MaterialPageRoute(builder: (_) => const BudgetScreen()));
        return;
      }

      if (type == 'price_alert') {
        navigator.push(
            MaterialPageRoute(builder: (_) => const PriceAlertsScreen()));
        return;
      }

      // Type inconnu : ne rien ouvrir vaut mieux qu'ouvrir au hasard.
      if (kDebugMode) {
        debugPrint('ℹ️ [EPILIST] Notification sans écran associé (type=$type)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [EPILIST] Ouverture impossible: $e');
      }
    }
  }

  /// Conversation d'une liste (mêmes dépendances que depuis l'app).
  static Future<void> _openChat(
    NavigatorState navigator,
    AuthService authService,
    int listId,
    String listName,
  ) async {
    final token = await authService.getToken();
    final dio = Dio()
      ..options.baseUrl = AppConfig.baseUrl
      ..options.headers['Authorization'] = 'Bearer $token';

    navigator.push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => ChatBloc(chatService: ChatService(dio: dio)),
          child: ChatScreen(listId: listId, listName: listName),
        ),
      ),
    );
  }

  /// Détail d'une liste : la notification ne porte que son identifiant,
  /// l'objet complet est donc récupéré avant d'ouvrir l'écran.
  static Future<void> _openList(
    NavigatorState navigator,
    ShoppingListService listService,
    int listId,
  ) async {
    final list = await listService.getShoppingListById(listId);
    navigator.push(
      MaterialPageRoute(builder: (_) => ListDetailScreen(shoppingList: list)),
    );
  }

  static void dispose() {
    _isBasicInitialized = false;
    _isFullyInitialized = false;
    _deviceRegistrationInProgress = false;
  }
}

@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('📨 [EPILIST] Background message: ${message.notification?.title}');
  }
  // Handle background messages
}
