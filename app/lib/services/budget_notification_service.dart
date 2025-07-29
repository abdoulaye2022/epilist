// services/budget_notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:epilist/models/budget.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:convert';

class BudgetNotificationService {
  static const String _budgetAlertsKey = 'budget_alerts_enabled';
  static const String _lastNotificationKey = 'last_budget_notification';

  final FlutterLocalNotificationsPlugin _localNotifications;
  final FirebaseMessaging _firebaseMessaging;
  final AuthService _authService;

  BudgetNotificationService({
    required FlutterLocalNotificationsPlugin localNotifications,
    required FirebaseMessaging firebaseMessaging,
    required AuthService authService,
  }) : _localNotifications = localNotifications,
       _firebaseMessaging = firebaseMessaging,
       _authService = authService;

  /// Initialiser les notifications de budget
  Future<void> initialize() async {
    try {
      // Configuration des notifications locales pour les budgets
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Créer le canal de notification pour les budgets
      await _createBudgetNotificationChannel();

      debugPrint('✅ Budget notifications initialized');
    } catch (e) {
      debugPrint('❌ Error initializing budget notifications: $e');
    }
  }

  /// Créer le canal de notification pour les budgets
  Future<void> _createBudgetNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'budget_alerts',
      'Alertes de Budget',
      description: 'Notifications pour les alertes de budget et dépassements',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('budget_alert'),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  /// Gérer les notifications FCM de budget
  Future<void> handleBudgetFCMMessage(RemoteMessage message) async {
    try {
      debugPrint('📱 Budget FCM message received: ${message.data}');

      final data = message.data;
      final budgetId = data['budget_id'];
      final budgetName = data['budget_name'];
      final alertType = data['alert_type']; // 'warning', 'exceeded', 'expiring'
      final spentPercentage = data['spent_percentage'];
      final formattedSpent = data['formatted_spent'];
      final formattedBudget = data['formatted_budget'];

      if (budgetId != null && budgetName != null) {
        await _showBudgetNotification(
          budgetId: int.tryParse(budgetId) ?? 0,
          budgetName: budgetName,
          alertType: alertType ?? 'warning',
          spentPercentage: double.tryParse(spentPercentage ?? '0') ?? 0,
          formattedSpent: formattedSpent ?? '',
          formattedBudget: formattedBudget ?? '',
        );
      }
    } catch (e) {
      debugPrint('❌ Error handling budget FCM message: $e');
    }
  }

  /// Afficher une notification de budget
  Future<void> _showBudgetNotification({
    required int budgetId,
    required String budgetName,
    required String alertType,
    required double spentPercentage,
    required String formattedSpent,
    required String formattedBudget,
  }) async {
    try {
      // Vérifier si les notifications de budget sont activées
      if (!await areBudgetAlertsEnabled()) {
        debugPrint('🔕 Budget alerts disabled, skipping notification');
        return;
      }

      // Éviter les notifications trop fréquentes
      if (await _wasRecentlyNotified(budgetId)) {
        debugPrint('🔕 Budget $budgetId recently notified, skipping');
        return;
      }

      final (title, body, icon) = _getBudgetNotificationContent(
        budgetName: budgetName,
        alertType: alertType,
        spentPercentage: spentPercentage,
        formattedSpent: formattedSpent,
        formattedBudget: formattedBudget,
      );

      const androidDetails = AndroidNotificationDetails(
        'budget_alerts',
        'Alertes de Budget',
        channelDescription: 'Notifications pour les alertes de budget',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        styleInformation: BigTextStyleInformation(''),
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'budget_alert',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        budgetId +
            10000, // Offset pour éviter les conflits avec d'autres notifications
        title,
        body,
        notificationDetails,
        payload: json.encode({
          'type': 'budget_alert',
          'budget_id': budgetId,
          'alert_type': alertType,
        }),
      );

      // Marquer comme notifié récemment
      await _markAsRecentlyNotified(budgetId);

      debugPrint('✅ Budget notification shown for budget $budgetId');
    } catch (e) {
      debugPrint('❌ Error showing budget notification: $e');
    }
  }

  /// Obtenir le contenu de la notification selon le type d'alerte
  (String title, String body, String icon) _getBudgetNotificationContent({
    required String budgetName,
    required String alertType,
    required double spentPercentage,
    required String formattedSpent,
    required String formattedBudget,
  }) {
    switch (alertType) {
      case 'exceeded':
        return (
          '🚨 Budget dépassé!',
          'Votre budget "$budgetName" a été dépassé (${spentPercentage.toStringAsFixed(0)}%). '
              'Dépensé: $formattedSpent sur $formattedBudget.',
          '🚨',
        );

      case 'warning':
        return (
          '⚠️ Attention au budget',
          'Votre budget "$budgetName" atteint ${spentPercentage.toStringAsFixed(0)}%. '
              'Dépensé: $formattedSpent sur $formattedBudget.',
          '⚠️',
        );

      case 'expiring':
        return (
          '⏰ Budget bientôt expiré',
          'Votre budget "$budgetName" expire bientôt. '
              'Dépensé: $formattedSpent sur $formattedBudget.',
          '⏰',
        );

      case 'daily_summary':
        return (
          '📊 Résumé quotidien',
          'Mise à jour de vos budgets. Budget "$budgetName": '
              '$formattedSpent dépensé sur $formattedBudget.',
          '📊',
        );

      default:
        return (
          '💰 Mise à jour budget',
          'Votre budget "$budgetName" a été mis à jour. '
              'Dépensé: $formattedSpent sur $formattedBudget.',
          '💰',
        );
    }
  }

