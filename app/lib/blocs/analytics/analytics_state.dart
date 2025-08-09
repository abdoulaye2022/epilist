import 'package:equatable/equatable.dart';

abstract class AnalyticsState extends Equatable {
  const AnalyticsState();

  @override
  List<Object?> get props => [];
}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {}

// ✅ État principal du dashboard avec support du filtrage
class DashboardLoaded extends AnalyticsState {
  final Map<String, dynamic> dashboardData;

  const DashboardLoaded(this.dashboardData);

  @override
  List<Object> get props => [dashboardData];

  // Helper getters pour accéder facilement aux données
  bool get includeShared => dashboardData['include_shared'] ?? true;
  Map<String, dynamic>? get dataBreakdown => dashboardData['data_breakdown'];
  Map<String, dynamic> get currentMonth => dashboardData['current_month'] ?? {};
  List<dynamic> get last7Days => dashboardData['last_7_days'] ?? [];
  Map<String, dynamic> get quickStats => dashboardData['quick_stats'] ?? {};
}

// ✅ État pour les dépenses mensuelles
class MonthlySpendingLoaded extends AnalyticsState {
  final Map<String, dynamic> monthlyData;

  const MonthlySpendingLoaded(this.monthlyData);

  @override
  List<Object> get props => [monthlyData];

  List<dynamic> get monthlyDataList => monthlyData['monthly_data'] ?? [];
  Map<String, dynamic> get summary => monthlyData['summary'] ?? {};
  String get language => monthlyData['language'] ?? 'fr';
}

// ✅ État pour les dépenses quotidiennes
class DailySpendingLoaded extends AnalyticsState {
  final Map<String, dynamic> dailyData;

  const DailySpendingLoaded(this.dailyData);

  @override
  List<Object> get props => [dailyData];

  List<dynamic> get dailyDataList => dailyData['daily_data'] ?? [];
  Map<String, dynamic> get summary => dailyData['summary'] ?? {};
  String get language => dailyData['language'] ?? 'fr';
}

// ✅ État pour les dépenses hebdomadaires
class WeeklySpendingLoaded extends AnalyticsState {
  final Map<String, dynamic> weeklyData;

  const WeeklySpendingLoaded(this.weeklyData);

  @override
  List<Object> get props => [weeklyData];

  List<dynamic> get weeklyDataList => weeklyData['weekly_data'] ?? [];
  Map<String, dynamic> get summary => weeklyData['summary'] ?? {};
  String get language => weeklyData['language'] ?? 'fr';
}

// ✅ État pour les dépenses annuelles
class YearlySpendingLoaded extends AnalyticsState {
  final Map<String, dynamic> yearlyData;

  const YearlySpendingLoaded(this.yearlyData);

  @override
  List<Object> get props => [yearlyData];

  List<dynamic> get yearlyDataList => yearlyData['yearly_data'] ?? [];
  Map<String, dynamic> get summary => yearlyData['summary'] ?? {};
  String get language => yearlyData['language'] ?? 'fr';
}

// ✅ État générique pour les tendances (compatibilité arrière)
class SpendingTrendsLoaded extends AnalyticsState {
  final Map<String, dynamic> trendsData;

  const SpendingTrendsLoaded(this.trendsData);

  @override
  List<Object> get props => [trendsData];
}

// ✅ État pour les catégories de dépenses
class SpendingCategoriesLoaded extends AnalyticsState {
  final Map<String, dynamic> categoriesData;

  const SpendingCategoriesLoaded(this.categoriesData);

  @override
  List<Object> get props => [categoriesData];

  List<dynamic> get categories => categoriesData['categories'] ?? [];
  Map<String, dynamic> get summary => categoriesData['summary'] ?? {};
  String get language => categoriesData['language'] ?? 'fr';
  String get period => categoriesData['period'] ?? 'month';
}

// ✅ État pour les top produits
class TopProductsLoaded extends AnalyticsState {
  final Map<String, dynamic> productsData;

  const TopProductsLoaded(this.productsData);

  @override
  List<Object> get props => [productsData];

  List<dynamic> get products => productsData['products'] ?? [];
  Map<String, dynamic> get summary => productsData['summary'] ?? {};
  String get language => productsData['language'] ?? 'fr';
  String get sortBy => productsData['sort_by'] ?? 'total_spent';
  String get period => productsData['period'] ?? 'month';
}

