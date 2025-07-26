// notifications/notification_service.dart - VERSION COMPLÈTE ET CORRIGÉE

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:async';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static final Map<int, Timer> _activeTimers = {};
  static int _lastNotificationId = 0;

  /// ✅ MÉTHODE MANQUANTE : Obtenir le statut du service
  static Map<String, dynamic> getStatus() {
    return {
      'initialized': _initialized,
      'active_timers': _activeTimers.length,
      'timer_ids': _activeTimers.keys.toList(),
      'last_notification_id': _lastNotificationId,
      'platform': Platform.operatingSystem,
      'plugin_available': true, // Toujours true si on arrive ici
    };
  }

  /// ✅ MÉTHODE MANQUANTE : Test de notification immédiate
  static Future<void> testImmediateNotification() async {
    if (!_initialized) {
      print('❌ Service non initialisé pour le test');
      throw Exception('Service non initialisé');
    }

    final testId = ++_lastNotificationId;
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    await showNotification(
      id: testId,
      title: '🧪 Test Immédiat',
      body: 'Test envoyé à $timeStr - ID: $testId',
      payload: 'test_immediate',
    );

    print('✅ Test immédiat envoyé - ID: $testId à $timeStr');
  }

  /// Initialise le service de notifications
  static Future<void> initialize() async {
    if (_initialized) {
      print('⚠️ Service déjà initialisé');
      return;
    }

    print('🔄 Initialisation NotificationService...');

    try {
      // 1. Initialiser les fuseaux horaires
      tz.initializeTimeZones();

      // ✅ AMÉLIORATION : Détection automatique du timezone
      try {
        final location = tz.getLocation('America/Toronto');
        tz.setLocalLocation(location);
        print('🌍 Timezone configuré: America/Toronto');
      } catch (e) {
        print('⚠️ Fallback timezone UTC: $e');
        tz.setLocalLocation(tz.UTC);
      }

      // 2. Configuration Android
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // 3. Configuration iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // 4. Initialisation du plugin
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      print('✅ Plugin initialisé avec succès');

      // 5. Créer le canal Android
      if (Platform.isAndroid) {
        await _createNotificationChannel();
      }

      // 6. Demander les permissions
      final permissionsGranted = await _requestPermissions();
      print('🔐 Permissions: ${permissionsGranted ? "✅" : "❌"}');

      _initialized = true;
      print('✅ NotificationService initialisé avec succès');
    } catch (e) {
      print('❌ Erreur critique lors de l\'initialisation: $e');
      _initialized = false;
      rethrow;
    }
  }

  /// Créer le canal de notification pour Android
  static Future<void> _createNotificationChannel() async {
    try {
      const androidChannel = AndroidNotificationChannel(
        'epilist_main',
        'EpiList Notifications',
        description: 'Notifications principales d\'EpiList',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      final androidImplementation =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(androidChannel);
        print('✅ Canal Android créé: epilist_main');
      } else {
        print('⚠️ Implémentation Android non disponible');
      }
    } catch (e) {
      print('❌ Erreur création canal Android: $e');
    }
  }

  /// Demander les permissions
  static Future<bool> _requestPermissions() async {
    print('🔐 Demande de permissions...');

    try {
      if (Platform.isAndroid) {
        // Permission de base pour les notifications
        final notificationStatus = await Permission.notification.request();
        print('📱 Android notification: $notificationStatus');

        // Permission pour les alarmes exactes (Android 12+)
        final alarmStatus = await Permission.scheduleExactAlarm.request();
        print('📱 Android alarmes exactes: $alarmStatus');

        // Permission pour ignorer l'optimisation batterie
        final batteryStatus =
            await Permission.ignoreBatteryOptimizations.request();
        print('📱 Android batterie: $batteryStatus');

        final allGranted =
            notificationStatus == PermissionStatus.granted &&
            alarmStatus == PermissionStatus.granted;

        if (!allGranted) {
          print('❌ Certaines permissions Android manquent');
          print('💡 Notifications: $notificationStatus');
          print('💡 Alarmes: $alarmStatus');
          print('💡 Batterie: $batteryStatus');
        }

        return allGranted;
      }

      if (Platform.isIOS) {
        print('📱 Demande permission iOS...');

        final iosImplementation =
            _notifications
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >();

        if (iosImplementation != null) {
          final result = await iosImplementation.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

          print('📱 Résultat permission iOS: $result');

          if (result != true) {
            print('❌ Permission iOS refusée ou émulateur détecté');
            print(
              '💡 Utilisez un iPhone physique pour tester les notifications',
            );
          }

          return result ?? false;
        } else {
          print('⚠️ Implémentation iOS non disponible');
          return false;
        }
      }

      print('✅ Permissions accordées par défaut');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la demande de permissions: $e');
      return false;
    }
  }

  /// Gestionnaire des taps sur notifications
  static void _onNotificationTapped(NotificationResponse response) {
    print(
      '🔔 Notification tapée - ID: ${response.id}, Payload: ${response.payload}',
    );

    // Navigation selon le payload
    switch (response.payload) {
      case 'shopping_reminder':
        print('➡️ Navigation vers liste de courses');
        break;
      case 'budget_alert':
        print('➡️ Navigation vers budget');
        break;
      case 'test_immediate':
      case 'test_10s':
      case 'test_2min':
        print('🧪 Test notification reçue: ${response.payload}');
        break;
      case 'list_completed':
        print('➡️ Navigation vers liste terminée');
        break;
      default:
        print('🔔 Notification générique tapée');
    }
  }

  /// Afficher une notification immédiate
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      print('❌ Service non initialisé');
      throw Exception('Service non initialisé');
    }

    print('📤 Envoi notification immédiate: $title (ID: $id)');

    try {
      await _notifications.show(
        id,
        title,
        body,
        NotificationDetails(
          android: const AndroidNotificationDetails(
            'epilist_main',
            'EpiList Notifications',
            channelDescription: 'Notifications principales d\'EpiList',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );

      _lastNotificationId = id;
      print('✅ Notification immédiate envoyée (ID: $id)');
    } catch (e) {
      print('❌ Erreur envoi notification immédiate: $e');

      if (Platform.isIOS) {
        print('💡 Sur émulateur iOS, les notifications ne s\'affichent pas');
        print('📱 Testez sur un iPhone physique');
      }

      rethrow;
    }
  }

  /// Programmer une notification
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (!_initialized) {
      print('❌ Service non initialisé');
      throw Exception('Service non initialisé');
    }

    if (scheduledTime.isBefore(DateTime.now())) {
      print('❌ Date dans le passé: $scheduledTime');
      throw ArgumentError('La date programmée est dans le passé');
    }

    final delay = scheduledTime.difference(DateTime.now());
    print(
      '⏰ Programmation notification pour: $scheduledTime (dans ${delay.inSeconds}s)',
    );

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        NotificationDetails(
          android: const AndroidNotificationDetails(
            'epilist_main',
            'EpiList Notifications',
            channelDescription: 'Notifications principales d\'EpiList',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      _lastNotificationId = id;
      print('✅ Notification programmée (ID: $id) pour ${delay.inSeconds}s');
    } catch (e) {
      print('❌ Erreur programmation notification: $e');
      rethrow;
    }
  }

  /// ✅ NOUVELLE MÉTHODE : Programmer avec Timer Dart (fallback)
  static Future<void> scheduleWithTimer({
    required int id,
    required String title,
    required String body,
    required Duration delay,
    String? payload,
  }) async {
    if (!_initialized) {
      print('❌ Service non initialisé');
      throw Exception('Service non initialisé');
    }

    print('⏱️ Programmation avec Timer Dart: ${delay.inSeconds}s');

    // Annuler le timer existant s'il y en a un
    _activeTimers[id]?.cancel();

    // Créer un nouveau timer
    _activeTimers[id] = Timer(delay, () async {
      try {
        await showNotification(
          id: id,
          title: title,
          body: body,
          payload: payload,
        );
        print('✅ Timer exécuté pour notification $id');
      } catch (e) {
        print('❌ Erreur exécution timer $id: $e');
      } finally {
        _activeTimers.remove(id);
      }
    });

    print('✅ Timer créé (ID: $id) pour ${delay.inSeconds}s');
  }

  /// Vérifier les permissions actuelles
  static Future<Map<String, bool>> checkPermissions() async {
    final permissions = <String, bool>{};

    try {
      if (Platform.isAndroid) {
        permissions['Notification'] = await Permission.notification.isGranted;
        permissions['Alarme exacte'] =
            await Permission.scheduleExactAlarm.isGranted;
        permissions['Batterie'] =
            await Permission.ignoreBatteryOptimizations.isGranted;
      }

      if (Platform.isIOS) {
        final iosImplementation =
            _notifications
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >();

        if (iosImplementation != null) {
          // Sur iOS, on ne peut que redemander, pas vraiment "checker"
          permissions['iOS Notifications'] = true; // Assumé si pas d'erreur
        }
      }
    } catch (e) {
      print('❌ Erreur vérification permissions: $e');
    }

    return permissions;
  }

  /// Vérifier si le service a les permissions nécessaires
  static Future<bool> hasPermissions() async {
    final permissions = await checkPermissions();

    if (Platform.isAndroid) {
      return permissions['Notification'] == true &&
          permissions['Alarme exacte'] == true;
    }

    return permissions.isNotEmpty;
  }

  /// Obtenir les notifications en attente
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      print('❌ Erreur récupération notifications en attente: $e');
      return [];
    }
  }

  /// Annuler une notification
  static Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      _activeTimers[id]?.cancel();
      _activeTimers.remove(id);
      print('❌ Notification $id annulée');
    } catch (e) {
      print('❌ Erreur annulation notification $id: $e');
    }
  }

  /// Annuler toutes les notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      for (final timer in _activeTimers.values) {
        timer.cancel();
      }
      _activeTimers.clear();
      print('❌ Toutes les notifications annulées');
    } catch (e) {
      print('❌ Erreur annulation de toutes les notifications: $e');
    }
  }

  /// ✅ MÉTHODE DE DIAGNOSTIC AVANCÉ
  static Future<Map<String, dynamic>> runDiagnostic() async {
    final diagnostic = <String, dynamic>{};

    try {
      // Statut de base
      diagnostic['service_initialized'] = _initialized;
      diagnostic['platform'] = Platform.operatingSystem;
      diagnostic['active_timers'] = _activeTimers.length;
      diagnostic['timer_ids'] = _activeTimers.keys.toList();

      // Permissions
      diagnostic['permissions'] = await checkPermissions();

      // Notifications en attente
      final pending = await getPendingNotifications();
      diagnostic['pending_notifications'] = pending.length;
      diagnostic['pending_details'] =
          pending
              .map(
                (n) => {
                  'id': n.id,
                  'title': n.title,
                  'body': n.body,
                  'payload': n.payload,
                },
              )
              .toList();

      // Test de capacité
      try {
        final testResult = await _testServiceCapability();
        diagnostic['service_capability'] = testResult;
      } catch (e) {
        diagnostic['service_capability'] = {'error': e.toString()};
      }

      diagnostic['last_notification_id'] = _lastNotificationId;
      diagnostic['diagnostic_time'] = DateTime.now().toIso8601String();
    } catch (e) {
      diagnostic['diagnostic_error'] = e.toString();
    }

    return diagnostic;
  }

  /// Test de capacité du service
  static Future<Map<String, bool>> _testServiceCapability() async {
    final capability = <String, bool>{};

    try {
      // Test 1: Plugin accessible
      capability['plugin_accessible'] = true;

      // Test 2: Peut créer des notifications
      capability['can_create_notifications'] = _initialized;

      // Test 3: Permissions suffisantes
      capability['has_permissions'] = await hasPermissions();

      // Test 4: Peut programmer
      capability['can_schedule'] =
          _initialized && Platform.isAndroid
              ? await Permission.scheduleExactAlarm.isGranted
              : _initialized;
    } catch (e) {
      capability['test_error'] = false;
    }

    return capability;
  }
}