  /// Envoyer un résumé quotidien des budgets
  Future<void> sendDailySummary(List<Budget> budgets) async {
    try {
      if (!await areBudgetAlertsEnabled()) {
        return;
      }

      final alertBudgets = budgets.where((b) => b.shouldShowAlert).toList();
      final activeBudgets =
          budgets.where((b) => b.isActive && b.isCurrent).toList();

      if (alertBudgets.isEmpty && activeBudgets.isEmpty) {
        return;
      }

      String title = '📊 Résumé de vos budgets';
      String body;

      if (alertBudgets.isNotEmpty) {
        final exceededCount = alertBudgets.where((b) => b.isExceeded).length;
        final warningCount = alertBudgets.length - exceededCount;

        if (exceededCount > 0 && warningCount > 0) {
          body =
              '$exceededCount budget(s) dépassé(s) et $warningCount en alerte sur ${activeBudgets.length} actifs.';
        } else if (exceededCount > 0) {
          body =
              '$exceededCount budget(s) dépassé(s) sur ${activeBudgets.length} actifs.';
        } else {
          body =
              '$warningCount budget(s) en alerte sur ${activeBudgets.length} actifs.';
        }
      } else {
        body =
            'Tous vos ${activeBudgets.length} budgets sont sous contrôle. 👍';
      }

      const androidDetails = AndroidNotificationDetails(
        'budget_alerts',
        'Alertes de Budget',
        channelDescription: 'Résumé quotidien des budgets',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        enableVibration: false,
        playSound: false,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        99999, // ID fixe pour le résumé quotidien
        title,
        body,
        notificationDetails,
        payload: json.encode({
          'type': 'daily_budget_summary',
          'alert_count': alertBudgets.length,
          'active_count': activeBudgets.length,
        }),
      );

      debugPrint('✅ Daily budget summary sent');
    } catch (e) {
      debugPrint('❌ Error sending daily budget summary: $e');
    }
  }

  /// Programmer des notifications de rappel de budget
  Future<void> scheduleBudgetReminders(List<Budget> budgets) async {
    try {
      // Annuler les rappels existants
      await _cancelBudgetReminders();

      if (!await areBudgetAlertsEnabled()) {
        return;
      }

      for (final budget in budgets) {
        if (!budget.isActive || !budget.isCurrent) continue;

        // Programmer un rappel 3 jours avant expiration
        final reminderDate = budget.endDate.subtract(const Duration(days: 3));
        if (reminderDate.isAfter(DateTime.now())) {
          await _scheduleBudgetExpirationReminder(budget, reminderDate);
        }

        // Programmer un rappel si proche du seuil d'alerte
        if (!budget.isNearLimit &&
            budget.spentPercentage > (budget.alertThreshold - 10)) {
          await _scheduleNearLimitReminder(budget);
        }
      }

      debugPrint('✅ Budget reminders scheduled for ${budgets.length} budgets');
    } catch (e) {
      debugPrint('❌ Error scheduling budget reminders: $e');
    }
  }

  /// Programmer un rappel d'expiration de budget
  Future<void> _scheduleBudgetExpirationReminder(
    Budget budget,
    DateTime reminderDate,
  ) async {
    await _localNotifications.zonedSchedule(
      budget.id + 20000, // Offset pour les rappels d'expiration
      '⏰ Budget bientôt expiré',
      'Votre budget "${budget.name}" expire dans 3 jours. '
          'Dépensé: ${budget.formattedSpentAmount} sur ${budget.formattedBudgetAmount}.',
      _convertToTZDateTime(reminderDate),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'budget_alerts',
          'Alertes de Budget',
          channelDescription: 'Rappels d\'expiration de budget',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: json.encode({
        'type': 'budget_expiration_reminder',
        'budget_id': budget.id,
      }),
    );
  }

  /// Programmer un rappel de limite proche
  Future<void> _scheduleNearLimitReminder(Budget budget) async {
    // Programmer pour le lendemain à 9h
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final reminderTime = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      9,
      0,
    );

