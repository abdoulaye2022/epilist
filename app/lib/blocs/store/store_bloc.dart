// blocs/store/store_bloc.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/models/store.dart';
import 'package:epilist/services/store_service.dart';
import 'store_event.dart';
import 'store_state.dart';

class StoreBloc extends Bloc<StoreEvent, StoreState> {
  final StoreService storeService;

  StoreBloc({required this.storeService}) : super(StoreInitial()) {
    on<LoadStores>(_onLoadStores);
    on<CreateStore>(_onCreateStore);
    on<RenameStore>(_onRenameStore);
    on<DeleteStore>(_onDeleteStore);
    on<SaveCategoryOrder>(_onSaveCategoryOrder);
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
