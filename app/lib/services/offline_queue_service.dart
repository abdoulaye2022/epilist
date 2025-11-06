// services/offline_queue_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de gestion de la file d'attente des actions hors ligne
///
/// Ce service stocke toutes les actions effectuées hors ligne et les synchronise
/// automatiquement lorsque la connexion est rétablie.
///
/// SÉCURITÉ: Ne modifie JAMAIS directement la base de données.
/// Toutes les actions sont envoyées via l'API validée.
class OfflineQueueService {
  static const String _version = '1.0.0';
  static const String _versionKey = 'offline_queue_version';
  static const String _queueKey = 'offline_action_queue';
  static const String _statusKey = 'offline_queue_status';

  // ============================================================================
  // TYPES D'ACTIONS
  // ============================================================================

  static const String ACTION_CREATE_LIST = 'create_list';
  static const String ACTION_UPDATE_LIST = 'update_list';
  static const String ACTION_DELETE_LIST = 'delete_list';
  static const String ACTION_DUPLICATE_LIST = 'duplicate_list';

  static const String ACTION_CREATE_ITEM = 'create_item';
  static const String ACTION_UPDATE_ITEM = 'update_item';
  static const String ACTION_DELETE_ITEM = 'delete_item';
  static const String ACTION_TOGGLE_ITEM = 'toggle_item';

  static const String ACTION_CREATE_RECEIPT = 'create_receipt';
  static const String ACTION_UPDATE_RECEIPT = 'update_receipt';
  static const String ACTION_DELETE_RECEIPT = 'delete_receipt';

  static const String ACTION_CREATE_BUDGET = 'create_budget';
  static const String ACTION_UPDATE_BUDGET = 'update_budget';
  static const String ACTION_DELETE_BUDGET = 'delete_budget';

  static const String ACTION_UPDATE_PROFILE = 'update_profile';

  // ============================================================================
  // INITIALISATION
  // ============================================================================

  /// Initialiser la file d'attente et vérifier la version
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedVersion = prefs.getString(_versionKey);

