// notifications/notification_service.dart - VERSION COMPLÈTE OPTIMISÉE POUR ANDROID PHYSIQUE

import 'dart:async';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  
  // ✅ NOUVEAU: Gestion des timers pour courtes périodes
  static final Map<int, Timer> _activeTimers = {};

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

    // 3. Configuration iOS
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
      'epilist_shopping_reminders',
      'Rappels de courses EpiList',
      description: 'Notifications de rappels pour vos listes de courses',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      enableLights: true,
      ledColor: Color(0xFF4CAF50),
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    print('✅ Canal Android créé: ${androidChannel.id}');
  }

  /// Demander les permissions - VERSION COMPLÈTE
  static Future<bool> _requestPermissions() async {
    print('🔐 Demande de permissions...');

    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();
      print('📱 Version Android détectée: $androidInfo');

      // Permission notifications (Android 13+)
      final notificationStatus = await Permission.notification.request();
      print('📱 Permission notification: $notificationStatus');

      // Permission alarmes exactes (Android 12+)
      try {
        final scheduleExactAlarmStatus = await Permission.scheduleExactAlarm.request();
        print('⏰ Permission alarmes exactes: $scheduleExactAlarmStatus');
      } catch (e) {
        print('⚠️ Permission alarmes exactes non disponible: $e');
      }

      // ✅ NOUVEAU: Permission optimisation batterie
      try {
        final batteryStatus = await Permission.ignoreBatteryOptimizations.request();
        print('🔋 Permission batterie: $batteryStatus');
        
        if (batteryStatus != PermissionStatus.granted) {
          await _showBatteryOptimizationInstructions();
        }
      } catch (e) {
        print('⚠️ Permission batterie non disponible: $e');
      }

      if (notificationStatus != PermissionStatus.granted) {
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
        print('❌ Permission iOS refusée');
        return false;
      }
    }

    print('✅ Permissions accordées');
    return true;
  }

  /// ✅ NOUVEAU: Instructions optimisation batterie
  static Future<void> _showBatteryOptimizationInstructions() async {
    print('🔋 IMPORTANT: Optimisation de batterie détectée');
    print('💡 Pour des notifications fiables, désactivez l\'optimisation:');
    print('   1. Ouvrez les Paramètres Android');
    print('   2. Apps et notifications > Voir toutes les apps');
    print('   3. EpiList > Batterie > Non optimisée');
    print('   OU');
    print('   1. Paramètres > Batterie > Optimisation de batterie');
    print('   2. Recherchez EpiList > Ne pas optimiser');
  }

  /// Récupérer version Android
  static Future<String> _getAndroidVersion() async {
    try {
      return 'Android version détectée';
    } catch (e) {
      return 'Version inconnue';
    }
  }

  /// Gestionnaire des taps sur notifications
  static void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapée - ID: ${response.id}, Payload: ${response.payload}');

    switch (response.payload) {
      case 'shopping_reminder':
        print('➡️ Navigation vers liste de courses');
        break;
      case 'budget_alert':
        print('➡️ Navigation vers budget');
        break;
      case 'test':
      case 'test_immediate':
      case 'test_10_seconds':
      case 'test_30_seconds':
        print('🧪 Test notification reçue');
        break;
    }
  }

  /// ✅ MÉTHODE PRINCIPALE OPTIMISÉE: Programmer une notification
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (!_initialized) {
      print('❌ Service non initialisé');
      await initialize();
    }

    final now = DateTime.now();
    if (scheduledTime.isBefore(now)) {
      print('❌ Date dans le passé: $scheduledTime');
      return;
    }

    final difference = scheduledTime.difference(now);
    print('⏰ Programmation notification pour: $scheduledTime');
    print('⏰ Dans: ${difference.inMinutes}min ${difference.inSeconds % 60}s');

    // ✅ SOLUTION HYBRIDE: Choisir la meilleure méthode selon la durée
    if (Platform.isAndroid && difference.inMinutes <= 10) {
      // Pour Android et périodes ≤ 10 minutes: utiliser Timer Dart
      print('⚡ Période courte détectée, utilisation Timer Dart');
      await _scheduleWithDartTimer(id, title, body, difference, payload);
    } else {
      // Pour iOS ou périodes > 10 minutes: utiliser planification système
      print('📅 Période longue, utilisation planification système');
      await _scheduleWithSystemNotification(id, title, body, scheduledTime, payload);
    }
  }

  /// ✅ NOUVEAU: Planification avec Timer Dart (pour courtes périodes Android)
  static Future<void> _scheduleWithDartTimer(
    int id,
    String title,
    String body,
    Duration delay,
    String? payload,
  ) async {
    print('⏱️ Configuration Timer Dart pour ${delay.inSeconds}s');
    
    // Annuler timer existant pour cet ID si il existe
    _activeTimers[id]?.cancel();
    
    // Créer nouveau timer
    _activeTimers[id] = Timer(delay, () async {
      print('🔔 ⏰ Déclenchement timer pour notification $id');
      
      await showNotification(
        id: id,
        title: title,
        body: body,
        payload: payload,
      );
      
      // Nettoyer le timer de la map
      _activeTimers.remove(id);
      print('✅ Notification courte envoyée via Timer Dart');
    });

    print('✅ Timer Dart programmé pour ${delay.inSeconds} secondes');
    print('📊 Timers actifs: ${_activeTimers.length}');
  }

  /// ✅ NOUVEAU: Planification système (pour périodes longues ou iOS)
  static Future<void> _scheduleWithSystemNotification(
    int id,
    String title,
    String body,
    DateTime scheduledTime,
    String? payload,
  ) async {
    print('📅 Configuration planification système');
    
    try {
      final scheduledTZ = tz.TZDateTime.from(scheduledTime, tz.local);
      print('⏰ Heure TZ: $scheduledTZ');

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTZ,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'epilist_shopping_reminders',
            'Rappels de courses EpiList',
            channelDescription: 'Notifications de rappels pour vos listes de courses',
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
            enableLights: true,
            ledColor: const Color(0xFF4CAF50),
            autoCancel: true,
            fullScreenIntent: true,
            styleInformation: BigTextStyleInformation(
              body,
              contentTitle: title,
              summaryText: 'EpiList',
            ),
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

      print('✅ Notification système programmée avec succès');
      await _verifyScheduledNotification(id);
      
    } catch (e) {
      print('❌ Erreur planification système: $e');
      
      // Fallback pour très courtes périodes
      final difference = scheduledTime.difference(DateTime.now());
      if (difference.inMinutes <= 2) {
        print('🔄 Fallback: tentative notification immédiate après délai...');
        await Future.delayed(difference);
        await showNotification(
          id: id,
          title: title,
          body: body,
          payload: payload,
        );
      }
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

    print('📤 Envoi notification immédiate: $title');

    try {
      await _notifications.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'epilist_shopping_reminders',
            'Rappels de courses EpiList',
            channelDescription: 'Notifications de rappels pour vos listes de courses',
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
            enableLights: true,
            ledColor: const Color(0xFF4CAF50),
            autoCancel: true,
            fullScreenIntent: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );

      print('✅ Notification immédiate envoyée');
    } catch (e) {
      print('❌ Erreur envoi notification: $e');
    }
  }

  /// ✅ AMÉLIORÉ: Annuler une notification (gère Timer et système)
  static Future<void> cancelNotification(int id) async {
    // Annuler timer Dart si existe
    final timer = _activeTimers[id];
    if (timer != null) {
      timer.cancel();
      _activeTimers.remove(id);
      print('⏹️ Timer Dart $id annulé');
    }
    
    // Annuler notification système
    await _notifications.cancel(id);
    print('❌ Notification système $id annulée');
    print('📊 Timers restants: ${_activeTimers.length}');
  }

  /// Vérifier qu'une notification est programmée
  static Future<void> _verifyScheduledNotification(int id) async {
    try {
      final pendingNotifications = await getPendingNotifications();
      final found = pendingNotifications.any((notif) => notif.id == id);

      if (found) {
        print('✅ Notification $id confirmée dans la liste des notifications en attente');
      } else {
        print('⚠️ Notification $id NON trouvée dans les notifications en attente');
      }

      print('📋 Total notifications en attente: ${pendingNotifications.length}');
    } catch (e) {
      print('❌ Erreur vérification: $e');
    }
  }

  /// Vérifier les permissions
  static Future<bool> hasPermissions() async {
    if (Platform.isAndroid) {
      final notificationGranted = await Permission.notification.isGranted;
      print('🔐 Permission notification: $notificationGranted');
      return notificationGranted;
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

  /// Obtenir les notifications en attente
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      print('📋 ${pending.length} notifications système en attente');
      for (final notif in pending) {
        print('  - ID: ${notif.id}, Titre: ${notif.title}');
      }
      return pending;
    } catch (e) {
      print('❌ Erreur récupération notifications: $e');
      return [];
    }
  }

  /// ✅ NOUVEAU: Diagnostic complet pour Android
  static Future<void> diagnosticAndroidNotifications() async {
    print('🔍 === DIAGNOSTIC ANDROID NOTIFICATIONS ===');
    
    // 1. Vérifier toutes les permissions
    final permissions = <String, bool>{};
    
    try {
      permissions['Notification'] = await Permission.notification.isGranted;
      permissions['Alarme exacte'] = await Permission.scheduleExactAlarm.isGranted;
      permissions['Batterie'] = await Permission.ignoreBatteryOptimizations.isGranted;
    } catch (e) {
      print('❌ Erreur vérification permissions: $e');
    }
    
    permissions.forEach((name, granted) {
      print('📱 $name: ${granted ? "✅" : "❌"}');
    });
    
    // 2. Statut des timers actifs
    print('⏱️ Timers Dart actifs: ${_activeTimers.length}');
    _activeTimers.forEach((id, timer) {
      print('  - Timer $id: ${timer.isActive ? "✅ Actif" : "❌ Inactif"}');
    });
    
    // 3. Notifications système en attente
    final pending = await getPendingNotifications();
    print('📋 Notifications système en attente: ${pending.length}');
    
    // 4. Test notification immédiate
    print('🧪 Test notification immédiate...');
    await testImmediateNotification();
    
    // 5. Conseils d'optimisation
    print('\n💡 === CONSEILS D\'OPTIMISATION ===');
    if (!permissions['Batterie']!) {
      print('🔋 CRITIQUE: Désactivez l\'optimisation de batterie');
      print('   Paramètres > Apps > EpiList > Batterie > Non optimisée');
    }
    if (!permissions['Alarme exacte']!) {
      print('⏰ IMPORTANT: Activez les alarmes exactes');
      print('   Paramètres > Apps > Applications spéciales > Alarmes et rappels');
    }
    
    print('🔍 === FIN DIAGNOSTIC ===\n');
  }

  /// Test de notification immédiate
  static Future<void> testImmediateNotification() async {
    await showNotification(
      id: 9999,
      title: "🧪 Test Immédiat",
      body: "Cette notification devrait apparaître tout de suite !",
      payload: 'test_immediate',
    );
  }

  /// ✅ NOUVEAU: Test spécifique pour courtes périodes
  static Future<void> testShortPeriodNotification() async {
    print('🧪 Test notification dans 30 secondes (Timer Dart)...');
    
    await scheduleNotification(
      id: 7777,
      title: "⏰ Test 30 secondes",
      body: "Notification de test programmée il y a 30 secondes",
      scheduledTime: DateTime.now().add(const Duration(seconds: 30)),
      payload: 'test_30_seconds',
    );
    
    print('✅ Test 30s programmé via Timer Dart');
  }

  /// Test de notification dans 10 secondes
  static Future<void> testShortScheduled() async {
    final scheduledTime = DateTime.now().add(const Duration(seconds: 10));

    await scheduleNotification(
      id: 9998,
      title: "⏰ Test 10 secondes",
      body: "Cette notification était programmée il y a 10 secondes",
      scheduledTime: scheduledTime,
      payload: 'test_10_seconds',
    );

    print('⏰ Notification de test programmée dans 10 secondes...');
  }

  /// ✅ NOUVEAU: Test de notification longue (système)
  static Future<void> testLongPeriodNotification() async {
    print('🧪 Test notification dans 15 minutes (Système)...');
    
    await scheduleNotification(
      id: 8888,
      title: "📅 Test 15 minutes",
      body: "Notification de test système programmée il y a 15 minutes",
      scheduledTime: DateTime.now().add(const Duration(minutes: 15)),
      payload: 'test_15_minutes',
    );
    
    print('✅ Test 15min programmé via planification système');
  }

  /// ✅ NOUVEAU: Nettoyer tous les timers
  static void cleanupTimers() {
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
    print('🧹 Tous les timers Dart nettoyés');
  }

  /// ✅ NOUVEAU: Obtenir le statut détaillé
  static Map<String, dynamic> getStatus() {
    return {
      'initialized': _initialized,
      'active_timers': _activeTimers.length,
      'timer_ids': _activeTimers.keys.toList(),
    };
  }

  /// ✅ NOUVEAU: Test complet (toutes les durées)
  static Future<void> runCompleteTest() async {
    print('🧪 === TEST COMPLET NOTIFICATIONS ===');
    
    // 1. Diagnostic
    await diagnosticAndroidNotifications();
    
    // 2. Test immédiat
    print('\n1️⃣ Test notification immédiate...');
    await testImmediateNotification();
    await Future.delayed(const Duration(seconds: 2));
    
    // 3. Test court (Timer Dart)
    print('\n2️⃣ Test notification courte (30s - Timer)...');
    await testShortPeriodNotification();
    
    // 4. Test moyen (Système)
    print('\n3️⃣ Test notification longue (15min - Système)...');
    await testLongPeriodNotification();
    
    print('\n✅ Test complet programmé. Surveillez les notifications !');
    print('🔍 Statut: ${getStatus()}');
  }
}