// models/shared_list.dart - VERSION AVEC ENUMS CENTRALISÉS
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/models/user.dart';
import 'package:epilist/models/shared_enums.dart';

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
  final String? shareToken;

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

  // Utilisation des extensions pour les permissions
  bool get canEdit => permission.canEdit;
  bool get canDelete => permission.canDelete;
  bool get isOwner => permission.isAdmin;

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
