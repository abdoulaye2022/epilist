// models/shopping_list.dart - VERSION COMPATIBLE AVEC NOUVELLE API + FACTURES
import 'package:epilist/models/list_item.dart';
import 'package:epilist/models/shared_enums.dart';
import 'package:epilist/models/shared_list.dart';
import 'package:epilist/models/user.dart';

class ShoppingList {
  final int id;
  final int userId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final List<ListItem> items;

  // CHAMPS POUR LE PARTAGE (NOUVELLE API)
  final bool isShared;
  final bool isOwner;
  final String? sharePermission; // "edit", "read", "admin"
  final String? permissionDisplayName; // "Modification", "Lecture seule", etc.
  final User? sharedBy; // Utilisateur qui a partagé la liste
  final DateTime? sharedAt; // Date de partage
  final bool canEdit;
  final bool canDelete;

  // CHAMPS POUR LES FACTURES
  final int receiptsCount;
  final double receiptsTotal;
  final bool hasReceiptData;

  // ANCIENS CHAMPS POUR COMPATIBILITÉ
  final List<SharedList> sharedWith;
  final User? owner;
  final SharePermission? userPermission;

  ShoppingList({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.items,
    // Nouveaux champs API
    this.isShared = false,
    this.isOwner = true,
    this.sharePermission,
    this.permissionDisplayName,
    this.sharedBy,
    this.sharedAt,
    this.canEdit = true,
    this.canDelete = true,
    // Champs pour les factures
    this.receiptsCount = 0,
    this.receiptsTotal = 0.0,
    this.hasReceiptData = false,
    // Anciens champs avec valeurs par défaut pour compatibilité
    this.sharedWith = const [],
    this.owner,
    this.userPermission,
  });

  // GETTERS CALCULÉS EXISTANTS

  /// Nombre total d'articles dans la liste
  int get itemsCount => items.length;

  /// Nombre d'articles achetés
  int get purchasedItemsCount => items.where((item) => item.isPurchased).length;

  /// Nombre d'articles non achetés
  int get pendingItemsCount => items.where((item) => !item.isPurchased).length;

  /// Prix total de tous les articles (avec gestion des prix null)
  double get totalPrice {
    return items.fold(0.0, (sum, item) {
      final itemPrice = item.price ?? 0.0;
      return sum + (itemPrice * item.quantity);
    });
  }

  /// Prix total des articles achetés
  double get purchasedTotalPrice {
    return items.where((item) => item.isPurchased).fold(0.0, (sum, item) {
      final itemPrice = item.price ?? 0.0;
      return sum + (itemPrice * item.quantity);
    });
  }

  /// Prix total des articles non achetés
  double get pendingTotalPrice {
    return items.where((item) => !item.isPurchased).fold(0.0, (sum, item) {
      final itemPrice = item.price ?? 0.0;
      return sum + (itemPrice * item.quantity);
    });
  }

  /// Progression en pourcentage (0.0 à 1.0)
  double get progress {
    if (items.isEmpty) return 0.0;
    return purchasedItemsCount / itemsCount;
  }

  /// Progression en pourcentage (0 à 100)
  int get progressPercentage => (progress * 100).round();

  /// Vérifie si la liste est terminée (tous les articles achetés)
  bool get isCompleted => items.isNotEmpty && purchasedItemsCount == itemsCount;

  /// Vérifie si la liste est vide
  bool get isEmpty => items.isEmpty;

  /// Vérifie si la liste a des articles
  bool get hasItems => items.isNotEmpty;

  // GETTERS POUR LES FACTURES

  /// Vérifie si la liste a des factures associées
  bool get hasReceipts => receiptsCount > 0;

  /// Obtient le montant moyen par facture
  double get averageReceiptAmount {
    if (receiptsCount == 0) return 0.0;
    return receiptsTotal / receiptsCount;
  }

  /// Compare le total des factures avec le budget estimé des articles
  double get budgetVariance {
    if (receiptsTotal == 0.0 || totalPrice == 0.0) return 0.0;
    return receiptsTotal - totalPrice;
  }

