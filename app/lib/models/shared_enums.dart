// models/shared_enums.dart - ENUMS CENTRALISÉS POUR ÉVITER LA DUPLICATION
enum SharePermission { readOnly, edit, admin }

enum InvitationStatus { pending, accepted, declined, expired }

// Extensions utilitaires pour SharePermission
extension SharePermissionExtension on SharePermission {
  String get displayName {
    switch (this) {
      case SharePermission.readOnly:
        return 'Lecture seule';
      case SharePermission.edit:
        return 'Modification';
      case SharePermission.admin:
        return 'Administration';
    }
  }

  bool get canEdit =>
      this == SharePermission.edit || this == SharePermission.admin;
  bool get canDelete => this == SharePermission.admin;
  bool get isAdmin => this == SharePermission.admin;
}

// Extensions utilitaires pour InvitationStatus
extension InvitationStatusExtension on InvitationStatus {
  String get displayName {
    switch (this) {
      case InvitationStatus.pending:
        return 'En attente';
      case InvitationStatus.accepted:
        return 'Acceptée';
      case InvitationStatus.declined:
        return 'Refusée';
      case InvitationStatus.expired:
        return 'Expirée';
    }
  }

  bool get isPending => this == InvitationStatus.pending;
  bool get isAccepted => this == InvitationStatus.accepted;
  bool get isDeclined => this == InvitationStatus.declined;
  bool get isExpired => this == InvitationStatus.expired;
}
