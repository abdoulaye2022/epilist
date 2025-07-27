// blocs/analytics/analytics_state.dart
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
