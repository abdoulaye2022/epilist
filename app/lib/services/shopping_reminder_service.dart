// services/shopping_reminder_service.dart
import 'package:epilist/notifications/notification_service.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ShoppingReminderService {
  static const String _remindersKey = 'shopping_reminders';

  /// Programmer un rappel pour une liste de courses
  static Future<void> scheduleShoppingReminder({
    required ShoppingList shoppingList,
    required DateTime reminderTime,
    String? storeName,
    String? customMessage,
  }) async {
    // ID unique basé sur l'ID de la liste et le timestamp
    final notificationId = _generateNotificationId(
      shoppingList.id,
      reminderTime,
    );

    // Message personnalisé
    final body = _buildReminderMessage(
      listName: shoppingList.name,
      itemCount: shoppingList.items.length,
      storeName: storeName,
      customMessage: customMessage,
    );

    // Programmer la notification
    await NotificationService.scheduleNotification(
      id: notificationId,
      title: "🛒 Rappel de courses",
      body: body,
      scheduledTime: reminderTime,
      payload: json.encode({
        'type': 'shopping_reminder',
        'list_id': shoppingList.id,
        'list_name': shoppingList.name,
        'reminder_time': reminderTime.toIso8601String(),
      }),
    );

    // Sauvegarder le rappel localement
    await _saveReminder(
      listId: shoppingList.id,
      notificationId: notificationId,
      reminderTime: reminderTime,
      storeName: storeName,
    );

    print('✅ Rappel programmé pour ${shoppingList.name} le $reminderTime');
  }

  /// Programmer plusieurs rappels prédéfinis
  static Future<void> scheduleMultipleReminders({
    required ShoppingList shoppingList,
    required List<DateTime> reminderTimes,
    String? storeName,
  }) async {
    for (final time in reminderTimes) {
      await scheduleShoppingReminder(
        shoppingList: shoppingList,
        reminderTime: time,
        storeName: storeName,
      );
    }
  }

  /// Rappels pré-configurés populaires
  static Future<void> schedulePopularReminders({
    required ShoppingList shoppingList,
    String? storeName,
  }) async {
    final now = DateTime.now();

    // Rappels populaires
    final reminderTimes =
        [
          now.add(const Duration(hours: 2)), // Dans 2h
          now.add(const Duration(hours: 24)), // Demain même heure
          _getNextWeekendMorning(now), // Samedi matin
        ].where((time) => time.isAfter(now)).toList();

    await scheduleMultipleReminders(
      shoppingList: shoppingList,
      reminderTimes: reminderTimes,
      storeName: storeName,
    );
  }

  /// Annuler tous les rappels d'une liste
  static Future<void> cancelListReminders(int listId) async {
    final reminders = await _getSavedReminders();
    final listReminders = reminders.where((r) => r['list_id'] == listId);

    for (final reminder in listReminders) {
      await NotificationService.cancelNotification(reminder['notification_id']);
    }

    // Supprimer de la sauvegarde locale
    final updatedReminders =
        reminders.where((r) => r['list_id'] != listId).toList();
    await _updateSavedReminders(updatedReminders);

    print('❌ Rappels annulés pour la liste $listId');
  }

  /// Annuler un rappel spécifique
  static Future<void> cancelSpecificReminder(int notificationId) async {
    await NotificationService.cancelNotification(notificationId);

    final reminders = await _getSavedReminders();
    final updatedReminders =
        reminders.where((r) => r['notification_id'] != notificationId).toList();
    await _updateSavedReminders(updatedReminders);

    print('❌ Rappel $notificationId annulé');
  }

  /// Obtenir tous les rappels programmés
  static Future<List<Map<String, dynamic>>> getScheduledReminders() async {
    return await _getSavedReminders();
  }

  /// Obtenir les rappels d'une liste spécifique
  static Future<List<Map<String, dynamic>>> getListReminders(int listId) async {
    final allReminders = await _getSavedReminders();
    return allReminders.where((r) => r['list_id'] == listId).toList();
  }

  /// Nettoyer les rappels expirés
  static Future<void> cleanExpiredReminders() async {
    final now = DateTime.now();
    final reminders = await _getSavedReminders();

    final activeReminders =
        reminders.where((reminder) {
          final reminderTime = DateTime.parse(reminder['reminder_time']);
          return reminderTime.isAfter(now);
        }).toList();

    await _updateSavedReminders(activeReminders);
    print('🧹 Rappels expirés nettoyés');
  }

  // === MÉTHODES PRIVÉES ===

  /// Générer un ID unique pour la notification
  static int _generateNotificationId(int listId, DateTime reminderTime) {
    // Combine l'ID de la liste avec le timestamp pour unicité
    final combined = '${listId}${reminderTime.millisecondsSinceEpoch}';
    // Prendre les 8 premiers chiffres pour éviter les débordements
    return int.parse(
      combined.substring(0, combined.length > 8 ? 8 : combined.length),
    );
  }

  /// Construire le message du rappel
  static String _buildReminderMessage({
    required String listName,
    required int itemCount,
    String? storeName,
    String? customMessage,
  }) {
    if (customMessage != null && customMessage.isNotEmpty) {
      return customMessage;
    }

    final itemText = itemCount == 1 ? 'article' : 'articles';
    final baseMessage = '$listName ($itemCount $itemText)';

    if (storeName != null && storeName.isNotEmpty) {
      return 'Il est temps d\'aller chez $storeName!\n$baseMessage';
    }

    return 'N\'oubliez pas vos courses!\n$baseMessage';
  }

  /// Obtenir le prochain samedi matin
  static DateTime _getNextWeekendMorning(DateTime from) {
    int daysUntilSaturday = (DateTime.saturday - from.weekday) % 7;
    if (daysUntilSaturday == 0)
      daysUntilSaturday = 7; // Si c'est samedi, prendre le samedi suivant

    final saturday = from.add(Duration(days: daysUntilSaturday));
    return DateTime(saturday.year, saturday.month, saturday.day, 9, 0); // 9h00
  }

  /// Sauvegarder un rappel localement
  static Future<void> _saveReminder({
    required int listId,
    required int notificationId,
    required DateTime reminderTime,
    String? storeName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final reminders = await _getSavedReminders();

    reminders.add({
      'list_id': listId,
      'notification_id': notificationId,
      'reminder_time': reminderTime.toIso8601String(),
      'store_name': storeName,
      'created_at': DateTime.now().toIso8601String(),
    });

    await prefs.setString(_remindersKey, json.encode(reminders));
  }

  /// Récupérer les rappels sauvegardés
  static Future<List<Map<String, dynamic>>> _getSavedReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(_remindersKey);

    if (savedData == null) return [];

    try {
      final List<dynamic> decoded = json.decode(savedData);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Erreur lecture rappels: $e');
      return [];
    }
  }

  /// Mettre à jour les rappels sauvegardés
  static Future<void> _updateSavedReminders(
    List<Map<String, dynamic>> reminders,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_remindersKey, json.encode(reminders));
  }
}

// === EXTENSION POUR FACILITER L'UTILISATION ===

extension ShoppingListReminders on ShoppingList {
  /// Programmer un rappel pour cette liste
  Future<void> scheduleReminder({
    required DateTime when,
    String? storeName,
    String? customMessage,
  }) async {
    await ShoppingReminderService.scheduleShoppingReminder(
      shoppingList: this,
      reminderTime: when,
      storeName: storeName,
      customMessage: customMessage,
    );
  }

  /// Programmer les rappels populaires
  Future<void> schedulePopularReminders({String? storeName}) async {
    await ShoppingReminderService.schedulePopularReminders(
      shoppingList: this,
      storeName: storeName,
    );
  }

  /// Annuler tous les rappels de cette liste
  Future<void> cancelReminders() async {
    await ShoppingReminderService.cancelListReminders(id);
  }

  /// Obtenir les rappels de cette liste
  Future<List<Map<String, dynamic>>> getReminders() async {
    return await ShoppingReminderService.getListReminders(id);
  }
}
