// screens/shopping_list_screen.dart - VERSION SANS RAPPELS DE COURSES
import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_event.dart';
import 'package:epilist/blocs/shared_list/shared_list_state.dart';
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/screens/list_detail_screen.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/widgets/dialogs/create_list_dialog.dart';
import 'package:epilist/widgets/dialogs/delete_list_dialog.dart';
import 'package:epilist/widgets/dialogs/edit_list_dialog.dart';
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
  }

  void _loadShoppingLists() {
    context.read<ShoppingListBloc>().add(const LoadShoppingLists());
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

  // Dialogues
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
