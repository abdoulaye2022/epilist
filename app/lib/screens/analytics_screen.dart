// screens/analytics_screen.dart - Analytiques : une page sobre, sections
// commutées par chips (même langage que la page Budgets). Le bloc ne porte
// qu'un jeu de données à la fois : chaque section charge à la sélection.
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/blocs/analytics/analytics_event.dart';
import 'package:epilist/blocs/analytics/analytics_state.dart';
import 'package:epilist/widgets/analytics/period_chart_card.dart';
import 'package:epilist/widgets/connectivity/connected_action_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/analytics/analytics_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/analytics/dashboard_card.dart';
import 'package:epilist/widgets/analytics/categories_chart_card.dart';
import 'package:epilist/widgets/analytics/top_products_card.dart';
import 'package:epilist/widgets/analytics/comparison_card.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';

enum _AnalyticsSection { overview, trends, categories, topProducts }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  _AnalyticsSection _section = _AnalyticsSection.overview;

  @override
  void initState() {
    super.initState();
    _load(_section);
  }

  void _load(_AnalyticsSection section) {
    final bloc = context.read<AnalyticsBloc>();
    switch (section) {
      case _AnalyticsSection.overview:
        bloc.add(const LoadDashboard());
        break;
      case _AnalyticsSection.trends:
        bloc.add(const LoadMonthlySpending());
        break;
      case _AnalyticsSection.categories:
        bloc.add(const LoadSpendingCategories());
        break;
      case _AnalyticsSection.topProducts:
        bloc.add(const LoadTopProducts());
        break;
    }
  }

  void _select(_AnalyticsSection section) {
    if (section == _section) return;
    setState(() => _section = section);
    _load(section);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.analytics),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: () => _load(_section),
          ),
        ],
      ),
      body: BlocListener<AnalyticsBloc, AnalyticsState>(
        listener: (context, state) {
          if (state is AnalyticsError) {
            SmartSnackBarManager.showErrorSnackBar(
              context,
              state.message,
              duration: const Duration(seconds: 3),
            );
          }
        },
        child: Column(
          children: [
            _buildSectionChips(l10n),
            Expanded(
              child: ConnectedRefreshIndicator(
                onRefresh: () async => _load(_section),
                child: BlocBuilder<AnalyticsBloc, AnalyticsState>(
                  builder: (context, state) => _buildBody(state, l10n),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionChips(AppLocalizations l10n) {
    final options = <(_AnalyticsSection, String)>[
      (_AnalyticsSection.overview, l10n.overview),
      (_AnalyticsSection.trends, l10n.trends),
      (_AnalyticsSection.categories, l10n.categories),
      (_AnalyticsSection.topProducts, l10n.topProducts),
    ];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final (value, label) = options[index];
          return ChoiceChip(
            label: Text(label),
            selected: _section == value,
            showCheckmark: false,
            onSelected: (_) => _select(value),
          );
        },
      ),
    );
  }

  Widget _buildBody(AnalyticsState state, AppLocalizations l10n) {
    if (state is AnalyticsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final content = _contentFor(state);
    if (content == null) {
      return _buildEmptyState(l10n);
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: content,
      ),
    );
  }

  /// Contenu de la section active, ou null si l'état du bloc ne correspond
  /// pas encore (chargement croisé entre sections).
  List<Widget>? _contentFor(AnalyticsState state) {
    Widget card(Widget child) => Card(child: child);

    switch (_section) {
      case _AnalyticsSection.overview:
        if (state is DashboardLoaded) {
          return [
            card(DashboardCard(data: state.dashboardData)),
            const SizedBox(height: AppSpacing.md),
            card(ComparisonCard(
              data: state.dashboardData['comparison_with_last_month'] ?? {},
            )),
          ];
        }
        return null;

      case _AnalyticsSection.trends:
        final chartData = _trendsData(state);
        if (chartData != null) {
          return [card(PeriodChartCard(data: chartData))];
        }
        return null;

      case _AnalyticsSection.categories:
        if (state is SpendingCategoriesLoaded) {
          return [card(CategoriesChartCard(data: state.categoriesData))];
        }
        return null;

      case _AnalyticsSection.topProducts:
        if (state is TopProductsLoaded) {
          return [card(TopProductsCard(data: state.productsData))];
        }
        return null;
    }
  }

  Map<String, dynamic>? _trendsData(AnalyticsState state) {
    if (state is MonthlySpendingLoaded) {
      return {
        'monthly_data': state.monthlyData['monthly_data'] ?? [],
        'summary': state.monthlyData['summary'] ?? {},
        'period': 'month',
      };
    }
    if (state is DailySpendingLoaded) {
      return {
        'daily_data': state.dailyData['daily_data'] ?? [],
        'summary': state.dailyData['summary'] ?? {},
        'period': 'day',
      };
    }
    if (state is WeeklySpendingLoaded) {
      return {
        'weekly_data': state.weeklyData['weekly_data'] ?? [],
        'summary': state.weeklyData['summary'] ?? {},
        'period': 'week',
      };
    }
    if (state is YearlySpendingLoaded) {
      return {
        'yearly_data': state.yearlyData['yearly_data'] ?? [],
        'summary': state.yearlyData['summary'] ?? {},
        'period': 'year',
      };
    }
    if (state is SpendingTrendsLoaded) {
      final trendsData = state.trendsData;
      final period = trendsData['period_type'] ?? 'month';
      final key = switch (period) {
        'day' => 'daily_data',
        'week' => 'weekly_data',
        'year' => 'yearly_data',
        _ => 'monthly_data',
      };
      return {
        'period_data': trendsData[key] ?? [],
        'summary': trendsData['summary'] ?? {},
        'period': period,
      };
    }
    return null;
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.18),
        Icon(Icons.insights_outlined, size: 64, color: Colors.grey[400]),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.noAnalyticsData,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Commencez à faire vos courses pour voir vos analyses',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: OutlinedButton.icon(
            onPressed: () => _load(_section),
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l10n.loadData),
          ),
        ),
      ],
    );
  }
}
