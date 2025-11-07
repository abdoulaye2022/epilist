// screens/home_screen.dart - VERSION PRODUCTION SANS TEST

import 'dart:io';

import 'package:epilist/blocs/analytics/analytics_bloc.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_event.dart';
import 'package:epilist/blocs/shared_list/shared_list_state.dart';
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/screens/analytics_screen.dart';
import 'package:epilist/screens/budget_screen.dart';
import 'package:epilist/screens/category_management_screen.dart';
import 'package:epilist/services/analytics_service.dart';
import 'package:epilist/screens/profil_screen.dart';
import 'package:epilist/screens/list_detail_screen.dart';
import 'package:epilist/screens/shopping_list_screen.dart';
import 'package:epilist/services/deep_link_handler.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/widgets/dialogs/logout_confirmation_dialog.dart';
// import 'package:epilist/widgets/profile/notification_test_widget.dart'; // ✅ COMMENTÉ POUR PRODUCTION
import 'package:epilist/widgets/home/welcome_card.dart';
import 'package:epilist/widgets/home/home_app_bar.dart';
import 'package:epilist/widgets/home/lists_section_header.dart';
import 'package:epilist/widgets/home/shopping_lists_content.dart';
import 'package:epilist/widgets/dialogs/create_list_dialog.dart';
import 'package:epilist/widgets/dialogs/delete_list_dialog.dart';
import 'package:epilist/widgets/dialogs/edit_list_dialog.dart';
import 'package:epilist/widgets/dialogs/logout_dialog.dart';
import 'package:epilist/widgets/share_list_dialog.dart';
import 'package:epilist/widgets/shopping/empty_list_state.dart';
import 'package:epilist/widgets/shopping/error_state.dart';
import 'package:epilist/widgets/shopping/leave_shared_list_dialog.dart';
import 'package:epilist/widgets/shopping/manage_shares_dialog.dart';
import 'package:epilist/widgets/connectivity/connected_action_widgets.dart';
import 'package:epilist/widgets/connectivity/connectivity_wrapper.dart';
import 'package:epilist/widgets/common/network_status_indicator.dart';
import 'package:epilist/widgets/common/offline_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // Variables pour contrôler les initialisations et éviter les redondances
  bool _deepLinkInitialized = false;
  bool _isResuming = false;
  // ✅ SUPPRIMÉ : bool _showNotificationTest = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _loadShoppingLists();

    // Initialisation des deep links
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDeepLinksOnce();
    });
  }

  void _loadShoppingLists() {
    context.read<ShoppingListBloc>().add(LoadShoppingLists());
  }

  // Méthode pour initialiser les deep links une seule fois
  void _initializeDeepLinksOnce() {
    if (!_deepLinkInitialized && mounted) {
      // print('🚀 Initialisation unique des deep links depuis HomeScreen');
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
            // print('📱 App resumed - mise à jour contexte deep links');
            DeepLinkHandler.updateContext(context);
            _isResuming = false;
          }
        });
      }
    } else if (state == AppLifecycleState.paused) {
      _isResuming = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: HomeAppBar(
        onRefresh: () => _loadShoppingLists(),
        onViewAllLists: () => _goToAllLists(context),
        onProfile: () => _goToProfile(context),
        onManageCategories: () => _goToManageCategories(context),
        onLogout: () => _showLogoutDialog(context),
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

              // Indicateur de statut réseau
              const NetworkStatusIndicator(),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const WelcomeCard(),
                      const SizedBox(height: 24),

                // ✅ SUPPRIMÉ : Widget de test notifications
                // if (_showNotificationTest) ...[
                //   const NotificationTestWidget(),
                //   const SizedBox(height: 24),
                // ],

                // Section Actions rapides avec Budget
                _buildQuickActionsSection(context, l10n),
                const SizedBox(height: 24),

                // Section header des listes
                ListsSectionHeader(
                  onViewAll: () => _goToAllLists(context),
                  onCreateNew: () => _showCreateListDialog(context),
                ),

                const SizedBox(height: 16),

                // Section des listes de courses
                _buildShoppingListsSection(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // ✅ FAB pour création de liste (fonctionne hors ligne)
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateListDialog(context),
        backgroundColor: Colors.green[600],
        tooltip: l10n.createList,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Section d'actions rapides avec Budget, Analytics et Listes
  Widget _buildQuickActionsSection(
    BuildContext context,
    AppLocalizations l10n,
  ) {
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

        // Première ligne: Budget et Analytics
        Row(
          children: [
            // Bouton Budget
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.account_balance_wallet,
                title: l10n.budgets,
                subtitle: l10n.overviewOfYourBudgets,
                color: Colors.green[600]!,
                onTap: () => _goToBudget(context),
              ),
            ),
            const SizedBox(width: 12),
            // Bouton Analytics
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.analytics,
                title: l10n.analytics,
                subtitle: l10n.viewSpendingReports,
                color: Colors.blue[600]!,
                onTap: () => _goToAnalytics(context),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Deuxième ligne: Toutes les listes (pleine largeur)
        _buildQuickActionCard(
          icon: Icons.list_alt,
          title: l10n.allLists,
          subtitle: l10n.manageAllLists,
          color: Theme.of(context).primaryColor,
          onTap: () => _goToAllLists(context),
          isFullWidth: true,
        ),
      ],
    );
  }

  // Card avec background blanc
  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    return Card(
      color: Colors.white,
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
                  fontSize: 16,
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
                          color: Colors.grey[700],
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
                        color: Colors.grey[700],
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

  // Navigation vers la page Budget
  void _goToBudget(BuildContext context) {
    // ✅ Mode offline supporté: Les budgets en cache peuvent être consultés
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BudgetScreen()),
    );
  }

  // Navigation vers la page Analytics
  void _goToAnalytics(BuildContext context) {
    // ✅ Mode offline supporté: Les analytics en cache peuvent être consultés
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
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

  void _goToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  void _goToManageCategories(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CategoryManagementScreen(),
      ),
    );
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
              l10n.connectionRequired ?? 'Cette fonctionnalité nécessite une connexion',
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
              l10n.connectionRequired ?? 'Cette fonctionnalité nécessite une connexion',
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
              l10n.connectionRequired ?? 'Cette fonctionnalité nécessite une connexion',
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible:
          false, // ✅ Empêcher la fermeture en cliquant à l'extérieur
      builder:
          (dialogContext) => BlocProvider.value(
            // ✅ IMPORTANT : Passer le AuthBloc au dialog
            value: context.read<AuthBloc>(),
            child:
                const LogoutConfirmationDialog(), // ✅ UTILISER votre dialog personnalisé
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
