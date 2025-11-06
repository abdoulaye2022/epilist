// services/conflict_resolution_service.dart
import 'package:shared_preferences/shared_preferences.dart';

/// Service de résolution des conflits pour le mode hors ligne
///
/// Ce service détecte et résout les conflits lorsqu'une donnée a été modifiée
/// à la fois localement (hors ligne) et sur le serveur.
///
/// STRATÉGIES DE RÉSOLUTION:
/// 1. SERVER_WINS: Le serveur a toujours raison (par défaut, sécurisé)
/// 2. LOCAL_WINS: Les modifications locales ont priorité
/// 3. MERGE: Fusion intelligente des changements
/// 4. ASK_USER: Demander à l'utilisateur de choisir
class ConflictResolutionService {
  static const String _conflictsKey = 'offline_conflicts';
  static const String _resolutionStrategyKey = 'conflict_resolution_strategy';

  // ============================================================================
  // STRATÉGIES DE RÉSOLUTION
  // ============================================================================

  static const String STRATEGY_SERVER_WINS = 'server_wins';
  static const String STRATEGY_LOCAL_WINS = 'local_wins';
  static const String STRATEGY_MERGE = 'merge';
  static const String STRATEGY_ASK_USER = 'ask_user';

  // ============================================================================
  // TYPES DE CONFLITS
  // ============================================================================

  static const String CONFLICT_MODIFIED_BOTH = 'modified_both';
  static const String CONFLICT_DELETED_SERVER = 'deleted_server';
  static const String CONFLICT_DELETED_LOCAL = 'deleted_local';
  static const String CONFLICT_VERSION_MISMATCH = 'version_mismatch';

  // ============================================================================
  // GESTION DES CONFLITS
  // ============================================================================

  /// Détecter un conflit entre version locale et serveur
  static Future<ConflictInfo?> detectConflict({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
  }) async {
    try {
      // Comparer les timestamps
      final localTimestamp = _parseTimestamp(localData['updated_at']);
      final serverTimestamp = _parseTimestamp(serverData['updated_at']);

      if (localTimestamp == null || serverTimestamp == null) {
        print('⚠️ [ConflictResolution] Missing timestamps, assuming no conflict');
        return null;
      }

      // Si le serveur est plus récent et les données sont différentes
      if (serverTimestamp.isAfter(localTimestamp)) {
        if (!_areDataEqual(localData, serverData)) {
          print(
            '⚠️ [ConflictResolution] Conflict detected for $entityType:$entityId',
          );

          final conflict = ConflictInfo(
            entityType: entityType,
            entityId: entityId,
            conflictType: CONFLICT_MODIFIED_BOTH,
            localData: localData,
            serverData: serverData,
            localTimestamp: localTimestamp,
            serverTimestamp: serverTimestamp,
          );

          await _saveConflict(conflict);
          return conflict;
        }
      }

      return null;
    } catch (e) {
      print('❌ [ConflictResolution] Error detecting conflict: $e');
      return null;
    }
  }

  /// Résoudre un conflit selon la stratégie définie
  static Future<Map<String, dynamic>> resolveConflict(
    ConflictInfo conflict, {
    String? strategy,
  }) async {
    try {
      final resolvedStrategy =
          strategy ?? await _getResolutionStrategy();

      print(
        '🔧 [ConflictResolution] Resolving conflict with strategy: $resolvedStrategy',
      );

      Map<String, dynamic> resolvedData;

      switch (resolvedStrategy) {
        case STRATEGY_SERVER_WINS:
          resolvedData = conflict.serverData;
          print('✅ [ConflictResolution] Resolved: Server wins');
          break;

        case STRATEGY_LOCAL_WINS:
          resolvedData = conflict.localData;
          print('✅ [ConflictResolution] Resolved: Local wins');
          break;

        case STRATEGY_MERGE:
          resolvedData = _mergeData(conflict.localData, conflict.serverData);
          print('✅ [ConflictResolution] Resolved: Merged data');
          break;

        case STRATEGY_ASK_USER:
          // Dans ce cas, on retourne le conflit et laisse l'UI gérer
          print('⏳ [ConflictResolution] Waiting for user decision');
          return {};

        default:
          // Par défaut, le serveur gagne (plus sûr)
          resolvedData = conflict.serverData;
          print('✅ [ConflictResolution] Resolved: Default to server wins');
      }

      // Supprimer le conflit après résolution
      await _removeConflict(conflict.entityType, conflict.entityId);

      return resolvedData;
    } catch (e) {
      print('❌ [ConflictResolution] Error resolving conflict: $e');
      // En cas d'erreur, privilégier le serveur (plus sûr)
      return conflict.serverData;
    }
  }

