// models/budget.dart
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/models/currency.dart';
import 'package:equatable/equatable.dart';

enum BudgetPeriodType { weekly, monthly, yearly, custom }

enum BudgetStatus { ok, warning, exceeded }

class Budget extends Equatable {
  final int id;
  final int userId;
  final int? listId;
  final String? listName;
  final String name;
  final double budgetAmount;
  final String formattedBudgetAmount;
  final BudgetPeriodType periodType;
  final DateTime startDate;
  final DateTime endDate;
  final int alertThreshold;
  final bool isActive;

  // Champs calculés
  final double spentAmount;
  final String formattedSpentAmount;
  final double remainingAmount;
  final String formattedRemainingAmount;
  final double spentPercentage;
  final int daysRemaining;
  final BudgetStatus status;
  final bool isExceeded;
  final bool isNearLimit;
  final String? alertMessage;
  final bool shouldShowAlert;

  final DateTime createdAt;
  final DateTime updatedAt;

  // Devise associée
  final Currency? currency;

  const Budget({
    required this.id,
    required this.userId,
    this.listId,
    this.listName,
    required this.name,
    required this.budgetAmount,
    required this.formattedBudgetAmount,
    required this.periodType,
    required this.startDate,
    required this.endDate,
    required this.alertThreshold,
    required this.isActive,
    required this.spentAmount,
    required this.formattedSpentAmount,
    required this.remainingAmount,
    required this.formattedRemainingAmount,
    required this.spentPercentage,
    required this.daysRemaining,
    required this.status,
    required this.isExceeded,
    required this.isNearLimit,
    this.alertMessage,
    required this.shouldShowAlert,
    required this.createdAt,
    required this.updatedAt,
    this.currency,
  });

