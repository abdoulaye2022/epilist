// services/offline_storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/models/budget.dart';
import 'package:epilist/models/receipt.dart';

/// Service de stockage hors ligne sécurisé avec versioning
class OfflineStorageService {
  static const String _version = '1.0.0';
  static const String _versionKey = 'offline_cache_version';

  // ============================================================================
  // CLÉS DE CACHE
  // ============================================================================
  static const String _shoppingListsKey = 'cached_shopping_lists';
  static const String _budgetsKey = 'cached_budgets';
  static const String _receiptsKey = 'cached_receipts';
  static const String _userProfileKey = 'cached_user_profile';
  static const String _currencyKey = 'cached_currency';
  static const String _categoriesKey = 'cached_categories';
  static const String _lastSyncKey = 'last_sync_timestamp';

  // ============================================================================
  // INITIALISATION ET VÉRIFICATION
  // ============================================================================

  /// Initialiser le cache et vérifier la version
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedVersion = prefs.getString(_versionKey);

    if (cachedVersion != _version) {
      print('🔄 [OfflineStorage] Version mismatch, clearing cache...');
      await clearAll();
      await prefs.setString(_versionKey, _version);
      print('✅ [OfflineStorage] Cache initialized with version $_version');
    } else {
      print('✅ [OfflineStorage] Cache version OK: $_version');
    }
  }

  /// Vérifier si le cache est valide (moins de 7 jours)
  static Future<bool> isCacheValid() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt(_lastSyncKey);

    if (lastSync == null) return false;

    final lastSyncDate = DateTime.fromMillisecondsSinceEpoch(lastSync);
    final age = DateTime.now().difference(lastSyncDate);

    // Cache valide si moins de 7 jours
    return age.inDays < 7;
  }

  /// Mettre à jour le timestamp de dernière synchronisation
  static Future<void> updateLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  // ============================================================================
  // SHOPPING LISTS - CACHE
  // ============================================================================

  /// Sauvegarder les listes de shopping
  static Future<bool> saveShoppingLists(List<ShoppingList> lists) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = lists.map((list) => list.toJson()).toList();
      final encoded = json.encode(jsonList);

      await prefs.setString(_shoppingListsKey, encoded);
      await updateLastSync();

      print('💾 [OfflineStorage] Saved ${lists.length} shopping lists');
      return true;
    } catch (e) {
      print('❌ [OfflineStorage] Error saving shopping lists: $e');
      return false;
    }
  }

  /// Charger les listes de shopping depuis le cache
  static Future<List<ShoppingList>?> getShoppingLists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_shoppingListsKey);

      if (encoded == null || encoded.isEmpty) {
        print('ℹ️ [OfflineStorage] No cached shopping lists');
        return null;
      }

      final List<dynamic> jsonList = json.decode(encoded);
      final lists = jsonList.map((json) => ShoppingList.fromJson(json)).toList();

      print('📦 [OfflineStorage] Loaded ${lists.length} shopping lists from cache');
      return lists;
    } catch (e) {
      print('❌ [OfflineStorage] Error loading shopping lists: $e');
      return null;
    }
  }

  // ============================================================================
  // BUDGETS - CACHE
  // ============================================================================

  /// Sauvegarder les budgets
  static Future<bool> saveBudgets(List<Budget> budgets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = budgets.map((budget) => budget.toJson()).toList();
      final encoded = json.encode(jsonList);

      await prefs.setString(_budgetsKey, encoded);
      await updateLastSync();

      print('💾 [OfflineStorage] Saved ${budgets.length} budgets');
      return true;
    } catch (e) {
      print('❌ [OfflineStorage] Error saving budgets: $e');
      return false;
    }
  }

  /// Charger les budgets depuis le cache
  static Future<List<Budget>?> getBudgets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_budgetsKey);

      if (encoded == null || encoded.isEmpty) {
        print('ℹ️ [OfflineStorage] No cached budgets');
        return null;
      }

      final List<dynamic> jsonList = json.decode(encoded);
      final budgets = jsonList.map((json) => Budget.fromJson(json)).toList();

      print('📦 [OfflineStorage] Loaded ${budgets.length} budgets from cache');
      return budgets;
    } catch (e) {
      print('❌ [OfflineStorage] Error loading budgets: $e');
      return null;
    }
  }

  // ============================================================================
  // RECEIPTS - CACHE
  // ============================================================================

  /// Sauvegarder les factures par liste
  static Future<bool> saveReceipts(int listId, List<Receipt> receipts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_receiptsKey}_$listId';
      final jsonList = receipts.map((receipt) => receipt.toJson()).toList();
      final encoded = json.encode(jsonList);

      await prefs.setString(key, encoded);
      await updateLastSync();

      print('💾 [OfflineStorage] Saved ${receipts.length} receipts for list $listId');
      return true;
    } catch (e) {
      print('❌ [OfflineStorage] Error saving receipts: $e');
      return false;
    }
  }

  /// Charger les factures d'une liste depuis le cache
  static Future<List<Receipt>?> getReceipts(int listId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_receiptsKey}_$listId';
      final encoded = prefs.getString(key);

      if (encoded == null || encoded.isEmpty) {
        print('ℹ️ [OfflineStorage] No cached receipts for list $listId');
        return null;
      }

      final List<dynamic> jsonList = json.decode(encoded);
      final receipts = jsonList.map((json) => Receipt.fromJson(json)).toList();

      print('📦 [OfflineStorage] Loaded ${receipts.length} receipts from cache');
      return receipts;
    } catch (e) {
      print('❌ [OfflineStorage] Error loading receipts: $e');
      return null;
    }
  }

  // ============================================================================
  // USER PROFILE - CACHE
  // ============================================================================

  /// Sauvegarder le profil utilisateur
  static Future<bool> saveUserProfile(Map<String, dynamic> profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(profile);

      await prefs.setString(_userProfileKey, encoded);
      print('💾 [OfflineStorage] Saved user profile');
      return true;
    } catch (e) {
      print('❌ [OfflineStorage] Error saving user profile: $e');
      return false;
    }
  }

  /// Charger le profil utilisateur depuis le cache
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_userProfileKey);

      if (encoded == null || encoded.isEmpty) {
        print('ℹ️ [OfflineStorage] No cached user profile');
        return null;
      }

      final profile = json.decode(encoded) as Map<String, dynamic>;
      print('📦 [OfflineStorage] Loaded user profile from cache');
      return profile;
    } catch (e) {
      print('❌ [OfflineStorage] Error loading user profile: $e');
      return null;
    }
  }

  // ============================================================================
  // CURRENCY - CACHE
  // ============================================================================

  /// Sauvegarder la devise utilisateur
  static Future<bool> saveCurrency(Map<String, dynamic> currency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(currency);

      await prefs.setString(_currencyKey, encoded);
      print('💾 [OfflineStorage] Saved currency');
      return true;
    } catch (e) {
      print('❌ [OfflineStorage] Error saving currency: $e');
      return false;
    }
  }

  /// Charger la devise utilisateur depuis le cache
  static Future<Map<String, dynamic>?> getCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_currencyKey);

      if (encoded == null || encoded.isEmpty) {
        print('ℹ️ [OfflineStorage] No cached currency');
        return null;
      }

      final currency = json.decode(encoded) as Map<String, dynamic>;
      print('📦 [OfflineStorage] Loaded currency from cache');
      return currency;
    } catch (e) {
      print('❌ [OfflineStorage] Error loading currency: $e');
      return null;
    }
  }

  // ============================================================================
  // CATEGORIES - CACHE
  // ============================================================================

  /// Sauvegarder les catégories
  static Future<bool> saveCategories(List<Map<String, dynamic>> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(categories);

      await prefs.setString(_categoriesKey, encoded);
      print('💾 [OfflineStorage] Saved ${categories.length} categories');
      return true;
    } catch (e) {
      print('❌ [OfflineStorage] Error saving categories: $e');
      return false;
    }
  }

  /// Charger les catégories depuis le cache
  static Future<List<Map<String, dynamic>>?> getCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_categoriesKey);

      if (encoded == null || encoded.isEmpty) {
        print('ℹ️ [OfflineStorage] No cached categories');
        return null;
      }

      final List<dynamic> jsonList = json.decode(encoded);
      final categories = jsonList.cast<Map<String, dynamic>>();

      print('📦 [OfflineStorage] Loaded ${categories.length} categories from cache');
      return categories;
    } catch (e) {
      print('❌ [OfflineStorage] Error loading categories: $e');
      return null;
    }
  }

  // ============================================================================
  // NETTOYAGE
  // ============================================================================

  /// Nettoyer tout le cache (SÉCURISÉ - ne touche pas aux tokens)
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Liste des clés à supprimer (SEULEMENT le cache, PAS les tokens!)
      final keysToRemove = [
        _shoppingListsKey,
        _budgetsKey,
        _userProfileKey,
        _currencyKey,
        _categoriesKey,
        _lastSyncKey,
      ];

      // Supprimer aussi tous les receipts (pattern matching)
      final allKeys = prefs.getKeys();
      for (final key in allKeys) {
        if (key.startsWith(_receiptsKey)) {
          keysToRemove.add(key);
        }
      }

      for (final key in keysToRemove) {
        await prefs.remove(key);
      }

      print('🧹 [OfflineStorage] Cache cleared (${keysToRemove.length} keys)');
    } catch (e) {
      print('❌ [OfflineStorage] Error clearing cache: $e');
    }
  }

  /// Nettoyer uniquement les données expirées (> 7 jours)
  static Future<void> clearExpiredCache() async {
    final isValid = await isCacheValid();
    if (!isValid) {
      print('🗑️ [OfflineStorage] Cache expired, clearing...');
      await clearAll();
    }
  }

  // ============================================================================
  // STATISTIQUES
  // ============================================================================

  /// Obtenir les statistiques du cache
  static Future<Map<String, dynamic>> getCacheStats() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt(_lastSyncKey);

    final shoppingLists = await getShoppingLists();
    final budgets = await getBudgets();
    final profile = await getUserProfile();
    final currency = await getCurrency();
    final categories = await getCategories();

    return {
      'version': _version,
      'last_sync': lastSync != null
          ? DateTime.fromMillisecondsSinceEpoch(lastSync).toIso8601String()
          : null,
      'cache_valid': await isCacheValid(),
      'shopping_lists_count': shoppingLists?.length ?? 0,
      'budgets_count': budgets?.length ?? 0,
      'has_profile': profile != null,
      'has_currency': currency != null,
      'categories_count': categories?.length ?? 0,
    };
  }
}
