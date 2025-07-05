// models/share_invitation.dart - VERSION CORRIGÉE
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/models/shared_enums.dart';

class ShareInvitation {
  final String token;
  final int? listId;
  final String listName;
  final String ownerName;
  final String ownerEmail;
  final SharePermission permission;
  final String permissionDisplayName;
  final DateTime expiresAt;
  final bool isExpired;
  final InvitationStatus status;
  final String statusDisplayName;
  final DateTime createdAt;
  final ShoppingList? shoppingList;
  final ShareUrls? shareUrls;

  const ShareInvitation({
    required this.token,
    this.listId,
    required this.listName,
    required this.ownerName,
    required this.ownerEmail,
    required this.permission,
    required this.permissionDisplayName,
    required this.expiresAt,
    required this.isExpired,
    required this.status,
    required this.statusDisplayName,
    required this.createdAt,
    this.shoppingList,
    this.shareUrls,
  });

  factory ShareInvitation.fromJson(Map<String, dynamic> json) {
    // ✅ CORRECTION: Parsing du shopping_list avec la nouvelle méthode
    ShoppingList? shoppingList;
    if (json['shopping_list'] != null) {
      final shoppingListData = json['shopping_list'] as Map<String, dynamic>;

      // Utiliser la factory spécifique pour l'API de partage
      shoppingList = ShoppingList.fromShareApiJson(
        shoppingListData,
      ).withShareApiData(
        itemsCount: shoppingListData['items_count'] as int? ?? 0,
        purchasedItemsCount:
            shoppingListData['purchased_items_count'] as int? ?? 0,
        totalPrice: _parseDouble(shoppingListData['total_price']) ?? 0.0,
      );
    }

    return ShareInvitation(
      token: json['token'] as String,
      listId: _extractListId(json),
      listName: json['list_name'] as String,
      ownerName: json['owner_name'] as String,
      ownerEmail: json['owner_email'] as String? ?? '',
      permission: _parsePermission(json['permission']),
      permissionDisplayName:
          json['permission_display_name'] as String? ??
          _getDefaultPermissionDisplayName(json['permission']),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      isExpired: json['is_expired'] as bool? ?? false,
      status: _parseStatus(json['status']),
      statusDisplayName:
          json['status_display_name'] as String? ??
          _getDefaultStatusDisplayName(json['status']),
      createdAt: DateTime.parse(json['created_at'] as String),
      shoppingList: shoppingList,
      shareUrls:
          json['share_urls'] != null
              ? ShareUrls.fromJson(json['share_urls'] as Map<String, dynamic>)
              : null,
    );
  }

  // ✅ Méthode utilitaire pour parser les doubles
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  // Méthodes utilitaires pour parser les données (inchangées)
  static int? _extractListId(Map<String, dynamic> json) {
    if (json['list_id'] != null) {
      return json['list_id'] as int;
    }

    if (json['shopping_list'] != null && json['shopping_list']['id'] != null) {
      return json['shopping_list']['id'] as int;
    }

    return null;
  }

  static SharePermission _parsePermission(dynamic permission) {
    if (permission == null) return SharePermission.readOnly;

    return SharePermission.values.firstWhere(
      (e) => e.name == permission.toString(),
      orElse: () => SharePermission.readOnly,
    );
  }

  static InvitationStatus _parseStatus(dynamic status) {
    if (status == null) return InvitationStatus.pending;

    return InvitationStatus.values.firstWhere(
      (e) => e.name == status.toString(),
      orElse: () => InvitationStatus.pending,
    );
  }

  static String _getDefaultPermissionDisplayName(dynamic permission) {
    final parsedPermission = _parsePermission(permission);
    return parsedPermission.displayName;
  }

  static String _getDefaultStatusDisplayName(dynamic status) {
    final parsedStatus = _parseStatus(status);
    return parsedStatus.displayName;
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      if (listId != null) 'list_id': listId,
      'list_name': listName,
      'owner_name': ownerName,
      'owner_email': ownerEmail,
      'permission': permission.name,
      'permission_display_name': permissionDisplayName,
      'expires_at': expiresAt.toIso8601String(),
      'is_expired': isExpired,
      'status': status.name,
      'status_display_name': statusDisplayName,
      'created_at': createdAt.toIso8601String(),
      if (shoppingList != null) 'shopping_list': shoppingList!.toJson(),
      if (shareUrls != null) 'share_urls': shareUrls!.toJson(),
    };
  }

  // Utilisation des extensions pour les permissions et statuts
  bool get canEdit => permission.canEdit;
  bool get isPending => status.isPending;
  bool get isAccepted => status.isAccepted;
  bool get isDeclined => status.isDeclined;

  ShareInvitation copyWith({
    String? token,
    int? listId,
    String? listName,
    String? ownerName,
    String? ownerEmail,
    SharePermission? permission,
    String? permissionDisplayName,
    DateTime? expiresAt,
    bool? isExpired,
    InvitationStatus? status,
    String? statusDisplayName,
    DateTime? createdAt,
    ShoppingList? shoppingList,
    ShareUrls? shareUrls,
  }) {
    return ShareInvitation(
      token: token ?? this.token,
      listId: listId ?? this.listId,
      listName: listName ?? this.listName,
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      permission: permission ?? this.permission,
      permissionDisplayName:
          permissionDisplayName ?? this.permissionDisplayName,
      expiresAt: expiresAt ?? this.expiresAt,
      isExpired: isExpired ?? this.isExpired,
      status: status ?? this.status,
      statusDisplayName: statusDisplayName ?? this.statusDisplayName,
      createdAt: createdAt ?? this.createdAt,
      shoppingList: shoppingList ?? this.shoppingList,
      shareUrls: shareUrls ?? this.shareUrls,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShareInvitation &&
          runtimeType == other.runtimeType &&
          token == other.token &&
          listId == other.listId &&
          permission == other.permission &&
          status == other.status;

  @override
  int get hashCode =>
      token.hashCode ^
      (listId?.hashCode ?? 0) ^
      permission.hashCode ^
      status.hashCode;

  @override
  String toString() {
    return 'ShareInvitation{token: $token, listName: $listName, permission: $permission, status: $status}';
  }
}

// Classe pour gérer les URLs de partage (inchangée)
class ShareUrls {
  final String web;
  final String app;
  final String androidStore;
  final String iosStore;

  const ShareUrls({
    required this.web,
    required this.app,
    required this.androidStore,
    required this.iosStore,
  });

  factory ShareUrls.fromJson(Map<String, dynamic> json) {
    return ShareUrls(
      web: json['web'] as String,
      app: json['app'] as String,
      androidStore: json['android_store'] as String,
      iosStore: json['ios_store'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'web': web,
      'app': app,
      'android_store': androidStore,
      'ios_store': iosStore,
    };
  }

  @override
  String toString() {
    return 'ShareUrls{web: $web, app: $app}';
  }
}