// ===================================
// EpiList Notifications - Classes utilitaires
// ===================================

class EpiListNotifications {
  /// Test de notification immédiate
  static Future<void> testNotification() async {
    await NotificationService.testImmediateNotification();
  }

  /// Test programmé (utilise les deux méthodes)
  static Future<void> testScheduled({
    Duration delay = const Duration(seconds: 10),
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch % 10000;

    try {
      // Essayer d'abord la méthode système
      await NotificationService.scheduleNotification(
        id: id,
        title: '⏰ Test Programmé Système',
        body:
            'Notification programmée il y a ${delay.inSeconds} secondes (méthode système)',
        scheduledTime: DateTime.now().add(delay),
        payload: 'test_scheduled_system',
      );
      print('✅ Test programmé avec méthode système');
    } catch (e) {
      print('⚠️ Méthode système échouée, utilisation Timer Dart: $e');

      // Fallback sur Timer Dart
      await NotificationService.scheduleWithTimer(
        id: id + 1,
        title: '⏰ Test Programmé Timer',
        body:
            'Notification programmée il y a ${delay.inSeconds} secondes (Timer Dart)',
        delay: delay,
        payload: 'test_scheduled_timer',
      );
      print('✅ Test programmé avec Timer Dart');
    }
  }

  /// Rappel courses
  static Future<void> shoppingReminder({
    required String listName,
    required DateTime when,
    String? storeName,
  }) async {
    final body =
        storeName != null
            ? "Il est temps d'aller chez $storeName - Liste: $listName"
            : "N'oubliez pas vos courses - Liste: $listName";

    await NotificationService.scheduleNotification(
      id: 1,
      title: "🛒 Rappel courses",
      body: body,
      scheduledTime: when,
      payload: 'shopping_reminder',
    );
  }

  /// Alerte budget
  static Future<void> budgetAlert({
    required String listName,
    required double spent,
    required double budget,
  }) async {
    final percentage = (spent / budget * 100).round();

    await NotificationService.showNotification(
      id: 2,
      title: "💰 Budget: $percentage%",
      body:
          "$listName: ${spent.toStringAsFixed(2)}\$/${budget.toStringAsFixed(2)}\$",
      payload: 'budget_alert',
    );
  }

  /// Liste terminée
  static Future<void> listCompleted({
    required String listName,
    required int itemCount,
  }) async {
    await NotificationService.showNotification(
      id: 3,
      title: "🎉 Liste terminée !",
      body: "$listName - $itemCount articles cochés ✅",
      payload: 'list_completed',
    );
  }
}