  /// Fusionner les données locales et serveur intelligemment
  static Map<String, dynamic> _mergeData(
    Map<String, dynamic> localData,
    Map<String, dynamic> serverData,
  ) {
    final merged = Map<String, dynamic>.from(serverData);

    // Règles de fusion personnalisées par type de donnée
    final protectedFields = [
      'id',
      'created_at',
      'user_id',
    ]; // Ne jamais écraser

    for (final key in localData.keys) {
      if (protectedFields.contains(key)) {
        continue; // Garder la valeur du serveur
      }

      // Si la valeur locale n'est pas nulle et différente
      if (localData[key] != null && localData[key] != serverData[key]) {
        // Pour les champs spécifiques, privilégier local
        if (_shouldPreferLocalField(key)) {
          merged[key] = localData[key];
        }
        // Sinon garder la valeur du serveur (déjà fait)
      }
    }

    return merged;
  }

  /// Déterminer si un champ doit privilégier la valeur locale
  static bool _shouldPreferLocalField(String fieldName) {
    const localPreferredFields = [
      'notes',
      'is_purchased',
      'quantity',
      'price',
      'name',
      'total_amount',
    ];

    return localPreferredFields.contains(fieldName);
  }

  // ============================================================================
  // STOCKAGE DES CONFLITS
  // ============================================================================

  /// Sauvegarder un conflit pour traitement ultérieur
  static Future<void> _saveConflict(ConflictInfo conflict) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conflicts = await getPendingConflicts();

      // Ajouter le conflit
      conflicts.add(conflict.toJson());