    if (cachedVersion != _version) {
      print('🔄 [OfflineQueue] Version mismatch, clearing queue...');
      await clearQueue();
      await prefs.setString(_versionKey, _version);
      print('✅ [OfflineQueue] Queue initialized with version $_version');
    } else {
      print('✅ [OfflineQueue] Queue version OK: $_version');
    }
  }

  // ============================================================================
  // GESTION DE LA FILE D'ATTENTE
  // ============================================================================

  /// Ajouter une action à la file d'attente
  static Future<bool> enqueueAction({
    required String actionType,
    required Map<String, dynamic> payload,
    String? localId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = await _getQueue();

      final action = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'local_id': localId,
        'action_type': actionType,
        'payload': payload,
        'timestamp': DateTime.now().toIso8601String(),
        'retry_count': 0,
        'status': 'pending',
      };

      queue.add(action);

      await prefs.setString(_queueKey, json.encode(queue));
      await _updateStatus();

      print(
        '📥 [OfflineQueue] Action enqueued: $actionType (${queue.length} in queue)',
      );
      return true;
    } catch (e) {
      print('❌ [OfflineQueue] Error enqueuing action: $e');
      return false;
    }
  }

  /// Récupérer la file d'attente
  static Future<List<Map<String, dynamic>>> _getQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_queueKey);

      if (encoded == null || encoded.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(encoded);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ [OfflineQueue] Error loading queue: $e');
      return [];
    }
  }

  /// Obtenir toutes les actions en attente
  static Future<List<Map<String, dynamic>>> getPendingActions() async {
    final queue = await _getQueue();
    return queue.where((action) => action['status'] == 'pending').toList();
  }

  /// Obtenir le nombre d'actions en attente
  static Future<int> getPendingCount() async {
    final pending = await getPendingActions();
    return pending.length;
  }

  /// Marquer une action comme en cours
  static Future<bool> markAsProcessing(String actionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = await _getQueue();

      final index = queue.indexWhere((a) => a['id'] == actionId);
      if (index == -1) return false;

      queue[index]['status'] = 'processing';
      queue[index]['processing_at'] = DateTime.now().toIso8601String();

      await prefs.setString(_queueKey, json.encode(queue));
      await _updateStatus();

      print('⏳ [OfflineQueue] Action $actionId marked as processing');
      return true;
    } catch (e) {
      print('❌ [OfflineQueue] Error marking action as processing: $e');
      return false;
    }
  }

  /// Marquer une action comme réussie et la retirer de la queue
  static Future<bool> markAsCompleted(String actionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = await _getQueue();

      queue.removeWhere((a) => a['id'] == actionId);

      await prefs.setString(_queueKey, json.encode(queue));
      await _updateStatus();

      print('✅ [OfflineQueue] Action $actionId completed and removed');
      return true;
    } catch (e) {
      print('❌ [OfflineQueue] Error marking action as completed: $e');
      return false;
    }
  }

  /// Marquer une action comme échouée et incrémenter le compteur de retry
  static Future<bool> markAsFailed(String actionId, String error) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = await _getQueue();

      final index = queue.indexWhere((a) => a['id'] == actionId);
      if (index == -1) return false;

      queue[index]['retry_count'] = (queue[index]['retry_count'] ?? 0) + 1;
      queue[index]['status'] = 'failed';
      queue[index]['last_error'] = error;
      queue[index]['failed_at'] = DateTime.now().toIso8601String();

      // Si trop de retries (> 5), marquer comme abandonné
      if (queue[index]['retry_count'] >= 5) {
        queue[index]['status'] = 'abandoned';
        print('⚠️ [OfflineQueue] Action $actionId abandoned after 5 retries');
      } else {
        // Remettre en pending pour retry
        queue[index]['status'] = 'pending';
      }

      await prefs.setString(_queueKey, json.encode(queue));
      await _updateStatus();

      print(
        '❌ [OfflineQueue] Action $actionId failed (retry ${queue[index]['retry_count']}): $error',
      );
      return true;
    } catch (e) {
      print('❌ [OfflineQueue] Error marking action as failed: $e');
      return false;
    }
  }

  // ============================================================================
  // NETTOYAGE
  // ============================================================================

  /// Vider toute la file d'attente
  static Future<void> clearQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_queueKey);
      await prefs.remove(_statusKey);
      print('🧹 [OfflineQueue] Queue cleared');
    } catch (e) {
      print('❌ [OfflineQueue] Error clearing queue: $e');
    }
  }

  /// Supprimer les actions abandonnées (> 7 jours)
  static Future<void> cleanupAbandonedActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = await _getQueue();

      final now = DateTime.now();
      final cleanedQueue = queue.where((action) {
        if (action['status'] != 'abandoned') return true;

        final failedAt = DateTime.parse(action['failed_at']);
        final age = now.difference(failedAt);

        return age.inDays < 7; // Garder seulement les actions < 7 jours
      }).toList();

      if (cleanedQueue.length < queue.length) {
        await prefs.setString(_queueKey, json.encode(cleanedQueue));
        await _updateStatus();
        print(
          '🧹 [OfflineQueue] Cleaned ${queue.length - cleanedQueue.length} abandoned actions',
        );
      }
    } catch (e) {
      print('❌ [OfflineQueue] Error cleaning abandoned actions: $e');
    }
  }

  // ============================================================================
  // STATUT
  // ============================================================================

  /// Mettre à jour le statut global de la queue
  static Future<void> _updateStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = await _getQueue();

      final status = {
        'total': queue.length,
        'pending': queue.where((a) => a['status'] == 'pending').length,
        'processing': queue.where((a) => a['status'] == 'processing').length,
        'failed': queue.where((a) => a['status'] == 'failed').length,
        'abandoned': queue.where((a) => a['status'] == 'abandoned').length,
        'last_update': DateTime.now().toIso8601String(),
      };

      await prefs.setString(_statusKey, json.encode(status));
    } catch (e) {
      print('❌ [OfflineQueue] Error updating status: $e');
    }
  }

  /// Obtenir le statut de la queue
  static Future<Map<String, dynamic>> getStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_statusKey);

      if (encoded == null || encoded.isEmpty) {
        return {
          'total': 0,
          'pending': 0,
          'processing': 0,
          'failed': 0,
          'abandoned': 0,
          'last_update': null,
        };
      }

      return json.decode(encoded) as Map<String, dynamic>;
    } catch (e) {
      print('❌ [OfflineQueue] Error getting status: $e');
      return {
        'total': 0,
        'pending': 0,
        'processing': 0,
        'failed': 0,
        'abandoned': 0,
        'last_update': null,
      };
    }
  }

  /// Obtenir les statistiques détaillées
  static Future<Map<String, dynamic>> getDetailedStats() async {
    final queue = await _getQueue();
    final status = await getStatus();

    // Grouper par type d'action
    final actionTypes = <String, int>{};
    for (final action in queue) {
      final type = action['action_type'] as String;
      actionTypes[type] = (actionTypes[type] ?? 0) + 1;
    }

    // Trouver l'action la plus ancienne
    DateTime? oldestActionDate;
    if (queue.isNotEmpty) {
      final timestamps = queue
          .map((a) => DateTime.parse(a['timestamp']))
          .toList()
        ..sort();
      oldestActionDate = timestamps.first;
    }

    return {
      ...status,
      'by_action_type': actionTypes,
      'oldest_action':
          oldestActionDate?.toIso8601String(),
      'queue_age_days':
          oldestActionDate != null
              ? DateTime.now().difference(oldestActionDate).inDays
              : 0,
    };
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  /// Vérifier si une action est en double (même type + payload similaire)
  static Future<bool> isDuplicateAction({
    required String actionType,
    required Map<String, dynamic> payload,
  }) async {
    final queue = await _getQueue();

    for (final action in queue) {
      if (action['status'] == 'abandoned') continue;

      if (action['action_type'] == actionType) {
        final existingPayload = action['payload'] as Map<String, dynamic>;

        // Comparer les payloads (sans timestamps)
        final cleanPayload = Map<String, dynamic>.from(payload)
          ..remove('timestamp')
          ..remove('created_at');
        final cleanExisting = Map<String, dynamic>.from(existingPayload)
          ..remove('timestamp')
          ..remove('created_at');

        if (json.encode(cleanPayload) == json.encode(cleanExisting)) {
          return true; // Action dupliquée trouvée
        }
      }
    }

    return false;
  }

  /// Obtenir les actions pour un local_id spécifique
  static Future<List<Map<String, dynamic>>> getActionsByLocalId(
    String localId,
  ) async {
    final queue = await _getQueue();
    return queue.where((a) => a['local_id'] == localId).toList();
  }
}
