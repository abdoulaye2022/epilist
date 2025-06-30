// blocs/shared_list/shared_list_state.dart
import 'package:equatable/equatable.dart';
import 'package:epilist/models/shared_list.dart';
import 'package:epilist/models/shopping_list.dart';

abstract class SharedListState extends Equatable {
  const SharedListState();

  @override
  List<Object?> get props => [];
}

class SharedListInitial extends SharedListState {}

class SharedListLoading extends SharedListState {}

// États pour les listes partagées avec l'utilisateur
class SharedListsLoaded extends SharedListState {
  final List<SharedList> sharedLists;

  const SharedListsLoaded(this.sharedLists);

  @override
  List<Object> get props => [sharedLists];
}

// États pour les partages d'une liste spécifique
class ListSharesLoaded extends SharedListState {
  final int listId;
  final List<SharedList> shares;

  const ListSharesLoaded({required this.listId, required this.shares});

  @override
  List<Object> get props => [listId, shares];
}

// États pour les invitations
class ShareInvitationLoaded extends SharedListState {
  final ShareInvitation invitation;

  const ShareInvitationLoaded(this.invitation);

  @override
  List<Object> get props => [invitation];
}

class ShareInvitationAccepted extends SharedListState {
  final ShoppingList shoppingList;

  const ShareInvitationAccepted(this.shoppingList);

  @override
  List<Object> get props => [shoppingList];
}

class ShareInvitationDeclined extends SharedListState {}

// États pour les opérations de partage
class ShareLinkCreated extends SharedListState {
  final String shareUrl;

  const ShareLinkCreated(this.shareUrl);

  @override
  List<Object> get props => [shareUrl];
}

class ShareOperationSuccess extends SharedListState {
  final String message;

  const ShareOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class SharedListError extends SharedListState {
  final String message;

  const SharedListError(this.message);

  @override
  List<Object> get props => [message];
}
