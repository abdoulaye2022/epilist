// models/shopping_list.dart - VERSION COMPATIBLE AVEC USER EXISTANT
import 'package:epilist/models/list_item.dart';
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

  // NOUVEAUX CHAMPS POUR LE PARTAGE
  final List<SharedList> sharedWith; // Personnes avec qui la liste est partagée
  final User? owner; // Propriétaire de la liste
  final bool isOwner; // Si l'utilisateur actuel est propriétaire
  final SharePermission? userPermission; // Permission de l'utilisateur actuel

  ShoppingList({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.items,
    // Nouveaux paramètres avec valeurs par défaut
    this.sharedWith = const [],
    this.owner,
    this.isOwner = true,
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
      final itemPrice = item.price ?? 0.0; // Gérer les prix null
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

  // NOUVEAUX GETTERS POUR LE PARTAGE

  /// Vérifie si la liste est partagée
  bool get isShared => sharedWith.isNotEmpty;

  /// Nombre de personnes avec qui la liste est partagée
  int get sharedWithCount => sharedWith.length;

  /// Vérifie si l'utilisateur peut éditer la liste
  bool get canEdit {
    if (isOwner) return true;
    return userPermission == SharePermission.edit ||
        userPermission == SharePermission.admin;
  }

  /// Vérifie si l'utilisateur peut supprimer la liste
  bool get canDelete {
    if (isOwner) return true;
    return userPermission == SharePermission.admin;
  }

  /// Vérifie si l'utilisateur peut partager la liste
  bool get canShare {
    if (isOwner) return true;
    return userPermission == SharePermission.admin;
  }

  /// Vérifie si l'utilisateur peut gérer les articles
  bool get canManageItems {
    if (isOwner) return true;
    return userPermission == SharePermission.edit ||
        userPermission == SharePermission.admin;
  }

  /// Vérifie si l'utilisateur a seulement accès en lecture
  bool get isReadOnly => userPermission == SharePermission.readOnly;

  /// Retourne le statut de partage sous forme de texte
  String get sharingStatus {
    if (!isShared) return 'Privée';
    if (sharedWithCount == 1) return 'Partagée avec 1 personne';
    return 'Partagée avec $sharedWithCount personnes';
  }

  /// Retourne une description détaillée du statut de partage
  String get detailedSharingStatus {
    if (!isShared) return 'Cette liste est privée';

    final editCount = editableShares.length;
    final readOnlyCount = readOnlyShares.length;

    if (editCount > 0 && readOnlyCount > 0) {
      return 'Partagée avec $editCount collaborateur${editCount > 1 ? 's' : ''} et $readOnlyCount observateur${readOnlyCount > 1 ? 's' : ''}';
    } else if (editCount > 0) {
      return 'Partagée avec $editCount collaborateur${editCount > 1 ? 's' : ''}';
    } else {
      return 'Partagée avec $readOnlyCount observateur${readOnlyCount > 1 ? 's' : ''}';
    }
  }

  /// Liste des collaborateurs (utilisateurs avec qui la liste est partagée)
  List<User> get collaborators {
    return sharedWith
        .map((share) => share.sharedWithUser)
        .where((user) => user != null)
        .cast<User>()
        .toList();
  }

  /// Liste des partages avec permissions d'édition
  List<SharedList> get editableShares {
    return sharedWith.where((share) => share.canEdit).toList();
  }

  /// Liste des partages en lecture seule
  List<SharedList> get readOnlyShares {
    return sharedWith.where((share) => !share.canEdit).toList();
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
    if (owner?.id == userId || this.userId == userId) return true;
    return sharedWith.any((share) => share.sharedWithUserId == userId);
  }

  /// Obtient la permission d'un utilisateur spécifique
  SharePermission? getUserPermission(int userId) {
    if (owner?.id == userId || this.userId == userId)
      return SharePermission.admin;
    final share =
        sharedWith
            .where((share) => share.sharedWithUserId == userId)
            .firstOrNull;
    return share?.permission;
  }

  /// Vérifie si un utilisateur peut effectuer une action spécifique
  bool canUserEdit(int userId) {
    final permission = getUserPermission(userId);
    return permission == SharePermission.edit ||
        permission == SharePermission.admin;
  }

  bool canUserDelete(int userId) {
    final permission = getUserPermission(userId);
    return permission == SharePermission.admin;
  }

  bool canUserShare(int userId) {
    final permission = getUserPermission(userId);
    return permission == SharePermission.admin;
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

    // Parsing des partages
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

    // Parsing du propriétaire - UTILISE fromMap POUR COMPATIBILITÉ
    User? owner;
    if (json['owner'] != null) {
      try {
        owner = User.fromMap(json['owner'] as Map<String, dynamic>);
      } catch (e) {
        print("Error parsing owner: $e");
      }
    }

    // Parsing de la permission utilisateur
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
      sharedWith: sharedWithList,
      owner: owner,
      isOwner: json['is_owner'] ?? true,
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
      'shared_with': sharedWith.map((share) => share.toJson()).toList(),
      'owner': owner?.toJson(),
      'is_owner': isOwner,
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
    List<SharedList>? sharedWith,
    User? owner,
    bool? isOwner,
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
      sharedWith: sharedWith ?? this.sharedWith,
      owner: owner ?? this.owner,
      isOwner: isOwner ?? this.isOwner,
      userPermission: userPermission ?? this.userPermission,
    );
  }

  @override
  String toString() {
    return 'ShoppingList{id: $id, name: $name, itemsCount: ${items.length}, '
        'isShared: $isShared, sharedWithCount: $sharedWithCount, '
        'isOwner: $isOwner, userPermission: $userPermission}';
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
          sharedWith == other.sharedWith &&
          owner == other.owner &&
          isOwner == other.isOwner &&
          userPermission == other.userPermission;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      name.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      deletedAt.hashCode ^
      items.hashCode ^
      sharedWith.hashCode ^
      owner.hashCode ^
      isOwner.hashCode ^
      userPermission.hashCode;
}
