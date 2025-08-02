// blocs/analytics/analytics_event.dart - VERSION AVEC FILTRAGE
import 'package:equatable/equatable.dart';

abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboard extends AnalyticsEvent {
  final String? currencyCode;
  final bool includeShared; // ✅ NOUVEAU: Inclure les listes partagées

  const LoadDashboard({
    this.currencyCode,
    this.includeShared = true, // Par défaut, inclure les listes partagées
  });

  @override
  List<Object?> get props => [currencyCode, includeShared];
}

class LoadMonthlySpending extends AnalyticsEvent {
  final int months;
  final String? currencyCode;
  final bool includeShared; // ✅ NOUVEAU

  const LoadMonthlySpending({
    this.months = 12,
    this.currencyCode,
    this.includeShared = true,
  });

  @override
  List<Object?> get props => [months, currencyCode, includeShared];
}

class LoadSpendingTrends extends AnalyticsEvent {
  final String period;
  final String? currencyCode;
  final bool includeShared; // ✅ NOUVEAU

  const LoadSpendingTrends({
    this.period = 'month',
    this.currencyCode,
    this.includeShared = true,
  });

  @override
  List<Object?> get props => [period, currencyCode, includeShared];
}

class LoadSpendingCategories extends AnalyticsEvent {
  final String period;
  final int limit;
  final String? currencyCode;
  final bool includeShared; // ✅ NOUVEAU

  const LoadSpendingCategories({
    this.period = 'month',
    this.limit = 10,
    this.currencyCode,
    this.includeShared = true,
  });

  @override
  List<Object?> get props => [period, limit, currencyCode, includeShared];
}

class LoadTopProducts extends AnalyticsEvent {
  final String period;
  final String sortBy;
  final int limit;
  final String? currencyCode;
  final bool includeShared; // ✅ NOUVEAU

  const LoadTopProducts({
    this.period = 'month',
    this.sortBy = 'total_spent',
    this.limit = 10,
    this.currencyCode,
    this.includeShared = true,
  });

  @override
  List<Object?> get props => [
    period,
    sortBy,
    limit,
    currencyCode,
    includeShared,
  ];
}

class LoadPeriodComparison extends AnalyticsEvent {
  final String periodType;
  final String? currencyCode;
  final bool includeShared; // ✅ NOUVEAU

  const LoadPeriodComparison({
    this.periodType = 'month',
    this.currencyCode,
    this.includeShared = true,
  });

  @override
  List<Object?> get props => [periodType, currencyCode, includeShared];
}

class ChangeTopProductsSort extends AnalyticsEvent {
  final String sortBy;
  final String? period;
  final int? limit;
  final String? currencyCode;
  final bool includeShared; // ✅ NOUVEAU

  const ChangeTopProductsSort({
    required this.sortBy,
    this.period,
    this.limit,
    this.currencyCode,
    this.includeShared = true,
  });

  @override
  List<Object?> get props => [
    sortBy,
    period,
    limit,
    currencyCode,
    includeShared,
  ];
}

class LoadDailySpending extends AnalyticsEvent {
  final int days;
  final String? currencyCode;
  final bool includeShared; // ✅ NOUVEAU

  const LoadDailySpending({
    this.days = 30,
    this.currencyCode,
    this.includeShared = true,
  });

  @override
  List<Object?> get props => [days, currencyCode, includeShared];
}

class LoadWeeklySpending extends AnalyticsEvent {
  final int weeks;
  final String? currencyCode;
  final bool includeShared; // ✅ NOUVEAU

  const LoadWeeklySpending({
    this.weeks = 12,
    this.currencyCode,
    this.includeShared = true,
  });

  @override
  List<Object?> get props => [weeks, currencyCode, includeShared];
}

class LoadYearlySpending extends AnalyticsEvent {
  final int years;
  final String? currencyCode;
  final bool includeShared; // ✅ NOUVEAU

  const LoadYearlySpending({
    this.years = 5,
    this.currencyCode,
    this.includeShared = true,
  });

  @override
  List<Object?> get props => [years, currencyCode, includeShared];
}

// ✅ NOUVEAUX ÉVÉNEMENTS pour le contrôle global du filtrage
class ToggleSharedListsFilter extends AnalyticsEvent {
  final bool includeShared;

  const ToggleSharedListsFilter({required this.includeShared});

  @override
  List<Object?> get props => [includeShared];
}

class RefreshAnalyticsWithFilter extends AnalyticsEvent {
  final bool includeShared;
  final String? currencyCode;

  const RefreshAnalyticsWithFilter({
    required this.includeShared,
    this.currencyCode,
  });

  @override
  List<Object?> get props => [includeShared, currencyCode];
}
