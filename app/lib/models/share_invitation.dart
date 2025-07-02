// models/share_invitation.dart - VERSION MISE À JOUR POUR VOTRE API
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/models/shared_list.dart';

class ShareInvitation {
  final String token;
  final String listName; // ✅ Pas de listId dans votre API
  final String ownerName;
  final String ownerEmail;
  final SharePermission permission;
  final String permissionDisplayName; // ✅ Ajouté pour votre API
  final DateTime expiresAt;
  final bool isExpired;
  final DateTime createdAt; // ✅ Ajouté pour votre API
  final ShoppingListSummary?
  shoppingList; // ✅ Résumé au lieu de l'objet complet
  final ShareUrls? shareUrls; // ✅ Ajouté pour votre API

  const ShareInvitation({
    required this.token,
    required this.listName,
    required this.ownerName,
    required this.ownerEmail,
    required this.permission,
    required this.permissionDisplayName,
    required this.expiresAt,
    required this.isExpired,
    required this.createdAt,
    this.shoppingList,
    this.shareUrls,
  });

  // ✅ Factory constructor adapté à votre réponse API
  factory ShareInvitation.fromJson(Map<String, dynamic> json) {
    return ShareInvitation(
      token: json['token'] as String,
      listName: json['list_name'] as String,
      ownerName: json['owner_name'] as String,
      ownerEmail: json['owner_email'] as String,
      permission: _parsePermission(json['permission'] as String),
      permissionDisplayName: json['permission_display_name'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      isExpired: json['is_expired'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      shoppingList:
          json['shopping_list'] != null
              ? ShoppingListSummary.fromJson(
                json['shopping_list'] as Map<String, dynamic>,
              )
              : null,
      shareUrls:
          json['share_urls'] != null
              ? ShareUrls.fromJson(json['share_urls'] as Map<String, dynamic>)
              : null,
    );
  }

  static SharePermission _parsePermission(String permission) {
    switch (permission.toLowerCase()) {
      case 'readonly':
      case 'read_only':
        return SharePermission.readOnly;
      case 'edit':
        return SharePermission.edit;
      case 'admin':
        return SharePermission.admin;
      default:
        return SharePermission.readOnly;
    }
  }

  bool get canEdit =>
      permission == SharePermission.edit || permission == SharePermission.admin;

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'list_name': listName,
      'owner_name': ownerName,
      'owner_email': ownerEmail,
      'permission': permission.name,
      'permission_display_name': permissionDisplayName,
      'expires_at': expiresAt.toIso8601String(),
      'is_expired': isExpired,
      'created_at': createdAt.toIso8601String(),
      'shopping_list': shoppingList?.toJson(),
      'share_urls': shareUrls?.toJson(),
    };
  }
}

// ✅ Classe pour le résumé de la liste (données de votre API)
class ShoppingListSummary {
  final int id;
  final String name;
  final int itemsCount;
  final int purchasedItemsCount;
  final double totalPrice;
  final DateTime createdAt;

  const ShoppingListSummary({
    required this.id,
    required this.name,
    required this.itemsCount,
    required this.purchasedItemsCount,
    required this.totalPrice,
    required this.createdAt,
  });

  factory ShoppingListSummary.fromJson(Map<String, dynamic> json) {
    return ShoppingListSummary(
      id: json['id'] as int,
      name: json['name'] as String,
      itemsCount: json['items_count'] as int,
      purchasedItemsCount: json['purchased_items_count'] as int,
      totalPrice: (json['total_price'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'items_count': itemsCount,
      'purchased_items_count': purchasedItemsCount,
      'total_price': totalPrice,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// ✅ Classe pour les URLs de partage (données de votre API)
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
}
