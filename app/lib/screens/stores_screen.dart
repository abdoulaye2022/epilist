// screens/stores_screen.dart - Mes magasins (tri par rayon)
import 'package:epilist/blocs/store/store_bloc.dart';
import 'package:epilist/blocs/store/store_event.dart';
import 'package:epilist/blocs/store/store_state.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/store.dart';
import 'package:epilist/screens/store_aisle_order_screen.dart';
import 'package:epilist/services/store_service.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StoresScreen extends StatelessWidget {
  const StoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          StoreBloc(storeService: context.read<StoreService>())
            ..add(const LoadStores()),
      child: const _StoresView(),
    );
  }
}

class _StoresView extends StatelessWidget {
  const _StoresView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          l10n.myStores,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStoreNameDialog(context),
        backgroundColor: Colors.green[600],
        icon: const Icon(Icons.add_business, color: Colors.white),
        label: Text(
          l10n.addStore,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: BlocConsumer<StoreBloc, StoreState>(
        listener: (context, state) {
          if (state is StoreError) {
            SmartSnackBarManager.showErrorSnackBar(context, state.message);
          } else if (state is StoreOperationSuccess) {
            final message = switch (state.message) {
              'store_created' => l10n.storeCreated,
              'store_renamed' => l10n.storeRenamed,
              'store_deleted' => l10n.storeDeleted,
              'order_saved' => l10n.aisleOrderSaved,
              _ => state.message,
            };
            SmartSnackBarManager.showSuccessSnackBar(context, message);
          }
        },
        builder: (context, state) {
          if (state is StoreLoading || state is StoreInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          final stores = switch (state) {
            StoreLoaded(:final stores) => stores,
            StoreOperationSuccess(:final stores) => stores,
            StoreError(:final stores) => stores,
            _ => const <Store>[],
          };

          if (stores.isEmpty) {
            return _buildEmptyState(l10n);
          }

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<StoreBloc>().add(const LoadStores()),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: stores.length,
              itemBuilder: (context, index) =>
                  _buildStoreCard(context, l10n, stores[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              l10n.noStoresYet,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noStoresHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreCard(
    BuildContext context,
    AppLocalizations l10n,
    Store store,
  ) {
    final configured = store.hasAisleOrder;

    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: configured ? Colors.green[50] : Colors.grey[100],
          child: Icon(
            Icons.storefront,
            color: configured ? Colors.green[600] : Colors.grey[500],
          ),
        ),
        title: Text(
          store.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          configured
              ? '${l10n.aisleOrder} : ${store.categoryOrder.length}'
              : l10n.aisleOrder,
          style: TextStyle(
            fontSize: 13,
            color: configured ? Colors.green[700] : Colors.grey[500],
          ),
        ),
        trailing: PopupMenuButton<String>(
          color: Colors.white,
          onSelected: (value) {
            switch (value) {
              case 'rename':
                _showStoreNameDialog(context, store: store);
                break;
              case 'delete':
                _confirmDelete(context, l10n, store);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Text(l10n.renameStore,
                      style: const TextStyle(color: Colors.black87)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red[600]),
                  const SizedBox(width: 8),
                  Text(l10n.deleteStore,
                      style: TextStyle(color: Colors.red[600])),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<StoreBloc>(),
                child: StoreAisleOrderScreen(storeId: store.id),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showStoreNameDialog(BuildContext context, {Store? store}) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: store?.name ?? '');
    final bloc = context.read<StoreBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          store == null ? l10n.addStore : l10n.renameStore,
          style: const TextStyle(color: Colors.black87),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          maxLength: 120,
          decoration: InputDecoration(
            labelText: l10n.storeName,
            hintText: l10n.storeNameHint,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) =>
              _submitStoreName(dialogContext, bloc, controller.text, store),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
            onPressed: () =>
                _submitStoreName(dialogContext, bloc, controller.text, store),
            child: Text(store == null ? l10n.addStore : l10n.renameStore),
          ),
        ],
      ),
    );
  }

  void _submitStoreName(
    BuildContext dialogContext,
    StoreBloc bloc,
    String name,
    Store? store,
  ) {
    final trimmed = name.trim();
    if (trimmed.length < 2) return;
    Navigator.of(dialogContext).pop();
    if (store == null) {
      bloc.add(CreateStore(trimmed));
    } else {
      bloc.add(RenameStore(store.id, trimmed));
    }
  }

  void _confirmDelete(BuildContext context, AppLocalizations l10n, Store store) {
    final bloc = context.read<StoreBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          l10n.deleteStore,
          style: const TextStyle(color: Colors.black87),
        ),
        content: Text(
          l10n.deleteStoreConfirm(store.name),
          style: const TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red[600]),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              bloc.add(DeleteStore(store.id));
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
