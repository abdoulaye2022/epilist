// lib/models/email_preference.dart

class EmailPreference {
  final int? id;
  final int userId;

  // Transactional emails
  final bool emailVerification;
  final bool passwordChangeRequest;
  final bool passwordChanged;

  // List notifications
  final bool listSharedWithMe;
  final bool listItemAdded;
  final bool listItemChecked;
  final bool listCompleted;

  // Budget notifications
  final bool budgetAlert;
  final bool budgetSummary;

  // Marketing emails
  final bool marketingEmails;
  final bool productUpdates;
  final bool tipsAndTricks;

  // Notification frequency
  final String notificationFrequency; // 'realtime', 'daily', 'weekly'

  final DateTime? createdAt;
  final DateTime? updatedAt;

  EmailPreference({
    this.id,
    required this.userId,
    this.emailVerification = true,
    this.passwordChangeRequest = true,
    this.passwordChanged = true,
    this.listSharedWithMe = true,
    this.listItemAdded = true,
    this.listItemChecked = false,
    this.listCompleted = true,
    this.budgetAlert = true,
    this.budgetSummary = true,
    this.marketingEmails = true,
    this.productUpdates = true,
    this.tipsAndTricks = true,
    this.notificationFrequency = 'realtime',
    this.createdAt,
    this.updatedAt,
  });

  factory EmailPreference.fromJson(Map<String, dynamic> json) {
    return EmailPreference(
      id: json['id'] as int?,
      userId: json['user_id'] as int,
      emailVerification: json['email_verification'] == 1 || json['email_verification'] == true,
      passwordChangeRequest: json['password_change_request'] == 1 || json['password_change_request'] == true,
      passwordChanged: json['password_changed'] == 1 || json['password_changed'] == true,
      listSharedWithMe: json['list_shared_with_me'] == 1 || json['list_shared_with_me'] == true,
      listItemAdded: json['list_item_added'] == 1 || json['list_item_added'] == true,
      listItemChecked: json['list_item_checked'] == 1 || json['list_item_checked'] == true,
      listCompleted: json['list_completed'] == 1 || json['list_completed'] == true,
      budgetAlert: json['budget_alert'] == 1 || json['budget_alert'] == true,
      budgetSummary: json['budget_summary'] == 1 || json['budget_summary'] == true,
      marketingEmails: json['marketing_emails'] == 1 || json['marketing_emails'] == true,
      productUpdates: json['product_updates'] == 1 || json['product_updates'] == true,
      tipsAndTricks: json['tips_and_tricks'] == 1 || json['tips_and_tricks'] == true,
      notificationFrequency: json['notification_frequency'] as String? ?? 'realtime',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email_verification': emailVerification,
      'password_change_request': passwordChangeRequest,
      'password_changed': passwordChanged,
      'list_shared_with_me': listSharedWithMe,
      'list_item_added': listItemAdded,
      'list_item_checked': listItemChecked,
      'list_completed': listCompleted,
      'budget_alert': budgetAlert,
      'budget_summary': budgetSummary,
      'marketing_emails': marketingEmails,
      'product_updates': productUpdates,
      'tips_and_tricks': tipsAndTricks,
      'notification_frequency': notificationFrequency,
    };
  }

  EmailPreference copyWith({
    int? id,
    int? userId,
    bool? emailVerification,
    bool? passwordChangeRequest,
    bool? passwordChanged,
    bool? listSharedWithMe,
    bool? listItemAdded,
    bool? listItemChecked,
    bool? listCompleted,
    bool? budgetAlert,
    bool? budgetSummary,
    bool? marketingEmails,
    bool? productUpdates,
    bool? tipsAndTricks,
    String? notificationFrequency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmailPreference(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      emailVerification: emailVerification ?? this.emailVerification,
      passwordChangeRequest: passwordChangeRequest ?? this.passwordChangeRequest,
      passwordChanged: passwordChanged ?? this.passwordChanged,
      listSharedWithMe: listSharedWithMe ?? this.listSharedWithMe,
      listItemAdded: listItemAdded ?? this.listItemAdded,
      listItemChecked: listItemChecked ?? this.listItemChecked,
      listCompleted: listCompleted ?? this.listCompleted,
      budgetAlert: budgetAlert ?? this.budgetAlert,
      budgetSummary: budgetSummary ?? this.budgetSummary,
      marketingEmails: marketingEmails ?? this.marketingEmails,
      productUpdates: productUpdates ?? this.productUpdates,
      tipsAndTricks: tipsAndTricks ?? this.tipsAndTricks,
      notificationFrequency: notificationFrequency ?? this.notificationFrequency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
