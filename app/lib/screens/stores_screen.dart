// screens/stores_screen.dart - Mes magasins (tri par rayon)
import 'package:epilist/widgets/common/app_top_bar.dart';
import 'package:epilist/widgets/common/app_drawer.dart';
import 'package:epilist/widgets/common/main_bottom_bar.dart';
import 'package:epilist/widgets/common/main_shell_scope.dart';
import 'package:epilist/screens/price_alerts_screen.dart';
import 'package:epilist/services/space_service.dart';
import 'package:epilist/services/store_favorites.dart';
import 'package:epilist/widgets/common/app_states.dart';
import 'package:epilist/widgets/common/store_front.dart';
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
      create:
          (context) =>
              StoreBloc(storeService: context.read<StoreService>())
                ..add(const LoadStores()),
      child: const _StoresView(),
    );
  }
}

class _StoresView extends StatefulWidget {
  const _StoresView();

  @override
  State<_StoresView> createState() => _StoresViewState();
}

class _StoresViewState extends State<_StoresView> {
  /// Nombre d'alertes de prix ACTIVES par magasin. `null` tant que la
  /// requete n'a pas repondu — et elle peut ne jamais repondre : la
  /// ligne « alertes actives » disparait alors, au lieu d'afficher
  /// zero, qui serait un mensonge.
  Map<int, int>? _alertesParMagasin;

  @override
  void initState() {
    super.initState();
    _chargerAlertes();
  }