  // Getters calculés additionnels
  bool get isGeneral => listId == null;
  bool get isListSpecific => listId != null;
  bool get isCurrent =>
      DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);
  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isUpcoming => DateTime.now().isBefore(startDate);

  String get periodDisplayName {
    switch (periodType) {
      case BudgetPeriodType.weekly:
        return 'Hebdomadaire';
      case BudgetPeriodType.monthly:
        return 'Mensuel';
      case BudgetPeriodType.yearly:
        return 'Annuel';
      case BudgetPeriodType.custom:
        return 'Personnalisé';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case BudgetStatus.ok:
        return 'Dans le budget';
      case BudgetStatus.warning:
        return 'Attention';
      case BudgetStatus.exceeded:
        return 'Dépassé';
    }
  }

  String get scopeDisplayName {
    if (isGeneral) return 'Budget général';
    return 'Liste: ${listName ?? 'Inconnue'}';
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    // Parse period type
    BudgetPeriodType periodType;
    switch (json['period_type'] as String) {
      case 'weekly':
        periodType = BudgetPeriodType.weekly;
        break;
      case 'monthly':
        periodType = BudgetPeriodType.monthly;
        break;
      case 'yearly':
        periodType = BudgetPeriodType.yearly;
        break;
      case 'custom':
      default:
        periodType = BudgetPeriodType.custom;
        break;
    }

    // Parse status
    BudgetStatus status;
    switch (json['status'] as String) {
      case 'warning':
        status = BudgetStatus.warning;
        break;
      case 'exceeded':
        status = BudgetStatus.exceeded;
        break;
      case 'ok':
      default:
        status = BudgetStatus.ok;
        break;
    }

    return Budget(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      listId: json['list_id'] as int?,
      listName: json['list_name'] as String?,
      name: json['name'] as String,
      budgetAmount: (json['budget_amount'] as num).toDouble(),
      formattedBudgetAmount: json['formatted_budget_amount'] as String,
      periodType: periodType,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      alertThreshold: json['alert_threshold'] as int,
      isActive: json['is_active'] as bool,
      spentAmount: (json['spent_amount'] as num).toDouble(),
      formattedSpentAmount: json['formatted_spent_amount'] as String,
      remainingAmount: (json['remaining_amount'] as num).toDouble(),
      formattedRemainingAmount: json['formatted_remaining_amount'] as String,
      spentPercentage: (json['spent_percentage'] as num).toDouble(),
      daysRemaining: json['days_remaining'] as int,
      status: status,
      isExceeded: json['is_exceeded'] as bool,
      isNearLimit: json['is_near_limit'] as bool,
      alertMessage: json['alert_message'] as String?,
      shouldShowAlert: json['should_show_alert'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'list_id': listId,
      'list_name': listName,
      'name': name,
      'budget_amount': budgetAmount,
      'formatted_budget_amount': formattedBudgetAmount,
      'period_type': periodType.name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'alert_threshold': alertThreshold,
      'is_active': isActive,
      'spent_amount': spentAmount,
      'formatted_spent_amount': formattedSpentAmount,
      'remaining_amount': remainingAmount,
      'formatted_remaining_amount': formattedRemainingAmount,
      'spent_percentage': spentPercentage,
      'days_remaining': daysRemaining,
      'status': status.name,
      'is_exceeded': isExceeded,
      'is_near_limit': isNearLimit,
      'alert_message': alertMessage,
      'should_show_alert': shouldShowAlert,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Budget copyWith({
    int? id,
    int? userId,
    int? listId,
    String? listName,
    String? name,
    double? budgetAmount,
    String? formattedBudgetAmount,
    BudgetPeriodType? periodType,
    DateTime? startDate,
    DateTime? endDate,
    int? alertThreshold,
    bool? isActive,
    double? spentAmount,
    String? formattedSpentAmount,
    double? remainingAmount,
    String? formattedRemainingAmount,
    double? spentPercentage,
    int? daysRemaining,
    BudgetStatus? status,
    bool? isExceeded,
    bool? isNearLimit,
    String? alertMessage,
    bool? shouldShowAlert,
    DateTime? createdAt,
    DateTime? updatedAt,
    Currency? currency,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      listId: listId ?? this.listId,
      listName: listName ?? this.listName,
      name: name ?? this.name,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      formattedBudgetAmount:
          formattedBudgetAmount ?? this.formattedBudgetAmount,
      periodType: periodType ?? this.periodType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      isActive: isActive ?? this.isActive,
      spentAmount: spentAmount ?? this.spentAmount,
      formattedSpentAmount: formattedSpentAmount ?? this.formattedSpentAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      formattedRemainingAmount:
          formattedRemainingAmount ?? this.formattedRemainingAmount,
      spentPercentage: spentPercentage ?? this.spentPercentage,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      status: status ?? this.status,
      isExceeded: isExceeded ?? this.isExceeded,
      isNearLimit: isNearLimit ?? this.isNearLimit,
      alertMessage: alertMessage ?? this.alertMessage,
      shouldShowAlert: shouldShowAlert ?? this.shouldShowAlert,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currency: currency ?? this.currency,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    listId,
    listName,
    name,
    budgetAmount,
    formattedBudgetAmount,
    periodType,
    startDate,
    endDate,
    alertThreshold,
    isActive,
    spentAmount,
    formattedSpentAmount,
    remainingAmount,
    formattedRemainingAmount,
    spentPercentage,
    daysRemaining,
    status,
    isExceeded,
    isNearLimit,
    alertMessage,
    shouldShowAlert,
    createdAt,
    updatedAt,
    currency,
  ];

  @override
  String toString() {
    return 'Budget{id: $id, name: $name, budgetAmount: $budgetAmount, '
        'spentAmount: $spentAmount, status: $status, isListSpecific: $isListSpecific}';
  }
}

// Modèle pour les statistiques de budget
class BudgetSummary extends Equatable {
  final int totalBudgets;
  final int activeBudgets;
  final int exceedingBudgets;
  final int warningBudgets;
  final double totalBudgeted;
  final double totalSpent;
  final String formattedTotalBudgeted;
  final String formattedTotalSpent;

  const BudgetSummary({
    required this.totalBudgets,
    required this.activeBudgets,
    required this.exceedingBudgets,
    required this.warningBudgets,
    required this.totalBudgeted,
    required this.totalSpent,
    required this.formattedTotalBudgeted,
    required this.formattedTotalSpent,
  });

  factory BudgetSummary.fromJson(Map<String, dynamic> json) {
    return BudgetSummary(
      totalBudgets: json['total_budgets'] as int,
      activeBudgets: json['active_budgets'] as int,
      exceedingBudgets: json['exceeding_budgets'] as int,
      warningBudgets: json['warning_budgets'] as int,
      totalBudgeted: (json['total_budgeted'] as num).toDouble(),
      totalSpent: (json['total_spent'] as num).toDouble(),
      formattedTotalBudgeted: json['formatted_total_budgeted'] as String,
      formattedTotalSpent: json['formatted_total_spent'] as String,
    );
  }

  @override
  List<Object?> get props => [
    totalBudgets,
    activeBudgets,
    exceedingBudgets,
    warningBudgets,
    totalBudgeted,
    totalSpent,
    formattedTotalBudgeted,
    formattedTotalSpent,
  ];
}

// Modèle pour créer/éditer un budget
class CreateBudgetRequest extends Equatable {
  final String name;
  final double budgetAmount;
  final BudgetPeriodType periodType;
  final DateTime startDate;
  final DateTime endDate;
  final int alertThreshold;
  final int? listId;

  const CreateBudgetRequest({
    required this.name,
    required this.budgetAmount,
    required this.periodType,
    required this.startDate,
    required this.endDate,
    this.alertThreshold = 80,
    this.listId,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'budget_amount': budgetAmount,
      'period_type': periodType.name,
      'start_date': startDate.toIso8601String().split('T')[0], // Date seulement
      'end_date': endDate.toIso8601String().split('T')[0], // Date seulement
      'alert_threshold': alertThreshold,
      if (listId != null) 'list_id': listId,
    };
  }

  @override
  List<Object?> get props => [
    name,
    budgetAmount,
    periodType,
    startDate,
    endDate,
    alertThreshold,
    listId,
  ];
}

class UpdateBudgetRequest extends Equatable {
  final String? name;
  final double? budgetAmount;
  final BudgetPeriodType? periodType;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? alertThreshold;
  final bool? isActive;

  const UpdateBudgetRequest({
    this.name,
    this.budgetAmount,
    this.periodType,
    this.startDate,
    this.endDate,
    this.alertThreshold,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (name != null) json['name'] = name;
    if (budgetAmount != null) json['budget_amount'] = budgetAmount;
    if (periodType != null) json['period_type'] = periodType!.name;
    if (startDate != null)
      json['start_date'] = startDate!.toIso8601String().split('T')[0];
    if (endDate != null)
      json['end_date'] = endDate!.toIso8601String().split('T')[0];
    if (alertThreshold != null) json['alert_threshold'] = alertThreshold;
    if (isActive != null) json['is_active'] = isActive;
    return json;
  }

  @override
  List<Object?> get props => [
    name,
    budgetAmount,
    periodType,
    startDate,
    endDate,
    alertThreshold,
    isActive,
  ];
}

// Modèle pour les alertes de budget
class BudgetAlert extends Equatable {
  final int id;
  final String budgetName;
  final String? listName;
  final BudgetStatus status;
  final String message;
  final double spentPercentage;
  final bool isExceeded;
  final int daysRemaining;

  const BudgetAlert({
    required this.id,
    required this.budgetName,
    this.listName,
    required this.status,
    required this.message,
    required this.spentPercentage,
    required this.isExceeded,
    required this.daysRemaining,
  });

  factory BudgetAlert.fromJson(Map<String, dynamic> json) {
    BudgetStatus status;
    switch (json['status'] as String) {
      case 'warning':
        status = BudgetStatus.warning;
        break;
      case 'exceeded':
        status = BudgetStatus.exceeded;
        break;
      case 'ok':
      default:
        status = BudgetStatus.ok;
        break;
    }

    return BudgetAlert(
      id: json['id'] as int,
      budgetName: json['budget_name'] as String,
      listName: json['list_name'] as String?,
      status: status,
      message: json['message'] as String,
      spentPercentage: (json['spent_percentage'] as num).toDouble(),
      isExceeded: json['is_exceeded'] as bool,
      daysRemaining: json['days_remaining'] as int,
    );
  }

  @override
  List<Object?> get props => [
    id,
    budgetName,
    listName,
    status,
    message,
    spentPercentage,
    isExceeded,
    daysRemaining,
  ];
}
