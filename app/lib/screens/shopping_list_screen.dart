// screens/shopping_list_screen.dart - VERSION AVEC RAPPELS DE COURSES
import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_event.dart';
import 'package:epilist/blocs/shared_list/shared_list_state.dart';
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/services/shopping_reminder_service.dart';
import 'package:epilist/screens/list_detail_screen.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/widgets/dialogs/create_list_dialog.dart';
import 'package:epilist/widgets/dialogs/delete_list_dialog.dart';
import 'package:epilist/widgets/dialogs/edit_list_dialog.dart';
import 'package:epilist/widgets/dialogs/schedule_reminder_dialog.dart';
import 'package:epilist/widgets/share_list_dialog.dart';
import 'package:epilist/widgets/shopping/empty_list_state.dart';
import 'package:epilist/widgets/shopping/error_state.dart';
import 'package:epilist/widgets/shopping/leave_shared_list_dialog.dart';
import 'package:epilist/widgets/shopping/manage_shares_dialog.dart';
import 'package:epilist/widgets/shopping/shopping_list_app_bar.dart';
import 'package:epilist/widgets/dialogs/shopping_list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  @override
  void initState() {
    super.initState();
    _loadShoppingLists();
    _cleanExpiredReminders();
  }

  void _loadShoppingLists() {
    context.read<ShoppingListBloc>().add(const LoadShoppingLists());
  }

  /// Nettoyer les rappels expirés au démarrage
  void _cleanExpiredReminders() {
    ShoppingReminderService.cleanExpiredReminders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: ShoppingListAppBar(onRefresh: _loadShoppingLists),
      body: MultiBlocListener(
        listeners: [_buildShoppingListListener(), _buildSharedListListener()],
        child: _buildBody(),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // Listeners
  BlocListener<ShoppingListBloc, ShoppingListState>
  _buildShoppingListListener() {
    return BlocListener<ShoppingListBloc, ShoppingListState>(
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
    );
  }

  BlocListener<SharedListBloc, SharedListState> _buildSharedListListener() {
    return BlocListener<SharedListBloc, SharedListState>(
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
    );
  }

  // Body
  Widget _buildBody() {
    return BlocBuilder<ShoppingListBloc, ShoppingListState>(
      builder: (context, state) {
        if (state is ShoppingListLoading) {
          return _buildLoadingState();
        }

        if (state is ShoppingListLoaded) {
          if (state.lists.isEmpty) {
            return EmptyListState(onCreateList: _showCreateListDialog);
          }
          return _buildListView(state.lists);
        }

        if (state is ShoppingListError) {
          return ErrorState(
            message: state.message,
            onRetry: _loadShoppingLists,
          );
        }

        return EmptyListState(onCreateList: _showCreateListDialog);
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(child: CircularProgressIndicator(color: Colors.green[600]));
  }

  Widget _buildListView(List<ShoppingList> lists) {
    return RefreshIndicator(
      onRefresh: () async => _loadShoppingLists(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lists.length,
        itemBuilder: (context, index) {
          final list = lists[index];
          return ShoppingListCard(
            list: list,
            onTap: () => _openListDetails(list),
            onMenuAction: (action) => _handleListAction(action, list),
          );
        },
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    final l10n = AppLocalizations.of(context)!;

    return FloatingActionButton(
      onPressed: _showCreateListDialog,
      backgroundColor: Colors.green[600],
      tooltip: l10n.createList,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  // Actions
  void _openListDetails(ShoppingList list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListDetailScreen(shoppingList: list),
      ),
    ).then((_) => _loadShoppingLists());
  }

  void _handleListAction(String action, ShoppingList list) {
    final l10n = AppLocalizations.of(context)!;

    switch (action) {
      case 'edit':
        if (list.canEdit) {
          _showEditListDialog(list);
        } else {
          SmartSnackBarManager.showErrorSnackBar(
            context,
            l10n.cannotEditPermission,
          );
        }
        break;

      case 'duplicate':
        _duplicateList(list);
        break;

      // ✅ NOUVEAU: Gestion des rappels de courses
      case 'schedule_reminder':
        _showScheduleReminderDialog(list);
        break;

      case 'quick_reminder_2h':
        _scheduleQuickReminder(list, const Duration(hours: 2));
        break;

      case 'quick_reminder_tomorrow':
        _scheduleQuickReminder(list, const Duration(hours: 24));
        break;

      case 'view_reminders':
        _showScheduledReminders(list);
        break;

      case 'cancel_reminders':
        _cancelAllReminders(list);
        break;

      case 'share':
        if (list.canShare) {
          _showShareDialog(list);
        } else {
          SmartSnackBarManager.showErrorSnackBar(
            context,
            l10n.cannotSharePermission,
          );
        }
        break;

      case 'manage_shares':
        if (list.isOwner && list.isShared) {
          _showManageSharesDialog(list);
        } else {
          SmartSnackBarManager.showErrorSnackBar(
            context,
            l10n.onlyOwnerManageShares,
          );
        }
        break;

      case 'leave':
        if (!list.isOwner) {
          _showLeaveSharedListDialog(list);
        } else {
          SmartSnackBarManager.showErrorSnackBar(
            context,
            l10n.cannotLeaveOwnList,
          );
        }
        break;

      case 'delete':
        if (list.canDelete) {
          _showDeleteListDialog(list);
        } else {
          SmartSnackBarManager.showErrorSnackBar(
            context,
            l10n.cannotDeletePermission,
          );
        }
        break;
    }
  }

  void _duplicateList(ShoppingList list) {
    context.read<ShoppingListBloc>().add(DuplicateShoppingList(list.id));
  }

  // ✅ NOUVELLES MÉTHODES: Gestion des rappels

  /// Afficher le dialog de programmation de rappel
  void _showScheduleReminderDialog(ShoppingList list) {
    showDialog(
      context: context,
      builder: (context) => ScheduleReminderDialog(shoppingList: list),
    );
  }

  /// Programmer un rappel rapide
  Future<void> _scheduleQuickReminder(ShoppingList list, Duration delay) async {
    final l10n = AppLocalizations.of(context)!;

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

  /// Afficher les rappels programmés pour une liste
  Future<void> _showScheduledReminders(ShoppingList list) async {
    final l10n = AppLocalizations.of(context)!;

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

      // Afficher la liste des rappels dans un dialog
      showDialog(
        context: context,
        builder: (context) => _buildRemindersDialog(list, reminders, l10n),
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

  /// Construire le dialog des rappels programmés
  Widget _buildRemindersDialog(
    ShoppingList list,
    List<Map<String, dynamic>> reminders,
    AppLocalizations l10n,
  ) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            final reminderTime = DateTime.parse(reminder['reminder_time']);
            final storeName = reminder['store_name'] as String?;

            return ListTile(
              leading: Icon(Icons.alarm, color: Colors.orange[600]),
              title: Text(_formatReminderTime(reminderTime)),
              subtitle:
                  storeName != null ? Text('${l10n.store}: $storeName') : null,
              trailing: IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red[600]),
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
    );
  }

  /// Annuler un rappel spécifique
  Future<void> _cancelSpecificReminder(
    int notificationId,
    AppLocalizations l10n,
  ) async {
    try {
      await ShoppingReminderService.cancelSpecificReminder(notificationId);

      if (mounted) {
        Navigator.pop(context); // Fermer le dialog
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

  /// Annuler tous les rappels d'une liste
  Future<void> _cancelAllReminders(ShoppingList list) async {
    final l10n = AppLocalizations.of(context)!;

    // Dialog de confirmation
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

  /// Formater l'heure du rappel
  String _formatReminderTime(DateTime reminderTime) {
    final now = DateTime.now();
    final difference = reminderTime.difference(now);

    if (difference.isNegative) {
      return 'Expiré'; // Devrait être nettoyé
    }

    if (difference.inDays > 0) {
      return '${difference.inDays}j ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}min';
    } else {
      return '${difference.inMinutes}min';
    }
  }

  // Dialogues existants
  void _showCreateListDialog() {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<ShoppingListBloc>(),
            child: const CreateListDialog(),
          ),
    );
  }

  void _showEditListDialog(ShoppingList list) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<ShoppingListBloc>(),
            child: EditListDialog(list: list),
          ),
    );
  }

  void _showDeleteListDialog(ShoppingList list) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<ShoppingListBloc>(),
            child: DeleteListDialog(list: list),
          ),
    );
  }

  void _showShareDialog(ShoppingList list) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<SharedListBloc>(),
            child: ShareListDialog(listId: list.id, listName: list.name),
          ),
    );
  }

  void _showManageSharesDialog(ShoppingList list) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<SharedListBloc>(),
            child: ManageSharesDialog(list: list),
          ),
    );
  }

  void _showLeaveSharedListDialog(ShoppingList list) {
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
