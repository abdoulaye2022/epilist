// screens/budget_screen.dart - VERSION CORRIGÉE AVEC DESIGN HARMONISÉ
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/budget/budget_bloc.dart';
import 'package:epilist/models/budget.dart';
import 'package:epilist/widgets/budget/budget_card.dart';
import 'package:epilist/widgets/budget/budget_summary_card.dart' as summary;
import 'package:epilist/widgets/budget/budget_filters.dart' as filters;
import 'package:epilist/widgets/budget/create_budget_dialog.dart';
import 'package:epilist/widgets/budget/budget_alerts_widget.dart' as alerts;
import 'package:epilist/widgets/connectivity/connected_action_widgets.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/budget/quick_budget_dialog.dart' as quick;
import 'package:epilist/screens/budget_details_screen.dart'; // ✅ Nouveau import

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Charger les budgets au démarrage
    context.read<BudgetBloc>().add(const LoadBudgets());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      // ✅ CORRECTION: Background gris clair comme HomeScreen
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        // ✅ CORRECTION: Style harmonisé avec HomeScreen (fond blanc)
        title: Text(
          l10n.budgets,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green[700], // ✅ Texte vert au lieu de blanc
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white, // ✅ Fond blanc comme HomeScreen
        foregroundColor: Colors.black, // ✅ Texte noir comme HomeScreen
        elevation: 0, // ✅ Pas d'ombre comme HomeScreen
        iconTheme: const IconThemeData(color: Colors.black), // ✅ Icônes noires
        actions: [
          // ✅ Icône de filtres avec couleur noire
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: _showFilters ? Colors.green[700] : Colors.black,
            ),
            tooltip: _showFilters ? l10n.hideFilters : l10n.showFilters,
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          // ✅ Menu popup avec style harmonisé
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.black, // ✅ Icône noire
            ),
            tooltip: l10n.moreOptions,
            onSelected: (value) => _handleMenuAction(value, context),
            color: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 20, color: Colors.green[600]),
                        const SizedBox(width: 8),
                        Text(l10n.refresh),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'quick_budget',
                    child: Row(
                      children: [
                        Icon(
                          Icons.flash_on,
                          size: 20,
                          color: Colors.orange[600],
                        ),
                        const SizedBox(width: 8),
                        Text(l10n.quickBudget),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'sort_by_name',
                    child: Row(
                      children: [
                        Icon(
                          Icons.sort_by_alpha,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(l10n.sortByName),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'sort_by_amount',
                    child: Row(
                      children: [
                        Icon(
                          Icons.monetization_on,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(l10n.sortByAmount),
                      ],
                    ),
                  ),
                ],
          ),
          const SizedBox(width: 8), // ✅ Espacement à droite comme HomeScreen
        ],
        // ✅ TabBar avec style harmonisé (texte noir sur fond blanc)
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green[700], // ✅ Onglet sélectionné en vert
          unselectedLabelColor:
              Colors.grey[600], // ✅ Onglets non sélectionnés en gris
          indicatorColor: Colors.green[700], // ✅ Indicateur vert
          indicatorWeight: 3,
          tabs: [
            Tab(
              icon: Icon(Icons.dashboard, color: Colors.green[600]),
              text: l10n.overview,
            ),
            Tab(
              icon: Icon(
                Icons.account_balance_wallet,
                color: Colors.green[600],
              ),
              text: l10n.active,
            ),
            Tab(
              icon: Icon(Icons.warning, color: Colors.orange[600]),
              text: l10n.alerts,
            ),
          ],
        ),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<BudgetBloc, BudgetState>(
            listener: (context, state) {
              if (state is BudgetError) {
                SmartSnackBarManager.showErrorSnackBar(
                  context,
                  state.message,
                  duration: const Duration(seconds: 4),
                );
              } else if (state is BudgetOperationSuccess) {
                SmartSnackBarManager.showSuccessSnackBar(
                  context,
                  state.message,
                  duration: const Duration(seconds: 2),
                );
              }
            },
          ),
        ],
        child: Column(
          children: [
            // ✅ Filtres avec style adapté (fond blanc)
            if (_showFilters)
              BlocBuilder<BudgetBloc, BudgetState>(
                builder: (context, state) {
                  // Récupérer les filtres actifs depuis le state
                  String? activeStatusFilter;
                  String? activePeriodFilter;
                  String? activeScopeFilter;
                  String? activeSortBy;
                  bool? activeSortAscending;

                  if (state is BudgetLoaded) {
                    activeStatusFilter = state.activeStatusFilter;
                    activePeriodFilter = state.activePeriodFilter;
                    activeScopeFilter = state.activeScopeFilter;
                    activeSortBy = state.activeSortBy;
                    activeSortAscending = state.activeSortAscending;
                  }

                  return Container(
                    color: Colors.white,
                    child: filters.BudgetFilters(
                      activeStatusFilter: activeStatusFilter,
                      activePeriodFilter: activePeriodFilter,
                      activeScopeFilter: activeScopeFilter,
                      activeSortBy: activeSortBy,
                      activeSortAscending: activeSortAscending,
                      onStatusFilterChanged: (value) {
                        context.read<BudgetBloc>().add(
                          FilterBudgets(statusFilter: value),
                        );
                      },
                      onPeriodFilterChanged: (value) {
                        context.read<BudgetBloc>().add(
                          FilterBudgets(periodFilter: value),
                        );
                      },
                      onScopeFilterChanged: (value) {
                        context.read<BudgetBloc>().add(
                          FilterBudgets(scopeFilter: value),
                        );
                      },
                      onSortChanged: (sortBy, ascending) {
                        context.read<BudgetBloc>().add(
                          SortBudgets(sortBy, ascending),
                        );
                      },
                      onClearFilters: () {
                        context.read<BudgetBloc>().add(FilterBudgets());
                      },
                    ),
                  );
                },
              ),

            // Contenu principal avec onglets
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(context, l10n),
                  _buildActiveBudgetsTab(context, l10n),
                  _buildAlertsTab(context, l10n),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ConnectedFloatingActionButton(
        onPressed: () => _showCreateBudgetDialog(context),
        backgroundColor: Colors.green[600],
        tooltip: l10n.createBudget,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildContextualEmptyState(BudgetLoaded state, AppLocalizations l10n) {
    final hasFilters = _hasActiveFilters(state);

    if (hasFilters) {
      return _buildEmptyFilteredState(l10n);
    } else {
      return _buildEmptyState(l10n);
    }
  }

  bool _hasActiveFilters(BudgetLoaded state) {
    return state.hasActiveFilters ?? false;
  }

  Widget _buildErrorState(String message, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ CORRECTION: Card avec fond blanc
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(
                      l10n.errorLoadingBudgets,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<BudgetBloc>().add(const LoadBudgets());
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.retry, overflow: TextOverflow.ellipsis),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, AppLocalizations l10n) {
    return BlocBuilder<BudgetBloc, BudgetState>(
      builder: (context, state) {
        if (state is BudgetLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.green),
          );
        }

        if (state is BudgetError) {
          return _buildErrorState(state.message, l10n);
        }

        if (state is BudgetLoaded) {
          if (state.budgets.isEmpty) {
            return _buildContextualEmptyState(state, l10n);
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<BudgetBloc>().add(const RefreshBudgets());
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carte de résumé
                  summary.BudgetSummaryCard(
                    totalBudgets: state.totalBudgets,
                    activeBudgets: state.activeBudgets,
                    exceededBudgets: state.exceededBudgets,
                    warningBudgets: state.warningBudgets,
                  ),

                  const SizedBox(height: 24),

                  // Actions rapides
                  _buildQuickActions(context, l10n),

                  const SizedBox(height: 24),

                  // Budgets récents
                  _buildRecentBudgetsSection(
                    state.budgets.take(5).toList(),
                    l10n,
                  ),
                ],
              ),
            ),
          );
        }

        return _buildEmptyState(l10n);
      },
    );
  }

  Widget _buildEmptyFilteredState(AppLocalizations l10n) {
    return Center(
      child: SingleChildScrollView(
        // ✅ CORRECTION OVERFLOW: Permettre le défilement
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          // ✅ CORRECTION OVERFLOW: Contraindre la hauteur minimale
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
                mainAxisSize: MainAxisSize.min, // ✅ CORRECTION OVERFLOW
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icône
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_off,
                      size: 48, // ✅ RÉDUIT pour éviter overflow
                      color: Colors.orange[300],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Titre
                  Text(
                    l10n.noResultsFound,
                    style: const TextStyle(
                      fontSize: 18, // ✅ RÉDUIT de 20 à 18
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    overflow:
                        TextOverflow.visible, // ✅ PERMETTRE LE RETOUR LIGNE
                    maxLines: 2,
                  ),

                  const SizedBox(height: 8),

                  // Description
                  Flexible(
                    // ✅ CORRECTION OVERFLOW: Flexible pour s'adapter
                    child: Text(
                      l10n.tryAdjustingFilters,
                      style: TextStyle(
                        fontSize: 13, // ✅ RÉDUIT de 14 à 13
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                      overflow:
                          TextOverflow.visible, // ✅ PERMETTRE LE RETOUR LIGNE
                      maxLines: 3,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Boutons - Version responsive
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // ✅ CORRECTION OVERFLOW: Layout adaptatif selon la largeur
                      if (constraints.maxWidth < 300) {
                        // Version verticale pour petits écrans
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  context.read<BudgetBloc>().add(
                                    FilterBudgets(),
                                  );
                                  setState(() {
                                    _showFilters = false;
                                  });
                                },
                                icon: const Icon(Icons.clear_all, size: 18),
                                label: Text(
                                  l10n.clearFilters,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed:
                                    () => _showCreateBudgetDialog(context),
                                icon: const Icon(Icons.add, size: 18),
                                label: Text(
                                  l10n.createBudget,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.green[600],
                                  side: BorderSide(color: Colors.green[600]!),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        // Version horizontale pour grands écrans
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              // ✅ CORRECTION OVERFLOW: Flexible au lieu d'Expanded
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  context.read<BudgetBloc>().add(
                                    FilterBudgets(),
                                  );
                                  setState(() {
                                    _showFilters = false;
                                  });
                                },
                                icon: const Icon(Icons.clear_all, size: 18),
                                label: Text(
                                  l10n.clearFilters,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              // ✅ CORRECTION OVERFLOW: Flexible au lieu d'Expanded
                              child: OutlinedButton.icon(
                                onPressed:
                                    () => _showCreateBudgetDialog(context),
                                icon: const Icon(Icons.add, size: 18),
                                label: Text(
                                  l10n.createBudget,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.green[600],
                                  side: BorderSide(color: Colors.green[600]!),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveBudgetsTab(BuildContext context, AppLocalizations l10n) {
    return BlocBuilder<BudgetBloc, BudgetState>(
      builder: (context, state) {
        if (state is BudgetLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.green),
          );
        }

        if (state is BudgetError) {
          return _buildErrorState(state.message, l10n);
        }

        if (state is BudgetLoaded) {
          final activeBudgets = state.currentBudgets;

          if (activeBudgets.isEmpty) {
            final hasFilters = _hasActiveFilters(state);
            if (hasFilters) {
              return _buildEmptyFilteredState(l10n);
            } else {
              return _buildEmptyActiveState(l10n);
            }
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<BudgetBloc>().add(const RefreshBudgets());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: activeBudgets.length,
              itemBuilder: (context, index) {
                final budget = activeBudgets[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BudgetCard(
                    budget: budget,
                    onTap: () => _openBudgetDetails(budget),
                    onEdit: () => _editBudget(budget),
                    onDelete: () => _deleteBudget(budget),
                    onToggleStatus: () => _toggleBudgetStatus(budget),
                  ),
                );
              },
            ),
          );
        }

        return _buildEmptyActiveState(l10n);
      },
    );
  }

  Widget _buildAlertsTab(BuildContext context, AppLocalizations l10n) {
    return BlocBuilder<BudgetBloc, BudgetState>(
      builder: (context, state) {
        if (state is BudgetLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.green),
          );
        }

        if (state is BudgetLoaded) {
          final alertBudgets =
              state.budgets.where((budget) => budget.shouldShowAlert).toList();

          if (alertBudgets.isEmpty) {
            return _buildNoAlertsState(l10n);
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<BudgetBloc>().add(const RefreshBudgets());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: alertBudgets.length,
              itemBuilder: (context, index) {
                final budget = alertBudgets[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: alerts.BudgetAlertsWidget(
                    budget: budget,
                    onDismiss: () {
                      // Optionnel: logique pour masquer cette alerte
                    },
                  ),
                );
              },
            ),
          );
        }

        return _buildNoAlertsState(l10n);
      },
    );
  }

  Widget _buildQuickActions(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickActions,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.flash_on,
                title: l10n.quickBudget,
                subtitle: l10n.createQuickBudget,
                color: Colors.orange[600]!,
                onTap: () => _showQuickBudgetDialog(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.trending_up,
                title: l10n.monthlyBudget,
                subtitle: l10n.createMonthlyBudget,
                color: Colors.blue[600]!,
                onTap: () => _createMonthlyBudget(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ✅ CORRECTION: Card avec fond blanc
  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.white, // ✅ Fond blanc
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentBudgetsSection(
    List<Budget> budgets,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ CORRECTION: Header avec fond blanc
        Card(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.recentBudgets,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (budgets.length > 5)
                  TextButton(
                    onPressed: () => _tabController.animateTo(1),
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    child: Text(
                      l10n.viewAll,
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...budgets.map(
          (budget) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: BudgetCard(
              budget: budget,
              compact: true,
              onTap: () => _openBudgetDetails(budget),
              onEdit: () => _editBudget(budget),
              onDelete: () => _deleteBudget(budget),
              onToggleStatus: () => _toggleBudgetStatus(budget),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: SingleChildScrollView(
        // ✅ CORRECTION OVERFLOW: Permettre le défilement
        padding: const EdgeInsets.all(16),
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
                      color: Colors.green[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      size: 48, // ✅ RÉDUIT pour éviter overflow
                      color: Colors.green[300],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    l10n.noBudgetsYet,
                    style: const TextStyle(
                      fontSize: 18, // ✅ RÉDUIT
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
                      l10n.createFirstBudgetDescription,
                      style: TextStyle(
                        fontSize: 13, // ✅ RÉDUIT
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                      maxLines: 3,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bouton responsive
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showCreateBudgetDialog(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(
                          l10n.createBudget,
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
      );
  }

  Widget _buildEmptyActiveState(AppLocalizations l10n) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.4,
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
                  Icon(
                    Icons.hourglass_empty,
                    size: 48, // ✅ RÉDUIT
                    color: Colors.grey[400],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    l10n.noActiveBudgets,
                    style: const TextStyle(
                      fontSize: 16, // ✅ RÉDUIT
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
                      l10n.createActiveBudgetDescription,
                      style: TextStyle(
                        fontSize: 13, // ✅ RÉDUIT
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                      maxLines: 3,
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

  Widget _buildNoAlertsState(AppLocalizations l10n) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.4,
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
                      color: Colors.green[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 48, // ✅ RÉDUIT
                      color: Colors.green[400],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    l10n.noBudgetAlerts,
                    style: const TextStyle(
                      fontSize: 16, // ✅ RÉDUIT
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
                      l10n.allBudgetsOnTrack,
                      style: TextStyle(
                        fontSize: 13, // ✅ RÉDUIT
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                      maxLines: 2,
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

  // Actions methods - IDENTIQUES AU CODE ORIGINAL
  void _handleMenuAction(String action, BuildContext context) {
    switch (action) {
      case 'refresh':
        context.read<BudgetBloc>().add(const RefreshBudgets());
        break;
      case 'quick_budget':
        _showQuickBudgetDialog(context);
        break;
      case 'sort_by_name':
        context.read<BudgetBloc>().add(const SortBudgets('name', true));
        break;
      case 'sort_by_amount':
        context.read<BudgetBloc>().add(const SortBudgets('amount', false));
        break;
    }
  }

  void _showCreateBudgetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<BudgetBloc>(),
            child: BlocListener<BudgetBloc, BudgetState>(
              listener: (context, state) {
                if (state is BudgetOperationSuccess) {
                  Navigator.pop(dialogContext);
                } else if (state is BudgetError) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const CreateBudgetDialog(),
            ),
          ),
    );
  }

  void _showQuickBudgetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<BudgetBloc>(),
            child: BlocListener<BudgetBloc, BudgetState>(
              listener: (context, state) {
                if (state is BudgetOperationSuccess) {
                  Navigator.pop(dialogContext);
                } else if (state is BudgetError) {
                  Navigator.pop(dialogContext);
                }
              },
              child: quick.QuickBudgetDialog(
                onCreateBudget: (type, amount, name, listId) {
                  context.read<BudgetBloc>().add(
                    CreateQuickBudget(
                      type: type,
                      amount: amount,
                      name: name,
                      listId: listId,
                    ),
                  );
                },
              ),
            ),
          ),
    );
  }

  void _createMonthlyBudget(BuildContext context) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0);

    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<BudgetBloc>(),
            child: BlocListener<BudgetBloc, BudgetState>(
              listener: (context, state) {
                if (state is BudgetOperationSuccess) {
                  Navigator.pop(dialogContext);
                } else if (state is BudgetError) {
                  Navigator.pop(dialogContext);
                }
              },
              child: CreateBudgetDialog(
                initialPeriodType: BudgetPeriodType.monthly,
                initialStartDate: startDate,
                initialEndDate: endDate,
              ),
            ),
          ),
    );
  }

  void _openBudgetDetails(Budget budget) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<BudgetBloc>(),
          child: BudgetDetailsScreen(budget: budget),
        ),
      ),
    ).then((_) {
      // Rafraîchir les budgets au retour
      context.read<BudgetBloc>().add(const RefreshBudgets());
    });
  }

  void _editBudget(Budget budget) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<BudgetBloc>(),
            child: BlocListener<BudgetBloc, BudgetState>(
              listener: (context, state) {
                if (state is BudgetOperationSuccess) {
                  Navigator.pop(dialogContext);
                } else if (state is BudgetError) {
                  Navigator.pop(dialogContext);
                }
              },
              child: CreateBudgetDialog(budgetToEdit: budget),
            ),
          ),
    );
  }

  void _deleteBudget(Budget budget) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: Colors.white, // ✅ Fond blanc pour les dialogs
            title: Text(l10n.deleteBudget),
            content: Text(l10n.deleteBudgetConfirmation(budget.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.read<BudgetBloc>().add(DeleteBudget(budget.id));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.delete),
              ),
            ],
          ),
    );
  }

  void _toggleBudgetStatus(Budget budget) {
    context.read<BudgetBloc>().add(
      ToggleBudgetStatus(budget.id, !budget.isActive),
    );
  }
}
