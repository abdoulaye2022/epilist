// blocs/list_item/list_item_state.dart
part of 'list_item_bloc.dart';

abstract class ListItemState extends Equatable {
  const ListItemState();

  @override
  List<Object> get props => [];
}

class ListItemInitial extends ListItemState {}

class ListItemLoading extends ListItemState {}

class ListItemLoaded extends ListItemState {
  final List<ListItem> items;

  const ListItemLoaded(this.items);

  @override
  List<Object> get props => [items];
}

class ListItemOperationSuccess extends ListItemState {
  final String message;

  const ListItemOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class ListItemError extends ListItemState {
  final String message;

  const ListItemError(this.message);

  @override
  List<Object> get props => [message];
}
