// screens/analytics_screen.dart
import 'package:epilist/blocs/analytics/analytics_event.dart';
import 'package:epilist/blocs/analytics/analytics_state.dart';
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
  String? _selectedCurrency;

  // Devises populaires disponibles
  final List<Map<String, String>> _availableCurrencies = [
    {'code': 'CAD', 'symbol': '\$', 'name': 'Dollar Canadien'},
    {'code': 'USD', 'symbol': '\$', 'name': 'Dollar Américain'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'Livre Sterling'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Yen Japonais'},
  ];

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
    // Charger le dashboard initial
    context.read<AnalyticsBloc>().add(
      LoadDashboard(currencyCode: _selectedCurrency),
    );
  }

  void _refreshCurrentTab() {
    switch (_tabController.index) {
      case 0:
        context.read<AnalyticsBloc>().add(
          LoadDashboard(currencyCode: _selectedCurrency),
        );
        break;
      case 1:
        context.read<AnalyticsBloc>().add(
          LoadMonthlySpending(currencyCode: _selectedCurrency),
        );
        break;
      case 2:
        context.read<AnalyticsBloc>().add(
          LoadSpendingCategories(currencyCode: _selectedCurrency),
        );
        break;
      case 3:
        context.read<AnalyticsBloc>().add(
          LoadTopProducts(currencyCode: _selectedCurrency),
        );
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
          // ✅ CORRECTION: Sélecteur de devise simplifié sans CurrencyBloc
          PopupMenuButton<String>(
            icon: const Icon(Icons.currency_exchange, color: Colors.white),
            tooltip: 'Choisir la devise',
            onSelected: (currency) {
              setState(() {
                _selectedCurrency = currency;
              });
              _refreshCurrentTab();

              // Afficher un snackbar de confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    currency == null
                        ? 'Devise utilisateur sélectionnée'
                        : 'Devise changée vers $currency',
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green[600],
                ),
              );
            },
            itemBuilder:
                (context) => [
                  // Option devise utilisateur
                  PopupMenuItem<String>(
                    value: null,
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color:
                              _selectedCurrency == null
                                  ? Colors.green[600]
                                  : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.userCurrency,
                              style: TextStyle(
                                fontWeight:
                                    _selectedCurrency == null
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                color:
                                    _selectedCurrency == null
                                        ? Colors.green[600]
                                        : Colors.black87,
                              ),
                            ),
                            Text(
                              'Devise par défaut',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (_selectedCurrency == null)
                          Icon(Icons.check, color: Colors.green[600], size: 18),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),

                  // Devises disponibles
                  ..._availableCurrencies.map((currency) {
                    final isSelected = _selectedCurrency == currency['code'];
                    return PopupMenuItem<String>(
                      value: currency['code'],
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? Colors.green[100]
                                      : Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? Colors.green[600]!
                                        : Colors.grey[300]!,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                currency['symbol']!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isSelected
                                          ? Colors.green[600]
                                          : Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currency['code']!,
                                  style: TextStyle(
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                    color:
                                        isSelected
                                            ? Colors.green[600]
                                            : Colors.black87,
                                  ),
                                ),
                                Text(
                                  currency['name']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check,
                              color: Colors.green[600],
                              size: 18,
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
          ),

          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualiser',
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
                context.read<AnalyticsBloc>().add(
                  LoadDashboard(currencyCode: _selectedCurrency),
                );
                break;
              case 1:
                context.read<AnalyticsBloc>().add(
                  LoadMonthlySpending(currencyCode: _selectedCurrency),
                );
                break;
              case 2:
                context.read<AnalyticsBloc>().add(
                  LoadSpendingCategories(currencyCode: _selectedCurrency),
                );
                break;
              case 3:
                context.read<AnalyticsBloc>().add(
                  LoadTopProducts(currencyCode: _selectedCurrency),
                );
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

  Widget _buildTrendsTab(BuildContext context, AppLocalizations l10n) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        if (state is AnalyticsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.green),
          );
        }

        if (state is MonthlySpendingLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                MonthlyChartCard(data: state.monthlyData),
                const SizedBox(height: 16),
                // Ajouter d'autres widgets de tendances ici
              ],
            ),
          );
        }

        return _buildEmptyState(l10n, () {
          context.read<AnalyticsBloc>().add(
            LoadMonthlySpending(currencyCode: _selectedCurrency),
          );
        });
      },
    );
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
          context.read<AnalyticsBloc>().add(
            LoadSpendingCategories(currencyCode: _selectedCurrency),
          );
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
              children: [TopProductsCard(data: state.productsData)],
            ),
          );
        }

        return _buildEmptyState(l10n, () {
          context.read<AnalyticsBloc>().add(
            LoadTopProducts(currencyCode: _selectedCurrency),
          );
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
