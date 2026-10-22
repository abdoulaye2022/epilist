// utils/list_picker.dart - « Dans quelle liste ? », une fois pour toutes.
//
// Ce choix était recopié dans l'accueil (_pickTargetList), et nulle part
// ailleurs : toute action qui a besoin d'une liste — scanner un reçu,
// saisir une facture, un code-barres, une photo — n'était donc atteignable
// que depuis le tableau de bord. Le sélecteur vit ici, et fonctionne
// depuis n'importe quel écran.
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/list_item.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/services/list_item_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/widgets/common/app_empty_state.dart';
import 'package:epilist/widgets/common/app_search_field.dart';
import 'package:epilist/widgets/dialogs/create_list_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Les listes accessibles, en attendant le chargement si besoin.
/// L'ancien code lisait l'état du bloc sans jamais le déclencher : hors
/// de l'accueil, la liste pouvait être vide alors qu'elle existait.
Future<List<ShoppingList>> accessibleLists(BuildContext context) async {
  final bloc = context.read<ShoppingListBloc>();
  final state = bloc.state;
  if (state is ShoppingListLoaded) return state.lists;

  bloc.add(LoadShoppingLists());
  final settled = await bloc.stream
      .firstWhere((s) => s is ShoppingListLoaded || s is ShoppingListError)
      .timeout(const Duration(seconds: 15), onTimeout: () => bloc.state);
  return settled is ShoppingListLoaded ? settled.lists : const [];
}

/// Demande la liste cible. `null` si l'utilisateur renonce.
/// Une seule liste : pas de question posée. Aucune liste : on propose
/// d'en créer une, puisque c'est le seul geste qui débloque la suite.
Future<ShoppingList?> pickShoppingList(
  BuildContext context, {
  bool Function(ShoppingList list)? where,
}) async {
  final l10n = AppLocalizations.of(context)!;
  var lists = await accessibleLists(context);
  if (!context.mounted) return null;
  if (where != null) lists = lists.where(where).toList();

  if (lists.isEmpty) {
    SmartSnackBarManager.showInfoSnackBar(context, l10n.noListYet);
    final bloc = context.read<ShoppingListBloc>();
    await showDialog(
      context: context,
      builder:
          (dialogContext) =>
              BlocProvider.value(value: bloc, child: const CreateListDialog()),
    );
    return null;
  }
  if (lists.length == 1) return lists.first;

  return showModalBottomSheet<ShoppingList>(
    context: context,
    isScrollControlled: true,
    builder:
        (sheetContext) =>
            _ListPickerSheet(lists: lists, title: l10n.pickListTitle),
  );
}

class _ListPickerSheet extends StatefulWidget {
  const _ListPickerSheet({required this.lists, required this.title});

  final List<ShoppingList> lists;
  final String title;

  @override
  State<_ListPickerSheet> createState() => _ListPickerSheetState();
}

class _ListPickerSheetState extends State<_ListPickerSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final q = _query.trim().toLowerCase();
    final shown =
        q.isEmpty
            ? widget.lists
            : widget.lists
                .where((l) => l.name.toLowerCase().contains(q))
                .toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHandle(title: widget.title),
            // Au-delà de six listes, chercher est plus rapide que faire défiler.
            if (widget.lists.length > 6)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: AppSearchField(
                  controller: _search,
                  hintText: l10n.search,
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            Flexible(
              child:
                  shown.isEmpty
                      ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          l10n.noResultsFound,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: shown.length,
                        itemBuilder: (_, i) {
                          final list = shown[i];
                          return ListTile(
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm + 2,
                                ),
                              ),
                              child: Icon(
                                Icons.shopping_basket_outlined,
                                size: 20,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            title: Text(
                              list.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${list.items.length} ${l10n.itemsCount}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            onTap: () => Navigator.of(context).pop(list),
                          );
                        },
                      ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

/// Demande l'article cible dans la liste [listId]. `null` si on renonce.
Future<ListItem?> pickListItem(
  BuildContext context, {
  required int listId,
  required String title,
}) {
  return showModalBottomSheet<ListItem>(
    context: context,
    isScrollControlled: true,
    builder:
        (sheetContext) => _ItemPickerSheet(
          title: title,
          load: context.read<ListItemService>().getListItems(listId),
        ),
  );
}

class _ItemPickerSheet extends StatefulWidget {
  const _ItemPickerSheet({required this.title, required this.load});

  final String title;
  final Future<List<ListItem>> load;

  @override
  State<_ItemPickerSheet> createState() => _ItemPickerSheetState();
}

class _ItemPickerSheetState extends State<_ItemPickerSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHandle(title: widget.title),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: AppSearchField(
                  controller: _search,
                  hintText: l10n.search,
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<ListItem>>(
                  future: widget.load,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return AppEmptyState(
                        icon: Icons.cloud_off_rounded,
                        title: l10n.errorLoadingItems,
                      );
                    }
                    final q = _query.trim().toLowerCase();
                    final items =
                        (snap.data ?? const <ListItem>[])
                            .where(
                              (it) =>
                                  q.isEmpty ||
                                  it.productName.toLowerCase().contains(q),
                            )
                            .toList();
                    if (items.isEmpty) {
                      return AppEmptyState(
                        icon: Icons.inbox_outlined,
                        title:
                            q.isEmpty
                                ? l10n.noItemsInList
                                : l10n.noResultsFound,
                      );
                    }
                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final item = items[i];
                        return ListTile(
                          leading: Icon(
                            item.imageUrl?.isNotEmpty == true
                                ? Icons.image_outlined
                                : Icons.add_a_photo_outlined,
                            color: AppColors.textSecondary,
                          ),
                          title: Text(
                            item.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => Navigator.of(context).pop(item),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Poignée + titre : l'en-tête commun des feuilles de l'app.
class _SheetHandle extends StatelessWidget {
  const _SheetHandle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.sm + 2),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
      ],
    );
  }
}
