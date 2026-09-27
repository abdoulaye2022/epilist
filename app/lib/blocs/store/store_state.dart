// blocs/store/store_state.dart
import 'package:equatable/equatable.dart';
import 'package:epilist/models/store.dart';

abstract class StoreState extends Equatable {
  const StoreState();

  @override
  List<Object?> get props => [];
}

class StoreInitial extends StoreState {}

class StoreLoading extends StoreState {}

class StoreLoaded extends StoreState {
  final List<Store> stores;
  const StoreLoaded(this.stores);

  @override
  List<Object?> get props => [stores];
}

class StoreOperationSuccess extends StoreState {
  final List<Store> stores;
  final String message;
  const StoreOperationSuccess(this.stores, this.message);

  @override
  List<Object?> get props => [stores, message];
}

class StoreError extends StoreState {
  final String message;

  /// Derniers magasins connus, pour ne pas vider l'écran sur une erreur.
  final List<Store> stores;
  const StoreError(this.message, {this.stores = const []});

  @override
  List<Object?> get props => [message, stores];
}
