// screens/list_detail_screen.dart - VERSION REFACTORISÉE AVEC WIDGETS RÉUTILISABLES
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/screens/shopping_mode_screen.dart';
import 'package:dio/dio.dart';
import 'package:epilist/blocs/category/category_bloc.dart';
import 'package:epilist/blocs/chat/chat_bloc.dart';
import 'package:epilist/blocs/list_item/list_item_bloc.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart';
import 'package:epilist/blocs/receipt/receipt_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_state.dart';
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/config/app_config.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/screens/chat_screen.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:epilist/services/chat_service.dart';
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
import 'package:epilist/models/category.dart';
import 'package:epilist/models/store.dart';
import 'package:epilist/services/category_guesser.dart';
import 'package:epilist/services/store_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:epilist/widgets/list_detail/item_filters_bar.dart';
import 'package:epilist/widgets/list_detail/voice_input_dialog.dart';
import 'package:epilist/widgets/share_list_dialog.dart';
import 'package:epilist/widgets/shopping/manage_shares_dialog.dart';
import 'package:epilist/widgets/currency/formatted_amount.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ListDetailAction { none, addItem, voiceItem }

class ListDetailScreen extends StatefulWidget {
  final ShoppingList shoppingList;

  /// Action a declencher a l'ouverture (dashboard : ajout rapide, voix).
  final ListDetailAction initialAction;

  const ListDetailScreen({
    super.key,
    required this.shoppingList,
    this.initialAction = ListDetailAction.none,
  });

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
      child: _ListDetailView(
        shoppingList: widget.shoppingList,
        initialAction: widget.initialAction,
      ),
    );
  }
}

class _ListDetailView extends StatefulWidget {
  final ShoppingList shoppingList;
  final ListDetailAction initialAction;

  const _ListDetailView({
    required this.shoppingList,
    this.initialAction = ListDetailAction.none,
  });

  @override
  _ListDetailViewState createState() => _ListDetailViewState();
}

class _ListDetailViewState extends State<_ListDetailView> {
  late ShoppingList currentList;
  ItemFilterCriteria _filterCriteria = ItemFilterCriteria();

  // Tri par rayon : magasin actif (choix local à l'appareil, par liste)
  // et classement rayon -> position pour ce magasin.
  List<Store> _myStores = [];
  Store? _activeStore;
  Map<int, int> _aisleRank = {};

  String get _activeStorePrefKey => 'active_store_for_list_${currentList.id}';

