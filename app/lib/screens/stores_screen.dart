// screens/stores_screen.dart - Mes magasins (tri par rayon)
import 'package:epilist/theme/app_theme.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          l10n.myStores,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStoreNameDialog(context),
        backgroundColor: AppColors.primary,
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
              'stores_merged' => l10n.storesMerged,
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
            Icon(Icons.storefront, size: 72, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text(
              l10n.noStoresYet,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noStoresHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
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
    // Magasin créé hors ligne, pas encore synchronisé : édition bloquée
    // tant que le serveur ne lui a pas donné son vrai id.
    final pendingSync = store.id < 0;

    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: configured ? AppColors.primaryLight : AppColors.background,
          child: Icon(
            Icons.storefront,
            color: configured ? AppColors.primary : AppColors.textDisabled,
          ),
        ),
        title: Text(
          store.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          pendingSync
              ? l10n.storePendingSync
              : configured
                  ? '${l10n.aisleOrder} : ${store.categoryOrder.length}'
                  : l10n.aisleOrder,
          style: TextStyle(
            fontSize: 13,
            color: pendingSync
                ? AppColors.warning
                : configured
                    ? AppColors.primaryDark
                    : AppColors.textDisabled,
          ),
        ),
        trailing: pendingSync
            ? Icon(Icons.cloud_upload, color: Colors.orange[400])
            : PopupMenuButton<String>(
          color: Colors.white,
          onSelected: (value) {
            switch (value) {
              case 'rename':
                _showStoreNameDialog(context, store: store);
                break;
              case 'merge':
                _showMergeDialog(context, l10n, store);
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
                  Icon(Icons.edit, size: 20, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(l10n.renameStore,
                      style: const TextStyle(color: AppColors.textPrimary)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'merge',
              child: Row(
                children: [
                  Icon(Icons.merge, size: 20, color: Colors.teal[600]),
                  const SizedBox(width: 8),
                  Text(l10n.mergeStore,
                      style: const TextStyle(color: AppColors.textPrimary)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text(l10n.deleteStore,
                      style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
        onTap: pendingSync
            ? null
            : () {
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
          style: const TextStyle(color: AppColors.textPrimary),
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
              backgroundColor: AppColors.primary,
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

  void _showMergeDialog(BuildContext context, AppLocalizations l10n, Store source) {
    final bloc = context.read<StoreBloc>();
    final state = bloc.state;
    final all = switch (state) {
      StoreLoaded(:final stores) => stores,
      StoreOperationSuccess(:final stores) => stores,
      StoreError(:final stores) => stores,
      _ => const <Store>[],
    };
    final targets =
        all.where((s) => s.id != source.id && s.id > 0).toList();
    if (targets.isEmpty) return;

    showDialog(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        backgroundColor: Colors.white,
        title: Text(
          '${l10n.mergeStore} ${source.name}',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
        ),
        children: targets
            .map(
              (target) => SimpleDialogOption(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _confirmMerge(context, l10n, source, target);
                },
                child: Row(
                  children: [
                    Icon(Icons.storefront, size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(target.name,
                          style: const TextStyle(color: AppColors.textPrimary)),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  void _confirmMerge(
    BuildContext context,
    AppLocalizations l10n,
    Store source,
    Store target,
  ) {
    final bloc = context.read<StoreBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(l10n.mergeStore,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
          l10n.mergeStoreConfirm(source.name, target.name),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal[600],
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              bloc.add(MergeStores(source.id, target.id));
            },
            child: Text(l10n.mergeStore),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppLocalizations l10n, Store store) {
    final bloc = context.read<StoreBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          l10n.deleteStore,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.deleteStoreConfirm(store.name),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
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
