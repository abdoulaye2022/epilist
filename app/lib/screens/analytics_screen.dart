// screens/analytics_screen.dart - VERSION SANS SÉLECTEUR DE DEVISE
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
    // Charger le dashboard initial (utilise la devise utilisateur par défaut)
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // ✅ SIMPLIFIÉ: Seulement le bouton d'actualisation
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: l10n.refresh,
            onPressed: _refreshCurrentTab,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          onTap: (index) {
            // Charger les données selon l'onglet sélectionné
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
            Tab(icon: const Icon(Icons.dashboard), text: l10n.overview),
            Tab(icon: const Icon(Icons.trending_up), text: l10n.trends),
            Tab(icon: const Icon(Icons.pie_chart), text: l10n.categories),
            Tab(icon: const Icon(Icons.star), text: l10n.topProducts),
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
                DashboardCard(data: state.dashboardData),
                const SizedBox(height: 16),
                ComparisonCard(
                  data: state.dashboardData['comparison_with_last_month'] ?? {},
                  currency: state.dashboardData['currency'] ?? 'CAD',
                ),
              ],
            ),
          );
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                l10n.noAnalyticsData,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _loadInitialData(),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.loadData),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ✅ ONGLET TENDANCES MISE À JOUR - Support des nouveaux états
  Widget _buildTrendsTab(BuildContext context, AppLocalizations l10n) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        if (state is AnalyticsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.green),
          );
        }

        // ✅ Gérer tous les types de données de tendances
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
          // ✅ Compatibilité avec l'ancien état générique
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
                PeriodChartCard(
                  data: chartData,
                  selectedCurrency: null, // ✅ Utilise la devise utilisateur
                ),
                const SizedBox(height: 16),
                // Vous pouvez ajouter d'autres widgets de tendances ici
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

  /// ✅ MÉTHODE UTILITAIRE MISE À JOUR pour extraire les données selon la période
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
              children: [CategoriesChartCard(data: state.categoriesData)],
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
                TopProductsCard(
                  data: state.productsData,
                  selectedCurrency: null, // ✅ Utilise la devise utilisateur
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            l10n.noDataAvailable,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.loadData),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