  Future<void> _chargerAlertes() async {
    try {
      final alertes = await context.read<SpaceService>().getPriceAlerts();
      if (!mounted) return;
      final compte = <int, int>{};
      for (final a in alertes) {
        if (!a.isActive || a.storeId == null) continue;
        compte[a.storeId!] = (compte[a.storeId!] ?? 0) + 1;
      }
      setState(() => _alertesParMagasin = compte);
    } catch (_) {
      // Sans reponse, on n'ecrit rien sur les alertes.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      bottomNavigationBar: const AppPageBottomBar(tab: MainTab.sections),
      appBar: AppTopBar(title: l10n.myStores),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStoreNameDialog(context),
        backgroundColor: AppColors.primary,
        icon: Icon(Icons.add_business, color: AppColors.onPrimary),
        label: Text(
          l10n.addStore,
          style: TextStyle(color: AppColors.onPrimary),
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
            onRefresh:
                () async => context.read<StoreBloc>().add(const LoadStores()),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: stores.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      l10n.storesIntro,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                final store = stores[index - 1];
                return _buildStoreCard(
                  context,
                  l10n,
                  store,
                  _alertesParMagasin?[store.id] ??
                      (_alertesParMagasin == null ? null : 0),
                );
              },
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
              style: TextStyle(
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

  /// La carte d'un magasin, comme sur la planche : sa devanture, ce
  /// qu'on sait de lui en phrases, son etoile avec l'etat ECRIT, et ses
  /// deux actions.
  ///
  /// Avant, tout cela tenait dans une `ListTile` : une pastille grise
  /// identique pour chaque magasin, un sous-titre de 13 points, et
  /// l'ordre des rayons atteignable par un appui sur la ligne — sans
  /// que rien ne dise qu'elle etait touchable.
  Widget _buildStoreCard(
    BuildContext context,
    AppLocalizations l10n,
    Store store,
    int? alertes,
  ) {
    final configured = store.hasAisleOrder;
    // Magasin créé hors ligne, pas encore synchronisé : édition bloquée
    // tant que le serveur ne lui a pas donné son vrai id.
    final pendingSync = store.id < 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border, width: 2),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              image: true,
              label: l10n.storeFrontOf(store.name),
              child: StoreFront(seed: store.id),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          store.name,
                          style: AppFonts.displayStyle(
                            size: 23,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (pendingSync)
                        Icon(Icons.cloud_upload, color: AppColors.warningInk)
                      else
                        _storeMenu(context, l10n, store),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    pendingSync
                        ? l10n.storePendingSync
                        : configured
                        ? l10n.storeAisleConfigured(store.categoryOrder.length)
                        : l10n.storeAisleMissing,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (alertes != null) ...[
                    const SizedBox(height: AppSpacing.xs + 2),
                    Text(
                      l10n.storeActiveAlerts(alertes),
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm + 4),
                  ValueListenableBuilder<Set<int>>(
                    valueListenable: storeFavorites,
                    builder: (context, favoris, _) {
                      final favori = favoris.contains(store.id);
                      return AppFavoriteButton(
                        favorite: favori,
                        label:
                            favori
                                ? l10n.storeFavoriteYes
                                : l10n.storeFavoriteNo,
                        onPressed: () => storeFavorites.toggle(store.id),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm + 4),
                  OutlinedButton.icon(
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PriceAlertsScreen(),
                          ),
                        ),
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: Text(l10n.storeSeeAlerts),
                  ),
                  const SizedBox(height: AppSpacing.sm + 4),
                  FilledButton.icon(
                    onPressed:
                        pendingSync
                            ? null
                            : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => BlocProvider.value(
                                      value: context.read<StoreBloc>(),
                                      child: StoreAisleOrderScreen(
                                        storeId: store.id,
                                      ),
                                    ),
                              ),
                            ),
                    icon: const Icon(Icons.reorder_rounded),
                    label: Text(l10n.aisleOrder),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Renommer, fusionner, supprimer.
  Widget _storeMenu(BuildContext context, AppLocalizations l10n, Store store) {
    return PopupMenuButton<String>(
      color: AppColors.surface,
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
      itemBuilder:
          (context) => [
            PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(
                    l10n.renameStore,
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'merge',
              child: Row(
                children: [
                  Icon(Icons.merge, size: 20, color: AppColors.teal),
                  const SizedBox(width: 8),
                  Text(
                    l10n.mergeStore,
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text(
                    l10n.deleteStore,
                    style: TextStyle(color: AppColors.error),
                  ),
                ],
              ),
            ),
          ],
    );
  }

  void _showStoreNameDialog(BuildContext context, {Store? store}) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: store?.name ?? '');
    final bloc = context.read<StoreBloc>();

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              store == null ? l10n.addStore : l10n.renameStore,
              style: TextStyle(color: AppColors.textPrimary),
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
              onSubmitted:
                  (_) => _submitStoreName(
                    dialogContext,
                    bloc,
                    controller.text,
                    store,
                  ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
                onPressed:
                    () => _submitStoreName(
                      dialogContext,
                      bloc,
                      controller.text,
                      store,
                    ),
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

  void _showMergeDialog(
    BuildContext context,
    AppLocalizations l10n,
    Store source,
  ) {
    final bloc = context.read<StoreBloc>();
    final state = bloc.state;
    final all = switch (state) {
      StoreLoaded(:final stores) => stores,
      StoreOperationSuccess(:final stores) => stores,
      StoreError(:final stores) => stores,
      _ => const <Store>[],
    };
    final targets = all.where((s) => s.id != source.id && s.id > 0).toList();
    if (targets.isEmpty) return;

    showDialog(
      context: context,
      builder:
          (dialogContext) => SimpleDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              '${l10n.mergeStore} ${source.name}',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
            ),
            children:
                targets
                    .map(
                      (target) => SimpleDialogOption(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _confirmMerge(context, l10n, source, target);
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.storefront,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                target.name,
                                style: TextStyle(color: AppColors.textPrimary),
                              ),
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
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              l10n.mergeStore,
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: Text(
              l10n.mergeStoreConfirm(source.name, target.name),
              style: TextStyle(color: AppColors.textPrimary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: AppColors.onPrimary,
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

  void _confirmDelete(
    BuildContext context,
    AppLocalizations l10n,
    Store store,
  ) {
    final bloc = context.read<StoreBloc>();
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              l10n.deleteStore,
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: Text(
              l10n.deleteStoreConfirm(store.name),
              style: TextStyle(color: AppColors.textPrimary),
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
