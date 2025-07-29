// blocs/budget/budget_state.dart
part of 'budget_bloc.dart';

abstract class BudgetState extends Equatable {
  const BudgetState();

  @override
  List<Object?> get props => [];
}

/// État initial
class BudgetInitial extends BudgetState {}

/// Chargement en cours
class BudgetLoading extends BudgetState {}

/// Budgets chargés avec succès
class BudgetLoaded extends BudgetState {
  final List<Budget> budgets;
  final List<Budget> allBudgets; // Pour le filtrage local
  final BudgetSummary? summary;
  final Map<String, dynamic>? dashboardData;
  final List<BudgetAlert>? alerts;

  // Filtres actifs
  final String? activeStatusFilter;
  final String? activePeriodFilter;
  final String? activeScopeFilter;
  final String? activeSortBy;
  final bool? activeSortAscending;

  const BudgetLoaded({
    required this.budgets,
    List<Budget>? allBudgets,
    this.summary,
    this.dashboardData,
    this.alerts,
    this.activeStatusFilter,
    this.activePeriodFilter,
    this.activeScopeFilter,
    this.activeSortBy,
    this.activeSortAscending,
  }) : allBudgets = allBudgets ?? budgets;

  /// Getters pour les statistiques rapides
  int get totalBudgets => budgets.length;
  int get activeBudgets =>
      budgets.where((b) => b.isActive && b.isCurrent).length;
  int get exceededBudgets => budgets.where((b) => b.isExceeded).length;
  int get warningBudgets =>
      budgets.where((b) => b.isNearLimit && !b.isExceeded).length;
  int get generalBudgets => budgets.where((b) => b.isGeneral).length;
  int get listBudgets => budgets.where((b) => b.isListSpecific).length;

  /// Budgets par statut
  List<Budget> get currentBudgets => budgets.where((b) => b.isCurrent).toList();
  List<Budget> get expiredBudgets => budgets.where((b) => b.isExpired).toList();
  List<Budget> get upcomingBudgets =>
      budgets.where((b) => b.isUpcoming).toList();

  /// Budgets par type
  List<Budget> get weeklyBudgets =>
      budgets.where((b) => b.periodType == BudgetPeriodType.weekly).toList();
  List<Budget> get monthlyBudgets =>
      budgets.where((b) => b.periodType == BudgetPeriodType.monthly).toList();
  List<Budget> get yearlyBudgets =>
      budgets.where((b) => b.periodType == BudgetPeriodType.yearly).toList();

  /// Vérifier si des filtres sont actifs
  bool get hasActiveFilters =>
      activeStatusFilter != null ||
      activePeriodFilter != null ||
      activeScopeFilter != null;

  BudgetLoaded copyWith({
    List<Budget>? budgets,
    List<Budget>? allBudgets,
    BudgetSummary? summary,
    Map<String, dynamic>? dashboardData,
    List<BudgetAlert>? alerts,
    String? activeStatusFilter,
    String? activePeriodFilter,
    String? activeScopeFilter,
    String? activeSortBy,
    bool? activeSortAscending,
  }) {
    return BudgetLoaded(
      budgets: budgets ?? this.budgets,
      allBudgets: allBudgets ?? this.allBudgets,
      summary: summary ?? this.summary,
      dashboardData: dashboardData ?? this.dashboardData,
      alerts: alerts ?? this.alerts,
      activeStatusFilter: activeStatusFilter ?? this.activeStatusFilter,
      activePeriodFilter: activePeriodFilter ?? this.activePeriodFilter,
      activeScopeFilter: activeScopeFilter ?? this.activeScopeFilter,
      activeSortBy: activeSortBy ?? this.activeSortBy,
      activeSortAscending: activeSortAscending ?? this.activeSortAscending,
    );
  }

  @override
  List<Object?> get props => [
    budgets,
    allBudgets,
    summary,
    dashboardData,
    alerts,
    activeStatusFilter,
    activePeriodFilter,
    activeScopeFilter,
    activeSortBy,
    activeSortAscending,
  ];
}

/// Budget spécifique chargé
class BudgetDetailLoaded extends BudgetState {
  final Budget budget;

  const BudgetDetailLoaded(this.budget);

  @override
  List<Object> get props => [budget];
}

/// Tableau de bord chargé
class BudgetDashboardLoaded extends BudgetState {
  final BudgetSummary summary;
  final Map<String, dynamic> dashboardData;
  final List<Budget> currentBudgets;
  final List<Budget> recentExpired;
  final List<BudgetAlert> alerts;

  const BudgetDashboardLoaded({
    required this.summary,
    required this.dashboardData,
    required this.currentBudgets,
    required this.recentExpired,
    required this.alerts,
  });

  @override
  List<Object> get props => [
    summary,
    dashboardData,
    currentBudgets,
    recentExpired,
    alerts,
  ];
}

/// Alertes de budget chargées
class BudgetAlertsLoaded extends BudgetState {
  final List<BudgetAlert> alerts;

  const BudgetAlertsLoaded(this.alerts);

  int get totalAlerts => alerts.length;
  int get exceededAlerts => alerts.where((a) => a.isExceeded).length;
  int get warningAlerts => alerts.where((a) => !a.isExceeded).length;

  @override
  List<Object> get props => [alerts];
}

/// Opération réussie
class BudgetOperationSuccess extends BudgetState {
  final String message;
  final Budget? budget; // Budget créé/modifié si applicable

  const BudgetOperationSuccess(this.message, {this.budget});

  @override
  List<Object?> get props => [message, budget];
}

/// Erreur
class BudgetError extends BudgetState {
  final String message;

  const BudgetError(this.message);

  @override
  List<Object> get props => [message];
}

/// État de chargement spécifique à une opération
class BudgetOperationLoading extends BudgetState {
  final String operation; // 'creating', 'updating', 'deleting'

  const BudgetOperationLoading(this.operation);

  @override
  List<Object> get props => [operation];
}