  /// Pourcentage de variance entre factures et budget
  double get budgetVariancePercentage {
    if (totalPrice == 0.0) return 0.0;
    return (budgetVariance / totalPrice) * 100;
  }

  /// Indique si le budget a été dépassé
  bool get isOverBudget => budgetVariance > 0;

  /// Indique si le budget a été respecté
  bool get isUnderBudget => budgetVariance < 0;

  // GETTERS POUR LE PARTAGE (NOUVELLE API)

  /// Nombre de personnes avec qui la liste est partagée (estimation)
  int get sharedWithCount =>
      isShared ? 1 : 0; // API ne fournit pas le nombre exact

  /// Vérifie si l'utilisateur peut partager la liste
  bool get canShare => isOwner || sharePermission == 'admin';

  /// Vérifie si l'utilisateur peut gérer les articles
  bool get canManageItems => canEdit;

  /// Vérifie si l'utilisateur a seulement accès en lecture
  bool get isReadOnly => sharePermission == 'read' || (!canEdit && !canDelete);

  /// Retourne le statut de partage sous forme de texte
  String get sharingStatus {
    if (!isShared) return 'Privée';
    if (isOwner) return 'Partagée';
    return 'Partagée avec vous';
  }

  /// Retourne une description détaillée du statut de partage
  String get detailedSharingStatus {
    if (!isShared) return 'Cette liste est privée';

    if (isOwner) {
      return 'Cette liste est partagée';
    } else {
      final sharedByName = sharedBy?.name ?? 'un utilisateur';
      return 'Partagée par $sharedByName';
    }
  }

  /// Retourne la permission sous forme d'enum pour compatibilité
  SharePermission? get computedUserPermission {
    if (sharePermission == null) return userPermission;

    switch (sharePermission) {
      case 'admin':
        return SharePermission.admin;
      case 'edit':
        return SharePermission.edit;
      case 'read':
        return SharePermission.readOnly;
      default:
        return SharePermission.edit;
    }
  }

  /// Vérifie si la liste a été modifiée récemment par quelqu'un d'autre
  bool get hasRecentCollaborativeActivity {
    if (!isShared) return false;
    final now = DateTime.now();
    final timeDiff = now.difference(updatedAt).inMinutes;
    return timeDiff < 30; // Modifiée dans les 30 dernières minutes
  }

  // MÉTHODES UTILITAIRES POUR LE PARTAGE

  /// Vérifie si un utilisateur spécifique a accès à la liste
  bool hasUserAccess(int userId) {
    if (this.userId == userId || owner?.id == userId) return true;
    return isShared; // Si partagée, on assume que l'utilisateur a accès
  }

  /// Obtient la permission d'un utilisateur spécifique
  SharePermission? getUserPermission(int userId) {
    if (this.userId == userId || owner?.id == userId) {
      return SharePermission.admin;
    }
    return computedUserPermission;
  }

  /// Vérifie si un utilisateur peut effectuer une action spécifique
  bool canUserEdit(int userId) {
    if (this.userId == userId || owner?.id == userId) return true;
    return canEdit;
  }

  bool canUserDelete(int userId) {
    if (this.userId == userId || owner?.id == userId) return true;
    return canDelete;
  }

  bool canUserShare(int userId) {
    if (this.userId == userId || owner?.id == userId) return true;
    return sharePermission == 'admin';
  }

  // MÉTHODES POUR GÉRER LES ARTICLES (AVEC VÉRIFICATION DES PERMISSIONS)

  /// Ajoute un article à la liste (avec vérification des permissions)
  ShoppingList addItem(ListItem item) {
    if (!canManageItems) {
      throw Exception('Permission insuffisante pour ajouter des articles');
    }
    return copyWith(items: [...items, item]);
  }

  /// Supprime un article de la liste (avec vérification des permissions)
  ShoppingList removeItem(int itemId) {
    if (!canManageItems) {
      throw Exception('Permission insuffisante pour supprimer des articles');
    }
    return copyWith(items: items.where((item) => item.id != itemId).toList());
  }

