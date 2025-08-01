// screens/receipts_screen.dart
import 'package:epilist/blocs/receipt/receipt_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/receipt.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/widgets/receipts/add_receipt_dialog.dart';
import 'package:epilist/widgets/receipts/edit_receipt_dialog.dart';
import 'package:epilist/widgets/receipts/receipt_card.dart';
import 'package:epilist/widgets/receipts/receipt_stats_card.dart';
import 'package:epilist/widgets/receipts/store_group_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReceiptsScreen extends StatefulWidget {
  final ShoppingList shoppingList;

  const ReceiptsScreen({super.key, required this.shoppingList});

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final PageController _pageController;

  // ✅ AJOUT: Variables pour traquer l'état actuel de chaque onglet
  int _currentTabIndex = 0;
  bool _hasLoadedInitialData = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pageController = PageController();

    // ✅ Charger les données de l'onglet initial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataForCurrentTab();
      _hasLoadedInitialData = true;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ✅ NOUVEAU: Méthode centralisée pour charger les données selon l'onglet
  void _loadDataForCurrentTab() {
    switch (_currentTabIndex) {
      case 0:
        _loadReceipts();
        break;
      case 1:
        _loadReceiptsByStore();
        break;
      case 2:
        _loadStats();
        break;
    }
  }

  void _loadReceipts() {
    context.read<ReceiptBloc>().add(LoadReceipts(widget.shoppingList.id));
  }

  void _loadStats() {
    context.read<ReceiptBloc>().add(LoadReceiptStats(widget.shoppingList.id));
  }

  void _loadReceiptsByStore() {
    context.read<ReceiptBloc>().add(
      LoadReceiptsByStore(widget.shoppingList.id),
    );
  }

  // ✅ NOUVEAU: Méthode pour changer d'onglet avec gestion d'état
  void _onTabChanged(int index) {
    if (_currentTabIndex != index) {
      setState(() {
        _currentTabIndex = index;
      });

      // ✅ Recharger les données pour le nouvel onglet
      _loadDataForCurrentTab();

      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // ✅ NOUVELLE MÉTHODE: Gestionnaire du menu d'actions
  void _handleMenuAction(String action, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    switch (action) {
      case 'refresh':
        _loadDataForCurrentTab();
        SmartSnackBarManager.showInfoSnackBar(
          context,
          l10n.refreshing,
          duration: const Duration(seconds: 1),
        );
        break;
      case 'add_receipt':
        _showAddReceiptDialog();
        break;
      case 'export':
        _showExportDialog();
        break;
    }
  }

  // ✅ NOUVELLE MÉTHODE: Dialog d'export
  void _showExportDialog() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.file_download, color: Colors.green[600]),
                const SizedBox(width: 8),
                Text(l10n.export),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.exportReceiptsDescription),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _exportToPDF();
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('PDF'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red[600],
                          side: BorderSide(color: Colors.red[600]!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _exportToCSV();
                        },
                        icon: const Icon(Icons.table_chart),
                        label: const Text('CSV'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green[600],
                          side: BorderSide(color: Colors.green[600]!),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.cancel),
              ),
            ],
          ),
    );
  }

  // ✅ Méthodes d'export (à implémenter selon vos besoins)
  void _exportToPDF() {
    SmartSnackBarManager.showInfoSnackBar(
      context,
      'Export PDF en cours...',
      duration: const Duration(seconds: 2),
    );
  }

  void _exportToCSV() {
    SmartSnackBarManager.showInfoSnackBar(
      context,
      'Export CSV en cours...',
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      // ✅ CORRECTION: Background gris clair comme BudgetScreen
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        // ✅ CORRECTION: Style harmonisé avec BudgetScreen (fond blanc)
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.receipts,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green[700], // ✅ Texte vert au lieu de blanc
              ),
            ),
            Text(
              widget.shoppingList.name,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600], // ✅ Gris au lieu de blanc70
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white, // ✅ Fond blanc comme BudgetScreen
        foregroundColor: Colors.black, // ✅ Texte noir comme BudgetScreen
        elevation: 0, // ✅ Pas d'ombre comme BudgetScreen
        iconTheme: const IconThemeData(color: Colors.black), // ✅ Icônes noires
        // ✅ AJOUT: Menu d'actions comme dans BudgetScreen
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.black, // ✅ Icône noire
            ),
            tooltip: l10n.moreOptions,
            onSelected: (value) => _handleMenuAction(value, context),
            color: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 20, color: Colors.green[600]),
                        const SizedBox(width: 8),
                        Text(l10n.refresh),
                      ],
                    ),
                  ),
                  if (widget.shoppingList.canEdit) ...[
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'add_receipt',
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 20, color: Colors.blue[600]),
                          const SizedBox(width: 8),
                          Text(l10n.addReceipt),
                        ],
                      ),
                    ),
                  ],
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(
                          Icons.file_download,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(l10n.export),
                      ],
                    ),
                  ),
                ],
          ),
          const SizedBox(width: 8), // ✅ Espacement à droite comme BudgetScreen
        ],

        // ✅ TabBar avec style harmonisé (texte noir sur fond blanc)
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green[700], // ✅ Onglet sélectionné en vert
          unselectedLabelColor:
              Colors.grey[600], // ✅ Onglets non sélectionnés en gris
          indicatorColor: Colors.green[700], // ✅ Indicateur vert
          indicatorWeight: 3,
          onTap: _onTabChanged, // ✅ Garder la logique existante
          tabs: [
            Tab(
              icon: Icon(Icons.receipt_long, color: Colors.green[600]),
              text: l10n.allReceipts,
            ),
            Tab(
              icon: Icon(Icons.store, color: Colors.green[600]),
              text: l10n.byStore,
            ),
            Tab(
              icon: Icon(Icons.analytics, color: Colors.green[600]),
              text: l10n.statistics,
            ),
          ],
        ),
      ),
      body: BlocListener<ReceiptBloc, ReceiptState>(
        listener: (context, state) {
          if (state is ReceiptError) {
            SmartSnackBarManager.showErrorSnackBar(
              context,
              state.message,
              duration: const Duration(seconds: 3),
            );
          } else if (state is ReceiptOperationSuccess) {
            SmartSnackBarManager.showSuccessSnackBar(
              context,
              state.message,
              duration: const Duration(seconds: 2),
            );

            // ✅ NOUVEAU: Recharger les données après une opération réussie
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _loadDataForCurrentTab();
              }
            });
          }
        },
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            _tabController.animateTo(index);
            // ✅ CORRECTION: Mettre à jour l'index et recharger si nécessaire
            if (_currentTabIndex != index) {
              setState(() {
                _currentTabIndex = index;
              });
              _loadDataForCurrentTab();
            }
          },
          children: [
            _buildAllReceiptsTab(),
            _buildByStoreTab(),
            _buildStatsTab(),
          ],
        ),
      ),
      floatingActionButton:
          widget.shoppingList.canEdit
              ? FloatingActionButton(
                onPressed: _showAddReceiptDialog,
                backgroundColor: Colors.green[600],
                child: const Icon(Icons.add, color: Colors.white),
              )
              : null,
    );
  }

  Widget _buildAllReceiptsTab() {
    return BlocBuilder<ReceiptBloc, ReceiptState>(
      // ✅ NOUVEAU: Construire seulement si on est sur le bon onglet
      buildWhen: (previous, current) {
        return _currentTabIndex == 0 &&
            (current is ReceiptLoading ||
                current is ReceiptLoaded ||
                current is ReceiptError);
      },
      builder: (context, state) {
        if (state is ReceiptLoading && _currentTabIndex == 0) {
          return _buildLoadingState();
        }

        if (state is ReceiptLoaded && _currentTabIndex == 0) {
          if (state.receipts.isEmpty) {
            return _buildEmptyState();
          }
          return _buildReceiptsList(state.receipts);
        }

        if (state is ReceiptError && _currentTabIndex == 0) {
          return _buildErrorState(state.message);
        }

        // ✅ État par défaut si pas encore chargé
        if (_currentTabIndex == 0 && !_hasLoadedInitialData) {
          return _buildLoadingState();
        }

        return _buildEmptyState();
      },
    );
  }

  Widget _buildByStoreTab() {
    return BlocBuilder<ReceiptBloc, ReceiptState>(
      // ✅ NOUVEAU: Construire seulement si on est sur le bon onglet
      buildWhen: (previous, current) {
        return _currentTabIndex == 1 &&
            (current is ReceiptLoading ||
                current is ReceiptsByStoreLoaded ||
                current is ReceiptError);
      },
      builder: (context, state) {
        if (state is ReceiptLoading && _currentTabIndex == 1) {
          return _buildLoadingState();
        }

        if (state is ReceiptsByStoreLoaded && _currentTabIndex == 1) {
          if (state.storeGroups.isEmpty) {
            return _buildEmptyState();
          }
          return _buildStoreGroupsList(state.storeGroups);
        }

        if (state is ReceiptError && _currentTabIndex == 1) {
          return _buildErrorState(state.message);
        }

        // ✅ État par défaut si pas encore chargé
        if (_currentTabIndex == 1) {
          return _buildLoadingState();
        }

        return _buildEmptyState();
      },
    );
  }

  Widget _buildStatsTab() {
    return BlocBuilder<ReceiptBloc, ReceiptState>(
      // ✅ NOUVEAU: Construire seulement si on est sur le bon onglet
      buildWhen: (previous, current) {
        return _currentTabIndex == 2 &&
            (current is ReceiptLoading ||
                current is ReceiptStatsLoaded ||
                current is ReceiptError);
      },
      builder: (context, state) {
        if (state is ReceiptLoading && _currentTabIndex == 2) {
          return _buildLoadingState();
        }

        if (state is ReceiptStatsLoaded && _currentTabIndex == 2) {
          return _buildStatsView(state.stats);
        }

        if (state is ReceiptError && _currentTabIndex == 2) {
          return _buildErrorState(state.message);
        }

        // ✅ État par défaut si pas encore chargé
        if (_currentTabIndex == 2) {
          return _buildLoadingState();
        }

        return _buildEmptyState();
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(child: CircularProgressIndicator(color: Colors.green[600]));
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: Card(
            color: Colors.white, // ✅ Fond blanc comme BudgetScreen
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      size: 48,
                      color: Colors.green[300],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noReceipts,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Text(
                      l10n.addFirstReceipt,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                      maxLines: 3,
                    ),
                  ),
                  if (widget.shoppingList.canEdit) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showAddReceiptDialog,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addReceipt),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          child: Card(
            color: Colors.white, // ✅ Fond blanc comme BudgetScreen
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    l10n.error,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red[600],
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Text(
                      message,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                      maxLines: 4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // ✅ CORRECTION: Utiliser la méthode centralisée
                      _loadDataForCurrentTab();
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.retry),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptsList(List<Receipt> receipts) {
    return RefreshIndicator(
      onRefresh: () async => _loadReceipts(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: receipts.length,
        itemBuilder: (context, index) {
          final receipt = receipts[index];
          return ReceiptCard(
            receipt: receipt,
            canEdit: widget.shoppingList.canEdit,
            onEdit: () => _showEditReceiptDialog(receipt),
            onDelete: () => _showDeleteReceiptDialog(receipt),
          );
        },
      ),
    );
  }

  Widget _buildStoreGroupsList(List<StoreReceiptGroup> storeGroups) {
    return RefreshIndicator(
      onRefresh: () async => _loadReceiptsByStore(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: storeGroups.length,
        itemBuilder: (context, index) {
          final storeGroup = storeGroups[index];
          return StoreGroupCard(
            storeGroup: storeGroup,
            canEdit: widget.shoppingList.canEdit,
            onEditReceipt: (receipt) => _showEditReceiptDialog(receipt),
            onDeleteReceipt: (receipt) => _showDeleteReceiptDialog(receipt),
          );
        },
      ),
    );
  }

  Widget _buildStatsView(ReceiptStats stats) {
    return RefreshIndicator(
      onRefresh: () async => _loadStats(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ReceiptStatsCard(stats: stats),
      ),
    );
  }

  void _showAddReceiptDialog() {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<ReceiptBloc>(),
            child: AddReceiptDialog(listId: widget.shoppingList.id),
          ),
    );
  }

  void _showEditReceiptDialog(Receipt receipt) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<ReceiptBloc>(),
            child: EditReceiptDialog(
              listId: widget.shoppingList.id,
              receipt: receipt,
            ),
          ),
    );
  }

  void _showDeleteReceiptDialog(Receipt receipt) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: Colors.white, // ✅ Fond blanc pour cohérence
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.red[600]),
                const SizedBox(width: 8),
                Text(l10n.deleteReceipt),
              ],
            ),
            content: Text(l10n.deleteReceiptConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.read<ReceiptBloc>().add(
                    DeleteReceipt(
                      listId: widget.shoppingList.id,
                      receiptId: receipt.id,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.delete),
              ),
            ],
          ),
    );
  }
}
