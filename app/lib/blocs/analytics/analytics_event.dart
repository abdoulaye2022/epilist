// blocs/analytics/analytics_event.dart
import 'package:equatable/equatable.dart';

abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboard extends AnalyticsEvent {
  final String? currencyCode;

  const LoadDashboard({this.currencyCode});

  @override
  List<Object?> get props => [currencyCode];
}

class LoadMonthlySpending extends AnalyticsEvent {
  final int months;
  final String? currencyCode;

  const LoadMonthlySpending({this.months = 12, this.currencyCode});

  @override
  List<Object?> get props => [months, currencyCode];
}

class LoadSpendingTrends extends AnalyticsEvent {
  final String period;
  final String? currencyCode;

  const LoadSpendingTrends({this.period = 'month', this.currencyCode});

  @override
  List<Object?> get props => [period, currencyCode];
}

class LoadSpendingCategories extends AnalyticsEvent {
  final String period;
  final int limit;
  final String? currencyCode;

  const LoadSpendingCategories({
    this.period = 'month',
    this.limit = 10,
    this.currencyCode,
  });

  @override
  List<Object?> get props => [period, limit, currencyCode];
}

class LoadTopProducts extends AnalyticsEvent {
  final String period;
  final String sortBy;
  final int limit;
  final String? currencyCode;

  const LoadTopProducts({
    this.period = 'month',
    this.sortBy = 'total_spent',
    this.limit = 10,
    this.currencyCode,
  });

  @override
  List<Object?> get props => [period, sortBy, limit, currencyCode];
}

class LoadPeriodComparison extends AnalyticsEvent {
  final String periodType;
  final String? currencyCode;

  const LoadPeriodComparison({this.periodType = 'month', this.currencyCode});

  @override
  List<Object?> get props => [periodType, currencyCode];
}
