// services/offline_cache_service.dart
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Service pour gérer le cache hors ligne de l'application
class OfflineCacheService {
  static final OfflineCacheService _instance = OfflineCacheService._internal();
  factory OfflineCacheService() => _instance;
  OfflineCacheService._internal();

  // Noms des boxes Hive
  static const String _shoppingListsBox = 'shopping_lists';
  static const String _listItemsBox = 'list_items';
  static const String _categoriesBox = 'categories';
  static const String _pendingActionsBox = 'pending_actions';

  // Boxes Hive
  Box<dynamic>? _shoppingLists;
  Box<dynamic>? _listItems;
  Box<dynamic>? _categories;
  Box<dynamic>? _pendingActions;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialise Hive et ouvre les boxes
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialiser Hive Flutter
      await Hive.initFlutter();

      // Ouvrir les boxes
      _shoppingLists = await Hive.openBox(_shoppingListsBox);
      _listItems = await Hive.openBox(_listItemsBox);
      _categories = await Hive.openBox(_categoriesBox);
      _pendingActions = await Hive.openBox(_pendingActionsBox);

      _isInitialized = true;
      print('✅ [OfflineCache] Cache hors ligne initialisé avec succès');
    } catch (e) {
      print('❌ [OfflineCache] Erreur lors de l\'initialisation: $e');
      rethrow;
    }
  }

  // ========== SHOPPING LISTS ==========

  /// Sauvegarde une liste de courses dans le cache
  Future<void> cacheShoppingList(Map<String, dynamic> list) async {
    _ensureInitialized();
    try {
      final id = list['id']?.toString();
      if (id == null) return;

      await _shoppingLists?.put(id, jsonEncode(list));
      print('💾 [OfflineCache] Liste $id mise en cache');
    } catch (e) {
      print('❌ [OfflineCache] Erreur cache liste: $e');
    }
  }

  /// Sauvegarde plusieurs listes de courses
  Future<void> cacheShoppingLists(List<Map<String, dynamic>> lists) async {
    _ensureInitialized();
    try {
      for (var list in lists) {
        await cacheShoppingList(list);
      }
      print('💾 [OfflineCache] ${lists.length} listes mises en cache');
    } catch (e) {
      print('❌ [OfflineCache] Erreur cache listes: $e');
    }
  }

  /// Récupère une liste depuis le cache
  Map<String, dynamic>? getCachedShoppingList(String id) {
    _ensureInitialized();
    try {
      final cached = _shoppingLists?.get(id);
      if (cached == null) return null;

      return jsonDecode(cached as String) as Map<String, dynamic>;
    } catch (e) {
      print('❌ [OfflineCache] Erreur récupération liste: $e');
      return null;
    }
  }

  /// Récupère toutes les listes en cache
  List<Map<String, dynamic>> getAllCachedShoppingLists() {
    _ensureInitialized();
    try {
      final lists = <Map<String, dynamic>>[];
      for (var key in _shoppingLists?.keys ?? []) {
        final cached = _shoppingLists?.get(key);
        if (cached != null) {
          lists.add(jsonDecode(cached as String) as Map<String, dynamic>);
        }
      }
      return lists;
    } catch (e) {
      print('❌ [OfflineCache] Erreur récupération listes: $e');
      return [];
    }
  }

  /// Supprime une liste du cache
  Future<void> removeCachedShoppingList(String id) async {
    _ensureInitialized();
    try {
      await _shoppingLists?.delete(id);
      print('🗑️ [OfflineCache] Liste $id supprimée du cache');
    } catch (e) {
      print('❌ [OfflineCache] Erreur suppression liste: $e');
    }
  }

  // ========== LIST ITEMS ==========

  /// Sauvegarde un article dans le cache
  Future<void> cacheListItem(Map<String, dynamic> item) async {
    _ensureInitialized();
    try {
      final id = item['id']?.toString();
      if (id == null) return;

      await _listItems?.put(id, jsonEncode(item));
    } catch (e) {
      print('❌ [OfflineCache] Erreur cache article: $e');
    }
  }

  /// Sauvegarde plusieurs articles
  Future<void> cacheListItems(List<Map<String, dynamic>> items) async {
    _ensureInitialized();
    try {
      for (var item in items) {
        await cacheListItem(item);
      }
      print('💾 [OfflineCache] ${items.length} articles mis en cache');
    } catch (e) {
      print('❌ [OfflineCache] Erreur cache articles: $e');
    }
  }

  /// Récupère les articles d'une liste depuis le cache
  List<Map<String, dynamic>> getCachedListItems(int listId) {
    _ensureInitialized();
    try {
      final items = <Map<String, dynamic>>[];
      for (var key in _listItems?.keys ?? []) {
        final cached = _listItems?.get(key);
        if (cached != null) {
          final item = jsonDecode(cached as String) as Map<String, dynamic>;
          if (item['shopping_list_id'] == listId) {
            items.add(item);
          }
        }
      }
      return items;
    } catch (e) {
      print('❌ [OfflineCache] Erreur récupération articles: $e');
      return [];
    }
  }

  /// Supprime un article du cache
  Future<void> removeCachedListItem(String id) async {
    _ensureInitialized();
    try {
      await _listItems?.delete(id);
    } catch (e) {
      print('❌ [OfflineCache] Erreur suppression article: $e');
    }
  }

  // ========== CATEGORIES ==========

  /// Sauvegarde les catégories dans le cache
  Future<void> cacheCategories(List<Map<String, dynamic>> categories) async {
    _ensureInitialized();
    try {
      await _categories?.put('all', jsonEncode(categories));
      print('💾 [OfflineCache] ${categories.length} catégories mises en cache');
    } catch (e) {
      print('❌ [OfflineCache] Erreur cache catégories: $e');
    }
  }

  /// Récupère les catégories depuis le cache
  List<Map<String, dynamic>> getCachedCategories() {
    _ensureInitialized();
    try {
      final cached = _categories?.get('all');
      if (cached == null) return [];

      final List<dynamic> decoded = jsonDecode(cached as String);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ [OfflineCache] Erreur récupération catégories: $e');
      return [];
    }
  }

  // ========== PENDING ACTIONS (Queue de synchronisation) ==========

  /// Ajoute une action en attente de synchronisation
  Future<void> addPendingAction(Map<String, dynamic> action) async {
    _ensureInitialized();
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final key = '${action['type']}_$timestamp';

      await _pendingActions?.put(key, jsonEncode({
        ...action,
        'timestamp': timestamp,
        'retryCount': 0,
      }));

      print('📝 [OfflineCache] Action en attente ajoutée: ${action['type']}');
    } catch (e) {
      print('❌ [OfflineCache] Erreur ajout action: $e');
    }
  }

  /// Récupère toutes les actions en attente
  List<Map<String, dynamic>> getPendingActions() {
    _ensureInitialized();
    try {
      final actions = <Map<String, dynamic>>[];
      for (var key in _pendingActions?.keys ?? []) {
        final cached = _pendingActions?.get(key);
        if (cached != null) {
          final action = jsonDecode(cached as String) as Map<String, dynamic>;
          actions.add({...action, 'key': key});
        }
      }

      // Trier par timestamp
      actions.sort((a, b) =>
        (a['timestamp'] as int).compareTo(b['timestamp'] as int));

      return actions;
    } catch (e) {
      print('❌ [OfflineCache] Erreur récupération actions: $e');
      return [];
    }
  }

  /// Supprime une action en attente
  Future<void> removePendingAction(String key) async {
    _ensureInitialized();
    try {
      await _pendingActions?.delete(key);
      print('✅ [OfflineCache] Action synchronisée et supprimée');
    } catch (e) {
      print('❌ [OfflineCache] Erreur suppression action: $e');
    }
  }

  /// Incrémente le compteur de retry d'une action
  Future<void> incrementActionRetry(String key) async {
    _ensureInitialized();
    try {
      final cached = _pendingActions?.get(key);
      if (cached != null) {
        final action = jsonDecode(cached as String) as Map<String, dynamic>;
        action['retryCount'] = (action['retryCount'] as int? ?? 0) + 1;
        await _pendingActions?.put(key, jsonEncode(action));
      }
    } catch (e) {
      print('❌ [OfflineCache] Erreur incrémentation retry: $e');
    }
  }

  /// Supprime toutes les actions en attente
  Future<void> clearPendingActions() async {
    _ensureInitialized();
    try {
      await _pendingActions?.clear();
      print('🗑️ [OfflineCache] Actions en attente effacées');
    } catch (e) {
      print('❌ [OfflineCache] Erreur effacement actions: $e');
    }
  }

  // ========== UTILITIES ==========

  /// Efface tout le cache
  Future<void> clearAllCache() async {
    _ensureInitialized();
    try {
      await _shoppingLists?.clear();
      await _listItems?.clear();
      await _categories?.clear();
      await _pendingActions?.clear();
      print('🗑️ [OfflineCache] Cache entièrement effacé');
    } catch (e) {
      print('❌ [OfflineCache] Erreur effacement cache: $e');
    }
  }

  /// Vérifie si le cache est initialisé
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('OfflineCacheService doit être initialisé avant utilisation');
    }
  }

  /// Ferme toutes les boxes
  Future<void> dispose() async {
    try {
      await _shoppingLists?.close();
      await _listItems?.close();
      await _categories?.close();
      await _pendingActions?.close();
      _isInitialized = false;
      print('👋 [OfflineCache] Cache fermé');
    } catch (e) {
      print('❌ [OfflineCache] Erreur fermeture cache: $e');
    }
  }
}
