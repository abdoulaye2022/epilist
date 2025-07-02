// blocs/shared_list/shared_list_event.dart
import 'package:epilist/models/shared_enums.dart';
import 'package:equatable/equatable.dart';
import 'package:epilist/models/shared_list.dart';

abstract class SharedListEvent extends Equatable {
  const SharedListEvent();

  @override
  List<Object?> get props => [];
}

// Événements pour gérer les partages
class LoadSharedLists extends SharedListEvent {}

class LoadListShares extends SharedListEvent {
  final int listId;

  const LoadListShares(this.listId);

  @override
  List<Object> get props => [listId];
}

class CreateShareLink extends SharedListEvent {
  final int listId;
  final SharePermission permission;
  final int? expirationDays;

  const CreateShareLink({
    required this.listId,
    required this.permission,
    this.expirationDays,
  });

  @override
  List<Object?> get props => [listId, permission, expirationDays];
}

class LoadShareInvitation extends SharedListEvent {
  final String shareToken;

  const LoadShareInvitation(this.shareToken);

  @override
  List<Object> get props => [shareToken];
}

class AcceptShareInvitation extends SharedListEvent {
  final String shareToken;

  const AcceptShareInvitation(this.shareToken);

  @override
  List<Object> get props => [shareToken];
}

class DeclineShareInvitation extends SharedListEvent {
  final String shareToken;

  const DeclineShareInvitation(this.shareToken);

  @override
  List<Object> get props => [shareToken];
}

class UpdateSharePermission extends SharedListEvent {
  final int shareId;
  final SharePermission permission;

  const UpdateSharePermission({
    required this.shareId,
    required this.permission,
  });

  @override
  List<Object> get props => [shareId, permission];
}

class RevokeShare extends SharedListEvent {
  final int shareId;

  const RevokeShare(this.shareId);

  @override
  List<Object> get props => [shareId];
}

class LeaveSharedList extends SharedListEvent {
  final int listId;

  const LeaveSharedList(this.listId);

  @override
  List<Object> get props => [listId];
}

class RevokeAllShareLinks extends SharedListEvent {
  final int listId;

  const RevokeAllShareLinks(this.listId);

  @override
  List<Object> get props => [listId];
}
