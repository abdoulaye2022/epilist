// screens/analytics_screen.dart - VERSION CORRIGÉE
import 'package:epilist/blocs/analytics/analytics_event.dart';
import 'package:epilist/blocs/analytics/analytics_state.dart';
import 'package:epilist/widgets/analytics/period_chart_card.dart';
import 'package:epilist/widgets/connectivity/connected_action_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/analytics/analytics_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/connectivity/connectivity_wrapper.dart';
import 'package:epilist/widgets/analytics/dashboard_card.dart';
import 'package:epilist/widgets/analytics/monthly_chart_card.dart';
import 'package:epilist/widgets/analytics/categories_chart_card.dart';
import 'package:epilist/widgets/analytics/top_products_card.dart';
import 'package:epilist/widgets/analytics/comparison_card.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    context.read<AnalyticsBloc>().add(const LoadDashboard());
  }

  void _refreshCurrentTab() {
    switch (_tabController.index) {
      case 0:
        context.read<AnalyticsBloc>().add(const LoadDashboard());
        break;
      case 1:
        context.read<AnalyticsBloc>().add(const LoadMonthlySpending());
        break;
      case 2:
        context.read<AnalyticsBloc>().add(const LoadSpendingCategories());
        break;
      case 3:
        context.read<AnalyticsBloc>().add(const LoadTopProducts());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          l10n.analytics,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            tooltip: l10n.refresh,
            onPressed: _refreshCurrentTab,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green[700],
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.green[700],
          indicatorWeight: 3,
          onTap: (index) {
            switch (index) {
              case 0:
                context.read<AnalyticsBloc>().add(const LoadDashboard());
                break;
              case 1:
                context.read<AnalyticsBloc>().add(const LoadMonthlySpending());
                break;
              case 2:
                context.read<AnalyticsBloc>().add(
                  const LoadSpendingCategories(),
                );
                break;
              case 3:
                context.read<AnalyticsBloc>().add(const LoadTopProducts());
                break;
            }
          },
          tabs: [
            Tab(
              icon: Icon(Icons.dashboard, color: Colors.green[600]),
              text: l10n.overview,
            ),
            Tab(
              icon: Icon(Icons.trending_up, color: Colors.blue[600]),
              text: l10n.trends,
            ),
            Tab(
              icon: Icon(Icons.pie_chart, color: Colors.purple[600]),
              text: l10n.categories,
            ),
            Tab(
              icon: Icon(Icons.star, color: Colors.orange[600]),
              text: l10n.topProducts,
            ),
          ],
        ),
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
        child: ConnectedRefreshIndicator(
          onRefresh: () async => _refreshCurrentTab(),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(context, l10n),
              _buildTrendsTab(context, l10n),
              _buildCategoriesTab(context, l10n),
              _buildTopProductsTab(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, AppLocalizations l10n) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        if (state is AnalyticsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.green),
          );
        }

        if (state is DashboardLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DashboardCard(data: state.dashboardData),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  // ✅ CORRECTION: Suppression du paramètre currency
                  child: ComparisonCard(
                    data:
                        state.dashboardData['comparison_with_last_month'] ?? {},
                  ),
                ),
              ],
            ),
          );
        }

        return _buildEmptyState(l10n, () => _loadInitialData());
      },
    );
  }

  Widget _buildTrendsTab(BuildContext context, AppLocalizations l10n) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        if (state is AnalyticsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.green),
          );
        }

        Map<String, dynamic> chartData = {};

        if (state is MonthlySpendingLoaded) {
          chartData = {
            'monthly_data': state.monthlyData['monthly_data'] ?? [],
            'summary': state.monthlyData['summary'] ?? {},
            'period': 'month',
          };
        } else if (state is DailySpendingLoaded) {
          chartData = {
            'daily_data': state.dailyData['daily_data'] ?? [],
            'summary': state.dailyData['summary'] ?? {},
            'period': 'day',
          };
        } else if (state is WeeklySpendingLoaded) {
          chartData = {
            'weekly_data': state.weeklyData['weekly_data'] ?? [],
            'summary': state.weeklyData['summary'] ?? {},
            'period': 'week',
          };
        } else if (state is YearlySpendingLoaded) {
          chartData = {
            'yearly_data': state.yearlyData['yearly_data'] ?? [],
            'summary': state.yearlyData['summary'] ?? {},
            'period': 'year',
          };
        } else if (state is SpendingTrendsLoaded) {
          final trendsData = state.trendsData;
          final period = trendsData['period_type'] ?? 'month';

          chartData = {
            'period_data': _extractPeriodData(trendsData, period),
            'summary': trendsData['summary'] ?? {},
            'period': period,
          };
        }

        if (chartData.isNotEmpty) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  // ✅ CORRECTION: Suppression du paramètre selectedCurrency
                  child: PeriodChartCard(data: chartData),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        }

        return _buildEmptyState(l10n, () {
          context.read<AnalyticsBloc>().add(const LoadMonthlySpending());
        });
      },
    );
  }

  List<dynamic> _extractPeriodData(
    Map<String, dynamic> trendsData,
    String period,
  ) {
    switch (period) {
      case 'day':
        return trendsData['daily_data'] ?? [];
      case 'week':
        return trendsData['weekly_data'] ?? [];
      case 'year':
        return trendsData['yearly_data'] ?? [];
      case 'month':
      default:
        return trendsData['monthly_data'] ?? [];
    }
  }

  Widget _buildCategoriesTab(BuildContext context, AppLocalizations l10n) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        if (state is AnalyticsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.green),
          );
        }

        if (state is SpendingCategoriesLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CategoriesChartCard(data: state.categoriesData),
                ),
              ],
            ),
          );
        }

        return _buildEmptyState(l10n, () {
          context.read<AnalyticsBloc>().add(const LoadSpendingCategories());
        });
      },
    );
  }

  Widget _buildTopProductsTab(BuildContext context, AppLocalizations l10n) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        if (state is AnalyticsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.green),
          );
        }

        if (state is TopProductsLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  // ✅ CORRECTION: Suppression du paramètre selectedCurrency
                  child: TopProductsCard(data: state.productsData),
                ),
              ],
            ),
          );
        }

        return _buildEmptyState(l10n, () {
          context.read<AnalyticsBloc>().add(const LoadTopProducts());
        });
      },
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, VoidCallback onRetry) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: Card(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.analytics_outlined,
                      size: 48,
                      color: Colors.blue[300],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noAnalyticsData,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.visible,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Text(
                      'Commencez à faire vos courses pour voir vos analyses',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(
                          l10n.loadData,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
