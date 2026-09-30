import 'package:flutter/foundation.dart';
// services/offline_sync_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:epilist/models/budget.dart';
import 'package:epilist/services/connectivity_service.dart';
import 'package:epilist/services/offline_queue_service.dart';
import 'package:epilist/services/offline_storage_service.dart';
import 'package:epilist/services/shopping_list_service.dart';
import 'package:epilist/services/list_item_service.dart';
import 'package:epilist/services/store_service.dart';
import 'package:epilist/services/receipt_service.dart';
import 'package:epilist/services/budget_service.dart';
import 'package:epilist/services/category_service.dart';
import 'package:epilist/services/space_service.dart';
import 'package:epilist/services/token_store.dart';
import 'package:epilist/config/app_config.dart';

/// Service de synchronisation pour le mode hors ligne
/// Gère la queue d'actions en attente et la synchronisation avec le serveur
///
/// SÉCURITÉ: Toutes les actions sont exécutées via l'API validée.
/// Aucune modification directe de la base de données.
class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  final _connectivityService = ConnectivityService();

  // Services API (seront injectés)
  ShoppingListService? _shoppingListService;
  ListItemService? _listItemService;
  StoreService? _storeService;
  ReceiptService? _receiptService;
  BudgetService? _budgetService;
  CategoryService? _categoryService;

  /// Correspondance id local (négatif) → id serveur, construite pendant la
  /// passe de synchro (ex. create_list) et persistée dans la file pour les
  /// actions qui suivent.
  final Map<int, int> _idMap = {};

  StreamSubscription<bool>? _connectivitySubscription;
  bool _isSyncing = false;
  bool _isInitialized = false;

  // Stream pour notifier les changements de synchronisation
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  /// Initialise le service de synchronisation
  Future<void> initialize({
    required ShoppingListService shoppingListService,
    required ListItemService listItemService,
    StoreService? storeService,
    ReceiptService? receiptService,
    BudgetService? budgetService,
    CategoryService? categoryService,
  }) async {
    if (_isInitialized) return;

    _shoppingListService = shoppingListService;
    _listItemService = listItemService;
    _storeService = storeService;
    _receiptService = receiptService;
    _budgetService = budgetService;
    _categoryService = categoryService;

    // Initialiser la queue
    await OfflineQueueService.initialize();

    // Écouter les changements de connectivité
    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      (isConnected) async {
        if (isConnected && !_isSyncing) {
          debugPrint('📡 [OfflineSync] Connexion rétablie, démarrage de la synchronisation...');
          await syncPendingActions();
        }
      },
    );

    _isInitialized = true;
    debugPrint('✅ [OfflineSync] Service de synchronisation initialisé');
  }

  /// Synchronise toutes les actions en attente
  Future<void> syncPendingActions() async {
    if (_isSyncing) {
      debugPrint('⏳ [OfflineSync] Synchronisation déjà en cours...');
      return;
    }

    if (!_connectivityService.isConnected) {
      debugPrint('📵 [OfflineSync] Pas de connexion, synchronisation annulée');
      return;
    }

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      final pendingActions = await OfflineQueueService.getPendingActions();

      if (pendingActions.isEmpty) {
        debugPrint('✅ [OfflineSync] Aucune action en attente');
        _syncStatusController.add(SyncStatus.idle);
        return;
      }

      debugPrint('🔄 [OfflineSync] ${pendingActions.length} actions à synchroniser');

      int successCount = 0;
      int failureCount = 0;

      // Trier par timestamp (plus ancien en premier)
      pendingActions.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp'] as String);
        final bTime = DateTime.parse(b['timestamp'] as String);
        return aTime.compareTo(bTime);
      });

      for (var action in pendingActions) {
        try {
          // Marquer comme en cours
          await OfflineQueueService.markAsProcessing(action['id'] as String);

          // Rejouer DANS l'espace capturé à l'enqueue (0 = personnel).
          SpaceHeaderInterceptor.syncOverride = (action['space_id'] as int?) ?? 0;

          // Exécuter l'action
          final success = await _syncAction(action);

          if (success) {
            // Marquer comme réussie
            await OfflineQueueService.markAsCompleted(action['id'] as String);
            successCount++;
          } else {
            // Marquer comme échouée
            await OfflineQueueService.markAsFailed(
              action['id'] as String,
              'Sync failed',
            );
            failureCount++;
          }
        } catch (e) {
          debugPrint('❌ [OfflineSync] Erreur sync action ${action['action_type']}: $e');
          await OfflineQueueService.markAsFailed(
            action['id'] as String,
            e.toString(),
          );
          failureCount++;
        }

        SpaceHeaderInterceptor.syncOverride = null;

        // Petit délai entre chaque action
        await Future.delayed(const Duration(milliseconds: 500));
      }

      debugPrint('✅ [OfflineSync] Synchronisation terminée: $successCount succès, $failureCount échecs');

      // Rafraîchir le cache des listes après une synchro qui a modifié des
      // données : sinon le prochain démarrage hors ligne montre des
      // compteurs périmés (état d'avant les actions rejouées).
      if (successCount > 0) {
        await _refreshListsCache();
      }

      _syncStatusController.add(
        failureCount > 0 ? SyncStatus.partiallyFailed : SyncStatus.success,
      );
    } catch (e) {
      debugPrint('❌ [OfflineSync] Erreur lors de la synchronisation: $e');
      _syncStatusController.add(SyncStatus.failed);
    } finally {
      _isSyncing = false;
    }
  }

  /// Traduit un id local (négatif) vers l'id serveur si connu.
  int _mapId(int id) => id < 0 ? (_idMap[id] ?? id) : id;

  /// Un service manquant est un ÉCHEC explicite : avec l'ancien `?.`,
  /// l'action était marquée synchronisée sans qu'aucune requête ne parte
  /// (perte silencieuse).
  bool _missing(Object? service, String name) {
    if (service != null) return false;
    debugPrint('❌ [OfflineSync] Service $name non injecté, action conservée en file');
    return true;
  }

  /// Recharge et sauvegarde le cache des listes après une synchro réussie.
  Future<void> _refreshListsCache() async {
    try {
      final lists = await _shoppingListService?.getShoppingLists();
      if (lists != null) {
        await OfflineStorageService.saveShoppingLists(lists);
        debugPrint('💾 [OfflineSync] Cache des listes rafraîchi après synchro');
      }
    } catch (e) {
      debugPrint('⚠️ [OfflineSync] Rafraîchissement du cache listes impossible: $e');
    }
  }

  /// Enregistre une correspondance id local → id serveur et la propage
  /// aux actions encore en file.
  Future<void> _registerIdMapping(String? localId, int serverId) async {
    final local = int.tryParse(localId ?? '');
    if (local == null || local >= 0) return;
    _idMap[local] = serverId;
    await OfflineQueueService.remapLocalIds({local: serverId});
  }

  /// Synchronise une action spécifique
  Future<bool> _syncAction(Map<String, dynamic> action) async {
    final type = action['action_type'] as String;
    final payload = action['payload'] as Map<String, dynamic>;

    debugPrint('🔄 [OfflineSync] Synchronisation de: $type');

    try {
      switch (type) {
        // Shopping Lists
        case OfflineQueueService.actionCreateList:
          if (_missing(_shoppingListService, 'listes')) return false;
          final created = await _shoppingListService!.createShoppingList(
            payload['name'] as String,
          );
          await _registerIdMapping(action['local_id'] as String?, created.id);
          return true;

        case OfflineQueueService.actionUpdateList:
          if (_missing(_shoppingListService, 'listes')) return false;
          final listId = _mapId(payload['id'] as int);
          if (listId < 0) return false; // create_list pas encore synchronisé
          await _shoppingListService!.updateShoppingList(
            listId,
            payload['name'] as String,
          );
          return true;

        case OfflineQueueService.actionDeleteList:
          if (_missing(_shoppingListService, 'listes')) return false;
          final listId = _mapId(payload['id'] as int);
          // Liste jamais créée côté serveur : rien à supprimer.
          if (listId < 0) return true;
          await _shoppingListService!.deleteShoppingList(listId);
          return true;

        case OfflineQueueService.actionDuplicateList:
          if (_missing(_shoppingListService, 'listes')) return false;
          final listId = _mapId(payload['id'] as int);
          if (listId < 0) return false;
          await _shoppingListService!.duplicateShoppingList(listId);
          return true;

        // List Items
        case OfflineQueueService.actionCreateItem:
          if (_missing(_listItemService, 'articles')) return false;
          final listId = _mapId(payload['list_id'] as int);
          if (listId < 0) return false;
          final result = await _listItemService!.addListItem(
            listId: listId,
            productName: payload['product_name'] as String,
            price: (payload['price'] as num?)?.toDouble(),
            quantity: payload['quantity'] as int? ?? 1,
            categoryId: payload['category_id'] as int?,
            storeName: payload['store_name'] as String?,
          );
          final createdId = result.item?.id;
          if (createdId != null) {
            await _registerIdMapping(action['local_id'] as String?, createdId);
          }
          return true;

        case OfflineQueueService.actionUpdateItem:
          if (_missing(_listItemService, 'articles')) return false;
          final listId = _mapId(payload['list_id'] as int);
          final itemId = _mapId(payload['item_id'] as int);
          if (listId < 0 || itemId < 0) return false;
          await _listItemService!.updateListItem(
            listId: listId,
            itemId: itemId,
            productName: payload['product_name'] as String,
            price: (payload['price'] as num?)?.toDouble(),
            quantity: payload['quantity'] as int? ?? 1,
            categoryId: payload['category_id'] as int?,
            storeName: payload['store_name'] as String?,
          );
          return true;

        case OfflineQueueService.actionDeleteItem:
          if (_missing(_listItemService, 'articles')) return false;
          final listId = _mapId(payload['list_id'] as int);
          final itemId = _mapId(payload['item_id'] as int);
          if (itemId < 0) return true; // article jamais créé côté serveur
          if (listId < 0) return false;
          await _listItemService!.deleteListItem(
            listId: listId,
            itemId: itemId,
          );
          return true;

        case OfflineQueueService.actionToggleItem:
          if (_missing(_listItemService, 'articles')) return false;
          final listId = _mapId(payload['list_id'] as int);
          final itemId = _mapId(payload['item_id'] as int);
          if (listId < 0 || itemId < 0) return false;
          await _listItemService!.togglePurchasedStatus(
            listId: listId,
            itemId: itemId,
            isPurchased: payload['is_purchased'] as bool,
          );
          return true;

        // Receipts
        case OfflineQueueService.actionCreateReceipt:
          if (_missing(_receiptService, 'factures')) return false;
          final listId = _mapId(payload['list_id'] as int);
          if (listId < 0) return false;
          await _receiptService!.createReceipt(
            listId: listId,
            storeName: payload['store_name'] as String,
            totalAmount: (payload['total_amount'] as num).toDouble(),
            purchaseDate: DateTime.parse(payload['purchase_date'] as String),
            notes: payload['notes'] as String?,
          );
          return true;

        case OfflineQueueService.actionUpdateReceipt:
          if (_missing(_receiptService, 'factures')) return false;
          await _receiptService!.updateReceipt(
            listId: _mapId(payload['list_id'] as int),
            receiptId: payload['receipt_id'] as int,
            storeName: payload['store_name'] as String?,
            totalAmount: (payload['total_amount'] as num?)?.toDouble(),
            purchaseDate: payload['purchase_date'] != null
                ? DateTime.parse(payload['purchase_date'] as String)
                : null,
            notes: payload['notes'] as String?,
          );
          return true;

        case OfflineQueueService.actionDeleteReceipt:
          if (_missing(_receiptService, 'factures')) return false;
          await _receiptService!.deleteReceipt(
            _mapId(payload['list_id'] as int),
            payload['receipt_id'] as int,
          );
          return true;

        // Budgets : le payload porte désormais la requête complète
        // (CreateBudgetRequest/UpdateBudgetRequest.toJson côté bloc).
        case OfflineQueueService.actionCreateBudget:
          if (_missing(_budgetService, 'budgets')) return false;
          await _budgetService!.createBudget(
            CreateBudgetRequest(
              name: payload['name'] as String,
              budgetAmount: (payload['budget_amount'] as num).toDouble(),
              periodType:
                  BudgetPeriodType.values.byName(payload['period_type'] as String),
              startDate: DateTime.parse(payload['start_date'] as String),
              endDate: DateTime.parse(payload['end_date'] as String),
              alertThreshold: payload['alert_threshold'] as int? ?? 80,
              listId: payload['list_id'] != null
                  ? _mapId(payload['list_id'] as int)
                  : null,
            ),
          );
          return true;

        case OfflineQueueService.actionUpdateBudget:
          if (_missing(_budgetService, 'budgets')) return false;
          final budgetId = payload['budget_id'] as int;
          if (budgetId < 0) return false;
          await _budgetService!.updateBudget(
            budgetId,
            UpdateBudgetRequest(
              name: payload['name'] as String?,
              budgetAmount: (payload['budget_amount'] as num?)?.toDouble(),
              periodType: payload['period_type'] != null
                  ? BudgetPeriodType.values.byName(payload['period_type'] as String)
                  : null,
              startDate: payload['start_date'] != null
                  ? DateTime.parse(payload['start_date'] as String)
                  : null,
              endDate: payload['end_date'] != null
                  ? DateTime.parse(payload['end_date'] as String)
                  : null,
              alertThreshold: payload['alert_threshold'] as int?,
              isActive: payload['is_active'] as bool?,
            ),
          );
          return true;

        case OfflineQueueService.actionDeleteBudget:
          if (_missing(_budgetService, 'budgets')) return false;
          final budgetId = payload['budget_id'] as int;
          if (budgetId < 0) return true; // budget jamais créé côté serveur
          await _budgetService!.deleteBudget(budgetId);
          return true;

        // Catégories : ces actions étaient mises en file par le bloc mais
        // jamais rejouées (« type inconnu » → abandon).
        case OfflineQueueService.actionCreateCategory:
          if (_missing(_categoryService, 'catégories')) return false;
          final created = await _categoryService!.createCategory(
            name: payload['name'] as String,
            iconCode: payload['icon_code'] as String,
            colorHex: payload['color_hex'] as String,
            orderIndex: payload['order_index'] as int? ?? 0,
          );
          await _registerIdMapping(action['local_id'] as String?, created.id);
          return true;

        case OfflineQueueService.actionUpdateCategory:
          if (_missing(_categoryService, 'catégories')) return false;
          final categoryId = _mapId(payload['category_id'] as int);
          if (categoryId < 0) return false;
          await _categoryService!.updateCategory(
            categoryId: categoryId,
            name: payload['name'] as String?,
            iconCode: payload['icon_code'] as String?,
            colorHex: payload['color_hex'] as String?,
            orderIndex: payload['order_index'] as int?,
          );
          return true;

        case OfflineQueueService.actionDeleteCategory:
          if (_missing(_categoryService, 'catégories')) return false;
          final categoryId = _mapId(payload['category_id'] as int);
          if (categoryId < 0) return true; // catégorie jamais créée côté serveur
          await _categoryService!.deleteCategory(categoryId);
          return true;

        case OfflineQueueService.actionReorderCategories:
          if (_missing(_categoryService, 'catégories')) return false;
          final ids = (payload['category_ids'] as List)
              .cast<int>()
              .map(_mapId)
              .where((id) => id > 0)
              .toList();
          if (ids.isNotEmpty) {
            await _categoryService!.reorderCategories(ids);
          }
          return true;

        // Magasins (tri par rayon). Les actions sur un id temporaire
        // (negatif, cree hors ligne) sont ignorees : l'ecran bloque leur
        // edition tant que la synchro n'est pas passee.
        case OfflineQueueService.actionCreateStore:
          await _storeService?.createStore(payload['name'] as String);
          return true;

        case OfflineQueueService.actionRenameStore:
          final storeId = payload['store_id'] as int;
          if (storeId < 0) return true;
          await _storeService?.renameStore(storeId, payload['name'] as String);
          return true;

        case OfflineQueueService.actionDeleteStore:
          final storeId = payload['store_id'] as int;
          if (storeId < 0) return true;
          await _storeService?.deleteStore(storeId);
          return true;

        case OfflineQueueService.actionSetStoreOrder:
          final storeId = payload['store_id'] as int;
          if (storeId < 0) return true;
          await _storeService?.setCategoryOrder(
            storeId,
            (payload['category_kinds'] as List).cast<String>(),
          );
          return true;

        // User Profile - TODO: Implémenter quand UserService sera disponible
        case OfflineQueueService.actionUpdateProfile:
          debugPrint('⚠️ [OfflineSync] actionUpdateProfile not yet implemented');
          return true; // Ignorer pour l'instant

        // Email Preferences
        case OfflineQueueService.actionUpdateEmailPreferences:
          final token = await _getToken();
          if (token == null) return false;

          final response = await http.put(
            Uri.parse('${AppConfig.baseUrl}/user/email-preferences'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode(payload),
          );

          if (response.statusCode == 200) {
            final jsonData = json.decode(response.body);
            return jsonData['success'] == true;
          }
          return false;

        // Send Feedback
        case OfflineQueueService.actionSendFeedback:
          final token = await _getToken();
          // Déterminer l'endpoint selon si l'utilisateur est connecté
          final endpoint = token != null
              ? '${AppConfig.baseUrl}/contact/feedback'
              : '${AppConfig.baseUrl}/contact/feedback-anonymous';

          final headers = {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          };

          if (token != null) {
            headers['Authorization'] = 'Bearer $token';
          }

          final response = await http.post(
            Uri.parse(endpoint),
            headers: headers,
            body: json.encode(payload),
          );

          if (response.statusCode == 200) {
            final jsonData = json.decode(response.body);
            return jsonData['success'] == true;
          }
          return false;

        default:
          debugPrint('⚠️ [OfflineSync] Type d\'action inconnu: $type');
          return false;
      }
    } catch (e) {
      debugPrint('❌ [OfflineSync] Erreur sync $type: $e');
      return false;
    }
  }

  /// Token d'accès depuis le stockage sécurisé. L'ancienne lecture
  /// SharedPreferences['access_token'] retournait toujours null depuis la
  /// migration TokenStore (la clé legacy est supprimée à la migration).
  Future<String?> _getToken() async {
    try {
      return await TokenStore.readAccess();
    } catch (e) {
      debugPrint('❌ [OfflineSync] Error getting token: $e');
      return null;
    }
  }

  /// Ajoute une action à la queue de synchronisation
  Future<void> queueAction({
    required String type,
    required Map<String, dynamic> payload,
    String? localId,
  }) async {
    try {
      await OfflineQueueService.enqueueAction(
        actionType: type,
        payload: payload,
        localId: localId,
      );

      debugPrint('📝 [OfflineSync] Action mise en queue: $type');

      // Tenter la synchronisation immédiatement si connecté
      if (_connectivityService.isConnected && !_isSyncing) {
        await syncPendingActions();
      }
    } catch (e) {
      debugPrint('❌ [OfflineSync] Erreur mise en queue: $e');
    }
  }

  /// Obtient le nombre d'actions en attente
  Future<int> getPendingActionsCount() async {
    return await OfflineQueueService.getPendingCount();
  }

  /// Obtient les actions en attente
  Future<List<Map<String, dynamic>>> getPendingActions() async {
    return await OfflineQueueService.getPendingActions();
  }

  /// Efface toutes les actions en attente
  Future<void> clearPendingActions() async {
    await OfflineQueueService.clearQueue();
    debugPrint('🗑️ [OfflineSync] Actions en attente effacées');
  }

  /// Force la synchronisation manuelle
  Future<void> forceSyncNow() async {
    debugPrint('🔄 [OfflineSync] Synchronisation forcée...');
    await syncPendingActions();
  }

  /// Obtenir le statut de la queue
  Future<Map<String, dynamic>> getQueueStatus() async {
    return await OfflineQueueService.getStatus();
  }

  /// Obtenir les statistiques détaillées
  Future<Map<String, dynamic>> getDetailedStats() async {
    return await OfflineQueueService.getDetailedStats();
  }

  /// Nettoie les ressources
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
    _isInitialized = false;
    debugPrint('👋 [OfflineSync] Service de synchronisation fermé');
  }
}

/// Statut de synchronisation
enum SyncStatus {
  idle,
  syncing,
  success,
  partiallyFailed,
  failed,
}
