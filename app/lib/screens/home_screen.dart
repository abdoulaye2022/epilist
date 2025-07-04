// screens/home_screen.dart
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/screens/profil_screen.dart';
import 'package:epilist/screens/list_detail_screen.dart';
import 'package:epilist/screens/shopping_list_screen.dart';
import 'package:epilist/widgets/home/welcome_card.dart';
import 'package:epilist/widgets/home/home_app_bar.dart';
import 'package:epilist/widgets/home/lists_section_header.dart';
import 'package:epilist/widgets/home/shopping_lists_content.dart';
import 'package:epilist/widgets/dialogs/create_list_dialog.dart';
import 'package:epilist/widgets/dialogs/delete_list_dialog.dart';
import 'package:epilist/widgets/dialogs/edit_list_dialog.dart';
import 'package:epilist/widgets/dialogs/logout_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ShoppingListBloc>().add(LoadShoppingLists());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: HomeAppBar(
        onRefresh:
            () => context.read<ShoppingListBloc>().add(LoadShoppingLists()),
        onViewAllLists: () => _goToAllLists(context),
        onProfile: () => _goToProfile(context),
        onLogout: () => _showLogoutDialog(context),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<ShoppingListBloc>().add(LoadShoppingLists());
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WelcomeCard(),
              SizedBox(height: 24),
              ListsSectionHeader(
                onViewAll: () => _goToAllLists(context),
                onCreateNew: () => _showCreateListDialog(context),
              ),
              SizedBox(height: 16),
              Expanded(
                child: ShoppingListsContent(
                  onCreateNew: () => _showCreateListDialog(context),
                  onListTap: (list) => _openListDetails(context, list),
                  onListAction:
                      (action, list) =>
                          _handleListAction(action, list, context),
                  maxDisplayLists: 5,
                ),
              ),
            ],
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

  // Action handler
  void _handleListAction(
    String action,
    ShoppingList list,
    BuildContext context,
  ) {
    switch (action) {
      case 'edit':
        _showEditListDialog(list, context);
        break;
      case 'duplicate':
        context.read<ShoppingListBloc>().add(DuplicateShoppingList(list.id));
        break;
      case 'delete':
        _showDeleteListDialog(list, context);
        break;
    }
  }
}
