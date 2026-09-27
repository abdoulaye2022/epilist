// blocs/store/store_bloc.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/models/store.dart';
import 'package:epilist/services/connectivity_service.dart';
import 'package:epilist/services/offline_queue_service.dart';
import 'package:epilist/services/offline_storage_service.dart';
import 'package:epilist/services/store_service.dart';
import 'store_event.dart';
import 'store_state.dart';

class StoreBloc extends Bloc<StoreEvent, StoreState> {
  final StoreService storeService;
  final ConnectivityService _connectivity = ConnectivityService();

  bool get _offline => !_connectivity.isConnected;

  /// Persiste l'état local dans le cache (mode hors ligne).
  Future<void> _cacheStores(List<Store> stores) async {
    await OfflineStorageService.saveStores(
      stores.map((s) => s.toJson()).toList(),
    );
  }

  StoreBloc({required this.storeService}) : super(StoreInitial()) {
    on<LoadStores>(_onLoadStores);
    on<CreateStore>(_onCreateStore);
    on<RenameStore>(_onRenameStore);
    on<DeleteStore>(_onDeleteStore);
    on<SaveCategoryOrder>(_onSaveCategoryOrder);
    on<MergeStores>(_onMergeStores);
  }

  Future<void> _onMergeStores(MergeStores event, Emitter<StoreState> emit) async {
    final previous = _currentStores;
    if (_offline) {
      emit(StoreError('Fusion indisponible hors ligne', stores: previous));
      emit(StoreLoaded(previous));
      return;
    }
    try {
      final target =
          await storeService.mergeStores(event.sourceStoreId, event.targetStoreId);
      final stores = previous
          .where((s) => s.id != event.sourceStoreId)
          .map((s) => s.id == target.id ? target : s)
          .toList();
      await _cacheStores(stores);
      emit(StoreOperationSuccess(stores, 'stores_merged'));
      emit(StoreLoaded(stores));
    } catch (e) {
      debugPrint('❌ [StoreBloc] Erreur fusion magasins: $e');
      emit(StoreError('Impossible de fusionner les magasins', stores: previous));
      emit(StoreLoaded(previous));
    }
  }

  List<Store> get _currentStores {
    final s = state;
    if (s is StoreLoaded) return s.stores;
    if (s is StoreOperationSuccess) return s.stores;
    if (s is StoreError) return s.stores;
    return const [];
  }

  Future<void> _onLoadStores(LoadStores event, Emitter<StoreState> emit) async {
    emit(StoreLoading());
    try {
      final stores = await storeService.getStores();
      emit(StoreLoaded(stores));
    } catch (e) {
      debugPrint('❌ [StoreBloc] Erreur chargement magasins: $e');
      emit(StoreError('Impossible de charger les magasins',
          stores: _currentStores));
    }
  }

  Future<void> _onCreateStore(CreateStore event, Emitter<StoreState> emit) async {
    final previous = _currentStores;
    if (_offline) {
      // Id temporaire négatif : l'édition de l'ordre est bloquée par l'UI
      // tant que la synchro n'a pas créé le vrai magasin côté serveur.
      final temp = Store(
        id: -DateTime.now().millisecondsSinceEpoch,
        name: event.name.trim(),
        slug: event.name.trim().toLowerCase(),
      );
      final stores = [...previous, temp]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      await OfflineQueueService.enqueueAction(
        actionType: OfflineQueueService.ACTION_CREATE_STORE,
        payload: {'name': temp.name},
      );
      await _cacheStores(stores);
      emit(StoreOperationSuccess(stores, 'store_created'));
      emit(StoreLoaded(stores));
      return;
    }
    try {
      final created = await storeService.createStore(event.name.trim());
      final stores = [...previous.where((s) => s.id != created.id), created]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      emit(StoreOperationSuccess(stores, 'store_created'));
      emit(StoreLoaded(stores));
    } catch (e) {
      debugPrint('❌ [StoreBloc] Erreur création magasin: $e');
      emit(StoreError('Impossible de créer le magasin', stores: previous));
      emit(StoreLoaded(previous));
    }
  }