  @override
  void initState() {
    super.initState();
    currentList = widget.shoppingList;

    // Charger les catégories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryBloc>().add(const LoadCategories());
      _loadStoresAndActiveStore();
      // Action rapide demandee par le dashboard
      switch (widget.initialAction) {
        case ListDetailAction.addItem:
          _addNewItem();
          break;
        case ListDetailAction.voiceItem:
          _addItemByVoice();
          break;
        case ListDetailAction.none:
          break;
      }
    });
  }

  Future<void> _loadStoresAndActiveStore() async {
    try {
      final stores = await context.read<StoreService>().getStores();
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getInt(_activeStorePrefKey);
      if (!mounted) return;
      setState(() {
        _myStores = stores;
        _activeStore = savedId == null
            ? null
            : stores.where((s) => s.id == savedId).firstOrNull;
        _rebuildAisleRank();
      });
    } catch (_) {
      // Hors ligne ou API indisponible : le tri par rayon est simplement
      // masqué, le reste de l'écran fonctionne normalement.
    }
  }

  /// Construit categoryId -> position du rayon, à partir de l'ordre des
  /// kinds du magasin actif et des catégories de l'utilisateur.
  void _rebuildAisleRank() {
    final store = _activeStore;
    final categoryState = context.read<CategoryBloc>().state;
    if (store == null ||
        !store.hasAisleOrder ||
        categoryState is! CategoryLoaded) {
      _aisleRank = {};
      return;
    }
    final kindRank = <String, int>{
      for (var i = 0; i < store.categoryOrder.length; i++)
        store.categoryOrder[i]: i,
    };
    _aisleRank = {
      for (final cat in categoryState.categories)
        if (cat.kind != null && kindRank.containsKey(cat.kind))
          cat.id: kindRank[cat.kind]!,
    };
  }

  Future<void> _selectActiveStore(Store? store) async {
    final l10n = AppLocalizations.of(context)!;
    final prefs = await SharedPreferences.getInstance();
    if (store == null) {
      await prefs.remove(_activeStorePrefKey);
    } else {
      await prefs.setInt(_activeStorePrefKey, store.id);
    }
    if (!mounted) return;
    setState(() {
      _activeStore = store;
      _rebuildAisleRank();
      if (store != null && store.hasAisleOrder) {
        _filterCriteria.sortBy = ItemSortBy.aisle;
      } else if (_filterCriteria.sortBy == ItemSortBy.aisle) {
        _filterCriteria.sortBy = ItemSortBy.dateAdded;
      }
    });
    if (store != null && !store.hasAisleOrder) {
      SmartSnackBarManager.showWarningSnackBar(
        context,
        l10n.aisleOrderNotConfigured,
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// Sélecteur « Je suis au magasin... » : n'apparaît que si l'utilisateur
  /// a configuré au moins un magasin.
  Widget _buildActiveStoreSelector() {
    final l10n = AppLocalizations.of(context)!;
    final active = _activeStore;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Icon(Icons.storefront,
              size: 20,
              color: active != null ? AppColors.primary : AppColors.textDisabled),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              active?.name ?? l10n.chooseStore,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    active != null ? FontWeight.w600 : FontWeight.normal,
                color: active != null ? AppColors.textPrimary : AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Mode « Je suis au magasin » : plein écran, gros boutons,
          // regroupé par rayon dans l'ordre du magasin actif.
          IconButton(
            tooltip: l10n.startShopping,
            icon: const Icon(Icons.shopping_cart_checkout,
                color: AppColors.primary),
            onPressed: () {
              // Le ListItemBloc est fourni par cet écran : on le passe
              // explicitement à la route (sinon Provider introuvable).
              final bloc = context.read<ListItemBloc>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: bloc,
                    child: ShoppingModeScreen(
                      shoppingList: currentList,
                      store: _activeStore,
                      aisleRank: _aisleRank,
                    ),
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<int>(
            color: Colors.white,
            icon: Icon(Icons.expand_more, color: AppColors.textSecondary),
            onSelected: (id) {
              _selectActiveStore(
                  id == -1 ? null : _myStores.where((s) => s.id == id).firstOrNull);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: -1,
                child: Text(l10n.noActiveStore,
                    style: const TextStyle(color: AppColors.textPrimary)),
              ),
              ..._myStores.map(
                (s) => PopupMenuItem(
                  value: s.id,
                  child: Row(
                    children: [
                      Icon(
                        s.hasAisleOrder ? Icons.route : Icons.storefront,
                        size: 18,
                        color: s.hasAisleOrder
                            ? AppColors.primary
                            : AppColors.textDisabled,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(s.name,
                            style: const TextStyle(color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Méthode pour rafraîchir les données de la liste
  void _refreshListData() {
    context.read<ShoppingListBloc>().add(const LoadShoppingLists());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // ✅ UTILISATION DU WIDGET RÉUTILISABLE ListDetailAppBar
      appBar: ListDetailAppBar(
        listName: currentList.name,
        shoppingList: currentList,
        onAddItem: currentList.canManageItems ? _addNewItem : null,
        onShare: currentList.canShare ? _showShareDialog : null,
        onEdit: currentList.canEdit ? _showEditListDialog : null,
        onDelete: currentList.canDelete ? _showDeleteConfirmation : null,
        onOpenChat: currentList.isShared ? _openChatScreen : null,
        onManageShares:
            currentList.isOwner && currentList.isShared
                ? _showManageSharesDialog
                : null,
      ),
      body: MultiBlocListener(
        listeners: [
          // Listener pour les articles
          BlocListener<ListItemBloc, ListItemState>(
            listener: (context, state) {
              if (state is ListItemDuplicateDetected) {
                // Afficher un dialogue pour gérer le doublon
                _showDuplicateDialog(state);
              } else {
                SmartSnackBarManager.showForState(context, state);
              }
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
          backgroundColor: AppColors.accent,
          tooltip: l10n.receipts,
          child: const Icon(Icons.receipt_long, color: Colors.white),
        ),
        const SizedBox(height: 12),
        // Bouton d'ajout vocal
        FloatingActionButton(
          onPressed: currentList.canEdit ? _addItemByVoice : null,
          heroTag: "voice_fab",
          backgroundColor:
              currentList.canEdit ? Colors.purple[600] : AppColors.textDisabled,
          tooltip: AppLocalizations.of(context)!.quickVoice,
          child: const Icon(Icons.mic, color: Colors.white),
        ),
        const SizedBox(height: 12),
        // Bouton d'ajout d'article
        FloatingActionButton(
          onPressed: currentList.canEdit ? _addNewItem : null,
          heroTag: "add_item_fab",
          backgroundColor:
              currentList.canEdit ? AppColors.primary : AppColors.textDisabled,
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
    // Recalculé à chaque build : couvre le cas où les catégories arrivent
    // après les magasins (course au chargement). ~12 entrées, coût nul.
    _rebuildAisleRank();

    List<ListItem> items = [];
    List<ListItem> filteredItems = [];
    bool isLoading = false;

    if (state is ListItemLoading) {
      isLoading = true;
    } else if (state is ListItemLoaded) {
      items = state.items;
      filteredItems = _filterCriteria.apply(items, aisleRank: _aisleRank);
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
        if (_myStores.isNotEmpty) _buildActiveStoreSelector(),
        // Widget de filtres
        BlocBuilder<CategoryBloc, CategoryState>(
          builder: (context, categoryState) {
            final categories = categoryState is CategoryLoaded
                ? categoryState.categories
                    .where((cat) => cat.deletedAt == null)
                    .map((cat) => {
                          'id': cat.id,
                          'name': cat.name,
                        })
                    .toList()
                : <Map<String, dynamic>>[];

            return ItemFiltersBar(
              criteria: _filterCriteria,
              onCriteriaChanged: (newCriteria) {
                setState(() {
                  _filterCriteria = newCriteria;
                });
              },
              availableStores: availableStores,
              availableCategories: categories,
              aisleSortAvailable: _activeStore?.hasAisleOrder == true,
            );
          },
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
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (items.isEmpty) {
      return EmptyItemsState(
        shoppingList: currentList,
        onAddItem: currentList.canManageItems ? _addNewItem : null,
      );
    }

    // En tri par rayon : liste groupée avec un en-tête par rayon,
    // dans l'ordre du magasin actif. Sinon : liste plate habituelle.
    final grouped = _filterCriteria.sortBy == ItemSortBy.aisle &&
        _activeStore?.hasAisleOrder == true;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ListItemBloc>().add(LoadListItems(currentList.id));
      },
      child: grouped
          ? _buildGroupedByAisle(items)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _buildItemCard(items[index]);
              },
            ),
    );
  }

  /// Liste groupée par rayon : les items arrivent déjà triés par rang
  /// (apply avec aisleRank) ; on insère un en-tête à chaque changement
  /// de rayon. Les articles sans rayon vont dans « Non classé » à la fin.
  Widget _buildGroupedByAisle(List<ListItem> items) {
    final l10n = AppLocalizations.of(context)!;
    final categoryState = context.read<CategoryBloc>().state;
    final categoriesById = <int, Category>{
      if (categoryState is CategoryLoaded)
        for (final cat in categoryState.categories) cat.id: cat,
    };

    String headerFor(ListItem item) {
      final catId = item.categoryId;
      if (catId == null || !_aisleRank.containsKey(catId)) {
        return l10n.uncategorizedAisle;
      }
      return categoriesById[catId]?.name ?? l10n.uncategorizedAisle;
    }

    final rows = <Widget>[];
    String? currentHeader;
    for (final item in items) {
      final header = headerFor(item);
      if (header != currentHeader) {
        currentHeader = header;
        final cat = item.categoryId != null ? categoriesById[item.categoryId!] : null;
        final inAisle = item.categoryId != null &&
            _aisleRank.containsKey(item.categoryId!);
        rows.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Row(
              children: [
                Icon(
                  inAisle ? (cat?.icon ?? Icons.category) : Icons.help_outline,
                  size: 18,
                  color: inAisle
                      ? (cat?.color ?? AppColors.textSecondary)
                      : AppColors.textDisabled,
                ),
                const SizedBox(width: 8),
                Text(
                  header,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: inAisle ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Divider(color: AppColors.border)),
              ],
            ),
          ),
        );
      }
      rows.add(_buildItemCard(item));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: rows,
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
                      ? (item.isPurchased ? AppColors.textDisabled : AppColors.textSecondary)
                      : (item.isPurchased ? Colors.grey : AppColors.textPrimary),
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
        color: AppColors.error,
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
          color: item.isPurchased ? AppColors.primaryLight : AppColors.background,
          border: Border.all(
            color: item.isPurchased ? Colors.green[300]! : AppColors.border,
            width: 2,
          ),
        ),
        child:
            item.isPurchased
                ? Icon(Icons.check, size: 16, color: AppColors.primary)
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
                  _showPermissionDenied(AppLocalizations.of(context)!.permActionEditStatus),
      activeColor: AppColors.primary,
      fillColor:
          currentList.canManageItems
              ? null
              : MaterialStateProperty.all(AppColors.border),
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
                        ? AppColors.textDisabled
                        : AppColors.textSecondary,
              ),
            ),
            if (item.price != null && item.price! > 0) ...[
              Text(
                ' • ',
                style: TextStyle(
                  color:
                      currentList.isReadOnly
                          ? AppColors.textDisabled
                          : AppColors.textSecondary,
                ),
              ),
              FormattedAmount(
                amount: item.price!,
                style: TextStyle(
                  color:
                      currentList.isReadOnly
                          ? AppColors.textDisabled
                          : AppColors.textSecondary,
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
                        ? AppColors.textDisabled
                        : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.storeName!,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        currentList.isReadOnly
                            ? AppColors.textDisabled
                            : AppColors.textSecondary,
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
          color: AppColors.accentLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility, size: 14, color: AppColors.accent),
            const SizedBox(width: 4),
            Text(
              AppLocalizations.of(context)!.readOnly,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return IconButton(
      icon: Icon(Icons.edit, color: AppColors.accent),
      onPressed:
          currentList.canEdit
              ? () => _editItem(item)
              : () => _showPermissionDenied(AppLocalizations.of(context)!.permActionEditItems),
      tooltip:
          currentList.canEdit
              ? AppLocalizations.of(context)!.editItem
              : AppLocalizations.of(context)!.insufficientPermission,
    );
  }

  // ===== MÉTHODES D'ACTION =====

  void _showEditListDialog() {
    if (!currentList.canEdit) {
      _showPermissionDenied(AppLocalizations.of(context)!.permActionEditList);
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
      _showPermissionDenied(AppLocalizations.of(context)!.permActionShareList);
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

  void _openChatScreen() async {
    if (!currentList.isShared) {
      _showPermissionDenied(AppLocalizations.of(context)!.permActionAccessChat);
      return;
    }

    // Créer un Dio configuré avec l'authentification
    final authService = context.read<AuthService>();
    final token = await authService.getToken();

    final dio = Dio();
    dio.options.baseUrl = AppConfig.baseUrl;
    dio.options.headers['Authorization'] = 'Bearer $token';

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (newContext) => BlocProvider(
              create:
                  (blocContext) => ChatBloc(
                    chatService: ChatService(dio: dio),
                  ),
              child: ChatScreen(
                listId: currentList.id,
                listName: currentList.name,
              ),
            ),
      ),
    );
  }

  void _showManageSharesDialog() {
    if (!currentList.isOwner || !currentList.isShared) {
      _showPermissionDenied(AppLocalizations.of(context)!.permActionManageShares);
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
      _showPermissionDenied(AppLocalizations.of(context)!.permActionEditItems);
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
      _showPermissionDenied(AppLocalizations.of(context)!.permActionAddItems);
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

  void _addItemByVoice() {
    if (!currentList.canManageItems) {
      _showPermissionDenied(AppLocalizations.of(context)!.permActionAddItems);
      return;
    }

    showVoiceInputDialog(
      context,
      onItemConfirmed: (itemName, quantity) {
        // Auto-catégorisation depuis le nom dicté (dictionnaire local)
        final categoryState = context.read<CategoryBloc>().state;
        final guessed = CategoryGuesser.guessCategory(
          categoryState is CategoryLoaded
              ? categoryState.categories
                  .where((c) => c.deletedAt == null)
                  .toList()
              : const [],
          itemName,
        );

        // Ajouter l'item avec les données reconnues par voix
        context.read<ListItemBloc>().add(
          AddListItem(
            listId: currentList.id,
            productName: itemName,
            quantity: quantity.toInt(),
            categoryId: guessed?.id,
            storeName: null,
            price: null,
          ),
        );

        // Le message de succès sera affiché par le listener
        // sauf si c'est un doublon (alors le dialogue s'affichera)
      },
    );
  }

  void _showDuplicateDialog(ListItemDuplicateDetected state) {
    final duplicate = state.duplicates.first; // Prendre le premier doublon

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(AppLocalizations.of(context)!.itemAlreadyPresent)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              duplicate.suggestionType == DuplicateType.exactMatch
                  ? AppLocalizations.of(context)!.itemExistsInList
                  : AppLocalizations.of(context)!.similarItemExists,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    duplicate.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quantité actuelle: ${duplicate.quantity}',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  if (duplicate.storeName != null)
                    Text(
                      'Magasin: ${duplicate.storeName}',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.whatToDo,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Fusionner avec l'item existant (augmenter la quantité)
              context.read<ListItemBloc>().add(
                MergeWithExistingItem(
                  listId: state.listId,
                  existingItemId: duplicate.id,
                  additionalQuantity: state.quantity,
                ),
              );
              SmartSnackBarManager.showMessage(
                context,
                '✅ Quantité mise à jour: ${duplicate.quantity + state.quantity}',
                type: SnackBarType.success,
              );
            },
            child: Text('Augmenter la quantité (+${state.quantity})'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Forcer l'ajout malgré le doublon
              context.read<ListItemBloc>().add(
                ForceAddListItem(
                  listId: state.listId,
                  productName: state.productName,
                  quantity: state.quantity,
                  storeName: state.storeName,
                  price: state.price,
                ),
              );
            },
            child: Text(AppLocalizations.of(context)!.addAnyway),
          ),
        ],
      ),
    );
  }

  void _showPermissionDenied(String action) {
    String title;
    String message;
    String permission;

    if (currentList.isReadOnly) {
      title = AppLocalizations.of(context)!.readOnlyAccess;
      permission = currentList.permissionDisplayName ?? AppLocalizations.of(context)!.readOnly;
      message =
          '${AppLocalizations.of(context)!.permReadOnlyMessage(action)}\n\n'
          '${AppLocalizations.of(context)!.yourCurrentPermission(permission)}';
    } else {
      title = AppLocalizations.of(context)!.insufficientPermission;
      permission = currentList.permissionDisplayName ?? AppLocalizations.of(context)!.limitedPermission;
      message =
          '${AppLocalizations.of(context)!.permNoPermissionMessage(action)}\n\n'
          '${AppLocalizations.of(context)!.yourCurrentPermission(permission)}';
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
                        ? AppColors.accent
                        : AppColors.warning,
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
                    color: AppColors.textSecondary,
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