    await _localNotifications.zonedSchedule(
      budget.id + 30000, // Offset pour les rappels de limite
      '⚠️ Attention à votre budget',
      'Vous approchez de la limite de votre budget "${budget.name}". '
          'Déjà ${budget.spentPercentage.toStringAsFixed(0)}% dépensé.',
      _convertToTZDateTime(reminderTime),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'budget_alerts',
          'Alertes de Budget',
          channelDescription: 'Rappels de limite de budget',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: json.encode({
        'type': 'budget_near_limit_reminder',
        'budget_id': budget.id,
      }),
    );
  }

  /// Convertir DateTime en TZDateTime pour les notifications programmées
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    // Utiliser le timezone local
    final location = tz.local;
    return tz.TZDateTime.from(dateTime, location);
  }

  /// Annuler tous les rappels de budget
  Future<void> _cancelBudgetReminders() async {
    // Annuler les rappels avec les plages d'ID spécifiques
    final pendingNotifications =
        await _localNotifications.pendingNotificationRequests();

    for (final notification in pendingNotifications) {
      if (notification.id >= 20000 && notification.id < 40000) {
        await _localNotifications.cancel(notification.id);
      }
    }
  }

  /// Vérifier si les alertes de budget sont activées
  Future<bool> areBudgetAlertsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_budgetAlertsKey) ?? true; // Activé par défaut
    } catch (e) {
      debugPrint('❌ Error checking budget alerts setting: $e');
      return true;
    }
  }

  /// Activer/désactiver les alertes de budget
  Future<void> setBudgetAlertsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_budgetAlertsKey, enabled);

      if (!enabled) {
        // Annuler toutes les notifications de budget existantes
        await _cancelAllBudgetNotifications();
      }

      debugPrint('✅ Budget alerts ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      debugPrint('❌ Error setting budget alerts: $e');
    }
  }

  /// Vérifier si une notification récente a été envoyée pour ce budget
  Future<bool> _wasRecentlyNotified(int budgetId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastNotificationStr = prefs.getString(
        '${_lastNotificationKey}_$budgetId',
      );

      if (lastNotificationStr == null) return false;

      final lastNotification = DateTime.parse(lastNotificationStr);
      final now = DateTime.now();

      // Éviter les notifications dans la même heure
      return now.difference(lastNotification).inHours < 1;
    } catch (e) {
      debugPrint('❌ Error checking recent notification: $e');
      return false;
    }
  }

  /// Marquer un budget comme récemment notifié
  Future<void> _markAsRecentlyNotified(int budgetId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '${_lastNotificationKey}_$budgetId',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('❌ Error marking as recently notified: $e');
    }
  }

  /// Annuler toutes les notifications de budget
  Future<void> _cancelAllBudgetNotifications() async {
    try {
      final pendingNotifications =
          await _localNotifications.pendingNotificationRequests();

      for (final notification in pendingNotifications) {
        // Annuler les notifications avec les ID de budget (10000-40000)
        if (notification.id >= 10000 && notification.id < 40000) {
          await _localNotifications.cancel(notification.id);
        }
      }

      debugPrint('✅ All budget notifications cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling budget notifications: $e');
    }
  }

  /// Gérer le tap sur une notification
  void _onNotificationTapped(NotificationResponse response) {
    try {
      final payload = response.payload;
      if (payload == null) return;

      final data = json.decode(payload) as Map<String, dynamic>;
      final type = data['type'] as String?;

      debugPrint('📱 Budget notification tapped: $type');

      switch (type) {
        case 'budget_alert':
        case 'budget_expiration_reminder':
        case 'budget_near_limit_reminder':
          final budgetId = data['budget_id'] as int?;
          if (budgetId != null) {
            _navigateToBudgetDetails(budgetId);
          }
          break;

        case 'daily_budget_summary':
          _navigateToBudgetOverview();
          break;
      }
    } catch (e) {
      debugPrint('❌ Error handling notification tap: $e');
    }
  }

  /// Naviguer vers les détails d'un budget
  void _navigateToBudgetDetails(int budgetId) {
    // TODO: Implémenter la navigation vers les détails du budget
    debugPrint('🔄 Navigate to budget details: $budgetId');
  }

  /// Naviguer vers l'aperçu des budgets
  void _navigateToBudgetOverview() {
    // TODO: Implémenter la navigation vers l'aperçu des budgets
    debugPrint('🔄 Navigate to budget overview');
  }

  /// Nettoyer les données de notification anciennes
  Future<void> cleanupOldNotificationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final now = DateTime.now();

      for (final key in keys) {
        if (key.startsWith(_lastNotificationKey)) {
          final dateStr = prefs.getString(key);
          if (dateStr != null) {
            final date = DateTime.tryParse(dateStr);
            if (date != null && now.difference(date).inDays > 7) {
              await prefs.remove(key);
            }
          }
        }
      }

      debugPrint('✅ Old notification data cleaned up');
    } catch (e) {
      debugPrint('❌ Error cleaning up notification data: $e');
    }
  }
}
