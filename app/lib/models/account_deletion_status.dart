// models/account_deletion_status.dart
class AccountDeletionStatus {
  final bool isActive;
  final bool isDeletionRequested;
  final DateTime? deletionRequestedAt;
  final String? deletionReason;
  final bool canCancelDeletion;
  final DateTime? deletionEffectiveDate;
  final int? daysRemaining;

  AccountDeletionStatus({
    required this.isActive,
    required this.isDeletionRequested,
    this.deletionRequestedAt,
    this.deletionReason,
    required this.canCancelDeletion,
    this.deletionEffectiveDate,
    this.daysRemaining,
  });

  factory AccountDeletionStatus.fromJson(Map<String, dynamic> json) {
    return AccountDeletionStatus(
      isActive: json['is_active'] ?? true,
      isDeletionRequested: json['is_deletion_requested'] ?? false,
      deletionRequestedAt:
          json['deletion_requested_at'] != null
              ? DateTime.parse(json['deletion_requested_at'])
              : null,
      deletionReason: json['deletion_reason'],
      canCancelDeletion: json['can_cancel_deletion'] ?? false,
      deletionEffectiveDate:
          json['deletion_effective_date'] != null
              ? DateTime.parse(json['deletion_effective_date'])
              : null,
      daysRemaining: json['days_remaining'],
    );
  }

  bool get isScheduledForDeletion =>
      isDeletionRequested && deletionEffectiveDate != null;

  String get formattedDeletionDate {
    if (deletionEffectiveDate == null) return '';
    return deletionEffectiveDate!.toLocal().toString().split(' ')[0];
  }

  Map<String, dynamic> toJson() {
    return {
      'is_active': isActive,
      'is_deletion_requested': isDeletionRequested,
      'deletion_requested_at': deletionRequestedAt?.toIso8601String(),
      'deletion_reason': deletionReason,
      'can_cancel_deletion': canCancelDeletion,
      'deletion_effective_date': deletionEffectiveDate?.toIso8601String(),
      'days_remaining': daysRemaining,
    };
  }

  @override
  String toString() {
    return 'AccountDeletionStatus('
        'isActive: $isActive, '
        'isDeletionRequested: $isDeletionRequested, '
        'daysRemaining: $daysRemaining'
        ')';
  }
}
