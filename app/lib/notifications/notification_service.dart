// notifications/notification_service.dart - VERSION SIMPLE ET CORRIGÉE

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Initialise le service de notifications
  static Future<void> initialize() async {
    if (_initialized) return;

    print('🔄 Initialisation NotificationService...');

    // 1. Initialiser les fuseaux horaires
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Toronto'));

    // 2. Configuration Android
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // 3. Configuration iOS - VERSION CORRIGÉE (sans onDidReceiveLocalNotification)
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 4. Initialisation
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      print('✅ Plugin initialisé avec succès');
    } catch (e) {
      print('❌ Erreur initialisation plugin: $e');
      rethrow;
    }

    // 5. Créer le canal Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }

    // 6. Demander les permissions
    await _requestPermissions();

    _initialized = true;
    print('✅ NotificationService initialisé avec succès');
  }

  /// Créer le canal de notification pour Android
  static Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'epilist_main',
      'EpiList Notifications',
      description: 'Notifications principales d\'EpiList',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    print('✅ Canal Android créé');
  }

  /// Demander les permissions
  static Future<bool> _requestPermissions() async {
    print('🔐 Demande de permissions...');

    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      print('📱 Android permission: $status');

      if (status != PermissionStatus.granted) {
        print('❌ Permission notifications Android refusée');
        return false;
      }
    }

    if (Platform.isIOS) {
      print('📱 Demande permission iOS...');

      final bool? result = await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      print('📱 Résultat permission iOS: $result');

      if (result != true) {
        print('❌ Permission iOS refusée ou émulateur détecté');
        print('💡 Utilisez un iPhone physique pour tester les notifications');
        return false;
      }
    }

    print('✅ Permissions accordées');
    return true;
  }

  /// Gestionnaire des taps sur notifications
  static void _onNotificationTapped(NotificationResponse response) {
    print(
      '🔔 Notification tapée - ID: ${response.id}, Payload: ${response.payload}',
    );

    // Ici vous pouvez naviguer selon le payload
    switch (response.payload) {
      case 'shopping_reminder':
        print('➡️ Navigation vers liste');
        break;
      case 'budget_alert':
        print('➡️ Navigation vers budget');
        break;
      case 'test':
        print('🧪 Test notification reçue');
        break;
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
      return;
    }

    print('📤 Envoi notification: $title');

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

      print('✅ Notification envoyée');
    } catch (e) {
      print('❌ Erreur envoi notification: $e');

      if (Platform.isIOS) {
        print('💡 Sur émulateur iOS, les notifications ne s\'affichent pas');
        print('📱 Testez sur un iPhone physique ou utilisez Android');
      }
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
      return;
    }

    if (scheduledTime.isBefore(DateTime.now())) {
      print('❌ Date dans le passé');
      return;
    }

    print('⏰ Programmation notification pour: $scheduledTime');

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
        // ✅ CORRECTION: androidScheduleMode est TOUJOURS requis, même sur iOS
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      print('✅ Notification programmée');
    } catch (e) {
      print('❌ Erreur programmation: $e');
    }
  }

  /// Vérifier les permissions
  static Future<bool> hasPermissions() async {
    if (Platform.isAndroid) {
      return await Permission.notification.isGranted;
    }

    if (Platform.isIOS) {
      final settings = await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return settings ?? false;
    }

    return false;
  }

  /// Annuler une notification
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    print('❌ Notification $id annulée');
  }

  /// Obtenir les notifications en attente
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}

// ===================================
// EpiList Notifications - Version simple
// ===================================

class EpiListNotifications {
  // Test de base
  static Future<void> testNotification() async {
    await NotificationService.showNotification(
      id: 999,
      title: "🧪 Test EpiList",
      body: "Les notifications fonctionnent !",
      payload: 'test',
    );
  }

  // Test programmé
  static Future<void> testScheduled() async {
    await NotificationService.scheduleNotification(
      id: 998,
      title: "⏰ Test Programmé",
      body: "Notification programmée il y a 10 secondes",
      scheduledTime: DateTime.now().add(const Duration(seconds: 10)),
      payload: 'test_scheduled',
    );

    print('⏰ Notification programmée dans 10 secondes...');
  }

  // Rappel courses
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

  // Alerte budget
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

  // Liste terminée
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
