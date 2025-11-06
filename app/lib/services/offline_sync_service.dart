// services/offline_sync_service.dart
import 'dart:async';
import 'package:epilist/services/connectivity_service.dart';
import 'package:epilist/services/offline_cache_service.dart';
import 'package:epilist/services/shopping_list_service.dart';
import 'package:epilist/services/list_item_service.dart';

/// Service de synchronisation pour le mode hors ligne
/// Gère la queue d'actions en attente et la synchronisation avec le serveur
class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  final _connectivityService = ConnectivityService();
  final _cacheService = OfflineCacheService();

  // Services API (seront injectés)
  ShoppingListService? _shoppingListService;
  ListItemService? _listItemService;

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
  }) async {
    if (_isInitialized) return;

    _shoppingListService = shoppingListService;
    _listItemService = listItemService;

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
      final pendingActions = _cacheService.getPendingActions();

      if (pendingActions.isEmpty) {
        print('✅ [OfflineSync] Aucune action en attente');
        _syncStatusController.add(SyncStatus.idle);
        return;
      }

      print('🔄 [OfflineSync] ${pendingActions.length} actions à synchroniser');

      int successCount = 0;
      int failureCount = 0;

      for (var action in pendingActions) {
        try {
          final success = await _syncAction(action);

          if (success) {
            // Supprimer l'action de la queue
            await _cacheService.removePendingAction(action['key'] as String);
            successCount++;
          } else {
            // Incrémenter le compteur de retry
            await _cacheService.incrementActionRetry(action['key'] as String);
            failureCount++;

            // Supprimer l'action si trop de retries
            if ((action['retryCount'] as int? ?? 0) >= 3) {
              print('❌ [OfflineSync] Action abandonnée après 3 échecs: ${action['type']}');
              await _cacheService.removePendingAction(action['key'] as String);
            }
          }
        } catch (e) {
          print('❌ [OfflineSync] Erreur sync action ${action['type']}: $e');
          failureCount++;
        }
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
    final type = action['type'] as String;
    final data = action['data'] as Map<String, dynamic>?;

    print('🔄 [OfflineSync] Synchronisation de: $type');

    try {
      switch (type) {
        case 'create_list':
          if (data == null) return false;
          await _shoppingListService?.createShoppingList(
            data['name'] as String,
          );
          return true;

        case 'update_list':
          if (data == null) return false;
          await _shoppingListService?.updateShoppingList(
            data['id'] as int,
            data['name'] as String,
          );
          return true;

        case 'delete_list':
          if (data == null) return false;
          await _shoppingListService?.deleteShoppingList(data['id'] as int);
          return true;

        case 'create_item':
          if (data == null) return false;
          final result = await _listItemService?.addListItem(
            listId: data['list_id'] as int,
            productName: data['product_name'] as String,
            quantity: data['quantity'] as int? ?? 1,
            price: data['price'] as double?,
            storeName: data['store_name'] as String?,
            categoryId: data['category_id'] as int?,
          );
          // Retourner true si succès ou doublon
          return result != null;

        case 'update_item':
          if (data == null) return false;
          await _listItemService?.updateListItem(
            listId: data['list_id'] as int,
            itemId: data['id'] as int,
            productName: data['product_name'] as String,
            quantity: data['quantity'] as int? ?? 1,
            price: data['price'] as double?,
            storeName: data['store_name'] as String?,
            categoryId: data['category_id'] as int?,
          );
          return true;

        case 'delete_item':
          if (data == null) return false;
          await _listItemService?.deleteListItem(
            listId: data['list_id'] as int,
            itemId: data['id'] as int,
          );
          return true;

        case 'toggle_item':
          if (data == null) return false;
          await _listItemService?.togglePurchasedStatus(
            listId: data['list_id'] as int,
            itemId: data['id'] as int,
            isPurchased: data['is_purchased'] as bool,
          );
          return true;

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
    required Map<String, dynamic> data,
  }) async {
    try {
      await _cacheService.addPendingAction({
        'type': type,
        'data': data,
      });

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
  int getPendingActionsCount() {
    return _cacheService.getPendingActions().length;
  }

  /// Obtient les actions en attente
  List<Map<String, dynamic>> getPendingActions() {
    return _cacheService.getPendingActions();
  }

  /// Efface toutes les actions en attente
  Future<void> clearPendingActions() async {
    await _cacheService.clearPendingActions();
    print('🗑️ [OfflineSync] Actions en attente effacées');
  }

  /// Force la synchronisation manuelle
  Future<void> forceSyncNow() async {
    print('🔄 [OfflineSync] Synchronisation forcée...');
    await syncPendingActions();
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
