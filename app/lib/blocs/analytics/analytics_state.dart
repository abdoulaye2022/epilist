// blocs/analytics/analytics_state.dart - VERSION MISE À JOUR AVEC NOUVEAUX ÉTATS
import 'package:equatable/equatable.dart';

abstract class AnalyticsState extends Equatable {
  const AnalyticsState();

  @override
  List<Object?> get props => [];
}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {}

class DashboardLoaded extends AnalyticsState {
  final Map<String, dynamic> dashboardData;

  const DashboardLoaded(this.dashboardData);

  @override
  List<Object> get props => [dashboardData];
}

class MonthlySpendingLoaded extends AnalyticsState {
  final Map<String, dynamic> monthlyData;

  const MonthlySpendingLoaded(this.monthlyData);

  @override
  List<Object> get props => [monthlyData];
}

/// ✅ NOUVEAU: État pour les dépenses quotidiennes
class DailySpendingLoaded extends AnalyticsState {
  final Map<String, dynamic> dailyData;

  const DailySpendingLoaded(this.dailyData);

  @override
  List<Object> get props => [dailyData];
}

/// ✅ NOUVEAU: État pour les dépenses hebdomadaires
class WeeklySpendingLoaded extends AnalyticsState {
  final Map<String, dynamic> weeklyData;

  const WeeklySpendingLoaded(this.weeklyData);

  @override
  List<Object> get props => [weeklyData];
}

/// ✅ NOUVEAU: État pour les dépenses annuelles
class YearlySpendingLoaded extends AnalyticsState {
  final Map<String, dynamic> yearlyData;

  const YearlySpendingLoaded(this.yearlyData);

  @override
  List<Object> get props => [yearlyData];
}

/// ✅ CONSERVÉ: État générique pour les tendances (compatibilité)
class SpendingTrendsLoaded extends AnalyticsState {
  final Map<String, dynamic> trendsData;

  const SpendingTrendsLoaded(this.trendsData);

  @override
  List<Object> get props => [trendsData];
}

class SpendingCategoriesLoaded extends AnalyticsState {
  final Map<String, dynamic> categoriesData;

  const SpendingCategoriesLoaded(this.categoriesData);

  @override
  List<Object> get props => [categoriesData];
}

class TopProductsLoaded extends AnalyticsState {
  final Map<String, dynamic> productsData;

  const TopProductsLoaded(this.productsData);

  @override
  List<Object> get props => [productsData];
}

class PeriodComparisonLoaded extends AnalyticsState {
  final Map<String, dynamic> comparisonData;

  const PeriodComparisonLoaded(this.comparisonData);

  @override
  List<Object> get props => [comparisonData];
}

class AnalyticsError extends AnalyticsState {
  final String message;

  const AnalyticsError(this.message);

  @override
  List<Object> get props => [message];
}