  Future<void> _onRenameStore(RenameStore event, Emitter<StoreState> emit) async {
    final previous = _currentStores;
    if (_offline) {
      final stores = previous
          .map((s) => s.id == event.storeId ? s.copyWith(name: event.name.trim()) : s)
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (event.storeId > 0) {
        await OfflineQueueService.enqueueAction(
          actionType: OfflineQueueService.ACTION_RENAME_STORE,
          payload: {'store_id': event.storeId, 'name': event.name.trim()},
        );
      }
      await _cacheStores(stores);
      emit(StoreOperationSuccess(stores, 'store_renamed'));
      emit(StoreLoaded(stores));
      return;
    }
    try {
      final renamed = await storeService.renameStore(event.storeId, event.name.trim());
      final stores = previous.map((s) => s.id == renamed.id ? renamed : s).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      emit(StoreOperationSuccess(stores, 'store_renamed'));
      emit(StoreLoaded(stores));
    } catch (e) {
      debugPrint('❌ [StoreBloc] Erreur renommage magasin: $e');
      emit(StoreError('Impossible de renommer le magasin', stores: previous));
      emit(StoreLoaded(previous));
    }
  }

  Future<void> _onDeleteStore(DeleteStore event, Emitter<StoreState> emit) async {
    final previous = _currentStores;
    if (_offline) {
      final stores = previous.where((s) => s.id != event.storeId).toList();
      if (event.storeId > 0) {
        await OfflineQueueService.enqueueAction(
          actionType: OfflineQueueService.ACTION_DELETE_STORE,
          payload: {'store_id': event.storeId},
        );
      }
      await _cacheStores(stores);
      emit(StoreOperationSuccess(stores, 'store_deleted'));
      emit(StoreLoaded(stores));
      return;
    }
    try {
      await storeService.deleteStore(event.storeId);
      final stores = previous.where((s) => s.id != event.storeId).toList();
      emit(StoreOperationSuccess(stores, 'store_deleted'));
      emit(StoreLoaded(stores));
    } catch (e) {
      debugPrint('❌ [StoreBloc] Erreur suppression magasin: $e');
      emit(StoreError('Impossible de supprimer le magasin', stores: previous));
      emit(StoreLoaded(previous));
    }
  }

  Future<void> _onSaveCategoryOrder(
    SaveCategoryOrder event,
    Emitter<StoreState> emit,
  ) async {
    final previous = _currentStores;
    // Optimiste : appliquer localement tout de suite, l'éditeur reste fluide.
    final optimistic = previous
        .map((s) => s.id == event.storeId
            ? s.copyWith(categoryOrder: event.categoryKinds)
            : s)
        .toList();
    emit(StoreLoaded(optimistic));
    if (_offline) {
      if (event.storeId > 0) {
        await OfflineQueueService.enqueueAction(
          actionType: OfflineQueueService.ACTION_SET_STORE_ORDER,
          payload: {
            'store_id': event.storeId,
            'category_kinds': event.categoryKinds,
          },
        );
      }
      await _cacheStores(optimistic);
      emit(StoreOperationSuccess(optimistic, 'order_saved'));
      emit(StoreLoaded(optimistic));
      return;
    }
    try {
      await storeService.setCategoryOrder(event.storeId, event.categoryKinds);
      emit(StoreOperationSuccess(optimistic, 'order_saved'));
      emit(StoreLoaded(optimistic));
    } catch (e) {
      debugPrint('❌ [StoreBloc] Erreur sauvegarde ordre: $e');
      emit(StoreError('Impossible d\'enregistrer l\'ordre des rayons',
          stores: previous));
      emit(StoreLoaded(previous));
    }
  }
}
