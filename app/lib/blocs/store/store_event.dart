// blocs/store/store_event.dart
import 'package:equatable/equatable.dart';

abstract class StoreEvent extends Equatable {
  const StoreEvent();

  @override
  List<Object?> get props => [];
}

class LoadStores extends StoreEvent {
  const LoadStores();
}

class CreateStore extends StoreEvent {
  final String name;
  const CreateStore(this.name);

  @override
  List<Object?> get props => [name];
}

class RenameStore extends StoreEvent {
  final int storeId;
  final String name;
  const RenameStore(this.storeId, this.name);

  @override
  List<Object?> get props => [storeId, name];
}

class DeleteStore extends StoreEvent {
  final int storeId;
  const DeleteStore(this.storeId);

  @override
  List<Object?> get props => [storeId];
}

class SaveCategoryOrder extends StoreEvent {
  final int storeId;
  final List<String> categoryKinds;
  const SaveCategoryOrder(this.storeId, this.categoryKinds);

  @override
  List<Object?> get props => [storeId, categoryKinds];
}