  /// Met à jour un article de la liste (avec vérification des permissions)
  ShoppingList updateItem(ListItem updatedItem) {
    if (!canManageItems) {
      throw Exception('Permission insuffisante pour modifier des articles');
    }
    return copyWith(
      items:
          items
              .map((item) => item.id == updatedItem.id ? updatedItem : item)
              .toList(),
    );
  }

  /// Marque un article comme acheté/non acheté
  ShoppingList toggleItemPurchased(int itemId) {
    if (!canManageItems) {
      throw Exception(
        'Permission insuffisante pour modifier le statut des articles',
      );
    }
    return copyWith(
      items:
          items.map((item) {
            if (item.id == itemId) {
              return item.copyWith(isPurchased: !item.isPurchased);
            }
            return item;
          }).toList(),
    );
  }

  // SÉRIALISATION JSON

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    List<ListItem> itemsList = [];
    if (json['items'] != null) {
      try {
        itemsList =
            (json['items'] as List<dynamic>)
                .map((item) => ListItem.fromJson(item as Map<String, dynamic>))
                .toList();
      } catch (e) {
        print("Error parsing items: $e");
      }
    }

    // Parsing du partageur (shared_by)
    User? sharedBy;
    if (json['shared_by'] != null) {
      try {
        sharedBy = User.fromMap(json['shared_by'] as Map<String, dynamic>);
      } catch (e) {
        print("Error parsing shared_by: $e");
      }
    }

    // Parsing du propriétaire pour compatibilité
    User? owner;
    if (json['owner'] != null) {
      try {
        owner = User.fromMap(json['owner'] as Map<String, dynamic>);
      } catch (e) {
        print("Error parsing owner: $e");
      }
    }

    // Parsing des partages pour compatibilité
    List<SharedList> sharedWithList = [];
    if (json['shared_with'] != null) {
      try {
        sharedWithList =
            (json['shared_with'] as List<dynamic>)
                .map(
                  (share) => SharedList.fromJson(share as Map<String, dynamic>),
                )
                .toList();
      } catch (e) {
        print("Error parsing shared_with: $e");
      }
    }

    // Parsing de la permission utilisateur pour compatibilité
    SharePermission? userPermission;
    if (json['user_permission'] != null) {
      try {
        userPermission = SharePermission.values.firstWhere(
          (e) => e.name == json['user_permission'],
          orElse: () => SharePermission.edit,
        );
      } catch (e) {
        print("Error parsing user_permission: $e");
      }
    }

