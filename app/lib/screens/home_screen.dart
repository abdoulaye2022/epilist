// screens/home_screen.dart - VERSION PRODUCTION SANS TEST

import 'package:epilist/theme/app_theme.dart';

import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_state.dart';
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/screens/list_detail_screen.dart';
import 'package:epilist/screens/profil_screen.dart';
import 'package:epilist/screens/shopping_list_screen.dart';
import 'package:epilist/services/deep_link_handler.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/widgets/home/lists_section_header.dart';
import 'package:epilist/widgets/home/shopping_lists_content.dart';
import 'package:epilist/widgets/dialogs/create_list_dialog.dart';
import 'package:epilist/widgets/dialogs/delete_list_dialog.dart';
import 'package:epilist/widgets/dialogs/edit_list_dialog.dart';
import 'package:epilist/widgets/share_list_dialog.dart';
import 'package:epilist/widgets/shopping/leave_shared_list_dialog.dart';
import 'package:epilist/widgets/shopping/manage_shares_dialog.dart';
import 'package:epilist/widgets/connectivity/connected_action_widgets.dart';
import 'package:epilist/widgets/connectivity/connectivity_wrapper.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/main.dart' show routeObserver;
import 'package:epilist/models/budget.dart';
import 'package:intl/intl.dart';
import 'package:epilist/services/budget_service.dart';
import 'package:epilist/services/offline_storage_service.dart';
import 'package:epilist/services/space_service.dart';
import 'package:epilist/widgets/common/app_drawer.dart';
import 'package:epilist/widgets/dashboard/dashboard_widgets.dart';
import 'package:epilist/screens/budget_screen.dart';
import 'package:epilist/screens/stores_screen.dart';
import 'package:epilist/widgets/common/user_avatar.dart';
import 'package:epilist/widgets/common/offline_indicator.dart';
import 'package:epilist/utils/receipt_scan_flow.dart';
import 'package:epilist/services/app_version_service.dart';
import 'package:epilist/widgets/common/update_modal.dart';
import 'package:epilist/models/intelligence.dart';
import 'package:epilist/services/intelligence_service.dart';
import 'package:epilist/services/list_item_service.dart';
import 'package:epilist/screens/predictions_screen.dart';
import 'package:epilist/screens/meal_planner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';

