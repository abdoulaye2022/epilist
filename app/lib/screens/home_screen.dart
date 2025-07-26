// screens/home_screen.dart - VERSION AVEC SHOPPING_LIST_CARD INTÉGRÉ
import 'dart:io';

import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_event.dart';
import 'package:epilist/blocs/shared_list/shared_list_state.dart';
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/notifications/notification_service.dart';
import 'package:epilist/screens/diagnostic_screen.dart';
import 'package:epilist/services/shopping_reminder_service.dart';
import 'package:epilist/screens/profil_screen.dart';
import 'package:epilist/screens/list_detail_screen.dart';
import 'package:epilist/screens/shopping_list_screen.dart';
import 'package:epilist/services/deep_link_handler.dart';
import 'package:epilist/services/shopping_reminder_service.dart'; // ✅ AJOUT: Import du service de rappels
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/widgets/home/welcome_card.dart';
import 'package:epilist/widgets/home/home_app_bar.dart';
import 'package:epilist/widgets/home/lists_section_header.dart';
import 'package:epilist/widgets/dialogs/create_list_dialog.dart';
import 'package:epilist/widgets/dialogs/delete_list_dialog.dart';
import 'package:epilist/widgets/dialogs/edit_list_dialog.dart';
import 'package:epilist/widgets/dialogs/logout_dialog.dart';
import 'package:epilist/widgets/dialogs/schedule_reminder_dialog.dart'; // ✅ AJOUT: Import du dialog de rappels
import 'package:epilist/widgets/share_list_dialog.dart';
import 'package:epilist/widgets/shopping/empty_list_state.dart';
import 'package:epilist/widgets/shopping/error_state.dart';
import 'package:epilist/widgets/shopping/leave_shared_list_dialog.dart';
import 'package:epilist/widgets/shopping/manage_shares_dialog.dart';
import 'package:epilist/widgets/dialogs/shopping_list_card.dart'; // ✅ AJOUT: Import du ShoppingListCard
import 'package:epilist/widgets/connectivity/connected_action_widgets.dart';
import 'package:epilist/widgets/connectivity/connectivity_wrapper.dart';
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

    _loadShoppingLists();
    _cleanExpiredReminders(); // ✅ AJOUT: Nettoyage des rappels expirés

    // Initialisation des deep links
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDeepLinksOnce();
    });
  }

  void _loadShoppingLists() {
    context.read<ShoppingListBloc>().add(LoadShoppingLists());
  }

  /// ✅ AJOUT: Nettoyer les rappels expirés au démarrage
  void _cleanExpiredReminders() {
    ShoppingReminderService.cleanExpiredReminders();
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
        onRefresh: () => _loadShoppingLists(),
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
          onRefresh: () async => _loadShoppingLists(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const WelcomeCard(),
                const SizedBox(height: 24),

                // Section header
                ListsSectionHeader(
                  onViewAll: () => _goToAllLists(context),
                  onCreateNew: () => _showCreateListDialog(context),
                ),

                const SizedBox(height: 16),

                // ✅ REMPLACEMENT: Utilisation du BlocBuilder avec ShoppingListCard
                Expanded(child: _buildShoppingListsContent(context, l10n)),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: ConnectedFloatingActionButton(
        onPressed: () => _showCreateListDialog(context),
        backgroundColor: Colors.green[600],
        tooltip: l10n.createList,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ✅ NOUVEAU: Widget pour afficher les listes avec ShoppingListCard
  Widget _buildShoppingListsContent(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return BlocBuilder<ShoppingListBloc, ShoppingListState>(
      builder: (context, state) {
        if (state is ShoppingListLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.green),
          );
        }

        if (state is ShoppingListError) {
          return ErrorState(
            message: state.message,
            onRetry: _loadShoppingLists,
          );
        }

        if (state is ShoppingListLoaded) {
          if (state.lists.isEmpty) {
            return EmptyListState(
              onCreateList: () => _showCreateListDialog(context),
            );
          }

          // ✅ AJOUT: Afficher seulement les 5 premières listes sur l'accueil
          final displayLists = state.lists.take(5).toList();

          return Column(
            children: [
              // Header avec nombre total et bouton "Voir tout"
              if (state.lists.length > 5) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.showingXOfY(displayLists.length, state.lists.length),
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () => _goToAllLists(context),
                      child: Text(l10n.viewAll),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Liste des cartes
              Expanded(
                child: ListView.builder(
                  itemCount: displayLists.length,
                  itemBuilder: (context, index) {
                    final list = displayLists[index];
                    return ShoppingListCard(
                      list: list,
                      onTap: () => _openListDetails(context, list),
                      onMenuAction:
                          (action) =>
                              _handleListAction(action, list, context, l10n),
                    );
                  },
                ),
              ),
            ],
          );
        }

        return EmptyListState(
          onCreateList: () => _showCreateListDialog(context),
        );
      },
    );
  }

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
          MaterialPageRoute(builder: (context) => const ShoppingListScreen()),
        ).then((_) => _loadShoppingLists());
      },
    );
  }

  void _goToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  // ✅ AJOUT: Gestion complète des actions avec rappels
  void _handleListAction(
    String action,
    ShoppingList list,
    BuildContext context,
    AppLocalizations l10n,
  ) {
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

      // ✅ AJOUT: Gestion des rappels de courses
      case 'schedule_reminder':
        _showScheduleReminderDialog(list);
        break;

      case 'quick_reminder_2h':
        _scheduleQuickReminder(list, const Duration(hours: 2), l10n);
        break;

      case 'quick_reminder_tomorrow':
        _scheduleQuickReminder(list, const Duration(hours: 24), l10n);
        break;

      case 'view_reminders':
        _showScheduledReminders(list, l10n);
        break;

      case 'cancel_reminders':
        _cancelAllReminders(list, l10n);
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

  // ✅ AJOUT: Méthodes de gestion des rappels
  void _showScheduleReminderDialog(ShoppingList list) {
    showDialog(
      context: context,
      builder: (context) => ScheduleReminderDialog(shoppingList: list),
    );
  }

  Future<void> _scheduleQuickReminder(
    ShoppingList list,
    Duration delay,
    AppLocalizations l10n,
  ) async {
    try {
      await ShoppingReminderService.scheduleShoppingReminder(
        shoppingList: list,
        reminderTime: DateTime.now().add(delay),
      );

      if (mounted) {
        final timeText =
            delay.inHours < 24 ? l10n.inHours(delay.inHours) : l10n.tomorrow;

        SmartSnackBarManager.showSuccessSnackBar(
          context,
          '${l10n.reminderScheduledFor} $timeText',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (mounted) {
        SmartSnackBarManager.showErrorSnackBar(
          context,
          l10n.errorSchedulingReminder,
        );
      }
    }
  }

  Future<void> _showScheduledReminders(
    ShoppingList list,
    AppLocalizations l10n,
  ) async {
    try {
      final reminders = await ShoppingReminderService.getListReminders(list.id);

      if (!mounted) return;

      if (reminders.isEmpty) {
        SmartSnackBarManager.showInfoSnackBar(
          context,
          l10n.noRemindersScheduled,
        );
        return;
      }

      // Afficher la liste des rappels dans un dialog simplifié
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.scheduledReminders,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = reminders[index];
                    final reminderTime = DateTime.parse(
                      reminder['reminder_time'],
                    );
                    final storeName = reminder['store_name'] as String?;

                    return ListTile(
                      leading: Icon(Icons.alarm, color: Colors.orange[600]),
                      title: Text(_formatReminderTime(reminderTime)),
                      subtitle:
                          storeName != null
                              ? Text('${l10n.store}: $storeName')
                              : null,
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red[600],
                        ),
                        onPressed:
                            () => _cancelSpecificReminder(
                              reminder['notification_id'],
                              l10n,
                            ),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.close),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showScheduleReminderDialog(list);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.addReminder),
                ),
              ],
            ),
      );
    } catch (e) {
      if (mounted) {
        SmartSnackBarManager.showErrorSnackBar(
          context,
          l10n.errorLoadingReminders,
        );
      }
    }
  }

  Future<void> _cancelAllReminders(
    ShoppingList list,
    AppLocalizations l10n,
  ) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[600]),
                const SizedBox(width: 8),
                Text(l10n.cancelAllReminders),
              ],
            ),
            content: Text(l10n.cancelAllRemindersConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.cancelAll),
              ),
            ],
          ),
    );

    if (shouldCancel == true) {
      try {
        await ShoppingReminderService.cancelListReminders(list.id);

        if (mounted) {
          SmartSnackBarManager.showSuccessSnackBar(
            context,
            l10n.allRemindersCancelled,
          );
        }
      } catch (e) {
        if (mounted) {
          SmartSnackBarManager.showErrorSnackBar(
            context,
            l10n.errorCancellingReminders,
          );
        }
      }
    }
  }

  Future<void> _cancelSpecificReminder(
    int notificationId,
    AppLocalizations l10n,
  ) async {
    try {
      await ShoppingReminderService.cancelSpecificReminder(notificationId);

      if (mounted) {
        Navigator.pop(context);
        SmartSnackBarManager.showSuccessSnackBar(
          context,
          l10n.reminderCancelled,
        );
      }
    } catch (e) {
      if (mounted) {
        SmartSnackBarManager.showErrorSnackBar(
          context,
          l10n.errorCancellingReminder,
        );
      }
    }
  }

  String _formatReminderTime(DateTime reminderTime) {
    final now = DateTime.now();
    final difference = reminderTime.difference(now);

    if (difference.isNegative) {
      return 'Expiré';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays}j ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}min';
    } else {
      return '${difference.inMinutes}min';
    }
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
}
