// blocs/analytics/analytics_bloc.dart - VERSION PROPRE SANS DUPLICATION
import 'package:bloc/bloc.dart';
import 'package:epilist/blocs/analytics/analytics_event.dart';
import 'package:epilist/blocs/analytics/analytics_state.dart';
import 'package:epilist/services/analytics_service.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsService _analyticsService;
  final LocalizationBloc _localizationBloc;

  // ✅ État du filtre global
  bool _includeShared = true;
  String? _currentCurrency;
  String? _currentPeriodFilter;

  AnalyticsBloc({
    required AnalyticsService analyticsService,
    required LocalizationBloc localizationBloc,
  }) : _analyticsService = analyticsService,
       _localizationBloc = localizationBloc,
       super(AnalyticsInitial()) {
    // ✅ HANDLERS DE BASE (existants)
    on<LoadDashboard>(_onLoadDashboard);
    on<LoadMonthlySpending>(_onLoadMonthlySpending);
    on<LoadDailySpending>(_onLoadDailySpending);
    on<LoadWeeklySpending>(_onLoadWeeklySpending);
    on<LoadYearlySpending>(_onLoadYearlySpending);
    on<LoadSpendingTrends>(_onLoadSpendingTrends);
    on<LoadSpendingCategories>(_onLoadSpendingCategories);
    on<LoadTopProducts>(_onLoadTopProducts);
    on<LoadPeriodComparison>(_onLoadPeriodComparison);
    on<ChangeTopProductsSort>(_onChangeTopProductsSort);

    // ✅ NOUVEAUX HANDLERS POUR LE FILTRAGE (une seule fois chacun)
    on<ToggleSharedListsFilter>(_onToggleSharedListsFilter);
    on<SetPeriodFilter>(_onSetPeriodFilter);
    on<SetCurrencyFilter>(_onSetCurrencyFilter);
    on<RefreshAnalyticsWithFilter>(_onRefreshAnalyticsWithFilter);
  }

  // ✅ Getters pour l'état des filtres
  bool get includeShared => _includeShared;
  String? get currentCurrency => _currentCurrency;
  String? get currentPeriodFilter => _currentPeriodFilter;
  Map<String, dynamic> get currentFilters => {
    'include_shared': _includeShared,
    'currency': _currentCurrency,
    'period_filter': _currentPeriodFilter,
  };

  // ========================================
  // ✅ HANDLERS POUR LE FILTRAGE (NOUVEAUX)
  // ========================================

  Future<void> _onToggleSharedListsFilter(
    ToggleSharedListsFilter event,
    Emitter<AnalyticsState> emit,
  ) async {
    print('🔧 ToggleSharedListsFilter handler called: ${event.includeShared}');
    _includeShared = event.includeShared;

    // Recharger automatiquement le dashboard
    add(
      LoadDashboard(
        currencyCode: _currentCurrency,
        includeShared: _includeShared,
      ),
    );
  }

  Future<void> _onSetPeriodFilter(
    SetPeriodFilter event,
    Emitter<AnalyticsState> emit,
  ) async {
    print('🔧 SetPeriodFilter handler called: ${event.periodFilter}');
    _currentPeriodFilter = event.periodFilter;

    // Recharger automatiquement le dashboard avec le nouveau filtre
    add(
      LoadDashboard(
        currencyCode: _currentCurrency,
        includeShared: _includeShared,
      ),
    );
  }

  Future<void> _onSetCurrencyFilter(
    SetCurrencyFilter event,
    Emitter<AnalyticsState> emit,
  ) async {
    print('🔧 SetCurrencyFilter handler called: ${event.currencyFilter}');
    _currentCurrency = event.currencyFilter;

    // Recharger automatiquement le dashboard avec le nouveau filtre
    add(
      LoadDashboard(
        currencyCode: _currentCurrency,
        includeShared: _includeShared,
      ),
    );
  }

  Future<void> _onRefreshAnalyticsWithFilter(
    RefreshAnalyticsWithFilter event,
    Emitter<AnalyticsState> emit,
  ) async {
    print('🔧 RefreshAnalyticsWithFilter handler called');

    // Émettre d'abord l'état des filtres changés
    final previousState = state;

    if (event.clearAllFilters) {
      _includeShared = true;
      _currentCurrency = null;
      _currentPeriodFilter = null;
      print('🔧 All filters cleared');
    } else {
      _includeShared = event.includeShared;
      if (event.currencyCode != null) {
        _currentCurrency = event.currencyCode;
      }
      if (event.periodFilter != null) {
        _currentPeriodFilter = event.periodFilter;
      }
    }

    // Émettre le changement des filtres
    emit(
      AnalyticsFiltersChanged(
        filters: currentFilters,
        previousState: previousState,
      ),
    );

    // Recharger le dashboard avec les nouveaux paramètres
    add(
      LoadDashboard(
        currencyCode: _currentCurrency,
        includeShared: _includeShared,
      ),
    );
  }

  // ========================================
  // ✅ HANDLERS EXISTANTS (INCHANGÉS)
  // ========================================

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      // Mettre à jour l'état interne si nécessaire
      if (event.currencyCode != null) {
        _currentCurrency = event.currencyCode;
      }

      final data = await _analyticsService.getDashboard(
        event.currencyCode ?? _currentCurrency,
        event.includeShared ?? _includeShared,
      );
      emit(DashboardLoaded(data));
    } catch (e) {
      emit(AnalyticsError(_getTranslatedErrorMessage(e)));
    }
  }

  Future<void> _onLoadMonthlySpending(
    LoadMonthlySpending event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final data = await _analyticsService.getMonthlySpending(
        months: event.months,
        currencyCode: event.currencyCode ?? _currentCurrency,
        includeShared: event.includeShared ?? _includeShared,
      );
      emit(MonthlySpendingLoaded(data));
    } catch (e) {
      emit(AnalyticsError(_getTranslatedErrorMessage(e)));
    }
  }

  Future<void> _onLoadDailySpending(
    LoadDailySpending event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final data = await _analyticsService.getDailySpending(
        days: event.days,
        currencyCode: event.currencyCode ?? _currentCurrency,
        includeShared: event.includeShared ?? _includeShared,
      );
      emit(DailySpendingLoaded(data));
    } catch (e) {
      emit(AnalyticsError(_getTranslatedErrorMessage(e)));
    }
  }

  Future<void> _onLoadWeeklySpending(
    LoadWeeklySpending event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final data = await _analyticsService.getWeeklySpending(
        weeks: event.weeks,
        currencyCode: event.currencyCode ?? _currentCurrency,
        includeShared: event.includeShared ?? _includeShared,
      );
      emit(WeeklySpendingLoaded(data));
    } catch (e) {
      emit(AnalyticsError(_getTranslatedErrorMessage(e)));
    }
  }

  Future<void> _onLoadYearlySpending(
    LoadYearlySpending event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final data = await _analyticsService.getYearlySpending(
        years: event.years,
        currencyCode: event.currencyCode ?? _currentCurrency,
        includeShared: event.includeShared ?? _includeShared,
      );
      emit(YearlySpendingLoaded(data));
    } catch (e) {
      emit(AnalyticsError(_getTranslatedErrorMessage(e)));
    }
  }

  Future<void> _onLoadSpendingTrends(
    LoadSpendingTrends event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final data = await _analyticsService.getSpendingTrends(
        period: event.period,
        currencyCode: event.currencyCode ?? _currentCurrency,
        includeShared: event.includeShared ?? _includeShared,
      );

      // Émettre le bon état selon la période
      switch (event.period) {
        case 'day':
          emit(DailySpendingLoaded(data));
          break;
        case 'week':
          emit(WeeklySpendingLoaded(data));
          break;
        case 'year':
          emit(YearlySpendingLoaded(data));
          break;
        case 'month':
        default:
          emit(MonthlySpendingLoaded(data));
          break;
      }
    } catch (e) {
      emit(AnalyticsError(_getTranslatedErrorMessage(e)));
    }
  }

  Future<void> _onLoadSpendingCategories(
    LoadSpendingCategories event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final data = await _analyticsService.getSpendingCategories(
        period: event.period,
        limit: event.limit,
        currencyCode: event.currencyCode ?? _currentCurrency,
        includeShared: event.includeShared ?? _includeShared,
      );
      emit(SpendingCategoriesLoaded(data));
    } catch (e) {
      emit(AnalyticsError(_getTranslatedErrorMessage(e)));
    }
  }

  Future<void> _onLoadTopProducts(
    LoadTopProducts event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final data = await _analyticsService.getTopProducts(
        period: event.period,
        sortBy: event.sortBy,
        limit: event.limit,
        currencyCode: event.currencyCode ?? _currentCurrency,
        includeShared: event.includeShared ?? _includeShared,
      );
      emit(TopProductsLoaded(data));
    } catch (e) {
      emit(AnalyticsError(_getTranslatedErrorMessage(e)));
    }
  }

  Future<void> _onLoadPeriodComparison(
    LoadPeriodComparison event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final data = await _analyticsService.getPeriodComparison(
        periodType: event.periodType,
        currencyCode: event.currencyCode ?? _currentCurrency,
        includeShared: event.includeShared ?? _includeShared,
      );
      emit(PeriodComparisonLoaded(data));
    } catch (e) {
      emit(AnalyticsError(_getTranslatedErrorMessage(e)));
    }
  }

  Future<void> _onChangeTopProductsSort(
    ChangeTopProductsSort event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());

    try {
      final data = await _analyticsService.getTopProducts(
        period: event.period ?? 'month',
        sortBy: event.sortBy,
        limit: event.limit ?? 10,
        currencyCode: event.currencyCode ?? _currentCurrency,
        includeShared: event.includeShared ?? _includeShared,
      );

      emit(TopProductsLoaded(data));
    } catch (e) {
      emit(AnalyticsError(_getTranslatedErrorMessage(e)));
    }
  }

  // ========================================
  // ✅ UTILITAIRES
  // ========================================

  String _getTranslatedErrorMessage(dynamic error) {
    final isEnglish =
        _localizationBloc.state is LocalizationLoaded &&
        (_localizationBloc.state as LocalizationLoaded).locale.languageCode ==
            'en';

    const Map<String, String> frenchErrors = {
      'network': 'Erreur de réseau',
      'server': 'Erreur du serveur',
      'general': 'Erreur lors du chargement des analyses',
    };

    const Map<String, String> englishErrors = {
      'network': 'Network error',
      'server': 'Server error',
      'general': 'Error loading analytics',
    };

    String errorString = error.toString().toLowerCase();
    String errorType = 'general';

    if (errorString.contains('network') || errorString.contains('connection')) {
      errorType = 'network';
    } else if (errorString.contains('server') || errorString.contains('500')) {
      errorType = 'server';
    }

    return isEnglish ? englishErrors[errorType]! : frenchErrors[errorType]!;
  }
}