// Portée : le processus entier — une seule vérification de version
// par lancement de l'app.
bool _versionCheckDone = false;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, RouteAware {
  // Variables pour contrôler les initialisations et éviter les redondances
  bool _deepLinkInitialized = false;
  bool _isResuming = false;

  // Donnees du tableau de bord (chargees en douceur, jamais bloquantes)
  List<Budget> _allBudgets = [];
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  // Intelligence : suggestions « À prévoir bientôt » + projection budget
  List<ProductPrediction> _predictions = [];
  BudgetForecast? _forecast;
  bool _predictionsEnabled = true;
  bool _forecastEnabled = true;

  /// Budget couvrant le mois sélectionné (les mensuels d'abord).
  Budget? get _monthBudget {
    final monthStart = _selectedMonth;
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);
    bool covers(Budget b) =>
        !b.startDate.isAfter(monthEnd) && !b.endDate.isBefore(monthStart);
    final candidates = _allBudgets.where((b) => b.isActive && covers(b)).toList()
      ..sort((a, b) {
        int rank(Budget x) => x.periodType == BudgetPeriodType.monthly ? 0 : 1;
        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : b.startDate.compareTo(a.startDate);
      });
    return candidates.isEmpty ? null : candidates.first;
  }
  // ✅ SUPPRIMÉ : bool _showNotificationTest = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _loadShoppingLists();
    _loadDashboardData();

    // Changement d'espace (Phase 2) : la carte budget et les listes
    // de l'accueil suivent l'espace actif.
    ActiveSpaceStore.current.addListener(_onSpaceChanged);

    // Initialisation des deep links
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDeepLinksOnce();

      // Filet de sécurité avatar/prénom : si l'état auth courant ne porte
      // pas d'utilisateur (ex. EmailConfirmationSuccess), on recharge le
      // profil depuis l'API pour peupler l'en-tête et le drawer.
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthSuccess && authState is! ProfileUpdated) {
        context.read<AuthBloc>().add(RefreshCurrentUser());
      }

      // Contrôle de version : une seule fois par lancement du processus
      // (naviguer puis revenir ne repose pas la question), après la
      // première image, sur un écran qui a du sens. Échec = silence.
      if (!_versionCheckDone && mounted) {
        _versionCheckDone = true;
        showUpdateModalIfNeeded(context, context.read<AppVersionService>());
      }
    });
  }

  /// Charge tous les budgets pour la carte du mois (le depense/restant de
  /// chaque budget est calcule par le serveur). Echec silencieux : le
  /// dashboard reste utilisable hors ligne ou sans budget.
  Future<void> _loadDashboardData() async {
    try {
      final budgets = await context.read<BudgetService>().getBudgets();
      if (!mounted) return;
      setState(() => _allBudgets = budgets);
      // Cache hors ligne : la carte budget du dashboard doit survivre
      // à un démarrage sans réseau.
      await OfflineStorageService.saveBudgets(budgets);
    } catch (_) {
      // Hors ligne : servir le cache plutôt qu'une carte vide.
      try {
        final cached = await OfflineStorageService.getBudgets();
        if (mounted && cached != null && cached.isNotEmpty) {
          setState(() => _allBudgets = cached);
        }
      } catch (_) {
        // pas de cache : la carte passe en invite
      }
    }
    _loadIntelligence();
  }

  /// Suggestions prédictives + projection budget (selon les réglages
  /// Intelligence EpiList). Échec silencieux : jamais bloquant.
  Future<void> _loadIntelligence() async {
    _predictionsEnabled =
        await IntelligenceSettings.get(IntelligenceSettings.keyPredictions);
    _forecastEnabled =
        await IntelligenceSettings.get(IntelligenceSettings.keyBudgetForecast);
    if (!mounted) return;
    final service = context.read<IntelligenceService>();

    if (_predictionsEnabled) {
      try {
        final predictions = await service.getPredictions(limit: 3);
        if (mounted) setState(() => _predictions = predictions);
      } catch (_) {}
    } else if (_predictions.isNotEmpty) {
      setState(() => _predictions = []);
    }

    if (_forecastEnabled) {
      try {
        final forecast = await service.getBudgetForecast();
        if (mounted) setState(() => _forecast = forecast);
      } catch (_) {}
    } else if (_forecast != null) {
      setState(() => _forecast = null);
    }
  }

  /// Feedback sur une suggestion du dashboard (ajout, snooze…).
  Future<void> _predictionAction(ProductPrediction p, String action) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      if (action == 'added') {
        final state = context.read<ShoppingListBloc>().state;
        final lists =
            state is ShoppingListLoaded ? state.lists : <ShoppingList>[];
        if (lists.isNotEmpty) {
          await context.read<ListItemService>().forceAddListItem(
                listId: lists.first.id,
                productName: p.productName,
                quantity: p.avgQuantity.round().clamp(1, 99),
              );
          if (mounted) {
            SmartSnackBarManager.showSuccessSnackBar(
                context, l10n.predictionAdded(p.productName));
          }
        }
      }
      if (!mounted) return;
      await context
          .read<IntelligenceService>()
          .sendPredictionFeedback(p.productName, action);
      if (mounted) setState(() => _predictions.remove(p));
    } catch (_) {}
  }

  /// Sélecteur de mois de la carte budget : 12 derniers mois + suivant.
  void _pickBudgetMonth() {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime(DateTime.now().year, DateTime.now().month);
    final months = [
      for (var i = 1; i >= -11; i--) DateTime(now.year, now.month + i),
    ];

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.pickMonth,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: months.map((m) {
                  var label = DateFormat('MMMM yyyy', locale).format(m);
                  label = label[0].toUpperCase() + label.substring(1);
                  final selected = m.year == _selectedMonth.year &&
                      m.month == _selectedMonth.month;
                  return ListTile(
                    leading: Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 20,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textDisabled,
                    ),
                    title: Text(label),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      setState(() => _selectedMonth = m);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildGreeting(AppLocalizations l10n) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state is AuthSuccess
            ? state.user
            : (state is ProfileUpdated ? state.user : null);
        final name = user?.firstName ?? '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name.isEmpty ? l10n.helloGreeting : '${l10n.helloGreeting.replaceAll(' 👋', '')} $name 👋',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.readyToShop,
              style: const TextStyle(
                fontSize: 14.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Carrousel horizontal des listes recentes ; retombe sur la section
  /// complete (etats vide / erreur / chargement) quand il n'y a rien.
  Widget _buildListsCarousel(BuildContext context) {
    return BlocBuilder<ShoppingListBloc, ShoppingListState>(
      builder: (context, state) {
        if (state is ShoppingListLoaded && state.lists.isNotEmpty) {
          final lists = state.lists.take(6).toList();
          return SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: lists.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.sm + 4),
              itemBuilder: (context, index) => DashboardListCard(
                list: lists[index],
                onTap: () => _openListDetails(context, lists[index]),
              ),
            ),
          );
        }
        return _buildShoppingListsSection(context);
      },
    );
  }

  /// Ouvre la liste la plus recente avec l'action demandee (ajout, voix).
  /// Liste cible des actions rapides : directe s'il n'y en a qu'une,
  /// sinon l'utilisateur choisit dans une feuille. Null = annulé/aucune.
  Future<ShoppingList?> _pickTargetList() async {
    final l10n = AppLocalizations.of(context)!;
    final state = context.read<ShoppingListBloc>().state;
    final lists = state is ShoppingListLoaded ? state.lists : <ShoppingList>[];

    if (lists.isEmpty) {
      SmartSnackBarManager.showInfoSnackBar(context, l10n.noListYet);
      _showCreateListDialog(context);
      return null;
    }
    if (lists.length == 1) return lists.first;

    return showModalBottomSheet<ShoppingList>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
              child: Text(
                l10n.pickListTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: lists
                    .map((list) => ListTile(
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm + 2),
                            ),
                            child: const Icon(Icons.shopping_basket_outlined,
                                size: 20, color: AppColors.primaryDark),
                          ),
                          title: Text(list.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          onTap: () =>
                              Navigator.of(sheetContext).pop(list),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Future<void> _openRecentListWith(ListDetailAction action) async {
    final list = await _pickTargetList();
    if (list == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListDetailScreen(
          shoppingList: list,
          initialAction: action,
        ),
      ),
    ).then((_) => _loadShoppingLists());
  }

  /// Scanne un reçu et le rattache à la liste la plus récente.
  Future<void> _scanReceipt() async {
    final list = await _pickTargetList();
    if (list == null || !mounted) return;
    startReceiptScan(context, listId: list.id)
        .then((_) => _loadDashboardData());
  }

  /// Ouvre l'ecran Budgets et rafraichit la carte au retour
  /// (creation/modification d'un budget).
  void _openBudgets() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BudgetScreen()),
    ).then((_) => _loadDashboardData());
  }

  void _loadShoppingLists() {
    context.read<ShoppingListBloc>().add(LoadShoppingLists());
  }

  // Méthode pour initialiser les deep links une seule fois
  void _initializeDeepLinksOnce() {
    if (!_deepLinkInitialized && mounted) {
      // debugPrint('🚀 Initialisation unique des deep links depuis HomeScreen');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          DeepLinkHandler.updateContext(context);
          _deepLinkInitialized = true;
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
    if (_deepLinkInitialized && !_isResuming && mounted) {
      DeepLinkHandler.updateContext(context);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isResuming = true;
      _loadShoppingLists();

      if (_deepLinkInitialized) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted && _isResuming) {
            // debugPrint('📱 App resumed - mise à jour contexte deep links');
            DeepLinkHandler.updateContext(context);
            _isResuming = false;
          }
        });
      }
    } else if (state == AppLifecycleState.paused) {
      _isResuming = false;
    }
  }

  /// Appele quand on REVIENT sur le dashboard (retour d'un ecran pousse,
  /// y compris via le drawer) : la carte budget et les listes se
  /// rafraichissent.
  @override
  void didPopNext() {
    _loadDashboardData();
    _loadShoppingLists();
  }

  @override
  void dispose() {
    ActiveSpaceStore.current.removeListener(_onSpaceChanged);
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onSpaceChanged() {
    if (!mounted) return;
    _loadShoppingLists();
    _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      // Navigation centralisée dans le drawer : la barre reste minimale.
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('EpiList'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final user = state is AuthSuccess
                    ? state.user
                    : (state is ProfileUpdated ? state.user : null);
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                  child: UserAvatar(user: user, radius: 17),
                );
              },
            ),
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<ShoppingListBloc, ShoppingListState>(
            listener: (context, state) {
              if (state is ShoppingListError) {
                SmartSnackBarManager.showErrorSnackBar(
                  context,
                  state.message,
                  duration: const Duration(seconds: 3),
                );
              } else if (state is ShoppingListOperationSuccess) {
                SmartSnackBarManager.showSuccessSnackBar(
                  context,
                  state.message,
                  duration: const Duration(seconds: 2),
                );
              }
            },
          ),
          BlocListener<SharedListBloc, SharedListState>(
            listener: (context, state) {
              if (state is SharedListError) {
                SmartSnackBarManager.showErrorSnackBar(context, state.message);
              } else if (state is ShareOperationSuccess) {
                SmartSnackBarManager.showInfoSnackBar(
                  context,
                  state.message,
                  duration: const Duration(seconds: 2),
                );
                _loadShoppingLists();
              }
            },
          ),
        ],
        child: ConnectedRefreshIndicator(
          onRefresh: () async => _loadShoppingLists(),
          child: Column(
            children: [
              // Indicateur de mode hors ligne avec actions en attente
              const OfflineIndicator(),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGreeting(l10n),
                      const SizedBox(height: AppSpacing.md),
                      if (_monthBudget != null)
                        BudgetMonthCard(
                          budget: _monthBudget!,
                          onSeeDetail: _openBudgets,
                          selectedMonth: _selectedMonth,
                          onPickMonth: _pickBudgetMonth,
                        )
                      else
                        BudgetCtaCard(
                          onCreate: _openBudgets,
                          selectedMonth: _selectedMonth,
                          onPickMonth: _pickBudgetMonth,
                        ),
                      if (_forecast != null && _forecast!.hasBudget)
                        _buildForecastLine(l10n),
                      if (_predictions.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _buildPredictionsSection(l10n),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      ListsSectionHeader(
                        onViewAll: () => _goToAllLists(context),
                        onCreateNew: () => _showCreateListDialog(context),
                      ),
                      const SizedBox(height: AppSpacing.sm + 4),
                      _buildListsCarousel(context),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          QuickActionButton(
                            icon: Icons.add,
                            label: l10n.quickAddItem,
                            sublabel: l10n.toChosenList,
                            onTap: () => _openRecentListWith(
                                ListDetailAction.addItem),
                          ),
                          QuickActionButton(
                            icon: Icons.mic_none_rounded,
                            label: l10n.quickVoice,
                            sublabel: l10n.toChosenList,
                            onTap: () => _openRecentListWith(
                                ListDetailAction.voiceItem),
                          ),
                          QuickActionButton(
                            icon: Icons.receipt_long_outlined,
                            label: l10n.quickScan,
                            sublabel: l10n.aReceipt,
                            onTap: _scanReceipt,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          // Analytiques est desormais un onglet du bas :
                          // la tuile devient le planificateur de repas.
                          DashboardTile(
                            icon: Icons.restaurant_menu_outlined,
                            title: l10n.mealPlannerTitle,
                            subtitle: l10n.mealPlannerSubtitle,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const MealPlannerScreen()),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm + 4),
                          DashboardTile(
                            icon: Icons.storefront_outlined,
                            title: l10n.myStores,
                            subtitle: l10n.aisleOrder,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const StoresScreen()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // La création de liste passe par le bouton + central du MainShell.
    );
  }

  /// Ligne de projection sous la carte budget (§24) : rythme actuel,
  /// budget/jour recommandé. Discrète, jamais culpabilisante.
  Widget _buildForecastLine(AppLocalizations l10n) {
    final f = _forecast!;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  f.projectionGap > 0
                      ? Icons.trending_up
                      : Icons.trending_flat,
                  size: 16,
                  color: f.projectionGap > 0
                      ? AppColors.warning
                      : AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${l10n.atYourCurrentPace('${f.projection.toStringAsFixed(0)} \$')} · ${l10n.daysLeftShort(f.daysLeft)}',
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            if (f.daysLeft > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 24),
                child: Text(
                  l10n.perDayToStayOnBudget(
                      '${f.perDayRemaining.toStringAsFixed(2)} \$'),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Section « À prévoir bientôt » : 3 suggestions max + voir tout (§7).
  Widget _buildPredictionsSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.predictionsTitle,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            TextButton(
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PredictionsScreen()),
              ).then((_) => _loadIntelligence()),
              child: Text(l10n.seeAllSuggestions,
                  style: const TextStyle(fontSize: 12.5)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ..._predictions.take(3).map((p) => PredictionCard(
              prediction: p,
              compact: true,
              onAction: (action) => _predictionAction(p, action),
            )),
      ],
    );
  }

  // Section simplifiée utilisant ShoppingListsContent
  Widget _buildShoppingListsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<ShoppingListBloc, ShoppingListState>(
      builder: (context, state) {
        if (state is ShoppingListLoaded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec informations sur les listes récentes
              Card(
                color: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.recentLists('${state.lists.length}'),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (state.lists.length > 3)
                        TextButton(
                          onPressed: () => _goToAllLists(context),
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
                              color: AppColors.primaryDark,
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

              // Utilisation de ShoppingListsContent avec mode horizontal
              SizedBox(
                height: 200,
                child: ShoppingListsContent(
                  onCreateNew: () => _showCreateListDialog(context),
                  onListTap: (list) => _openListDetails(context, list),
                  onListAction:
                      (action, list) =>
                          _handleListAction(action, list, context, l10n),
                  maxDisplayLists: 5,
                  horizontalLayout: true,
                ),
              ),
            ],
          );
        }

        // Pour les autres états (loading, error, empty)
        return Column(
          children: [
            Card(
              color: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.recentLists('0'),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ShoppingListsContent(
                onCreateNew: () => _showCreateListDialog(context),
                onListTap: (list) => _openListDetails(context, list),
                onListAction:
                    (action, list) =>
                        _handleListAction(action, list, context, l10n),
                maxDisplayLists: 5,
                horizontalLayout: true,
              ),
            ),
          ],
        );
      },
    );
  }

  void _openListDetails(BuildContext context, ShoppingList list) {
    // ✅ Mode offline supporté: Pas besoin de connexion pour voir une liste en cache
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListDetailScreen(shoppingList: list),
      ),
    ).then((_) => _loadShoppingLists());
  }

  void _goToAllLists(BuildContext context) {
    // ✅ Mode offline supporté: Les listes en cache peuvent être consultées
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ShoppingListScreen()),
    ).then((_) => _loadShoppingLists());
  }

  // Gestion des actions déléguée à ShoppingListsContent
  void _handleListAction(
    String action,
    ShoppingList list,
    BuildContext context,
    AppLocalizations l10n,
  ) {
    switch (action) {
      case 'edit':
        if (list.canEdit) {
          // ✅ Mode offline: Les modifications seront mises en queue
          _showEditListDialog(list, context);
        } else {
          SmartSnackBarManager.showWarningSnackBar(
            context,
            l10n.cannotEditPermission,
          );
        }
        break;

      case 'duplicate':
        // ✅ Mode offline: La duplication sera mise en queue
        context.read<ShoppingListBloc>().add(
          DuplicateShoppingList(list.id),
        );
        break;

      case 'share':
        if (list.canShare) {
          // ⚠️ Partage: Nécessite une connexion (envoyer des invitations)
          if (context.isConnected) {
            _showShareDialog(list, context);
          } else {
            SmartSnackBarManager.showWarningSnackBar(
              context,
              l10n.connectionRequired,
            );
          }
        } else {
          SmartSnackBarManager.showWarningSnackBar(
            context,
            l10n.cannotSharePermission,
          );
        }
        break;

      case 'manage_shares':
        if (list.isOwner && list.isShared) {
          // ⚠️ Gestion partage: Nécessite une connexion
          if (context.isConnected) {
            _showManageSharesDialog(list, context);
          } else {
            SmartSnackBarManager.showWarningSnackBar(
              context,
              l10n.connectionRequired,
            );
          }
        } else {
          SmartSnackBarManager.showWarningSnackBar(
            context,
            l10n.onlyOwnerManageShares,
          );
        }
        break;

      case 'leave':
        if (!list.isOwner) {
          // ⚠️ Quitter liste partagée: Nécessite une connexion
          if (context.isConnected) {
            _showLeaveSharedListDialog(list, context);
          } else {
            SmartSnackBarManager.showWarningSnackBar(
              context,
              l10n.connectionRequired,
            );
          }
        } else {
          SmartSnackBarManager.showWarningSnackBar(
            context,
            l10n.cannotLeaveOwnList,
          );
        }
        break;

      case 'delete':
        if (list.canDelete) {
          // ✅ Mode offline: La suppression sera mise en queue
          _showDeleteListDialog(list, context);
        } else {
          SmartSnackBarManager.showWarningSnackBar(
            context,
            l10n.cannotDeletePermission,
          );
        }
        break;
    }
  }

  // Dialog methods - conservés identiques
  void _showCreateListDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<ShoppingListBloc>(),
            child: const CreateListDialog(),
          ),
    );
  }

  void _showEditListDialog(ShoppingList list, BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<ShoppingListBloc>(),
            child: EditListDialog(list: list),
          ),
    );
  }

  void _showDeleteListDialog(ShoppingList list, BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<ShoppingListBloc>(),
            child: DeleteListDialog(list: list),
          ),
    );
  }

  void _showShareDialog(ShoppingList list, BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<SharedListBloc>(),
            child: ShareListDialog(listId: list.id, listName: list.name),
          ),
    );
  }

  void _showManageSharesDialog(ShoppingList list, BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<SharedListBloc>(),
            child: ManageSharesDialog(list: list),
          ),
    );
  }

  void _showLeaveSharedListDialog(ShoppingList list, BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<SharedListBloc>(),
            child: LeaveSharedListDialog(list: list),
          ),
    );
  }
}
