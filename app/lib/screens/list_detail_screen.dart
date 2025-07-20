// screens/list_detail_screen.dart - VERSION CORRIGÉE AVEC TOUTES LES FONCTIONNALITÉS
import 'package:epilist/blocs/list_item/list_item_bloc.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_state.dart';
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/models/list_item.dart';
import 'package:epilist/services/list_item_service.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/widgets/dialogs/add_item_dialog.dart';
import 'package:epilist/widgets/dialogs/edit_item_dialog.dart';
import 'package:epilist/widgets/dialogs/delete_confirmation_dialog.dart';
import 'package:epilist/widgets/dialogs/edit_list_dialog.dart';
import 'package:epilist/widgets/list_detail/list_stats_header.dart';
import 'package:epilist/widgets/list_detail/empty_items_state.dart';
import 'package:epilist/widgets/list_detail/modern_dropdown_menu.dart';
import 'package:epilist/widgets/share_list_dialog.dart';
import 'package:epilist/widgets/shopping/manage_shares_dialog.dart';
import 'package:epilist/widgets/shopping/leave_shared_list_dialog.dart';
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

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(2)} \$CAD';
  }

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
      appBar: _buildAppBar(),
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

  AppBar _buildAppBar() {
    final l10n = AppLocalizations.of(context)!;

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentList.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (currentList.isShared) _buildSharingSubtitle(),
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 1,
      actions: [
        if (currentList.canManageItems)
          IconButton(
            onPressed: _addNewItem,
            icon: const Icon(Icons.add),
            tooltip: l10n.addItemTooltip,
          )
        else
          IconButton(
            onPressed: () => _showPermissionDenied(l10n.addItem.toLowerCase()),
            icon: const Icon(Icons.add, color: Colors.grey),
            tooltip: l10n.insufficientPermission,
          ),
        // Menu déroulant moderne avec toutes les fonctionnalités
        ModernDropdownMenu(
          shoppingList: currentList,
          onEdit: currentList.canEdit ? _showEditListDialog : null,
          onShare: currentList.canShare ? _showShareDialog : null,
          onManageShares:
              (currentList.isOwner && currentList.isShared)
                  ? _showManageSharesDialog
                  : null,
          onInfo: _showListInfo,
          onLeave: !currentList.isOwner ? _showLeaveConfirmation : null,
          onDelete: currentList.canDelete ? _showDeleteConfirmation : null,
        ),
      ],
    );
  }

  Widget _buildSharingSubtitle() {
    final l10n = AppLocalizations.of(context)!;
    String subtitle;
    Color color;

    if (currentList.isOwner) {
      subtitle = l10n.sharedList;
      color = Colors.blue[600]!;
    } else {
      subtitle = currentList.permissionDisplayName ?? l10n.sharedList;
      color = currentList.isReadOnly ? Colors.blue[600]! : Colors.green[600]!;
    }

    return Text(
      subtitle,
      style: TextStyle(
        fontSize: 12,
        color: color,
        fontWeight: FontWeight.normal,
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (!currentList.canManageItems) return null;

    return FloatingActionButton(
      onPressed: _addNewItem,
      backgroundColor: Colors.green[600],
      tooltip: 'Ajouter un article',
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  Widget _buildBody(ListItemState state) {
    List<ListItem> items = [];
    bool isLoading = false;

    if (state is ListItemLoading) {
      isLoading = true;
    } else if (state is ListItemLoaded) {
      items = state.items;
    }

    return Column(
      children: [
        if (!currentList.isOwner) _buildPermissionBanner(),
        ListStatsHeader(
          totalItems: items.length,
          purchasedItems: items.where((item) => item.isPurchased).length,
          totalPrice: items.fold(
            0.0,
            (sum, item) => sum + (item.price ?? 0) * item.quantity,
          ),
        ),
        Expanded(child: _buildContent(items, isLoading)),
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
          _showPermissionDenied('supprimer des articles');
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
          const Text(
            'Supprimer',
            style: TextStyle(
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
            if (item.price != null) ...[
              Text(
                ' • ${_formatPrice(item.price!)}',
                style: TextStyle(
                  color:
                      currentList.isReadOnly
                          ? Colors.grey[500]
                          : Colors.grey[600],
                ),
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

  // ===== FONCTIONNALITÉS AJOUTÉES =====

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
      // Rafraîchir les données après partage potentiel
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
      // Rafraîchir les données après gestion des partages
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

  void _showListInfo() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 10,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildListInfoIcon(),
                  const SizedBox(height: 20),
                  _buildListInfoTitle(),
                  const SizedBox(height: 12),
                  _buildListInfoDescription(),
                  const SizedBox(height: 24),
                  _buildListInfoContent(),
                  const SizedBox(height: 24),
                  _buildListInfoButton(),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildListInfoIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(40),
      ),
      child: Icon(Icons.info_rounded, size: 40, color: Colors.blue[600]),
    );
  }

  Widget _buildListInfoTitle() {
    final l10n = AppLocalizations.of(context)!;

    return Text(
      l10n.listInformation,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildListInfoDescription() {
    final l10n = AppLocalizations.of(context)!;

    return Text(
      l10n.detailsAndPermissions(currentList.name),
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
    );
  }

  Widget _buildListInfoContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRowStyled(
            'Nom',
            currentList.name,
            Icons.list_alt_rounded,
            Colors.blue[600]!,
          ),
          const SizedBox(height: 16),
          _buildInfoRowStyled(
            'Statut',
            currentList.isShared ? 'Partagée' : 'Privée',
            currentList.isShared ? Icons.people_rounded : Icons.lock_rounded,
            currentList.isShared ? Colors.green[600]! : Colors.orange[600]!,
          ),
          if (currentList.isShared) ...[
            const SizedBox(height: 16),
            _buildInfoRowStyled(
              'Votre rôle',
              currentList.isOwner
                  ? 'Propriétaire'
                  : (currentList.permissionDisplayName ?? 'Collaborateur'),
              currentList.isOwner ? Icons.crop_rounded : Icons.person_rounded,
              currentList.isOwner ? Colors.amber[600]! : Colors.purple[600]!,
            ),
            if (!currentList.isOwner && currentList.sharedBy != null) ...[
              const SizedBox(height: 16),
              _buildInfoRowStyled(
                'Partagée par',
                currentList.sharedBy!.name,
                Icons.share_rounded,
                Colors.teal[600]!,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRowStyled(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListInfoButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: const Text(
          'Fermer',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showLeaveConfirmation() {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<SharedListBloc>(),
            child: LeaveSharedListDialog(list: currentList),
          ),
    );
  }

  void _showDeleteConfirmation() {
    DeleteConfirmationDialog.showDeleteList(
      context: context,
      listName: currentList.name,
      onConfirm: () {
        // Déclencher la suppression via le bloc
        context.read<ShoppingListBloc>().add(
          DeleteShoppingList(currentList.id),
        );
        // Retourner à l'écran précédent
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
}
