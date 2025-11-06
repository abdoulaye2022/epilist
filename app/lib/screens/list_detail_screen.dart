// screens/list_detail_screen.dart - VERSION REFACTORISÉE AVEC WIDGETS RÉUTILISABLES
import 'package:epilist/blocs/list_item/list_item_bloc.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart';
import 'package:epilist/blocs/receipt/receipt_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_state.dart';
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/models/list_item.dart';
import 'package:epilist/screens/receipts_screen.dart';
import 'package:epilist/services/list_item_service.dart';
import 'package:epilist/services/receipt_service.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/widgets/list_detail/add_item_dialog.dart';
import 'package:epilist/widgets/list_detail/edit_item_dialog.dart';
import 'package:epilist/widgets/profile/delete_confirmation_dialog.dart';
import 'package:epilist/widgets/dialogs/edit_list_dialog.dart';
import 'package:epilist/widgets/list_detail/list_stats_header.dart';
import 'package:epilist/widgets/list_detail/list_detail_app_bar.dart'; // ✅ AJOUT
import 'package:epilist/widgets/list_detail/empty_items_state.dart';
import 'package:epilist/widgets/list_detail/item_filters_bar.dart';
import 'package:epilist/widgets/share_list_dialog.dart';
import 'package:epilist/widgets/shopping/manage_shares_dialog.dart';
import 'package:epilist/widgets/shopping/leave_shared_list_dialog.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListDetailScreen extends StatefulWidget {
  final ShoppingList shoppingList;

  const ListDetailScreen({super.key, required this.shoppingList});

  @override
  _ListDetailScreenState createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<ListItemBloc>(
      create:
          (context) => ListItemBloc(
            listItemService: context.read<ListItemService>(),
            localizationBloc: context.read<LocalizationBloc>(),
          )..add(LoadListItems(widget.shoppingList.id)),
      child: _ListDetailView(shoppingList: widget.shoppingList),
    );
  }
}

class _ListDetailView extends StatefulWidget {
  final ShoppingList shoppingList;

  const _ListDetailView({required this.shoppingList});

  @override
  _ListDetailViewState createState() => _ListDetailViewState();
}

class _ListDetailViewState extends State<_ListDetailView> {
  late ShoppingList currentList;
  ItemFilterCriteria _filterCriteria = ItemFilterCriteria();

  @override
  void initState() {
    super.initState();
    currentList = widget.shoppingList;
  }

