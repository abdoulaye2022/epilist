// models/shared_list.dart - VERSION COMPATIBLE AVEC USER EXISTANT
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/models/user.dart';

enum SharePermission { readOnly, edit, admin }

class SharedList {
  final int id;
  final int listId;
  final int ownerId;
  final int sharedWithUserId;
  final SharePermission permission;
  final DateTime sharedAt;
  final bool isActive;
  final ShoppingList? shoppingList;
  final User? owner;
  final User? sharedWithUser;
  final String? shareToken; // Token pour le partage via lien

  const SharedList({
    required this.id,
    required this.listId,
    required this.ownerId,
    required this.sharedWithUserId,
    required this.permission,
    required this.sharedAt,
    required this.isActive,
    this.shoppingList,
    this.owner,
    this.sharedWithUser,
    this.shareToken,
  });

  factory SharedList.fromJson(Map<String, dynamic> json) {
    return SharedList(
      id: json['id'] as int,
      listId: json['list_id'] as int,
      ownerId: json['owner_id'] as int,
      sharedWithUserId: json['shared_with_user_id'] as int,
      permission: SharePermission.values.firstWhere(
        (e) => e.name == json['permission'],
        orElse: () => SharePermission.readOnly,
      ),
      sharedAt: DateTime.parse(json['shared_at']),
      isActive: json['is_active'] ?? true,
      shoppingList:
          json['shopping_list'] != null
              ? ShoppingList.fromJson(json['shopping_list'])
              : null,
      // ADAPTATION: Utilise fromMap au lieu de fromJson pour compatibilité
      owner: json['owner'] != null ? User.fromMap(json['owner']) : null,
      sharedWithUser:
          json['shared_with_user'] != null
              ? User.fromMap(json['shared_with_user'])
              : null,
      shareToken: json['share_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'list_id': listId,
      'owner_id': ownerId,
      'shared_with_user_id': sharedWithUserId,
      'permission': permission.name,
      'shared_at': sharedAt.toIso8601String(),
      'is_active': isActive,
      'share_token': shareToken,
    };
  }

  bool get canEdit =>
      permission == SharePermission.edit || permission == SharePermission.admin;
  bool get canDelete => permission == SharePermission.admin;
  bool get isOwner => permission == SharePermission.admin;

  SharedList copyWith({
    int? id,
    int? listId,
    int? ownerId,
    int? sharedWithUserId,
    SharePermission? permission,
    DateTime? sharedAt,
    bool? isActive,
    ShoppingList? shoppingList,
    User? owner,
    User? sharedWithUser,
    String? shareToken,
  }) {
    return SharedList(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      ownerId: ownerId ?? this.ownerId,
      sharedWithUserId: sharedWithUserId ?? this.sharedWithUserId,
      permission: permission ?? this.permission,
      sharedAt: sharedAt ?? this.sharedAt,
      isActive: isActive ?? this.isActive,
      shoppingList: shoppingList ?? this.shoppingList,
      owner: owner ?? this.owner,
      sharedWithUser: sharedWithUser ?? this.sharedWithUser,
      shareToken: shareToken ?? this.shareToken,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SharedList &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          listId == other.listId &&
          ownerId == other.ownerId &&
          sharedWithUserId == other.sharedWithUserId &&
          permission == other.permission &&
          sharedAt == other.sharedAt &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^
      listId.hashCode ^
      ownerId.hashCode ^
      sharedWithUserId.hashCode ^
      permission.hashCode ^
      sharedAt.hashCode ^
      isActive.hashCode;

  @override
  String toString() {
    return 'SharedList{id: $id, listId: $listId, permission: $permission, sharedWithUser: ${sharedWithUser?.name}}';
  }
}

// models/share_invitation.dart
class ShareInvitation {
  final String token;
  final int listId;
  final String listName;
  final String ownerName;
  final String ownerEmail;
  final SharePermission permission;
  final DateTime expiresAt;
  final bool isExpired;
  final ShoppingList? shoppingList;

  const ShareInvitation({
    required this.token,
    required this.listId,
    required this.listName,
    required this.ownerName,
    required this.ownerEmail,
    required this.permission,
    required this.expiresAt,
    required this.isExpired,
    this.shoppingList,
  });

  factory ShareInvitation.fromJson(Map<String, dynamic> json) {
    return ShareInvitation(
      token: json['token'],
      listId: json['list_id'],
      listName: json['list_name'],
      ownerName: json['owner_name'],
      ownerEmail: json['owner_email'],
      permission: SharePermission.values.firstWhere(
        (e) => e.name == json['permission'],
        orElse: () => SharePermission.readOnly,
      ),
      expiresAt: DateTime.parse(json['expires_at']),
      isExpired: json['is_expired'] ?? false,
      shoppingList:
          json['shopping_list'] != null
              ? ShoppingList.fromJson(json['shopping_list'])
              : null,
    );
  }

  bool get canEdit =>
      permission == SharePermission.edit || permission == SharePermission.admin;

  String get permissionDisplayName {
    switch (permission) {
      case SharePermission.readOnly:
        return 'Lecture seule';
      case SharePermission.edit:
        return 'Modification';
      case SharePermission.admin:
        return 'Administration';
    }
  }
}