      await prefs.setString(_conflictsKey, _encodeConflicts(conflicts));
      print('💾 [ConflictResolution] Conflict saved');
    } catch (e) {
      print('❌ [ConflictResolution] Error saving conflict: $e');
    }
  }

  /// Supprimer un conflit résolu
  static Future<void> _removeConflict(
    String entityType,
    String entityId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conflicts = await getPendingConflicts();

      // Supprimer le conflit
      conflicts.removeWhere(
        (c) =>
            c['entity_type'] == entityType &&
            c['entity_id'] == entityId,
      );

      await prefs.setString(_conflictsKey, _encodeConflicts(conflicts));
      print('🗑️ [ConflictResolution] Conflict removed');
    } catch (e) {
      print('❌ [ConflictResolution] Error removing conflict: $e');
    }
  }

  /// Obtenir tous les conflits en attente
  static Future<List<Map<String, dynamic>>> getPendingConflicts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_conflictsKey);

      if (encoded == null || encoded.isEmpty) {
        return [];
      }

      return _decodeConflicts(encoded);
    } catch (e) {
      print('❌ [ConflictResolution] Error loading conflicts: $e');
      return [];
    }
  }

  /// Obtenir le nombre de conflits en attente
  static Future<int> getPendingConflictsCount() async {
    final conflicts = await getPendingConflicts();
    return conflicts.length;
  }

  /// Nettoyer tous les conflits
  static Future<void> clearAllConflicts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_conflictsKey);
      print('🧹 [ConflictResolution] All conflicts cleared');
    } catch (e) {
      print('❌ [ConflictResolution] Error clearing conflicts: $e');
    }
  }

  // ============================================================================
  // STRATÉGIE DE RÉSOLUTION
  // ============================================================================

  /// Définir la stratégie de résolution par défaut
  static Future<void> setResolutionStrategy(String strategy) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_resolutionStrategyKey, strategy);
      print('⚙️ [ConflictResolution] Resolution strategy set to: $strategy');
    } catch (e) {
      print('❌ [ConflictResolution] Error setting strategy: $e');
    }
  }

  /// Obtenir la stratégie de résolution actuelle
  static Future<String> _getResolutionStrategy() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_resolutionStrategyKey) ?? STRATEGY_SERVER_WINS;
    } catch (e) {
      print('❌ [ConflictResolution] Error getting strategy: $e');
      return STRATEGY_SERVER_WINS; // Par défaut le plus sûr
    }
  }

  // ============================================================================
  // UTILITAIRES
  // ============================================================================

  /// Parser un timestamp depuis différents formats
  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;

    try {
      if (timestamp is DateTime) {
        return timestamp;
      } else if (timestamp is String) {
        return DateTime.parse(timestamp);
      } else if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      print('❌ [ConflictResolution] Error parsing timestamp: $e');
    }

    return null;
  }

  /// Comparer deux maps de données
  static bool _areDataEqual(
    Map<String, dynamic> data1,
    Map<String, dynamic> data2,
  ) {
    // Exclure les champs de métadonnées
    final excludedKeys = [
      'updated_at',
      'created_at',
      'synced_at',
      'local_id',
    ];

    for (final key in data1.keys) {
      if (excludedKeys.contains(key)) continue;

      if (data1[key] != data2[key]) {
        return false;
      }
    }

    return true;
  }

  /// Encoder la liste de conflits en JSON
  static String _encodeConflicts(List<Map<String, dynamic>> conflicts) {
    // Utiliser une simple sérialisation JSON-like
    return conflicts.map((c) => _encodeMap(c)).join('|||');
  }

  /// Décoder la liste de conflits depuis JSON
  static List<Map<String, dynamic>> _decodeConflicts(String encoded) {
    if (encoded.isEmpty) return [];

    return encoded
        .split('|||')
        .where((s) => s.isNotEmpty)
        .map((s) => _decodeMap(s))
        .toList();
  }

  /// Encoder une map en string
  static String _encodeMap(Map<String, dynamic> map) {
    return map.entries.map((e) => '${e.key}::${e.value}').join(';;;');
  }

  /// Décoder une map depuis string
  static Map<String, dynamic> _decodeMap(String encoded) {
    final map = <String, dynamic>{};

    for (final entry in encoded.split(';;;')) {
      final parts = entry.split('::');
      if (parts.length == 2) {
        map[parts[0]] = parts[1];
      }
    }

    return map;
  }
}

// ============================================================================
// MODÈLE D'INFORMATION DE CONFLIT
// ============================================================================

class ConflictInfo {
  final String entityType;
  final String entityId;
  final String conflictType;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> serverData;
  final DateTime localTimestamp;
  final DateTime serverTimestamp;

  ConflictInfo({
    required this.entityType,
    required this.entityId,
    required this.conflictType,
    required this.localData,
    required this.serverData,
    required this.localTimestamp,
    required this.serverTimestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'entity_type': entityType,
      'entity_id': entityId,
      'conflict_type': conflictType,
      'local_data': ConflictResolutionService._encodeMap(localData),
      'server_data': ConflictResolutionService._encodeMap(serverData),
      'local_timestamp': localTimestamp.toIso8601String(),
      'server_timestamp': serverTimestamp.toIso8601String(),
    };
  }

  factory ConflictInfo.fromJson(Map<String, dynamic> json) {
    return ConflictInfo(
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      conflictType: json['conflict_type'] as String,
      localData:
          ConflictResolutionService._decodeMap(json['local_data'] as String),
      serverData:
          ConflictResolutionService._decodeMap(json['server_data'] as String),
      localTimestamp: DateTime.parse(json['local_timestamp'] as String),
      serverTimestamp: DateTime.parse(json['server_timestamp'] as String),
    );
  }

  @override
  String toString() {
    return 'ConflictInfo(type: $entityType, id: $entityId, '
        'conflict: $conflictType, local: $localTimestamp, server: $serverTimestamp)';
  }
}
