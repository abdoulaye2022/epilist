// blocs/analytics/analytics_bloc.dart - VERSION AVEC FILTRAGE
import 'package:bloc/bloc.dart';
import 'package:epilist/blocs/analytics/analytics_event.dart';
import 'package:epilist/blocs/analytics/analytics_state.dart';
import 'package:epilist/services/analytics_service.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsService _analyticsService;
  final LocalizationBloc _localizationBloc;

  // ✅ NOUVEAU: État du filtre global
  bool _includeShared = true;
  String? _currentCurrency;

  AnalyticsBloc({
    required AnalyticsService analyticsService,
    required LocalizationBloc localizationBloc,
  }) : _analyticsService = analyticsService,
       _localizationBloc = localizationBloc,
       super(AnalyticsInitial()) {
    // Handlers existants
    on<LoadDashboard>(_onLoadDashboard);
    on<LoadMonthlySpending>(_onLoadMonthlySpending);
    on<LoadSpendingTrends>(_onLoadSpendingTrends);
    on<LoadSpendingCategories>(_onLoadSpendingCategories);
    on<LoadTopProducts>(_onLoadTopProducts);
    on<LoadPeriodComparison>(_onLoadPeriodComparison);
    on<ChangeTopProductsSort>(_onChangeTopProductsSort);
    on<LoadDailySpending>(_onLoadDailySpending);
    on<LoadWeeklySpending>(_onLoadWeeklySpending);
    on<LoadYearlySpending>(_onLoadYearlySpending);

    // ✅ NOUVEAUX HANDLERS pour le filtrage
    on<ToggleSharedListsFilter>(_onToggleSharedListsFilter);
    on<RefreshAnalyticsWithFilter>(_onRefreshAnalyticsWithFilter);
  }

  // ✅ NOUVEAU: Getter pour l'état du filtre
  bool get includeShared => _includeShared;
  String? get currentCurrency => _currentCurrency;

  // ✅ NOUVEAU: Handler pour basculer le filtre des listes partagées
  Future<void> _onToggleSharedListsFilter(
    ToggleSharedListsFilter event,
    Emitter<AnalyticsState> emit,
  ) async {
    _includeShared = event.includeShared;

    // Optionnel: Recharger automatiquement le dashboard
    add(
      LoadDashboard(
        currencyCode: _currentCurrency,
        includeShared: _includeShared,
      ),
    );
  }

  // ✅ NOUVEAU: Handler pour rafraîchir avec le nouveau filtre
  Future<void> _onRefreshAnalyticsWithFilter(
    RefreshAnalyticsWithFilter event,
    Emitter<AnalyticsState> emit,
  ) async {
    _includeShared = event.includeShared;
    _currentCurrency = event.currencyCode;

    // Recharger le dashboard avec les nouveaux paramètres
    add(
      LoadDashboard(
        currencyCode: _currentCurrency,
        includeShared: _includeShared,
      ),
    );
  }

  // ✅ MODIFIÉ: Handlers mis à jour avec le paramètre includeShared
  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      _currentCurrency = event.currencyCode;
      final data = await _analyticsService.getDashboard(
        event.currencyCode,
        event.includeShared,
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
        currencyCode: event.currencyCode,
        includeShared: event.includeShared,
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
        currencyCode: event.currencyCode,
        includeShared: event.includeShared,
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
        currencyCode: event.currencyCode,
        includeShared: event.includeShared,
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
        currencyCode: event.currencyCode,
        includeShared: event.includeShared,
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
        currencyCode: event.currencyCode,
        includeShared: event.includeShared,
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
        currencyCode: event.currencyCode,
        includeShared: event.includeShared,
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
        currencyCode: event.currencyCode,
        includeShared: event.includeShared,
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
        currencyCode: event.currencyCode,
        includeShared: event.includeShared,
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
        currencyCode: event.currencyCode,
        includeShared: event.includeShared,
      );

      emit(TopProductsLoaded(data));
    } catch (e) {
      emit(AnalyticsError(_getTranslatedErrorMessage(e)));
    }
  }

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
