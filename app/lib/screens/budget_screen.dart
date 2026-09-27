// screens/budget_screen.dart - VERSION CORRIGÉE AVEC DESIGN HARMONISÉ
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/budget/budget_bloc.dart';
import 'package:epilist/models/budget.dart';
import 'package:epilist/widgets/budget/budget_card.dart';
import 'package:epilist/widgets/budget/budget_summary_card.dart' as summary;
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

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les budgets au démarrage
    context.read<BudgetBloc>().add(const LoadBudgets());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.budgets),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_outlined),
            tooltip: l10n.quickBudget,
            onPressed: () => _handleMenuAction('quick_budget', context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
            onPressed: () =>
                context.read<BudgetBloc>().add(const RefreshBudgets()),
          ),
        ],
      ),
      body: BlocConsumer<BudgetBloc, BudgetState>(
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
        builder: (context, state) {
          if (state is BudgetLoading || state is BudgetInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BudgetError) {
            return _buildErrorState(state.message, l10n);
          }
          if (state is BudgetLoaded) {
            return Column(
              children: [
                if (state.summary != null &&
                    state.summary!.totalBudgets > 0)
                  _buildSummaryStrip(state.summary!, l10n),
                _buildStatusChips(state.activeStatusFilter, l10n),
                Expanded(child: _buildBudgetList(state, l10n)),
              ],
            );
          }
          return _buildEmptyState(l10n);
        },
      ),
      floatingActionButton: ConnectedFloatingActionButton(
        onPressed: () => _showCreateBudgetDialog(context),
        backgroundColor: AppColors.primary,
        tooltip: l10n.createBudget,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// Bandeau resume : trois chiffres sur UNE ligne, pas de grosses cartes.
  Widget _buildSummaryStrip(BudgetSummary summary, AppLocalizations l10n) {
    Widget cell(String label, Widget value) => Expanded(
          child: Column(
            children: [
              value,
              const SizedBox(height: 1),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      child: Row(
        children: [
          cell(
            l10n.budgeted,
            Text(
              summary.formattedTotalBudgeted,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(width: 1, height: 26, color: AppColors.border),
          cell(
            l10n.spent,
            Text(
              summary.formattedTotalSpent,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(width: 1, height: 26, color: AppColors.border),
          cell(
            l10n.remaining,
            FormattedAmount(
              amount: summary.totalBudgeted - summary.totalSpent,
              showCode: false,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: summary.totalSpent > summary.totalBudgeted
                    ? AppColors.error
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Filtres de statut : une rangee de chips, remplace onglets + panneau.
  Widget _buildStatusChips(String? active, AppLocalizations l10n) {
    final options = <(String, String)>[
      ('all', l10n.all),
      ('active', l10n.active),
      ('warning', l10n.alerts),
      ('exceeded', l10n.exceeded),
      ('expired', l10n.expired),
    ];
    final current = active ?? 'all';

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
          final selected = current == value;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) => context
                .read<BudgetBloc>()
                .add(FilterBudgets(statusFilter: value)),
          );
        },
      ),
    );
  }

  Widget _buildBudgetList(BudgetLoaded state, AppLocalizations l10n) {
    final budgets = state.budgets;
    if (budgets.isEmpty) {
      return _hasActiveFilters(state)
          ? _buildEmptyFilteredState(l10n)
          : _buildEmptyState(l10n);
    }
    return RefreshIndicator(
      onRefresh: () async =>
          context.read<BudgetBloc>().add(const RefreshBudgets()),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.md, 96),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: budgets.length,
        itemBuilder: (context, index) {
          final budget = budgets[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
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

  bool _hasActiveFilters(BudgetLoaded state) {
    return state.hasActiveFilters ?? false;
  }

  Widget _buildErrorState(String message, AppLocalizations l10n) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: TextStyle(color: AppColors.textSecondary),
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
                        backgroundColor: AppColors.primary,
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
                      color: AppColors.textPrimary,
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
                        color: AppColors.textSecondary,
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
                                },
                                icon: const Icon(Icons.clear_all, size: 18),
                                label: Text(
                                  l10n.clearFilters,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.warning,
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
                                  foregroundColor: AppColors.primary,
                                  side: BorderSide(color: AppColors.primary),
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
                                },
                                icon: const Icon(Icons.clear_all, size: 18),
                                label: Text(
                                  l10n.clearFilters,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.warning,
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
                                  foregroundColor: AppColors.primary,
                                  side: BorderSide(color: AppColors.primary),
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
                      color: AppColors.primaryLight,
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
                      color: AppColors.textPrimary,
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
                        color: AppColors.textSecondary,
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
                          backgroundColor: AppColors.primary,
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
                  backgroundColor: AppColors.error,
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
