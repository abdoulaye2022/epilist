// blocs/budget/budget_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:epilist/models/budget.dart';
import 'package:epilist/services/budget_service.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

part 'budget_event.dart';
part 'budget_state.dart';

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  final BudgetService _budgetService;
  final LocalizationBloc _localizationBloc;

  BudgetBloc({
    required BudgetService budgetService,
    required LocalizationBloc localizationBloc,
  }) : _budgetService = budgetService,
       _localizationBloc = localizationBloc,
       super(BudgetInitial()) {
    on<LoadBudgets>(_onLoadBudgets);
    on<LoadBudgetsWithFilters>(_onLoadBudgetsWithFilters);
    on<LoadBudget>(_onLoadBudget);
    on<CreateBudget>(_onCreateBudget);
    on<UpdateBudget>(_onUpdateBudget);
    on<DeleteBudget>(_onDeleteBudget);
    on<LoadBudgetDashboard>(_onLoadBudgetDashboard);
    on<LoadBudgetAlerts>(_onLoadBudgetAlerts);
    on<CreateQuickBudget>(_onCreateQuickBudget);
    on<RefreshBudgets>(_onRefreshBudgets);
    on<ToggleBudgetStatus>(_onToggleBudgetStatus);
    on<FilterBudgets>(_onFilterBudgets);
    on<SortBudgets>(_onSortBudgets);
  }

  /// Messages traduits selon la langue
  String _getTranslatedSuccessMessage(String operation) {
    const Map<String, String> frenchMessages = {
      'create': 'Budget créé avec succès',
      'update': 'Budget modifié avec succès',
      'delete': 'Budget supprimé avec succès',
      'quick_create': 'Budget rapide créé avec succès',
      'toggle': 'Statut du budget modifié',
      'load': 'Budgets chargés avec succès',
    };

    const Map<String, String> englishMessages = {
      'create': 'Budget created successfully',
      'update': 'Budget updated successfully',
      'delete': 'Budget deleted successfully',
      'quick_create': 'Quick budget created successfully',
      'toggle': 'Budget status updated',
      'load': 'Budgets loaded successfully',
    };

    final isEnglish =
        _localizationBloc.state is LocalizationLoaded &&
        (_localizationBloc.state as LocalizationLoaded).locale.languageCode ==
            'en';

    if (isEnglish) {
      return englishMessages[operation] ?? 'Operation successful';
    } else {
      return frenchMessages[operation] ?? 'Opération réussie';
    }
  }

  String _getTranslatedErrorMessage(dynamic error) {
    const Map<String, String> frenchErrors = {
      'network': 'Erreur de réseau',
      'permission': 'Permission insuffisante',
      'not_found': 'Budget non trouvé',
      'validation': 'Données invalides',
      'conflict': 'Un budget existe déjà pour cette période',
      'server': 'Erreur du serveur',
      'general': 'Une erreur est survenue',
    };

    const Map<String, String> englishErrors = {
      'network': 'Network error',
      'permission': 'Insufficient permission',
      'not_found': 'Budget not found',
      'validation': 'Invalid data',
      'conflict': 'A budget already exists for this period',
      'server': 'Server error',
      'general': 'An error occurred',
    };

    final isEnglish =
        _localizationBloc.state is LocalizationLoaded &&
        (_localizationBloc.state as LocalizationLoaded).locale.languageCode ==
            'en';

    String errorString = error.toString().toLowerCase();
    String errorType = 'general';

    if (errorString.contains('network') ||
        errorString.contains('réseau') ||
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      errorType = 'network';
    } else if (errorString.contains('permission') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden')) {
      errorType = 'permission';
    } else if (errorString.contains('not found') ||
        errorString.contains('non trouvé')) {
      errorType = 'not_found';
    } else if (errorString.contains('validation') ||
        errorString.contains('invalid') ||
        errorString.contains('invalide')) {
      errorType = 'validation';
    } else if (errorString.contains('conflict') ||
        errorString.contains('existe déjà') ||
        errorString.contains('already exists') ||
        errorString.contains('overlapping')) {
      errorType = 'conflict';
    } else if (errorString.contains('server') ||
        errorString.contains('serveur')) {
      errorType = 'server';
    }

    if (isEnglish) {
      return englishErrors[errorType]!;
    } else {
      return frenchErrors[errorType]!;
    }
  }

  /// Charger tous les budgets
  Future<void> _onLoadBudgets(
    LoadBudgets event,
    Emitter<BudgetState> emit,
  ) async {
    emit(BudgetLoading());
    try {
      final budgets = await _budgetService.getBudgets();
      emit(BudgetLoaded(budgets: budgets, allBudgets: budgets));
    } catch (e) {
      debugPrint('Error loading budgets: $e');
      final errorMessage = _getTranslatedErrorMessage(e);
      emit(BudgetError(errorMessage));
    }
  }

  /// Charger les budgets avec filtres
  Future<void> _onLoadBudgetsWithFilters(
    LoadBudgetsWithFilters event,
    Emitter<BudgetState> emit,
  ) async {
    emit(BudgetLoading());
    try {
      final budgets = await _budgetService.getBudgets(
        status: event.status,
        periodType: event.periodType,
        listId: event.listId,
      );
      emit(
        BudgetLoaded(
          budgets: budgets,
          allBudgets: budgets,
          activeStatusFilter: event.status,
          activePeriodFilter: event.periodType,
          activeScopeFilter: event.listId,
        ),
      );
    } catch (e) {
      debugPrint('Error loading budgets with filters: $e');
      final errorMessage = _getTranslatedErrorMessage(e);
      emit(BudgetError(errorMessage));
    }
  }

  /// Charger un budget spécifique
  Future<void> _onLoadBudget(
    LoadBudget event,
    Emitter<BudgetState> emit,
  ) async {
    emit(BudgetLoading());
    try {
      final budget = await _budgetService.getBudget(event.budgetId);
      emit(BudgetDetailLoaded(budget));
    } catch (e) {
      debugPrint('Error loading budget: $e');
      final errorMessage = _getTranslatedErrorMessage(e);
      emit(BudgetError(errorMessage));
    }
  }

  /// ✅ CRÉATION DE BUDGET CORRIGÉE
  Future<void> _onCreateBudget(
    CreateBudget event,
    Emitter<BudgetState> emit,
  ) async {
    // ✅ Sauvegarder l'état actuel
    final previousState = state;

    emit(const BudgetOperationLoading('creating'));
    try {
      final newBudget = await _budgetService.createBudget(event.request);

      // ✅ IMPORTANT: Recharger TOUS les budgets depuis le serveur
      final allBudgets = await _budgetService.getBudgets();

      final successMessage = _getTranslatedSuccessMessage('create');

      // ✅ Émettre d'abord le succès
      emit(BudgetOperationSuccess(successMessage, budget: newBudget));

      // ✅ Puis mettre à jour l'état avec les données fraîches
      if (previousState is BudgetLoaded) {
        emit(
          previousState.copyWith(budgets: allBudgets, allBudgets: allBudgets),
        );
      } else {
        emit(BudgetLoaded(budgets: allBudgets, allBudgets: allBudgets));
      }
    } catch (e) {
      debugPrint('Error creating budget: $e');
      final errorMessage = _getTranslatedErrorMessage(e);

      // ✅ IMPORTANT: Restaurer l'état précédent (pas vider)
      if (previousState is BudgetLoaded) {
        emit(previousState);
      }

      // ✅ Puis émettre l'erreur qui sera captée par le BlocListener
      emit(BudgetError(errorMessage));
    }
  }

  /// ✅ MISE À JOUR DE BUDGET CORRIGÉE
  Future<void> _onUpdateBudget(
    UpdateBudget event,
    Emitter<BudgetState> emit,
  ) async {
    // ✅ Sauvegarder l'état actuel
    final previousState = state;

    emit(const BudgetOperationLoading('updating'));
    try {
      final updatedBudget = await _budgetService.updateBudget(
        event.budgetId,
        event.request,
      );

      // ✅ IMPORTANT: Recharger TOUS les budgets depuis le serveur
      final allBudgets = await _budgetService.getBudgets();

      final successMessage = _getTranslatedSuccessMessage('update');

      // ✅ Émettre d'abord le succès
      emit(BudgetOperationSuccess(successMessage, budget: updatedBudget));

      // ✅ Puis mettre à jour l'état avec les données fraîches
      if (previousState is BudgetLoaded) {
        emit(
          previousState.copyWith(budgets: allBudgets, allBudgets: allBudgets),
        );
      } else {
        emit(BudgetLoaded(budgets: allBudgets, allBudgets: allBudgets));
      }
    } catch (e) {
      debugPrint('Error updating budget: $e');
      final errorMessage = _getTranslatedErrorMessage(e);

      // ✅ IMPORTANT: Restaurer l'état précédent (pas vider)
      if (previousState is BudgetLoaded) {
        emit(previousState);
      }

      // ✅ Puis émettre l'erreur qui sera captée par le BlocListener
      emit(BudgetError(errorMessage));
    }
  }

  /// ✅ SUPPRESSION DE BUDGET CORRIGÉE
  Future<void> _onDeleteBudget(
    DeleteBudget event,
    Emitter<BudgetState> emit,
  ) async {
    // ✅ Sauvegarder l'état actuel
    final previousState = state;

    emit(const BudgetOperationLoading('deleting'));
    try {
      await _budgetService.deleteBudget(event.budgetId);

      // ✅ IMPORTANT: Recharger TOUS les budgets depuis le serveur
      final allBudgets = await _budgetService.getBudgets();

      final successMessage = _getTranslatedSuccessMessage('delete');

      // ✅ Émettre d'abord le succès
      emit(BudgetOperationSuccess(successMessage));

      // ✅ Puis mettre à jour l'état avec les données fraîches
      if (previousState is BudgetLoaded) {
        emit(
          previousState.copyWith(budgets: allBudgets, allBudgets: allBudgets),
        );
      } else {
        emit(BudgetLoaded(budgets: allBudgets, allBudgets: allBudgets));
      }
    } catch (e) {
      debugPrint('Error deleting budget: $e');
      final errorMessage = _getTranslatedErrorMessage(e);

      // ✅ IMPORTANT: Restaurer l'état précédent (pas vider)
      if (previousState is BudgetLoaded) {
        emit(previousState);
      }

      // ✅ Puis émettre l'erreur qui sera captée par le BlocListener
      emit(BudgetError(errorMessage));
    }
  }

  /// Charger le tableau de bord
  Future<void> _onLoadBudgetDashboard(
    LoadBudgetDashboard event,
    Emitter<BudgetState> emit,
  ) async {
    emit(BudgetLoading());
    try {
      final dashboardData = await _budgetService.getBudgetDashboard();
      final alerts = await _budgetService.getBudgetAlerts();

      emit(
        BudgetDashboardLoaded(
          summary: dashboardData['summary'] as BudgetSummary,
          dashboardData: dashboardData,
          currentBudgets: dashboardData['current_budgets'] as List<Budget>,
          recentExpired: dashboardData['recent_expired'] as List<Budget>,
          alerts: alerts,
        ),
      );
    } catch (e) {
      debugPrint('Error loading budget dashboard: $e');
      final errorMessage = _getTranslatedErrorMessage(e);
      emit(BudgetError(errorMessage));
    }
  }

  /// Charger les alertes
  Future<void> _onLoadBudgetAlerts(
    LoadBudgetAlerts event,
    Emitter<BudgetState> emit,
  ) async {
    try {
      final alerts = await _budgetService.getBudgetAlerts();
      emit(BudgetAlertsLoaded(alerts));
    } catch (e) {
      debugPrint('Error loading budget alerts: $e');
      final errorMessage = _getTranslatedErrorMessage(e);
      emit(BudgetError(errorMessage));
    }
  }

  /// ✅ CRÉATION DE BUDGET RAPIDE CORRIGÉE
  Future<void> _onCreateQuickBudget(
    CreateQuickBudget event,
    Emitter<BudgetState> emit,
  ) async {
    // ✅ Sauvegarder l'état actuel
    final previousState = state;

    emit(const BudgetOperationLoading('creating'));
    try {
      final newBudget = await _budgetService.createQuickBudget(
        type: event.type,
        amount: event.amount,
        name: event.name,
        listId: event.listId,
      );

      // ✅ IMPORTANT: Recharger TOUS les budgets depuis le serveur
      final allBudgets = await _budgetService.getBudgets();

      final successMessage = _getTranslatedSuccessMessage('quick_create');

      // ✅ Émettre d'abord le succès
      emit(BudgetOperationSuccess(successMessage, budget: newBudget));

      // ✅ Puis mettre à jour l'état avec les données fraîches
      if (previousState is BudgetLoaded) {
        emit(
          previousState.copyWith(budgets: allBudgets, allBudgets: allBudgets),
        );
      } else {
        emit(BudgetLoaded(budgets: allBudgets, allBudgets: allBudgets));
      }
    } catch (e) {
      debugPrint('Error creating quick budget: $e');
      final errorMessage = _getTranslatedErrorMessage(e);

      // ✅ IMPORTANT: Restaurer l'état précédent (pas vider)
      if (previousState is BudgetLoaded) {
        emit(previousState);
      }

      // ✅ Puis émettre l'erreur qui sera captée par le BlocListener
      emit(BudgetError(errorMessage));
    }
  }

  /// Rafraîchir les budgets
  Future<void> _onRefreshBudgets(
    RefreshBudgets event,
    Emitter<BudgetState> emit,
  ) async {
    try {
      final budgets = await _budgetService.getBudgets();

      if (state is BudgetLoaded) {
        final currentState = state as BudgetLoaded;
        emit(currentState.copyWith(budgets: budgets, allBudgets: budgets));
      } else {
        emit(BudgetLoaded(budgets: budgets, allBudgets: budgets));
      }
    } catch (e) {
      debugPrint('Error refreshing budgets: $e');
      final errorMessage = _getTranslatedErrorMessage(e);
      emit(BudgetError(errorMessage));
    }
  }

  /// ✅ TOGGLE BUDGET STATUS CORRIGÉ
  Future<void> _onToggleBudgetStatus(
    ToggleBudgetStatus event,
    Emitter<BudgetState> emit,
  ) async {
    // ✅ Sauvegarder l'état actuel
    final previousState = state;

    try {
      final request = UpdateBudgetRequest(isActive: event.isActive);
      await _budgetService.updateBudget(event.budgetId, request);

      // ✅ IMPORTANT: Recharger TOUS les budgets depuis le serveur
      final allBudgets = await _budgetService.getBudgets();

      final successMessage = _getTranslatedSuccessMessage('toggle');

      // ✅ Émettre d'abord le succès
      emit(BudgetOperationSuccess(successMessage));

      // ✅ Puis mettre à jour l'état avec les données fraîches
      if (previousState is BudgetLoaded) {
        emit(
          previousState.copyWith(budgets: allBudgets, allBudgets: allBudgets),
        );
      } else {
        emit(BudgetLoaded(budgets: allBudgets, allBudgets: allBudgets));
      }
    } catch (e) {
      debugPrint('Error toggling budget status: $e');
      final errorMessage = _getTranslatedErrorMessage(e);

      // ✅ IMPORTANT: Restaurer l'état précédent (pas vider)
      if (previousState is BudgetLoaded) {
        emit(previousState);
      }

      // ✅ Puis émettre l'erreur qui sera captée par le BlocListener
      emit(BudgetError(errorMessage));
    }
  }

  /// Filtrer les budgets localement
  Future<void> _onFilterBudgets(
    FilterBudgets event,
    Emitter<BudgetState> emit,
  ) async {
    if (state is BudgetLoaded) {
      final currentState = state as BudgetLoaded;
      List<Budget> filteredBudgets = List.from(currentState.allBudgets);

      debugPrint('🔍 Filtrage des budgets:');
      debugPrint('  - Status: ${event.statusFilter}');
      debugPrint('  - Period: ${event.periodFilter}');
      debugPrint('  - Scope: ${event.scopeFilter}');
      debugPrint('  - Total budgets avant filtrage: ${filteredBudgets.length}');

      // ✅ CORRECTION: Appliquer les filtres avec logs détaillés
      if (event.statusFilter != null && event.statusFilter != 'all') {
        final initialCount = filteredBudgets.length;
        switch (event.statusFilter) {
          case 'active':
            filteredBudgets =
                filteredBudgets
                    .where((b) => b.isActive && b.isCurrent)
                    .toList();
            break;
          case 'expired':
            filteredBudgets =
                filteredBudgets.where((b) => b.isExpired).toList();
            break;
          case 'upcoming':
            filteredBudgets =
                filteredBudgets.where((b) => b.isUpcoming).toList();
            break;
          case 'exceeded':
            filteredBudgets =
                filteredBudgets.where((b) => b.isExceeded).toList();
            break;
          case 'warning':
            filteredBudgets =
                filteredBudgets
                    .where((b) => b.isNearLimit && !b.isExceeded)
                    .toList();
            break;
        }
        debugPrint(
          '  - Après filtre status: ${filteredBudgets.length} (était $initialCount)',
        );
      }

      if (event.periodFilter != null && event.periodFilter != 'all') {
        final initialCount = filteredBudgets.length;
        // ✅ CORRECTION: Utiliser les bonnes valeurs d'enum
        BudgetPeriodType? periodType;
        switch (event.periodFilter) {
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
            periodType = BudgetPeriodType.custom;
            break;
        }

        if (periodType != null) {
          filteredBudgets =
              filteredBudgets.where((b) => b.periodType == periodType).toList();
        }
        debugPrint(
          '  - Après filtre period: ${filteredBudgets.length} (était $initialCount)',
        );
      }

      if (event.scopeFilter != null && event.scopeFilter != 'all') {
        final initialCount = filteredBudgets.length;
        switch (event.scopeFilter) {
          case 'general':
            filteredBudgets =
                filteredBudgets.where((b) => b.isGeneral).toList();
            break;
          case 'specific':
            filteredBudgets =
                filteredBudgets.where((b) => b.isListSpecific).toList();
            break;
        }
        debugPrint(
          '  - Après filtre scope: ${filteredBudgets.length} (était $initialCount)',
        );
      }

      debugPrint('✅ Filtrage terminé: ${filteredBudgets.length} budgets');

      emit(
        currentState.copyWith(
          budgets: filteredBudgets,
          activeStatusFilter: event.statusFilter,
          activePeriodFilter: event.periodFilter,
          activeScopeFilter: event.scopeFilter,
        ),
      );
    }
  }

  /// Trier les budgets
  Future<void> _onSortBudgets(
    SortBudgets event,
    Emitter<BudgetState> emit,
  ) async {
    if (state is BudgetLoaded) {
      final currentState = state as BudgetLoaded;
      List<Budget> sortedBudgets = List.from(currentState.budgets);

      switch (event.sortBy) {
        case 'name':
          sortedBudgets.sort(
            (a, b) =>
                event.ascending
                    ? a.name.compareTo(b.name)
                    : b.name.compareTo(a.name),
          );
          break;
        case 'amount':
          sortedBudgets.sort(
            (a, b) =>
                event.ascending
                    ? a.budgetAmount.compareTo(b.budgetAmount)
                    : b.budgetAmount.compareTo(a.budgetAmount),
          );
          break;
        case 'spent':
          sortedBudgets.sort(
            (a, b) =>
                event.ascending
                    ? a.spentAmount.compareTo(b.spentAmount)
                    : b.spentAmount.compareTo(a.spentAmount),
          );
          break;
        case 'remaining':
          sortedBudgets.sort(
            (a, b) =>
                event.ascending
                    ? a.remainingAmount.compareTo(b.remainingAmount)
                    : b.remainingAmount.compareTo(a.remainingAmount),
          );
          break;
        case 'date':
          sortedBudgets.sort(
            (a, b) =>
                event.ascending
                    ? a.startDate.compareTo(b.startDate)
                    : b.startDate.compareTo(a.startDate),
          );
          break;
      }

      emit(
        currentState.copyWith(
          budgets: sortedBudgets,
          activeSortBy: event.sortBy,
          activeSortAscending: event.ascending,
        ),
      );
    }
  }
}
