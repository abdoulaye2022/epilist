// screens/home_screen.dart - VERSION SANS SÉLECTION DE LANGUE
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_event.dart';
import 'package:epilist/blocs/shared_list/shared_list_state.dart';
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/models/shopping_list.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    context.read<ShoppingListBloc>().add(LoadShoppingLists());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkHandler.updateContext(context);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    DeepLinkHandler.updateContext(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ShoppingListBloc>().add(LoadShoppingLists());

      DeepLinkHandler.forceReinitialize();

      Future.delayed(const Duration(milliseconds: 1000), () {
        DeepLinkHandler.updateContext(context);
      });
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
            () => context.read<ShoppingListBloc>().add(LoadShoppingLists()),
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
                context.read<ShoppingListBloc>().add(LoadShoppingLists());
              }
            },
          ),
        ],
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<ShoppingListBloc>().add(LoadShoppingLists());
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const WelcomeCard(),
                const SizedBox(height: 24),

                // Section header sans sélecteur de langue
                ListsSectionHeader(
                  onViewAll: () => _goToAllLists(context),
                  onCreateNew: () => _showCreateListDialog(context),
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
    );
  }

  // Navigation methods
  void _openListDetails(BuildContext context, ShoppingList list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListDetailScreen(shoppingList: list),
      ),
    ).then((_) {
      context.read<ShoppingListBloc>().add(LoadShoppingLists());
    });
  }

  void _goToAllLists(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ShoppingListScreen()),
    ).then((_) {
      context.read<ShoppingListBloc>().add(LoadShoppingLists());
    });
  }

  void _goToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen()),
    );
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

  // Action handler avec traductions
  void _handleListAction(
    String action,
    ShoppingList list,
    BuildContext context,
    AppLocalizations l10n,
  ) {
    switch (action) {
      case 'edit':
        if (list.canEdit) {
          _showEditListDialog(list, context);
        } else {
          SmartSnackBarManager.showWarningSnackBar(
            context,
            l10n.cannotEditPermission,
          );
        }
        break;

      case 'duplicate':
        context.read<ShoppingListBloc>().add(DuplicateShoppingList(list.id));
        break;

      case 'share':
        if (list.canShare) {
          _showShareDialog(list, context);
        } else {
          SmartSnackBarManager.showWarningSnackBar(
            context,
            l10n.cannotSharePermission,
          );
        }
        break;

      case 'manage_shares':
        if (list.isOwner && list.isShared) {
          _showManageSharesDialog(list, context);
        } else {
          SmartSnackBarManager.showWarningSnackBar(
            context,
            l10n.onlyOwnerManageShares,
          );
        }
        break;

      case 'leave':
        if (!list.isOwner) {
          _showLeaveSharedListDialog(list, context);
        } else {
          SmartSnackBarManager.showWarningSnackBar(
            context,
            l10n.cannotLeaveOwnList,
          );
        }
        break;

      case 'delete':
        if (list.canDelete) {
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
}
