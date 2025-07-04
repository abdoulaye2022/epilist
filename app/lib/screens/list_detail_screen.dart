// screens/list_detail_screen.dart - VERSION REFACTORISÉE
import 'package:epilist/blocs/list_item/list_item_bloc.dart';
import 'package:epilist/models/list_item.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/services/list_item_service.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/widgets/dialogs/add_item_dialog.dart';
import 'package:epilist/widgets/dialogs/delete_item_dialog.dart';
import 'package:epilist/widgets/list_detail/empty_items_state.dart';
import 'package:epilist/widgets/list_detail/list_detail_app_bar.dart';
import 'package:epilist/widgets/list_detail/list_item_card.dart';
import 'package:epilist/widgets/list_detail/list_stats_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListDetailScreen extends StatefulWidget {
  final ShoppingList shoppingList;

  const ListDetailScreen({super.key, required this.shoppingList});

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<ListItemBloc>(
      create:
          (context) =>
              ListItemBloc(listItemService: context.read<ListItemService>())
                ..add(LoadListItems(widget.shoppingList.id)),
      child: _ListDetailView(shoppingList: widget.shoppingList),
    );
  }
}

class _ListDetailView extends StatefulWidget {
  final ShoppingList shoppingList;

  const _ListDetailView({required this.shoppingList});

  @override
  State<_ListDetailView> createState() => _ListDetailViewState();
}

class _ListDetailViewState extends State<_ListDetailView> {
  late ShoppingList currentList;

  @override
  void initState() {
    super.initState();
    currentList = widget.shoppingList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: ListDetailAppBar(
        listName: currentList.name,
        onAddItem: _showAddItemDialog,
      ),
      body: BlocConsumer<ListItemBloc, ListItemState>(
        listener: (context, state) {
          // ✨ Gestion intelligente des notifications
          SmartSnackBarManager.showForState(context, state);
        },
        builder: (context, state) => _buildBody(state),
      ),
    );
  }

  Widget _buildBody(ListItemState state) {
    List<ListItem> items = [];
    bool isLoading = state is ListItemLoading;

    if (state is ListItemLoaded) {
      items = state.items;
    }

    return Column(
      children: [
        _buildStatsHeader(items),
        Expanded(child: _buildContent(items, isLoading)),
      ],
    );
  }

  Widget _buildStatsHeader(List<ListItem> items) {
    final totalItems = items.length;
    final purchasedItems = items.where((item) => item.isPurchased).length;
    final totalPrice = items.fold(
      0.0,
      (sum, item) => sum + (item.price ?? 0) * item.quantity,
    );

    return ListStatsHeader(
      totalItems: totalItems,
      purchasedItems: purchasedItems,
      totalPrice: totalPrice,
    );
  }

  Widget _buildContent(List<ListItem> items, bool isLoading) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
        ),
      );
    }

    if (items.isEmpty) {
      return EmptyItemsState(onAddItem: _showAddItemDialog);
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ListItemBloc>().add(LoadListItems(currentList.id));
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ListItemCard(
            item: item,
            onTogglePurchased:
                (isPurchased) => _toggleItemStatus(item, isPurchased),
            onDelete: () => _showDeleteItemDialog(item),
          );
        },
      ),
    );
  }

  // Actions
  void _toggleItemStatus(ListItem item, bool isPurchased) {
    context.read<ListItemBloc>().add(
      TogglePurchasedStatus(
        listId: currentList.id,
        itemId: item.id,
        isPurchased: isPurchased,
      ),
    );
  }

  // Dialogues
  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<ListItemBloc>(),
            child: AddItemDialog(listId: currentList.id),
          ),
    );
  }

  void _showDeleteItemDialog(ListItem item) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<ListItemBloc>(),
            child: DeleteItemDialog(item: item, listId: currentList.id),
          ),
    );
  }
}
