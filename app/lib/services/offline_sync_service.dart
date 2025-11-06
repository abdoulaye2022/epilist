// services/offline_sync_service.dart
import 'dart:async';
import 'package:epilist/services/connectivity_service.dart';
import 'package:epilist/services/offline_queue_service.dart';
import 'package:epilist/services/shopping_list_service.dart';
import 'package:epilist/services/list_item_service.dart';
import 'package:epilist/services/receipt_service.dart';
import 'package:epilist/services/budget_service.dart';

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
  ReceiptService? _receiptService;
  BudgetService? _budgetService;

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
    ReceiptService? receiptService,
    BudgetService? budgetService,
  }) async {
    if (_isInitialized) return;

    _shoppingListService = shoppingListService;
    _listItemService = listItemService;
    _receiptService = receiptService;
    _budgetService = budgetService;

    // Initialiser la queue
    await OfflineQueueService.initialize();

    // Écouter les changements de connectivité
    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      (isConnected) async {
        if (isConnected && !_isSyncing) {
          print('📡 [OfflineSync] Connexion rétablie, démarrage de la synchronisation...');
          await syncPendingActions();
        }
      },
    );

    _isInitialized = true;
    print('✅ [OfflineSync] Service de synchronisation initialisé');
  }

  /// Synchronise toutes les actions en attente
  Future<void> syncPendingActions() async {
    if (_isSyncing) {
      print('⏳ [OfflineSync] Synchronisation déjà en cours...');
      return;
    }

    if (!_connectivityService.isConnected) {
      print('📵 [OfflineSync] Pas de connexion, synchronisation annulée');
      return;
    }

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      final pendingActions = await OfflineQueueService.getPendingActions();

      if (pendingActions.isEmpty) {
        print('✅ [OfflineSync] Aucune action en attente');
        _syncStatusController.add(SyncStatus.idle);
        return;
      }

      print('🔄 [OfflineSync] ${pendingActions.length} actions à synchroniser');

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
          print('❌ [OfflineSync] Erreur sync action ${action['action_type']}: $e');
          await OfflineQueueService.markAsFailed(
            action['id'] as String,
            e.toString(),
          );
          failureCount++;
        }

        // Petit délai entre chaque action
        await Future.delayed(const Duration(milliseconds: 500));
      }

      print('✅ [OfflineSync] Synchronisation terminée: $successCount succès, $failureCount échecs');
      _syncStatusController.add(
        failureCount > 0 ? SyncStatus.partiallyFailed : SyncStatus.success,
      );
    } catch (e) {
      print('❌ [OfflineSync] Erreur lors de la synchronisation: $e');
      _syncStatusController.add(SyncStatus.failed);
    } finally {
      _isSyncing = false;
    }
  }

  /// Synchronise une action spécifique
  Future<bool> _syncAction(Map<String, dynamic> action) async {
    final type = action['action_type'] as String;
    final payload = action['payload'] as Map<String, dynamic>;

    print('🔄 [OfflineSync] Synchronisation de: $type');

    try {
      switch (type) {
        // Shopping Lists
        case OfflineQueueService.ACTION_CREATE_LIST:
          await _shoppingListService?.createShoppingList(
            payload['name'] as String,
          );
          return true;

        case OfflineQueueService.ACTION_UPDATE_LIST:
          await _shoppingListService?.updateShoppingList(
            payload['id'] as int,
            payload['name'] as String,
          );
          return true;

        case OfflineQueueService.ACTION_DELETE_LIST:
          await _shoppingListService?.deleteShoppingList(payload['id'] as int);
          return true;

        case OfflineQueueService.ACTION_DUPLICATE_LIST:
          await _shoppingListService?.duplicateShoppingList(payload['id'] as int);
          return true;

        // List Items
        case OfflineQueueService.ACTION_CREATE_ITEM:
          await _listItemService?.addListItem(
            listId: payload['list_id'] as int,
            productName: payload['product_name'] as String,
            price: payload['price'] as double?,
            quantity: payload['quantity'] as int? ?? 1,
            categoryId: payload['category_id'] as int?,
            storeName: payload['store_name'] as String?,
          );
          return true;

        case OfflineQueueService.ACTION_UPDATE_ITEM:
          await _listItemService?.updateListItem(
            listId: payload['list_id'] as int,
            itemId: payload['item_id'] as int,
            productName: payload['product_name'] as String,
            price: payload['price'] as double?,
            quantity: payload['quantity'] as int? ?? 1,
            categoryId: payload['category_id'] as int?,
            storeName: payload['store_name'] as String?,
          );
          return true;

        case OfflineQueueService.ACTION_DELETE_ITEM:
          await _listItemService?.deleteListItem(
            listId: payload['list_id'] as int,
            itemId: payload['item_id'] as int,
          );
          return true;

        case OfflineQueueService.ACTION_TOGGLE_ITEM:
          await _listItemService?.togglePurchasedStatus(
            listId: payload['list_id'] as int,
            itemId: payload['item_id'] as int,
            isPurchased: payload['is_purchased'] as bool,
          );
          return true;

        // Receipts
        case OfflineQueueService.ACTION_CREATE_RECEIPT:
          await _receiptService?.createReceipt(
            listId: payload['list_id'] as int,
            storeName: payload['store_name'] as String,
            totalAmount: payload['total_amount'] as double,
            purchaseDate: DateTime.parse(payload['purchase_date'] as String),
            notes: payload['notes'] as String?,
          );
          return true;

        case OfflineQueueService.ACTION_UPDATE_RECEIPT:
          await _receiptService?.updateReceipt(
            listId: payload['list_id'] as int,
            receiptId: payload['receipt_id'] as int,
            storeName: payload['store_name'] as String?,
            totalAmount: payload['total_amount'] as double?,
            purchaseDate: payload['purchase_date'] != null
                ? DateTime.parse(payload['purchase_date'] as String)
                : null,
            notes: payload['notes'] as String?,
          );
          return true;

        case OfflineQueueService.ACTION_DELETE_RECEIPT:
          await _receiptService?.deleteReceipt(
            payload['list_id'] as int,
            payload['receipt_id'] as int,
          );
          return true;

        // Budgets
        case OfflineQueueService.ACTION_CREATE_BUDGET:
          // Note: Budget creation requires more data than stored in queue
          // This is a simplified version - consider storing full budget data
          print('⚠️ [OfflineSync] Budget creation from queue requires full data');
          return false;

        case OfflineQueueService.ACTION_UPDATE_BUDGET:
          // Note: Budget update requires UpdateBudgetRequest
          // This is a simplified version - consider storing full budget data
          print('⚠️ [OfflineSync] Budget update from queue requires full data');
          return false;

        case OfflineQueueService.ACTION_DELETE_BUDGET:
          await _budgetService?.deleteBudget(payload['budget_id'] as int);
          return true;

        // User Profile - TODO: Implémenter quand UserService sera disponible
        case OfflineQueueService.ACTION_UPDATE_PROFILE:
          print('⚠️ [OfflineSync] ACTION_UPDATE_PROFILE not yet implemented');
          return true; // Ignorer pour l'instant

        default:
          print('⚠️ [OfflineSync] Type d\'action inconnu: $type');
          return false;
      }
    } catch (e) {
      print('❌ [OfflineSync] Erreur sync $type: $e');
      return false;
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

      print('📝 [OfflineSync] Action mise en queue: $type');

      // Tenter la synchronisation immédiatement si connecté
      if (_connectivityService.isConnected && !_isSyncing) {
        await syncPendingActions();
      }
    } catch (e) {
      print('❌ [OfflineSync] Erreur mise en queue: $e');
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
    print('🗑️ [OfflineSync] Actions en attente effacées');
  }

  /// Force la synchronisation manuelle
  Future<void> forceSyncNow() async {
    print('🔄 [OfflineSync] Synchronisation forcée...');
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
    print('👋 [OfflineSync] Service de synchronisation fermé');
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