// ✅ État pour la comparaison des périodes
class PeriodComparisonLoaded extends AnalyticsState {
  final Map<String, dynamic> comparisonData;

  const PeriodComparisonLoaded(this.comparisonData);

  @override
  List<Object> get props => [comparisonData];

  Map<String, dynamic> get currentPeriod =>
      comparisonData['current_period'] ?? {};
  Map<String, dynamic> get previousPeriod =>
      comparisonData['previous_period'] ?? {};
  Map<String, dynamic> get changes => comparisonData['changes'] ?? {};
  Map<String, dynamic> get summary => comparisonData['summary'] ?? {};
  String get language => comparisonData['language'] ?? 'fr';
  String get periodType => comparisonData['period_type'] ?? 'month';
}

// ✅ NOUVEAU: État pour les dépenses par magasin
class SpendingByStoreLoaded extends AnalyticsState {
  final Map<String, dynamic> storeData;

  const SpendingByStoreLoaded(this.storeData);

  @override
  List<Object> get props => [storeData];

  List<dynamic> get stores => storeData['stores'] ?? [];
  Map<String, dynamic> get summary => storeData['summary'] ?? {};
  String get language => storeData['language'] ?? 'fr';
  String get period => storeData['period'] ?? 'month';
}

// ✅ NOUVEAU: État pour le rapport de qualité des données
class DataQualityReportLoaded extends AnalyticsState {
  final Map<String, dynamic> qualityData;

  const DataQualityReportLoaded(this.qualityData);

  @override
  List<Object> get props => [qualityData];

  Map<String, dynamic> get report => qualityData['report'] ?? {};
  Map<String, dynamic> get percentages => qualityData['percentages'] ?? {};
  String get language => qualityData['language'] ?? 'fr';
  int get totalLists => qualityData['total_lists'] ?? 0;
}

// ✅ NOUVEAU: État pour le breakdown des listes (propres vs partagées)
class ListsBreakdownLoaded extends AnalyticsState {
  final Map<String, dynamic> breakdownData;

  const ListsBreakdownLoaded(this.breakdownData);

  @override
  List<Object> get props => [breakdownData];

  Map<String, dynamic> get spendingBreakdown =>
      breakdownData['spending_breakdown'] ?? {};
  Map<String, dynamic> get listsStats => breakdownData['lists_stats'] ?? {};
  Map<String, dynamic> get formattedAmounts =>
      breakdownData['formatted_amounts'] ?? {};
  Map<String, dynamic> get periodInfo => breakdownData['period_info'] ?? {};
  String get language => breakdownData['language'] ?? 'fr';
  String get period => breakdownData['period'] ?? 'month';
}

// ✅ NOUVEAUX ÉTATS pour les rapports de listes partagées
class OwnerListReportLoaded extends AnalyticsState {
  final Map<String, dynamic> reportData;

  const OwnerListReportLoaded(this.reportData);

  @override
  List<Object> get props => [reportData];

  Map<String, dynamic> get listInfo => reportData['list_info'] ?? {};
  Map<String, dynamic> get financialSummary =>
      reportData['financial_summary'] ?? {};
  List<dynamic> get participants => reportData['participants'] ?? [];
  Map<String, dynamic> get spendingBreakdown =>
      reportData['spending_breakdown'] ?? {};
}

class ParticipantContributionLoaded extends AnalyticsState {
  final Map<String, dynamic> contributionData;

  const ParticipantContributionLoaded(this.contributionData);

  @override
  List<Object> get props => [contributionData];

  Map<String, dynamic> get myContributions =>
      contributionData['my_contributions'] ?? {};
  Map<String, dynamic> get listOverview =>
      contributionData['list_overview'] ?? {};
}

class TransparencyReportLoaded extends AnalyticsState {
  final Map<String, dynamic> transparencyData;

  const TransparencyReportLoaded(this.transparencyData);

  @override
  List<Object> get props => [transparencyData];

  Map<String, dynamic> get listInfo => transparencyData['list_info'] ?? {};
  Map<String, dynamic> get financialTransparency =>
      transparencyData['financial_transparency'] ?? {};
  Map<String, dynamic> get spendingDetails =>
      transparencyData['spending_details'] ?? {};
  Map<String, dynamic> get participantAccess =>
      transparencyData['participant_access'] ?? {};
}

class SharedBudgetReportLoaded extends AnalyticsState {
  final Map<String, dynamic> budgetData;

  const SharedBudgetReportLoaded(this.budgetData);

  @override
  List<Object> get props => [budgetData];

