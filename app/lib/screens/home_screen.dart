// screens/home_screen.dart - VERSION CORRIGÉE AVEC LES VRAIES PROPRIÉTÉS
import 'dart:io';

import 'package:epilist/blocs/analytics/analytics_bloc.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_event.dart';
import 'package:epilist/blocs/shared_list/shared_list_state.dart';
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/notifications/notification_service.dart';
import 'package:epilist/screens/analytics_screen.dart';
import 'package:epilist/screens/diagnostic_screen.dart';
import 'package:epilist/services/analytics_service.dart';
import 'package:epilist/services/shopping_reminder_service.dart';
import 'package:epilist/screens/profil_screen.dart';
import 'package:epilist/screens/list_detail_screen.dart';
import 'package:epilist/screens/shopping_list_screen.dart';
import 'package:epilist/services/deep_link_handler.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/widgets/home/welcome_card.dart';
import 'package:epilist/widgets/home/home_app_bar.dart';
import 'package:epilist/widgets/home/lists_section_header.dart';
import 'package:epilist/widgets/dialogs/create_list_dialog.dart';
import 'package:epilist/widgets/dialogs/delete_list_dialog.dart';
import 'package:epilist/widgets/dialogs/edit_list_dialog.dart';
import 'package:epilist/widgets/dialogs/logout_dialog.dart';
import 'package:epilist/widgets/dialogs/schedule_reminder_dialog.dart';
import 'package:epilist/widgets/share_list_dialog.dart';
import 'package:epilist/widgets/shopping/empty_list_state.dart';
import 'package:epilist/widgets/shopping/error_state.dart';
import 'package:epilist/widgets/shopping/leave_shared_list_dialog.dart';
import 'package:epilist/widgets/shopping/manage_shares_dialog.dart';
import 'package:epilist/widgets/dialogs/shopping_list_card.dart';
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
    _cleanExpiredReminders();

    // Initialisation des deep links
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDeepLinksOnce();
    });
  }

  void _loadShoppingLists() {
    context.read<ShoppingListBloc>().add(LoadShoppingLists());
  }

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const WelcomeCard(),
                const SizedBox(height: 24),

                // Section Actions rapides
                _buildQuickActionsSection(context, l10n),
                const SizedBox(height: 24),

                // Section header des listes
                ListsSectionHeader(
                  onViewAll: () => _goToAllLists(context),
                  onCreateNew: () => _showCreateListDialog(context),
                ),

                const SizedBox(height: 16),

                // Listes avec scroll horizontal
                _buildShoppingListsContent(context, l10n),
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

  // Section d'actions rapides avec bouton Analytics
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
        Row(
          children: [
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
            const SizedBox(width: 12),
            // Bouton Toutes les listes
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.list_alt,
                title: l10n.allLists,
                subtitle: l10n.manageAllLists,
                color: Colors.green[600]!,
                onTap: () => _goToAllLists(context),
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

  // Widget pour afficher les listes avec scroll horizontal
  Widget _buildShoppingListsContent(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return BlocBuilder<ShoppingListBloc, ShoppingListState>(
      builder: (context, state) {
        if (state is ShoppingListLoading) {
          return Container(
            height: 200,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.green),
            ),
          );
        }

        if (state is ShoppingListError) {
          return Container(
            height: 200,
            child: ErrorState(
              message: state.message,
              onRetry: _loadShoppingLists,
            ),
          );
        }

        if (state is ShoppingListLoaded) {
          if (state.lists.isEmpty) {
            return Container(
              height: 200,
              child: EmptyListState(
                onCreateList: () => _showCreateListDialog(context),
              ),
            );
          }

          // Affichage horizontal des listes
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec compte et bouton "Voir tout"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.recentLists('${state.lists.length}'),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (state.lists.length > 3)
                    TextButton(
                      onPressed: () => _goToAllLists(context),
                      child: Text(l10n.viewAll),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // ScrollView horizontal pour les listes
              SizedBox(
                height: 180, // Hauteur fixe pour les cartes
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: state.lists.length > 5 ? 5 : state.lists.length,
                  itemBuilder: (context, index) {
                    final list = state.lists[index];
                    return Container(
                      width: 280, // Largeur fixe pour chaque carte
                      margin: const EdgeInsets.only(right: 16),
                      child: _buildHorizontalListCard(list, context, l10n),
                    );
                  },
                ),
              ),
            ],
          );
        }

        return Container(
          height: 200,
          child: EmptyListState(
            onCreateList: () => _showCreateListDialog(context),
          ),
        );
      },
    );
  }

  // ✅ CORRIGÉ: Carte de liste avec les vraies propriétés du modèle
  Widget _buildHorizontalListCard(
    ShoppingList list,
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openListDetails(context, list),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec nom et menu
              Row(
                children: [
                  Expanded(
                    child: Text(
                      list.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected:
                        (action) =>
                            _handleListAction(action, list, context, l10n),
                    itemBuilder: (context) => _buildMenuItems(list, l10n),
                    child: Icon(Icons.more_vert, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Informations de la liste
              if (list.isShared) ...[
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.blue[600]),
                    const SizedBox(width: 4),
                    Text(
                      list.isOwner ? l10n.shared : l10n.sharedWithYou,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // ✅ CORRIGÉ: Statistiques avec les vraies propriétés
              Row(
                children: [
                  _buildStatChip(
                    Icons.shopping_cart,
                    '${list.itemsCount}', // ✅ Vraie propriété
                    l10n.items,
                    Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    Icons.check_circle,
                    '${list.purchasedItemsCount}', // ✅ Vraie propriété
                    l10n.done,
                    Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ✅ CORRIGÉ: Barre de progression avec la vraie propriété
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.progress,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${list.progressPercentage}%', // ✅ Vraie propriété
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: list.progress, // ✅ Vraie propriété (0.0 à 1.0)
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      list
                              .isCompleted // ✅ Vraie propriété
                          ? Colors.green[600]!
                          : Colors.blue[600]!,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Footer avec date
              Text(
                _formatDate(list.updatedAt),
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Navigation vers la page Analytics
  void _goToAnalytics(BuildContext context) {
    context.requireConnection(
      onConnected: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => BlocProvider(
                  create:
                      (context) => AnalyticsBloc(
                        analyticsService: context.read<AnalyticsService>(),
                        localizationBloc: context.read<LocalizationBloc>(),
                      ),
                  child: const AnalyticsScreen(),
                ),
          ),
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

  // Menu items pour les listes
  List<PopupMenuEntry<String>> _buildMenuItems(
    ShoppingList list,
    AppLocalizations l10n,
  ) {
    final items = <PopupMenuEntry<String>>[];

    // Voir/Modifier
    if (list.canEdit) {
      items.add(
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit, size: 20),
              const SizedBox(width: 8),
              Text(l10n.edit),
            ],
          ),
        ),
      );
    }

    // Dupliquer
    items.add(
      PopupMenuItem(
        value: 'duplicate',
        child: Row(
          children: [
            const Icon(Icons.copy, size: 20),
            const SizedBox(width: 8),
            Text(l10n.duplicate),
          ],
        ),
      ),
    );

    // Rappels
    items.add(const PopupMenuDivider());
    items.add(
      PopupMenuItem(
        value: 'schedule_reminder',
        child: Row(
          children: [
            Icon(Icons.schedule, size: 20, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Text(l10n.scheduleReminder),
          ],
        ),
      ),
    );

    items.add(
      PopupMenuItem(
        value: 'quick_reminder_2h',
        child: Row(
          children: [
            Icon(Icons.alarm, size: 20, color: Colors.orange[600]),
            const SizedBox(width: 8),
            Text(l10n.remindIn2Hours),
          ],
        ),
      ),
    );

    items.add(
      PopupMenuItem(
        value: 'view_reminders',
        child: Row(
          children: [
            Icon(Icons.list_alt, size: 20, color: Colors.green[600]),
            const SizedBox(width: 8),
            Text(l10n.viewReminders),
          ],
        ),
      ),
    );

    // Partager
    if (list.canShare) {
      items.add(const PopupMenuDivider());
      items.add(
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              const Icon(Icons.share, size: 20),
              const SizedBox(width: 8),
              Text(l10n.share),
            ],
          ),
        ),
      );
    }

    if (list.isOwner && list.isShared) {
      items.add(
        PopupMenuItem(
          value: 'manage_shares',
          child: Row(
            children: [
              const Icon(Icons.people, size: 20),
              const SizedBox(width: 8),
              Text(l10n.manageShares),
            ],
          ),
        ),
      );
    }

    // Supprimer/Quitter
    items.add(const PopupMenuDivider());
    if (list.canDelete) {
      items.add(
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red[600]),
              const SizedBox(width: 8),
              Text(l10n.delete, style: TextStyle(color: Colors.red[600])),
            ],
          ),
        ),
      );
    } else if (!list.isOwner) {
      items.add(
        PopupMenuItem(
          value: 'leave',
          child: Row(
            children: [
              Icon(Icons.exit_to_app, size: 20, color: Colors.orange[600]),
              const SizedBox(width: 8),
              Text(l10n.leave, style: TextStyle(color: Colors.orange[600])),
            ],
          ),
        ),
      );
    }

    return items;
  }

  // Gestion des actions
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

      // Gestion des rappels de courses
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

  // Méthodes de gestion des rappels
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

  // Dialog methods
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
