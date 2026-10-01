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
  final bool listCompleted;

  // Budget notifications
  final bool budgetAlert;
  final bool budgetSummary;

  // Tips and tricks
  final bool tipsAndTricks;

  // Notifications push — INDÉPENDANTES des emails
  final bool pushListActivity;
  final bool pushBudget;
  final bool pushPriceAlert;
  final bool pushReminders;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  EmailPreference({
    this.id,
    required this.userId,
    this.emailVerification = true,
    this.passwordChangeRequest = true,
    this.passwordChanged = true,
    this.listSharedWithMe = true,
    this.listCompleted = true,
    this.budgetAlert = true,
    this.budgetSummary = true,
    this.tipsAndTricks = true,
    this.pushListActivity = true,
    this.pushBudget = true,
    this.pushPriceAlert = true,
    this.pushReminders = true,
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
      listCompleted: json['list_completed'] == 1 || json['list_completed'] == true,
      budgetAlert: json['budget_alert'] == 1 || json['budget_alert'] == true,
      budgetSummary: json['budget_summary'] == 1 || json['budget_summary'] == true,
      tipsAndTricks: json['tips_and_tricks'] == 1 || json['tips_and_tricks'] == true,
      pushListActivity: json['push_list_activity'] != 0 && json['push_list_activity'] != false,
      pushBudget: json['push_budget'] != 0 && json['push_budget'] != false,
      pushPriceAlert: json['push_price_alert'] != 0 && json['push_price_alert'] != false,
      pushReminders: json['push_reminders'] != 0 && json['push_reminders'] != false,
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
      'list_completed': listCompleted,
      'budget_alert': budgetAlert,
      'budget_summary': budgetSummary,
      'tips_and_tricks': tipsAndTricks,
      'push_list_activity': pushListActivity,
      'push_budget': pushBudget,
      'push_price_alert': pushPriceAlert,
      'push_reminders': pushReminders,
    };
  }

  EmailPreference copyWith({
    int? id,
    int? userId,
    bool? emailVerification,
    bool? passwordChangeRequest,
    bool? passwordChanged,
    bool? listSharedWithMe,
    bool? listCompleted,
    bool? budgetAlert,
    bool? budgetSummary,
    bool? tipsAndTricks,
    bool? pushListActivity,
    bool? pushBudget,
    bool? pushPriceAlert,
    bool? pushReminders,
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
      listCompleted: listCompleted ?? this.listCompleted,
      budgetAlert: budgetAlert ?? this.budgetAlert,
      budgetSummary: budgetSummary ?? this.budgetSummary,
      tipsAndTricks: tipsAndTricks ?? this.tipsAndTricks,
      pushListActivity: pushListActivity ?? this.pushListActivity,
      pushBudget: pushBudget ?? this.pushBudget,
      pushPriceAlert: pushPriceAlert ?? this.pushPriceAlert,
      pushReminders: pushReminders ?? this.pushReminders,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