  Map<String, dynamic> get listInfo => budgetData['list_info'] ?? {};
  List<dynamic> get applicableBudgets => budgetData['applicable_budgets'] ?? [];
  Map<String, dynamic> get budgetImpactSummary =>
      budgetData['budget_impact_summary'] ?? {};
}

// ✅ État d'erreur avec plus de détails
class AnalyticsError extends AnalyticsState {
  final String message;
  final String? errorCode;
  final Map<String, dynamic>? details;

  const AnalyticsError(this.message, {this.errorCode, this.details});

  @override
  List<Object?> get props => [message, errorCode, details];

  bool get isNetworkError => errorCode?.contains('network') ?? false;
  bool get isServerError => errorCode?.contains('server') ?? false;
  bool get isAuthError => errorCode?.contains('auth') ?? false;
}

// ✅ NOUVEAU: État pour les données mises en cache avec timestamp
class AnalyticsCached extends AnalyticsState {
  final AnalyticsState cachedState;
  final DateTime cacheTime;
  final Duration cacheExpiry;

  const AnalyticsCached({
    required this.cachedState,
    required this.cacheTime,
    this.cacheExpiry = const Duration(minutes: 5),
  });

  @override
  List<Object> get props => [cachedState, cacheTime, cacheExpiry];

  bool get isExpired => DateTime.now().difference(cacheTime) > cacheExpiry;

  T? getCachedData<T extends AnalyticsState>() {
    return cachedState is T ? cachedState as T : null;
  }
}

// ✅ NOUVEAU: État pour les opérations en arrière-plan
class AnalyticsBackgroundLoading extends AnalyticsState {
  final AnalyticsState currentState;
  final String operation;

  const AnalyticsBackgroundLoading({
    required this.currentState,
    required this.operation,
  });

  @override
  List<Object> get props => [currentState, operation];
}

// ✅ Helpers pour identifier le type d'état facilement
extension AnalyticsStateExtensions on AnalyticsState {
  bool get isLoading =>
      this is AnalyticsLoading || this is AnalyticsBackgroundLoading;
  bool get hasError => this is AnalyticsError;
  bool get hasData =>
      this is! AnalyticsInitial &&
      this is! AnalyticsLoading &&
      this is! AnalyticsError;
  bool get isEmpty => this is AnalyticsInitial;

  // Getter pour récupérer les données communes
  String? get language {
    if (this is DashboardLoaded)
      return (this as DashboardLoaded).dashboardData['language'];
    if (this is MonthlySpendingLoaded)
      return (this as MonthlySpendingLoaded).language;
    if (this is DailySpendingLoaded)
      return (this as DailySpendingLoaded).language;
    if (this is WeeklySpendingLoaded)
      return (this as WeeklySpendingLoaded).language;
    if (this is YearlySpendingLoaded)
      return (this as YearlySpendingLoaded).language;
    if (this is SpendingCategoriesLoaded)
      return (this as SpendingCategoriesLoaded).language;
    if (this is TopProductsLoaded) return (this as TopProductsLoaded).language;
    if (this is PeriodComparisonLoaded)
      return (this as PeriodComparisonLoaded).language;
    return null;
  }

  String? get currency {
    if (this is DashboardLoaded)
      return (this as DashboardLoaded).dashboardData['currency'];
    if (this is MonthlySpendingLoaded)
      return (this as MonthlySpendingLoaded).monthlyData['currency'];
    if (this is DailySpendingLoaded)
      return (this as DailySpendingLoaded).dailyData['currency'];
    if (this is WeeklySpendingLoaded)
      return (this as WeeklySpendingLoaded).weeklyData['currency'];
    if (this is YearlySpendingLoaded)
      return (this as YearlySpendingLoaded).yearlyData['currency'];
    if (this is SpendingCategoriesLoaded)
      return (this as SpendingCategoriesLoaded).categoriesData['currency'];
    if (this is TopProductsLoaded)
      return (this as TopProductsLoaded).productsData['currency'];
    if (this is PeriodComparisonLoaded)
      return (this as PeriodComparisonLoaded).comparisonData['currency'];
    return null;
  }
}

class AnalyticsFiltersChanged extends AnalyticsState {
  final Map<String, dynamic> filters;
  final AnalyticsState previousState;

  const AnalyticsFiltersChanged({
    required this.filters,
    required this.previousState,
  });

  @override
  List<Object> get props => [filters, previousState];
}
