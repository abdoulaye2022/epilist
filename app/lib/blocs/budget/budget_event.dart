part of 'budget_bloc.dart';

abstract class BudgetEvent extends Equatable {
  const BudgetEvent();

  @override
  List<Object?> get props => [];
}

/// Charger tous les budgets
class LoadBudgets extends BudgetEvent {
  const LoadBudgets();
}

/// Charger les budgets avec filtres
class LoadBudgetsWithFilters extends BudgetEvent {
  final String? status;
  final String? periodType;
  final String? listId;

  const LoadBudgetsWithFilters({this.status, this.periodType, this.listId});

  @override
  List<Object?> get props => [status, periodType, listId];
}

/// Charger un budget spécifique
class LoadBudget extends BudgetEvent {
  final int budgetId;

  const LoadBudget(this.budgetId);

  @override
  List<Object> get props => [budgetId];
}

/// Créer un nouveau budget
class CreateBudget extends BudgetEvent {
  final CreateBudgetRequest request;

  const CreateBudget(this.request);

  @override
  List<Object> get props => [request];
}

/// Mettre à jour un budget
class UpdateBudget extends BudgetEvent {
  final int budgetId;
  final UpdateBudgetRequest request;

  const UpdateBudget(this.budgetId, this.request);

  @override
  List<Object> get props => [budgetId, request];
}

/// Supprimer un budget
class DeleteBudget extends BudgetEvent {
  final int budgetId;

  const DeleteBudget(this.budgetId);

  @override
  List<Object> get props => [budgetId];
}

/// Charger le tableau de bord
class LoadBudgetDashboard extends BudgetEvent {
  const LoadBudgetDashboard();
}

/// Charger les alertes de budget
class LoadBudgetAlerts extends BudgetEvent {
  const LoadBudgetAlerts();
}

/// Créer un budget rapide
class CreateQuickBudget extends BudgetEvent {
  final String type;
  final double amount;
  final String? name;
  final int? listId;

  const CreateQuickBudget({
    required this.type,
    required this.amount,
    this.name,
    this.listId,
  });

  @override
  List<Object?> get props => [type, amount, name, listId];
}

/// Rafraîchir les budgets
class RefreshBudgets extends BudgetEvent {
  const RefreshBudgets();
}

/// Activer/Désactiver un budget
class ToggleBudgetStatus extends BudgetEvent {
  final int budgetId;
  final bool isActive;

  const ToggleBudgetStatus(this.budgetId, this.isActive);

  @override
  List<Object> get props => [budgetId, isActive];
}

/// ✅ CORRECTION: Filtrer les budgets localement
class FilterBudgets extends BudgetEvent {
  final String? statusFilter;
  final String? periodFilter;
  final String? scopeFilter; // 'general', 'specific', 'all'

  const FilterBudgets({this.statusFilter, this.periodFilter, this.scopeFilter});

  @override
  List<Object?> get props => [statusFilter, periodFilter, scopeFilter];
}

/// Trier les budgets
class SortBudgets extends BudgetEvent {
  final String sortBy; // 'name', 'amount', 'spent', 'remaining', 'date'
  final bool ascending;

  const SortBudgets(this.sortBy, this.ascending);

  @override
  List<Object> get props => [sortBy, ascending];
}