    return ShoppingList(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt:
          json['deleted_at'] != null
              ? DateTime.parse(json['deleted_at'] as String)
              : null,
      items: itemsList,
      // Nouveaux champs API
      isShared: json['is_shared'] ?? false,
      isOwner: json['is_owner'] ?? true,
      sharePermission: json['share_permission'] as String?,
      permissionDisplayName: json['permission_display_name'] as String?,
      sharedBy: sharedBy,
      sharedAt:
          json['shared_at'] != null
              ? DateTime.parse(json['shared_at'] as String)
              : null,
      canEdit: json['can_edit'] ?? true,
      canDelete: json['can_delete'] ?? true,
      // Champs pour les factures
      receiptsCount: json['receipts_count'] ?? 0,
      receiptsTotal: (json['receipts_total'] as num?)?.toDouble() ?? 0.0,
      hasReceiptData: (json['receipts_count'] ?? 0) > 0,
      // Anciens champs pour compatibilité
      sharedWith: sharedWithList,
      owner: owner,
      userPermission: userPermission,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      // Nouveaux champs API
      'is_shared': isShared,
      'is_owner': isOwner,
      'share_permission': sharePermission,
      'permission_display_name': permissionDisplayName,
      'shared_by': sharedBy?.toJson(),
      'shared_at': sharedAt?.toIso8601String(),
      'can_edit': canEdit,
      'can_delete': canDelete,
      // Champs pour les factures
      'receipts_count': receiptsCount,
      'receipts_total': receiptsTotal,
      'has_receipt_data': hasReceiptData,
      // Anciens champs pour compatibilité
      'shared_with': sharedWith.map((share) => share.toJson()).toList(),
      'owner': owner?.toJson(),
      'user_permission': userPermission?.name,
    };
  }

  ShoppingList copyWith({
    int? id,
    int? userId,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    List<ListItem>? items,
    bool? isShared,
    bool? isOwner,
    String? sharePermission,
    String? permissionDisplayName,
    User? sharedBy,
    DateTime? sharedAt,
    bool? canEdit,
    bool? canDelete,
    int? receiptsCount,
    double? receiptsTotal,
    bool? hasReceiptData,
    List<SharedList>? sharedWith,
    User? owner,
    SharePermission? userPermission,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      items: items ?? this.items,
      isShared: isShared ?? this.isShared,
      isOwner: isOwner ?? this.isOwner,
      sharePermission: sharePermission ?? this.sharePermission,
      permissionDisplayName:
          permissionDisplayName ?? this.permissionDisplayName,
      sharedBy: sharedBy ?? this.sharedBy,
      sharedAt: sharedAt ?? this.sharedAt,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
      receiptsCount: receiptsCount ?? this.receiptsCount,
      receiptsTotal: receiptsTotal ?? this.receiptsTotal,
      hasReceiptData: hasReceiptData ?? this.hasReceiptData,
      sharedWith: sharedWith ?? this.sharedWith,
      owner: owner ?? this.owner,
      userPermission: userPermission ?? this.userPermission,
    );
  }

  @override
  String toString() {
    return 'ShoppingList{id: $id, name: $name, itemsCount: ${items.length}, '
        'isShared: $isShared, isOwner: $isOwner, '
        'sharePermission: $sharePermission, canEdit: $canEdit, canDelete: $canDelete, '
        'receiptsCount: $receiptsCount, receiptsTotal: $receiptsTotal}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingList &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          name == other.name &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt &&
          items == other.items &&
          isShared == other.isShared &&
          isOwner == other.isOwner &&
          sharePermission == other.sharePermission &&
          canEdit == other.canEdit &&
          canDelete == other.canDelete &&
          receiptsCount == other.receiptsCount &&
          receiptsTotal == other.receiptsTotal &&
          hasReceiptData == other.hasReceiptData;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      name.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      deletedAt.hashCode ^
      items.hashCode ^
      isShared.hashCode ^
      isOwner.hashCode ^
      sharePermission.hashCode ^
      canEdit.hashCode ^
      canDelete.hashCode ^
      receiptsCount.hashCode ^
      receiptsTotal.hashCode ^
      hasReceiptData.hashCode;

  // MÉTHODES POUR COMPATIBILITÉ AVEC L'ANCIENNE API DE PARTAGE
  factory ShoppingList.fromShareApiJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'] as int,
      userId: 0,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.now(),
      items: [],
      isShared: true,
      isOwner: false,
      sharePermission: 'edit',
      canEdit: true,
      canDelete: false,
      receiptsCount: json['receipts_count'] ?? 0,
      receiptsTotal: (json['receipts_total'] as num?)?.toDouble() ?? 0.0,
      hasReceiptData: (json['receipts_count'] ?? 0) > 0,
    );
  }

  // GETTERS SUPPLÉMENTAIRES POUR L'API DE PARTAGE (compatibilité)
  int get apiItemsCount => _apiItemsCount ?? itemsCount;
  int get apiPurchasedItemsCount =>
      _apiPurchasedItemsCount ?? purchasedItemsCount;
  double get apiTotalPrice => _apiTotalPrice ?? totalPrice;

  // CHAMPS PRIVÉS POUR STOCKER LES DONNÉES DE L'API
  int? _apiItemsCount;
  int? _apiPurchasedItemsCount;
  double? _apiTotalPrice;

  // MÉTHODE POUR CRÉER UNE INSTANCE AVEC LES DONNÉES DE L'API DE PARTAGE
  ShoppingList withShareApiData({
    required int itemsCount,
    required int purchasedItemsCount,
    required double totalPrice,
  }) {
    final instance = copyWith();
    instance._apiItemsCount = itemsCount;
    instance._apiPurchasedItemsCount = purchasedItemsCount;
    instance._apiTotalPrice = totalPrice;
    return instance;
  }
}
