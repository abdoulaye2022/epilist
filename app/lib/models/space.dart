// models/space.dart - Espaces (Phase 1) : le contexte dans lequel les
// achats sont gérés (personnel, foyer, restaurant, organisation).
class Space {
  final int id;
  final String name;
  final String type; // personal | household | restaurant | organization
  final int ownerUserId;
  final String? country;
  final String? region;
  final String? city;
  final String? postalCode;
  final String? currency;
  final int membersCount;
  final String? myRole; // owner | admin | manager | member | viewer

  const Space({
    required this.id,
    required this.name,
    required this.type,
    required this.ownerUserId,
    this.country,
    this.region,
    this.city,
    this.postalCode,
    this.currency,
    this.membersCount = 1,
    this.myRole,
  });

  bool get isPersonal => type == 'personal';
  bool get canManageMembers => myRole == 'owner' || myRole == 'admin';

  factory Space.fromJson(Map<String, dynamic> json) => Space(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? 'personal',
        ownerUserId: json['owner_user_id'] as int? ?? 0,
        country: json['country'] as String?,
        region: json['region'] as String?,
        city: json['city'] as String?,
        postalCode: json['postal_code'] as String?,
        currency: json['currency'] as String?,
        membersCount: json['members_count'] as int? ?? 1,
        myRole: json['my_role'] as String?,
      );
}

class SpaceMemberInfo {
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String? avatarUrl;
  final String role;

  const SpaceMemberInfo({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.avatarUrl,
    required this.role,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory SpaceMemberInfo.fromJson(Map<String, dynamic> json) => SpaceMemberInfo(
        userId: json['user_id'] as int,
        firstName: json['first_name'] as String? ?? '',
        lastName: json['last_name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
        role: json['role'] as String? ?? 'member',
      );
}

class SpaceInvitationInfo {
  final int id;
  final int spaceId;
  final String spaceName;
  final String spaceType;
  final String email;
  final String role;
  final String invitedByName;

  /// Présent uniquement pour le destinataire (GET /space-invitations).
  final String? token;

  const SpaceInvitationInfo({
    required this.id,
    required this.spaceId,
    required this.spaceName,
    required this.spaceType,
    required this.email,
    required this.role,
    required this.invitedByName,
    this.token,
  });

  factory SpaceInvitationInfo.fromJson(Map<String, dynamic> json) =>
      SpaceInvitationInfo(
        id: json['id'] as int,
        spaceId: json['space_id'] as int,
        spaceName: json['space_name'] as String? ?? '',
        spaceType: json['space_type'] as String? ?? 'household',
        email: json['email'] as String? ?? '',
        role: json['role'] as String? ?? 'member',
        invitedByName: json['invited_by_name'] as String? ?? '',
        token: json['token'] as String?,
      );
}

class SupplierInfo {
  final int id;
  final String name;
  final String? contactName;
  final String? phone;
  final String? email;
  final String? notes;
  final bool isActive;

  const SupplierInfo({
    required this.id,
    required this.name,
    this.contactName,
    this.phone,
    this.email,
    this.notes,
    this.isActive = true,
  });

  factory SupplierInfo.fromJson(Map<String, dynamic> json) => SupplierInfo(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        contactName: json['contact_name'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        notes: json['notes'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );
}

class PurchaseRequestInfo {
  final int id;
  final String productName;
  final double? quantity;
  final String? unit;
  final String? note;
  final String status;
  final int requestedBy;
  final String requesterName;
  final String? approverName;
  final String? decisionComment;

  const PurchaseRequestInfo({
    required this.id,
    required this.productName,
    this.quantity,
    this.unit,
    this.note,
    required this.status,
    required this.requestedBy,
    required this.requesterName,
    this.approverName,
    this.decisionComment,
  });

  factory PurchaseRequestInfo.fromJson(Map<String, dynamic> json) =>
      PurchaseRequestInfo(
        id: json['id'] as int,
        productName: json['product_name'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toDouble(),
        unit: json['unit'] as String?,
        note: json['note'] as String?,
        status: json['status'] as String? ?? 'pending',
        requestedBy: json['requested_by'] as int? ?? 0,
        requesterName: json['requester_name'] as String? ?? '',
        approverName: json['approver_name'] as String?,
        decisionComment: json['decision_comment'] as String?,
      );
}