  // Méthode pour rafraîchir les données de la liste
  void _refreshListData() {
    context.read<ShoppingListBloc>().add(const LoadShoppingLists());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // ✅ UTILISATION DU WIDGET RÉUTILISABLE ListDetailAppBar
      appBar: ListDetailAppBar(
        listName: currentList.name,
        shoppingList: currentList,
        onAddItem: currentList.canManageItems ? _addNewItem : null,
        onShare: currentList.canShare ? _showShareDialog : null,
        onEdit: currentList.canEdit ? _showEditListDialog : null,
        onDelete: currentList.canDelete ? _showDeleteConfirmation : null,
      ),
      body: MultiBlocListener(
        listeners: [
          // Listener pour les articles
          BlocListener<ListItemBloc, ListItemState>(
            listener: (context, state) {
              SmartSnackBarManager.showForState(context, state);
            },
          ),
          // Listener pour les listes (mise à jour du nom, etc.)
          BlocListener<ShoppingListBloc, ShoppingListState>(
            listener: (context, state) {
              if (state is ShoppingListLoaded) {
                // Mettre à jour la liste actuelle si elle a été modifiée
                final updatedList = state.lists.firstWhere(
                  (list) => list.id == currentList.id,
                  orElse: () => currentList,
                );
                if (updatedList.id == currentList.id) {
                  setState(() {
                    currentList = updatedList;
                  });
                }
              } else if (state is ShoppingListOperationSuccess) {
                SmartSnackBarManager.showMessage(
                  context,
                  state.message,
                  type: SnackBarType.success,
                );
              } else if (state is ShoppingListError) {
                SmartSnackBarManager.showMessage(
                  context,
                  state.message,
                  type: SnackBarType.error,
                );
              }
            },
          ),
          // Listener pour les actions de partage
          BlocListener<SharedListBloc, SharedListState>(
            listener: (context, state) {
              if (state is ShareOperationSuccess) {
                SmartSnackBarManager.showMessage(
                  context,
                  state.message,
                  type: SnackBarType.success,
                );
                // Si l'utilisateur a quitté la liste, retourner à l'écran précédent
                if (state.message.contains('quitté')) {
                  Navigator.of(context).pop();
                }
              } else if (state is SharedListError) {
                SmartSnackBarManager.showMessage(
                  context,
                  state.message,
                  type: SnackBarType.error,
                );
              }
            },
          ),
        ],
        child: BlocBuilder<ListItemBloc, ListItemState>(
          builder: (context, state) => _buildBody(state),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bouton des factures
        FloatingActionButton(
          onPressed: _openReceiptsScreen,
          heroTag: "receipts_fab",
          backgroundColor: Colors.blue[600],
          tooltip: l10n.receipts,
          child: const Icon(Icons.receipt_long, color: Colors.white),
        ),
        const SizedBox(height: 12),
        // Bouton d'ajout d'article
        FloatingActionButton(
          onPressed: currentList.canEdit ? _addNewItem : null,
          heroTag: "add_item_fab",
          backgroundColor:
              currentList.canEdit ? Colors.green[600] : Colors.grey[400],
          tooltip: l10n.addItem,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ],
    );
  }

  void _openReceiptsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BlocProvider(
              create:
                  (context) => ReceiptBloc(
                    receiptService: context.read<ReceiptService>(),
                    localizationBloc: context.read<LocalizationBloc>(),
                  ),
              child: ReceiptsScreen(shoppingList: widget.shoppingList),
            ),
      ),
    );
  }

  Widget _buildBody(ListItemState state) {
    List<ListItem> items = [];
    List<ListItem> filteredItems = [];
    bool isLoading = false;

    if (state is ListItemLoading) {
      isLoading = true;
    } else if (state is ListItemLoaded) {
      items = state.items;
      filteredItems = _filterCriteria.apply(items);
    }

    // Extraire les magasins uniques pour le filtre
    final availableStores = items
        .where((item) => item.storeName != null && item.storeName!.isNotEmpty)
        .map((item) => item.storeName!)
        .toSet()
        .toList()
      ..sort();

    return Column(
      children: [
        if (!currentList.isOwner) _buildPermissionBanner(),
        // ✅ UTILISATION DU WIDGET RÉUTILISABLE ListStatsHeader
        ListStatsHeader(
          totalItems: items.length,
          purchasedItems: items.where((item) => item.isPurchased).length,
          totalPrice: items.fold(
            0.0,
            (sum, item) => sum + (item.price ?? 0) * item.quantity,
          ),
        ),
        // Widget de filtres
        ItemFiltersBar(
          criteria: _filterCriteria,
          onCriteriaChanged: (newCriteria) {
            setState(() {
              _filterCriteria = newCriteria;
            });
          },
          availableStores: availableStores,
        ),
        Expanded(child: _buildContent(filteredItems, isLoading)),
      ],
    );
  }

  Widget _buildPermissionBanner() {
    final l10n = AppLocalizations.of(context)!;
    Color bannerColor;
    String bannerText;
    IconData bannerIcon;

    if (currentList.isReadOnly) {
      bannerColor = Colors.blue;
      bannerText = l10n.readOnlyAccessMode;
      bannerIcon = Icons.visibility;
    } else if (currentList.canEdit) {
      bannerColor = Colors.green;
      bannerText = l10n.sharedListCanEdit;
      bannerIcon = Icons.edit;
    } else {
      bannerColor = Colors.orange;
      bannerText = l10n.limitedAccess;
      bannerIcon = Icons.lock;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bannerColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(bannerIcon, size: 16, color: bannerColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              bannerText,
              style: TextStyle(
                fontSize: 13,
                color: bannerColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (currentList.sharedBy != null) ...[
            const SizedBox(width: 8),
            Text(
              '${l10n.by} ${currentList.sharedBy!.name}',
              style: TextStyle(
                fontSize: 12,
                color: bannerColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
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
      return EmptyItemsState(
        shoppingList: currentList,
        onAddItem: currentList.canManageItems ? _addNewItem : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ListItemBloc>().add(LoadListItems(currentList.id));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _buildItemCard(items[index]);
        },
      ),
    );
  }

  Widget _buildItemCard(ListItem item) {
    return Dismissible(
      key: Key('item_${item.id}'),
      direction:
          currentList.canEdit
              ? DismissDirection.horizontal
              : DismissDirection.none,
      background: _buildDismissBackground(isStartToEnd: true),
      secondaryBackground: _buildDismissBackground(isStartToEnd: false),
      confirmDismiss: (direction) async {
        if (!currentList.canEdit) {
          final l10n = AppLocalizations.of(context)!;
          _showPermissionDenied(l10n.deleteItems.toLowerCase());
          return false;
        }
        return await _showQuickDeleteConfirmation(item);
      },
      onDismissed: (direction) {
        context.read<ListItemBloc>().add(
          DeleteListItem(listId: currentList.id, itemId: item.id),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side:
              currentList.isReadOnly
                  ? BorderSide(color: Colors.blue[200]!, width: 1)
                  : BorderSide.none,
        ),
        child: ListTile(
          leading: _buildCheckbox(item),
          title: Text(
            item.productName,
            style: TextStyle(
              decoration: item.isPurchased ? TextDecoration.lineThrough : null,
              color:
                  currentList.isReadOnly
                      ? (item.isPurchased ? Colors.grey[500] : Colors.grey[700])
                      : (item.isPurchased ? Colors.grey : Colors.black87),
              fontWeight:
                  currentList.isReadOnly ? FontWeight.normal : FontWeight.w500,
            ),
          ),
          subtitle: _buildItemSubtitle(item),
          trailing: _buildItemTrailing(item),
          onTap: currentList.canEdit ? () => _editItem(item) : null,
        ),
      ),
    );
  }

  Widget _buildDismissBackground({required bool isStartToEnd}) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.red[600],
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: isStartToEnd ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_rounded, color: Colors.white, size: 32),
          const SizedBox(height: 4),
          Text(
            l10n.delete,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showQuickDeleteConfirmation(ListItem item) async {
    bool confirmed = false;

    await DeleteConfirmationDialog.showDeleteItem(
      context: context,
      itemName: item.productName,
      onConfirm: () {
        confirmed = true;
      },
    );

    return confirmed;
  }

  Widget _buildCheckbox(ListItem item) {
    if (currentList.isReadOnly) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: item.isPurchased ? Colors.green[100] : Colors.grey[100],
          border: Border.all(
            color: item.isPurchased ? Colors.green[300]! : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child:
            item.isPurchased
                ? Icon(Icons.check, size: 16, color: Colors.green[600])
                : null,
      );
    }

    return Checkbox(
      value: item.isPurchased,
      onChanged:
          currentList.canManageItems
              ? (value) {
                context.read<ListItemBloc>().add(
                  TogglePurchasedStatus(
                    listId: currentList.id,
                    itemId: item.id,
                    isPurchased: value!,
                  ),
                );
              }
              : (value) =>
                  _showPermissionDenied('modifier le statut des articles'),
      activeColor: Colors.green[600],
      fillColor:
          currentList.canManageItems
              ? null
              : MaterialStateProperty.all(Colors.grey[300]),
    );
  }

  Widget _buildItemSubtitle(ListItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Qté: ${item.quantity}',
              style: TextStyle(
                color:
                    currentList.isReadOnly
                        ? Colors.grey[500]
                        : Colors.grey[600],
              ),
            ),
            if (item.price != null && item.price! > 0) ...[
              Text(
                ' • ',
                style: TextStyle(
                  color:
                      currentList.isReadOnly
                          ? Colors.grey[500]
                          : Colors.grey[600],
                ),
              ),
              FormattedAmount(
                amount: item.price!,
                style: TextStyle(
                  color:
                      currentList.isReadOnly
                          ? Colors.grey[500]
                          : Colors.grey[600],
                ),
                showCode: false,
              ),
            ],
          ],
        ),
        if (item.storeName != null && item.storeName!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.store,
                size: 12,
                color:
                    currentList.isReadOnly
                        ? Colors.grey[400]
                        : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.storeName!,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        currentList.isReadOnly
                            ? Colors.grey[400]
                            : Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildItemTrailing(ListItem item) {
    if (currentList.isReadOnly) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility, size: 14, color: Colors.blue[600]),
            const SizedBox(width: 4),
            Text(
              'Lecture seule',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return IconButton(
      icon: Icon(Icons.edit, color: Colors.blue[600]),
      onPressed:
          currentList.canEdit
              ? () => _editItem(item)
              : () => _showPermissionDenied('modifier des articles'),
      tooltip:
          currentList.canEdit
              ? 'Modifier l\'article'
              : 'Permission insuffisante',
    );
  }

  // ===== MÉTHODES D'ACTION =====

  void _showEditListDialog() {
    if (!currentList.canEdit) {
      _showPermissionDenied('modifier cette liste');
      return;
    }

    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<ShoppingListBloc>(),
            child: EditListDialog(list: currentList),
          ),
    );
  }

  void _showShareDialog() {
    if (!currentList.canShare) {
      _showPermissionDenied('partager cette liste');
      return;
    }

    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<SharedListBloc>(),
            child: ShareListDialog(
              listId: currentList.id,
              listName: currentList.name,
            ),
          ),
    ).then((_) {
      _refreshListData();
    });
  }

  void _showManageSharesDialog() {
    if (!currentList.isOwner || !currentList.isShared) {
      _showPermissionDenied('gérer les partages');
      return;
    }

    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<SharedListBloc>(),
            child: ManageSharesDialog(list: currentList),
          ),
    ).then((_) {
      _refreshListData();
    });
  }

  void _editItem(ListItem item) {
    if (!currentList.canEdit) {
      _showPermissionDenied('modifier des articles');
      return;
    }

    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<ListItemBloc>(),
            child: EditItemDialog(listId: currentList.id, item: item),
          ),
    );
  }

  void _showDeleteConfirmation() {
    DeleteConfirmationDialog.showDeleteList(
      context: context,
      listName: currentList.name,
      onConfirm: () {
        context.read<ShoppingListBloc>().add(
          DeleteShoppingList(currentList.id),
        );
        Navigator.of(context).pop();
      },
    );
  }

  void _addNewItem() {
    if (!currentList.canManageItems) {
      _showPermissionDenied('ajouter des articles');
      return;
    }

    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<ListItemBloc>(),
            child: AddItemDialog(listId: currentList.id),
          ),
    );
  }

  void _showPermissionDenied(String action) {
    String title;
    String message;
    String permission;

    if (currentList.isReadOnly) {
      title = 'Accès en lecture seule';
      permission = currentList.permissionDisplayName ?? 'Lecture seule';
      message =
          'Vous ne pouvez pas $action car cette liste est en mode lecture seule.\n\n'
          'Votre permission actuelle : $permission';
    } else {
      title = 'Permission insuffisante';
      permission = currentList.permissionDisplayName ?? 'Limitée';
      message =
          'Vous n\'avez pas la permission de $action.\n\n'
          'Votre permission actuelle : $permission';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                currentList.isReadOnly ? Icons.visibility : Icons.lock,
                color:
                    currentList.isReadOnly
                        ? Colors.blue[600]
                        : Colors.orange[600],
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(title)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 16),
              if (!currentList.isOwner && currentList.sharedBy != null) ...[
                Text(
                  'Cette liste a été partagée par ${currentList.sharedBy!.name}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Compris'),
            ),
          ],
        );
      },
    );
  }
}
