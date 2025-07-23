// screens/home_screen.dart - VERSION SIMPLIFIÉE AVEC WIDGETS CONNECTÉS
import 'dart:io';

import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_event.dart';
import 'package:epilist/blocs/shared_list/shared_list_state.dart';
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/notifications/notification_service.dart';
import 'package:epilist/screens/profil_screen.dart';
import 'package:epilist/screens/list_detail_screen.dart';
import 'package:epilist/screens/shopping_list_screen.dart';
import 'package:epilist/services/deep_link_handler.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/widgets/home/welcome_card.dart';
import 'package:epilist/widgets/home/home_app_bar.dart';
import 'package:epilist/widgets/home/lists_section_header.dart';
import 'package:epilist/widgets/home/shopping_lists_content.dart';
import 'package:epilist/widgets/dialogs/create_list_dialog.dart';
import 'package:epilist/widgets/dialogs/delete_list_dialog.dart';
import 'package:epilist/widgets/dialogs/edit_list_dialog.dart';
import 'package:epilist/widgets/dialogs/logout_dialog.dart';
import 'package:epilist/widgets/share_list_dialog.dart';
import 'package:epilist/widgets/shopping/leave_shared_list_dialog.dart';
import 'package:epilist/widgets/shopping/manage_shares_dialog.dart';
import 'package:epilist/widgets/connectivity/connected_action_widgets.dart'; // ✅ NOUVEAU
import 'package:epilist/widgets/connectivity/connectivity_wrapper.dart'; // ✅ NOUVEAU
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ✅ SIMPLIFIÉ: Plus de gestion manuelle de connectivité
    _loadShoppingLists();

    // Initialisation des deep links
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDeepLinksOnce();
    });
  }

  // ✅ SIMPLIFIÉ: Plus besoin de vérifier la connectivité ici
  void _loadShoppingLists() {
    context.read<ShoppingListBloc>().add(LoadShoppingLists());
  }

  // Méthode pour initialiser les deep links une seule fois
  void _initializeDeepLinksOnce() {
    if (!_deepLinkInitialized && mounted) {
      print('🚀 Initialisation unique des deep links depuis HomeScreen');
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

      // ✅ SIMPLIFIÉ: Juste recharger les listes, la connectivité est gérée automatiquement
      _loadShoppingLists();

      if (_deepLinkInitialized) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted && _isResuming) {
            print('📱 App resumed - mise à jour contexte deep links');
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
      backgroundColor: Colors.grey[100],
      appBar: HomeAppBar(
        onRefresh:
            () =>
                _loadShoppingLists(), // ✅ ConnectivityWrapper gère la vérification
        onViewAllLists: () => _goToAllLists(context),
        onProfile: () => _goToProfile(context),
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
          // ✅ NOUVEAU: RefreshIndicator connecté
          onRefresh: () async => _loadShoppingLists(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    print('🧪 Lancement des tests de notifications...');

                    // Test notification immédiate
                    await EpiListNotifications.testNotification();

                    // Test notification programmée (dans 10 secondes)
                    await EpiListNotifications.testScheduled();

                    // Vérifier les permissions
                    final hasPerms = await NotificationService.hasPermissions();
                    print('🔐 Permissions: $hasPerms');

                    // Afficher les notifications en attente
                    final pending =
                        await NotificationService.getPendingNotifications();
                    print('📋 Notifications programmées: ${pending.length}');

                    // Message selon la plateforme
                    if (Platform.isIOS) {
                      print(
                        '📱 iOS: Si vous êtes sur émulateur, les notifications ne s\'afficheront pas',
                      );
                      print(
                        '💡 Utilisez un iPhone physique pour voir les notifications',
                      );
                    } else {
                      print(
                        '📱 Android: Les notifications devraient s\'afficher',
                      );
                    }

                    print('✅ Tests terminés - Vérifiez vos notifications !');
                  },
                  child: Text('Test Notifications'),
                ),
                const WelcomeCard(),
                const SizedBox(height: 24),

                // Section header
                ListsSectionHeader(
                  onViewAll: () => _goToAllLists(context),
                  onCreateNew:
                      () => _showCreateListDialog(
                        context,
                      ), // ✅ Gestion automatique
                ),

                const SizedBox(height: 16),
                Expanded(
                  child: ShoppingListsContent(
                    onCreateNew: () => _showCreateListDialog(context),
                    onListTap: (list) => _openListDetails(context, list),
                    onListAction:
                        (action, list) =>
                            _handleListAction(action, list, context, l10n),
                    maxDisplayLists: 5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: ConnectedFloatingActionButton(
        // ✅ NOUVEAU: FAB connecté
        onPressed: () => _showCreateListDialog(context),
        backgroundColor: Colors.green[600],
        tooltip: l10n.createList,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ✅ SIMPLIFIÉ: Plus de vérification manuelle de connectivité
  void _openListDetails(BuildContext context, ShoppingList list) {
    context.requireConnection(
      onConnected: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListDetailScreen(shoppingList: list),
          ),
        ).then((_) => _loadShoppingLists());
      },
    );
  }

  void _goToAllLists(BuildContext context) {
    context.requireConnection(
      onConnected: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ShoppingListScreen()),
        ).then((_) => _loadShoppingLists());
      },
    );
  }

  void _goToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen()),
    );
  }

  // Dialog methods (inchangées)
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
      barrierDismissible: false,
      builder: (dialogContext) => const LogoutDialog(),
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

  // Action handler avec traductions (simplifié)
  void _handleListAction(
    String action,
    ShoppingList list,
    BuildContext context,
    AppLocalizations l10n,
  ) {
    // ✅ SIMPLIFIÉ: Plus de vérification manuelle, utilise requireConnection
    switch (action) {
      case 'edit':
        if (list.canEdit) {
          context.requireConnection(
            onConnected: () => _showEditListDialog(list, context),
          );
        } else {
          SmartSnackBarManager.showWarningSnackBar(
            context,
            l10n.cannotEditPermission,
          );
        }
        break;

      case 'duplicate':
        context.requireConnection(
          onConnected:
              () => context.read<ShoppingListBloc>().add(
                DuplicateShoppingList(list.id),
              ),
        );
        break;

      case 'share':
        if (list.canShare) {
          context.requireConnection(
            onConnected: () => _showShareDialog(list, context),
          );
        } else {
          SmartSnackBarManager.showWarningSnackBar(
            context,
            l10n.cannotSharePermission,
          );
        }
        break;

      case 'manage_shares':
        if (list.isOwner && list.isShared) {
          context.requireConnection(
            onConnected: () => _showManageSharesDialog(list, context),
          );
        } else {
          SmartSnackBarManager.showWarningSnackBar(
            context,
            l10n.onlyOwnerManageShares,
          );
        }
        break;

      case 'leave':
        if (!list.isOwner) {
          context.requireConnection(
            onConnected: () => _showLeaveSharedListDialog(list, context),
          );
        } else {
          SmartSnackBarManager.showWarningSnackBar(
            context,
            l10n.cannotLeaveOwnList,
          );
        }
        break;

      case 'delete':
        if (list.canDelete) {
          context.requireConnection(
            onConnected: () => _showDeleteListDialog(list, context),
          );
        } else {
          SmartSnackBarManager.showWarningSnackBar(
            context,
            l10n.cannotDeletePermission,
          );
        }
        break;
    }
  }
}
