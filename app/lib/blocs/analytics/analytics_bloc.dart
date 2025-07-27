// blocs/analytics/analytics_bloc.dart - VERSION MISE À JOUR
import 'package:bloc/bloc.dart';
import 'package:epilist/blocs/analytics/analytics_event.dart';
import 'package:epilist/blocs/analytics/analytics_state.dart';
import 'package:epilist/services/analytics_service.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsService _analyticsService;
  final LocalizationBloc _localizationBloc;

  AnalyticsBloc({
    required AnalyticsService analyticsService,
    required LocalizationBloc localizationBloc,
  }) : _analyticsService = analyticsService,
       _localizationBloc = localizationBloc,
       super(AnalyticsInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<LoadMonthlySpending>(_onLoadMonthlySpending);
    on<LoadSpendingTrends>(_onLoadSpendingTrends);
    on<LoadSpendingCategories>(_onLoadSpendingCategories);
    on<LoadTopProducts>(_onLoadTopProducts);
    on<LoadPeriodComparison>(_onLoadPeriodComparison);
    on<ChangeTopProductsSort>(_onChangeTopProductsSort);

    // ✅ NOUVEAUX HANDLERS POUR LES ENDPOINTS SPÉCIFIQUES
    on<LoadDailySpending>(_onLoadDailySpending);
    on<LoadWeeklySpending>(_onLoadWeeklySpending);
    on<LoadYearlySpending>(_onLoadYearlySpending);
  }

  /// ✅ NOUVEAU: Handler pour les dépenses quotidiennes
  Future<void> _onLoadDailySpending(
    LoadDailySpending event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final data = await _analyticsService.getDailySpending(
        days: event.days,
        currencyCode: event.currencyCode,
      );
      emit(DailySpendingLoaded(data));
    } catch (e) {
      emit(AnalyticsError(_getTranslatedErrorMessage(e)));
    }
  }

  /// ✅ NOUVEAU: Handler pour les dépenses hebdomadaires
  Future<void> _onLoadWeeklySpending(
    LoadWeeklySpending event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final data = await _analyticsService.getWeeklySpending(
        weeks: event.weeks,
        currencyCode: event.currencyCode,
      );
      emit(WeeklySpendingLoaded(data));
    } catch (e) {
      emit(AnalyticsError(_getTranslatedErrorMessage(e)));
    }
  }

  /// ✅ NOUVEAU: Handler pour les dépenses annuelles
  Future<void> _onLoadYearlySpending(
    LoadYearlySpending event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final data = await _analyticsService.getYearlySpending(
        years: event.years,
        currencyCode: event.currencyCode,
      );
      emit(YearlySpendingLoaded(data));
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

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final data = await _analyticsService.getDashboard(event.currencyCode);
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
      );
      emit(MonthlySpendingLoaded(data));
    } catch (e) {
      emit(AnalyticsError(_getTranslatedErrorMessage(e)));
    }
  }

  /// ✅ MODIFIÉ: Handler pour les tendances génériques (garde la compatibilité)
  Future<void> _onLoadSpendingTrends(
    LoadSpendingTrends event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final data = await _analyticsService.getSpendingTrends(
        period: event.period,
        currencyCode: event.currencyCode,
      );

      // ✅ Émettre le bon état selon la période
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
      );
      emit(PeriodComparisonLoaded(data));
    } catch (e) {
      emit(AnalyticsError(_getTranslatedErrorMessage(e)));
    }
  }

  /// Handler pour le changement de tri des produits
  Future<void> _onChangeTopProductsSort(
    ChangeTopProductsSort event,
    Emitter<AnalyticsState> emit,
  ) async {
    // Indiquer le chargement
    emit(AnalyticsLoading());

    try {
      // Charger les données avec le nouveau tri
      final data = await _analyticsService.getTopProducts(
        period: event.period ?? 'month',
        sortBy: event.sortBy,
        limit: event.limit ?? 10,
        currencyCode: event.currencyCode,
      );

      // Émettre les nouvelles données
      emit(TopProductsLoaded(data));
    } catch (e) {
      // En cas d'erreur
      emit(AnalyticsError(_getTranslatedErrorMessage(e)));
    }
  }
}
