// screens/budget_screen.dart
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        // ✅ STYLE ANALYTICS - Fond vert avec texte blanc
        title: Text(
          l10n.budgets,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green[600], // ✅ Fond vert comme Analytics
        foregroundColor: Colors.white, // ✅ Texte blanc
        elevation: 0, // ✅ Pas d'ombre comme Analytics
        actions: [
          // ✅ Icône de filtres avec couleur blanche
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color:
                  _showFilters
                      ? Colors.white
                      : Colors.white70, // ✅ Couleurs blanches
            ),
            tooltip: _showFilters ? l10n.hideFilters : l10n.showFilters,
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          // ✅ Menu popup avec icône blanche
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ), // ✅ Icône blanche
            tooltip: l10n.moreOptions,
            onSelected: (value) => _handleMenuAction(value, context),
            // ✅ Style du menu popup adapté
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
        ],
        // ✅ TabBar avec style blanc comme Analytics
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white, // ✅ Onglet sélectionné en blanc
          unselectedLabelColor:
              Colors.white70, // ✅ Onglets non sélectionnés en blanc transparent
          indicatorColor: Colors.white, // ✅ Indicateur blanc
          indicatorWeight: 3, // ✅ Épaisseur comme Analytics
          tabs: [
            Tab(
              icon: const Icon(
                Icons.dashboard,
              ), // ✅ Ajout d'icônes comme Analytics
              text: l10n.overview,
            ),
            Tab(
              icon: const Icon(Icons.account_balance_wallet),
              text: l10n.active,
            ),
            Tab(icon: const Icon(Icons.warning), text: l10n.alerts),
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
            // ✅ Filtres avec style adapté (fond blanc pour contraster avec AppBar verte)
            if (_showFilters)
              Container(
                color: Colors.white,
                child: filters.BudgetFilters(
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
    // Vérifier s'il y a des filtres actifs
    final hasFilters = _hasActiveFilters(state);

    if (hasFilters) {
      return _buildEmptyFilteredState(l10n);
    } else {
      return _buildEmptyState(l10n);
    }
  }

  // Méthode helper pour vérifier les filtres actifs
  bool _hasActiveFilters(BudgetLoaded state) {
    // Cette méthode devra être adaptée selon votre implémentation BLoC
    // Exemple d'implémentation possible :
    return state.hasActiveFilters ?? false;
  }

  Widget _buildErrorState(String message, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              overflow: TextOverflow.ellipsis, // ✅ CORRECTION OVERFLOW
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis, // ✅ CORRECTION OVERFLOW
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<BudgetBloc>().add(const LoadBudgets());
              },
              icon: const Icon(Icons.refresh),
              label: Text(
                l10n.retry,
                overflow: TextOverflow.ellipsis, // ✅ CORRECTION OVERFLOW
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
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
            return _buildContextualEmptyState(
              state,
              l10n,
            ); // ✅ Utilise la nouvelle méthode
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<BudgetBloc>().add(const RefreshBudgets());
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics:
                  const AlwaysScrollableScrollPhysics(), // ✅ Pour le RefreshIndicator
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 64,
                color: Colors.orange[300],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noResultsFound, // Ajoutez cette clé de localisation
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis, // ✅ CORRECTION OVERFLOW
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tryAdjustingFilters, // Ajoutez cette clé de localisation
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis, // ✅ CORRECTION OVERFLOW
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Effacer tous les filtres
                    context.read<BudgetBloc>().add(FilterBudgets());
                    setState(() {
                      _showFilters = false;
                    });
                  },
                  icon: const Icon(Icons.clear_all),
                  label: Text(l10n.clearFilters),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _showCreateBudgetDialog(context),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.createBudget),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green[600],
                    side: BorderSide(color: Colors.green[600]!),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
            // Vérifier s'il y a des filtres actifs
            final hasFilters = _hasActiveFilters(state);
            if (hasFilters) {
              return _buildEmptyFilteredState(l10n); // ✅ État vide avec filtres
            } else {
              return _buildEmptyActiveState(l10n); // ✅ État vide normal
            }
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<BudgetBloc>().add(const RefreshBudgets());
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              physics:
                  const AlwaysScrollableScrollPhysics(), // ✅ Pour le RefreshIndicator
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
              physics:
                  const AlwaysScrollableScrollPhysics(), // ✅ Pour le RefreshIndicator
              itemCount: alertBudgets.length,
              itemBuilder: (context, index) {
                final budget = alertBudgets[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: alerts.BudgetAlertsWidget(
                    budget: budget,
                    // ✅ SUPPRESSION du paramètre onTap qui n'existe plus
                    onDismiss: () {
                      // Optionnel: logique pour masquer cette alerte
                      // Par exemple, marquer comme "vue" ou la cacher temporairement
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

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.recentBudgets,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (budgets.length > 5)
              TextButton(
                onPressed: () => _tabController.animateTo(1),
                child: Text(l10n.viewAll),
              ),
          ],
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet,
                size: 64,
                color: Colors.green[300],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noBudgetsYet,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.createFirstBudgetDescription,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCreateBudgetDialog(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.createBudget),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyActiveState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              l10n.noActiveBudgets,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.createActiveBudgetDescription,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAlertsState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 64,
                color: Colors.green[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noBudgetAlerts,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.allBudgetsOnTrack,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Actions methods
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
                  Navigator.pop(
                    dialogContext,
                  ); // Fermer le dialog en cas de succès
                } else if (state is BudgetError) {
                  Navigator.pop(
                    dialogContext,
                  ); // Fermer le dialog en cas d'erreur
                  // L'erreur sera gérée par le BlocListener principal
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
                  Navigator.pop(
                    dialogContext,
                  ); // Fermer le dialog en cas de succès
                } else if (state is BudgetError) {
                  Navigator.pop(
                    dialogContext,
                  ); // Fermer le dialog en cas d'erreur
                  // L'erreur sera gérée par le BlocListener principal
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
                  Navigator.pop(
                    dialogContext,
                  ); // Fermer le dialog en cas de succès
                } else if (state is BudgetError) {
                  Navigator.pop(
                    dialogContext,
                  ); // Fermer le dialog en cas d'erreur
                  // L'erreur sera gérée par le BlocListener principal
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
    // TODO: Implémenter la navigation vers les détails du budget
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (context) => BudgetDetailScreen(budget: budget),
    // ));
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
                  Navigator.pop(
                    dialogContext,
                  ); // Fermer le dialog en cas de succès
                } else if (state is BudgetError) {
                  Navigator.pop(
                    dialogContext,
                  ); // Fermer le dialog en cas d'erreur
                  // L'erreur sera gérée par le BlocListener principal
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
