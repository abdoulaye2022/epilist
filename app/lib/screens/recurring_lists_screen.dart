// screens/recurring_lists_screen.dart - Listes récurrentes intelligentes :
// modèles (hebdo / 2 semaines / mensuel), génération avec aperçu
// pré-coché selon les habitudes (validation en quelques secondes, §34).
//
// Le contenu d'une liste récurrente ÉTAIT une phrase, et rien d'autre :
// « Contenu : lait, œufs, pain… ». On ne pouvait pas la modifier. Elle
// s'ouvre maintenant d'un appui sur sa carte, article par article, avec
// sa quantité.
//
// Deux choses s'écrivent, parce qu'elles sont la confusion la plus
// fréquente avec les listes récurrentes : modifier le modèle ne change
// pas la liste déjà générée, et décocher un article dans l'aperçu ne le
// retire QUE de cette liste-ci.
import 'package:epilist/widgets/common/app_top_bar.dart';
import 'package:epilist/widgets/common/app_drawer.dart';
import 'package:epilist/widgets/common/main_bottom_bar.dart';
import 'package:epilist/widgets/common/main_shell_scope.dart';
import 'package:epilist/widgets/common/app_states.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/intelligence.dart';
import 'package:epilist/services/screen_cache.dart';
import 'package:epilist/services/intelligence_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class RecurringListsScreen extends StatefulWidget {
  const RecurringListsScreen({super.key});

  @override
  State<RecurringListsScreen> createState() => _RecurringListsScreenState();
}

class _RecurringListsScreenState extends State<RecurringListsScreen> {
  List<RecurringListModel> _lists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Derniere version connue d'abord, rafraichissement en silence.
    final cached = ScreenCache.read<List<RecurringListModel>>(
      'recurring_lists',
    );
    if (cached != null) {
      _lists = cached;
      _loading = false;
    }
    _load();
  }

  Future<void> _load() async {
    try {
      final lists =
          await context.read<IntelligenceService>().getRecurringLists();
      if (!mounted) return;
      ScreenCache.write('recurring_lists', lists);
      setState(() {
        _lists = lists;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _recurrenceLabel(AppLocalizations l10n, String type) => switch (type) {
    'biweekly' => l10n.recurrenceBiweekly,
    'monthly' => l10n.recurrenceMonthly,
    _ => l10n.recurrenceWeekly,
  };

  // --- Génération : aperçu pré-coché puis création --------------------

  Future<void> _prepare(RecurringListModel list) async {
    final l10n = AppLocalizations.of(context)!;
    final service = context.read<IntelligenceService>();

    List<RecurringPreviewItem> items;
    try {
      items = await service.previewRecurringList(list.id);
    } catch (_) {
      if (mounted) SmartSnackBarManager.showErrorSnackBar(context, l10n.error);
      return;
    }
    if (!mounted || items.isEmpty) return;

    final confirmed = await showModalBottomSheet<List<RecurringPreviewItem>>(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => _PreviewSheet(
            list: list,
            items: items,
            service: service,
            onModelChanged: _load,
          ),
    );
    if (confirmed == null || confirmed.isEmpty || !mounted) return;

    try {
      await service.generateRecurringList(list.id, confirmed);
      if (!mounted) return;
      SmartSnackBarManager.showSuccessSnackBar(context, l10n.listCreated);
      _load();
    } catch (_) {
      if (mounted) SmartSnackBarManager.showErrorSnackBar(context, l10n.error);
    }
  }

  /// Activer la liste ou la mettre en pause.
  ///
  /// La bascule etait enfermee dans la feuille d'edition, sous le nom
  /// « generation automatique » : mettre une liste en pause demandait
  /// d'ouvrir un formulaire. Elle est maintenant sur la carte, avec son
  /// etat ECRIT a cote — un interrupteur ne dit son etat que par une
  /// position et une couleur.
  Future<void> _toggleEnabled(RecurringListModel list, bool enabled) async {
    final l10n = AppLocalizations.of(context)!;
    final service = context.read<IntelligenceService>();

    // Optimiste : l'interrupteur doit repondre tout de suite. En cas
    // d'echec, on remet l'etat precedent et on le dit.
    setState(() {
      final i = _lists.indexWhere((e) => e.id == list.id);
      if (i >= 0) _lists[i] = _withEnabled(list, enabled);
    });
    try {
      await service.updateRecurringList(list.id, {'enabled': enabled});
    } catch (_) {
      if (!mounted) return;
      setState(() {
        final i = _lists.indexWhere((e) => e.id == list.id);
        if (i >= 0) _lists[i] = _withEnabled(list, !enabled);
      });
      SmartSnackBarManager.showErrorSnackBar(context, l10n.error);
    }
  }

  RecurringListModel _withEnabled(RecurringListModel l, bool enabled) =>
      RecurringListModel(
        id: l.id,
        name: l.name,
        recurrenceType: l.recurrenceType,
        weekday: l.weekday,
        nextRunAt: l.nextRunAt,
        enabled: enabled,
        autoGenerate: l.autoGenerate,
        items: l.items,
      );

  // --- Création / édition du modèle ------------------------------------

  Future<void> _edit([RecurringListModel? existing]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => _EditSheet(
            existing: existing,
            service: context.read<IntelligenceService>(),
          ),
    );
    if (saved == true) _load();
  }

  /// Dupliquer un modèle : la même fréquence, le même contenu, un nom
  /// qui dit que c'en est une copie.
  Future<void> _duplicate(RecurringListModel list) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await context.read<IntelligenceService>().createRecurringList(
        name: l10n.recurringCopySuffix(list.name),
        recurrenceType: list.recurrenceType,
        weekday: list.weekday,
        autoGenerate: list.autoGenerate,
        productNames: list.items.map((i) => i.productName).toList(),
      );
      if (!mounted) return;
      await _load();
    } catch (_) {
      if (!mounted) return;
      SmartSnackBarManager.showErrorSnackBar(context, l10n.error);
    }
  }

  Future<void> _delete(RecurringListModel list) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(list.name),
            content: Text(l10n.deleteRecurringConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.delete),
              ),
            ],
          ),
    );
    if (ok != true || !mounted) return;
    await context.read<IntelligenceService>().deleteRecurringList(list.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      bottomNavigationBar: const AppPageBottomBar(tab: MainTab.lists),
      appBar: AppTopBar(title: l10n.recurringListsTitle),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(),
        backgroundColor: AppColors.primary,
        tooltip: l10n.newRecurringList,
        child: Icon(Icons.add, color: AppColors.onPrimary),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _load,
                child:
                    _lists.isEmpty
                        ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 120),
                            Icon(
                              AppIcons.recurring,
                              size: 56,
                              color: AppColors.textDisabled,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl,
                              ),
                              child: Text(
                                l10n.recurringEmpty,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        )
                        : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                            96,
                          ),
                          itemCount: _lists.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                child: Text(
                                  l10n.recurringIntro,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              );
                            }
                            final list = _lists[index - 1];
                            return Card(
                              margin: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                // Toucher la carte OUVRE la liste. Le
                                // seul chemin vers son contenu passait
                                // par un menu « ⋮ » et une entree
                                // « Modifier ».
                                onTap: () => _edit(list),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              list.name,
                                              style: AppFonts.displayStyle(
                                                size: 23,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            icon: Icon(
                                              Icons.more_vert,
                                              size: 20,
                                              color: AppColors.textDisabled,
                                            ),
                                            onSelected:
                                                (v) => switch (v) {
                                                  'edit' => _edit(list),
                                                  'duplicate' => _duplicate(
                                                    list,
                                                  ),
                                                  _ => _delete(list),
                                                },
                                            itemBuilder:
                                                (_) => [
                                                  PopupMenuItem(
                                                    value: 'edit',
                                                    child: Text(l10n.edit),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'duplicate',
                                                    child: Text(
                                                      l10n.recurringDuplicate,
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'delete',
                                                    child: Text(l10n.delete),
                                                  ),
                                                ],
                                          ),
                                        ],
                                      ),
                                      // Trois phrases completes, comme sur
                                      // la planche, au lieu d'une ligne
                                      // de fragments separes par des
                                      // points mediants.
                                      Text(
                                        [
                                          l10n.recurringFrequencyLabel(
                                            _recurrenceLabel(
                                              l10n,
                                              list.recurrenceType,
                                            ),
                                          ),
                                          if (list.nextRunAt != null)
                                            l10n.recurringNextLabel(
                                              DateFormat(
                                                'd MMMM',
                                                locale,
                                              ).format(list.nextRunAt!),
                                            ),
                                          if (list.items.isNotEmpty)
                                            l10n.recurringContentLabel(
                                              list.items
                                                  .map((e) => e.productName)
                                                  .join(', '),
                                            ),
                                          // « Lundi prochain : 12
                                          // articles » : savoir ce qui
                                          // vient avant que ça vienne.
                                          if (list.nextRunAt != null)
                                            l10n.recurringNextPreview(
                                              DateFormat(
                                                'EEEE d MMMM',
                                                locale,
                                              ).format(list.nextRunAt!),
                                              list.items.length,
                                            ),
                                        ].join(' '),
                                        style: TextStyle(
                                          fontSize: 18,
                                          height: 1.5,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm + 4),
                                      AppStateSwitch(
                                        value: list.enabled,
                                        stateLabel:
                                            list.enabled
                                                ? l10n.recurringStateOn
                                                : l10n.recurringStateOff,
                                        semanticLabel: l10n
                                            .recurringSwitchLabel(list.name),
                                        onChanged:
                                            (v) => _toggleEnabled(list, v),
                                      ),
                                      const SizedBox(height: AppSpacing.sm + 4),
                                      SizedBox(
                                        width: double.infinity,
                                        child: FilledButton.tonalIcon(
                                          onPressed: () => _prepare(list),
                                          icon: const Icon(
                                            Icons.playlist_add_check,
                                            size: 18,
                                          ),
                                          label: Text(l10n.prepareMyList),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        l10n.recurringOpenToEdit,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              ),
    );
  }
}

/// Aperçu de génération : « Votre liste est prête » avec cases à cocher
/// et raison de chaque proposition (§34).
class _PreviewSheet extends StatefulWidget {
  final RecurringListModel list;
  final List<RecurringPreviewItem> items;
  final IntelligenceService service;

  /// Appelé quand le MODÈLE a changé (un article retiré pour de bon),
  /// pour que la carte derrière la feuille se remette à jour.
  final VoidCallback onModelChanged;

  const _PreviewSheet({
    required this.list,
    required this.items,
    required this.service,
    required this.onModelChanged,
  });

  @override
  State<_PreviewSheet> createState() => _PreviewSheetState();
}

class _PreviewSheetState extends State<_PreviewSheet> {
  /// Retirer un article POUR DE BON : il ne reviendra plus dans les
  /// prochaines générations. Décocher, à côté, ne vaut que pour cette
  /// liste-ci — ce sont deux gestes différents, et ils doivent le
  /// rester.
  Future<void> _retireDuModele(RecurringPreviewItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final restants =
        widget.list.items
            .where((a) => a.productName != item.productName)
            .map(
              (a) => {
                'product_name': a.productName,
                'quantity': a.quantity,
                if (a.unit != null && a.unit!.isNotEmpty) 'unit': a.unit,
              },
            )
            .toList();

    try {
      await widget.service.updateRecurringList(widget.list.id, {
        'items': restants,
      });
      if (!mounted) return;
      setState(() {
        widget.items.remove(item);
        item.suggested = false;
      });
      widget.onModelChanged();
      SmartSnackBarManager.showSuccessSnackBar(
        context,
        l10n.recurringRemovedFromModel(item.productName, widget.list.name),
      );
    } catch (_) {
      if (!mounted) return;
      SmartSnackBarManager.showErrorSnackBar(context, l10n.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    String reasonLabel(String reason) => switch (reason) {
      'inventory_out' => l10n.reasonInventoryOut,
      'inventory_at_home' => l10n.reasonInventoryAtHome,
      'bought_recently' => l10n.reasonBoughtRecently,
      'prediction_due' => l10n.reasonPredictionDue,
      _ => l10n.reasonNormalCycle,
    };

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder:
          (context, scrollController) => Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: Column(
              children: [
                Text(
                  l10n.recurringListReady,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  widget.list.name,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // La portée du changement, écrite. Décocher ici ne vaut
                // que pour cette liste-ci ; c'est la confusion la plus
                // fréquente avec les listes récurrentes, et rien ne la
                // levait.
                Text(
                  l10n.recurringPreviewHint,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: widget.items.length,
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      return CheckboxListTile(
                        controlAffinity: ListTileControlAffinity.leading,
                        value: item.suggested,
                        onChanged:
                            (v) => setState(() => item.suggested = v ?? false),
                        title: Text(
                          item.productName,
                          style: const TextStyle(fontSize: 17.5),
                        ),
                        subtitle: Text(
                          reasonLabel(item.reason),
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        secondary: IconButton(
                          tooltip: l10n.recurringRemoveFromModel,
                          onPressed: () => _retireDuModele(item),
                          icon: Icon(
                            Icons.playlist_remove_rounded,
                            color: AppColors.errorInk,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed:
                            () => Navigator.of(context).pop(
                              widget.items.where((i) => i.suggested).toList(),
                            ),
                        child: Text(l10n.createTheList),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

/// Création / édition d'un modèle récurrent.
class _EditSheet extends StatefulWidget {
  final RecurringListModel? existing;
  final IntelligenceService service;

  const _EditSheet({this.existing, required this.service});

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _product;
  String _type = 'weekly';
  int _weekday = 6; // samedi
  bool _autoGenerate = false;

  /// Les articles du modèle, avec leur QUANTITÉ. La feuille ne gardait
  /// que des noms : « 2 litres de lait » revenait en « lait ».
  late List<RecurringItem> _articles;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _product = TextEditingController();
    _type = e?.recurrenceType ?? 'weekly';
    _weekday = e?.weekday ?? 6;
    _autoGenerate = e?.autoGenerate ?? false;
    _articles = [...?e?.items];
  }

  @override
  void dispose() {
    _name.dispose();
    _product.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_name.text.trim().isEmpty || _articles.isEmpty) {
      SmartSnackBarManager.showErrorSnackBar(context, l10n.allFieldsRequired);
      return;
    }
    setState(() => _saving = true);
    try {
      // Un seul chemin pour les deux cas : le serveur lit « quantity »
      // la ou il rend « default_quantity ».
      final items =
          _articles
              .map(
                (a) => {
                  'product_name': a.productName,
                  'quantity': a.quantity,
                  if (a.unit != null && a.unit!.isNotEmpty) 'unit': a.unit,
                },
              )
              .toList();

      if (widget.existing == null) {
        await widget.service.createRecurringListWithItems(
          name: _name.text.trim(),
          recurrenceType: _type,
          weekday: _type == 'monthly' ? null : _weekday,
          autoGenerate: _autoGenerate,
          items: items,
        );
      } else {
        await widget.service.updateRecurringList(widget.existing!.id, {
          'name': _name.text.trim(),
          'recurrence_type': _type,
          'weekday': _type == 'monthly' ? null : _weekday,
          'auto_generate': _autoGenerate,
          'items': items,
        });
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      SmartSnackBarManager.showErrorSnackBar(context, l10n.error);
    }
  }

  void _ajoute(String brut) {
    final nom = brut.trim();
    if (nom.isEmpty) {
      return;
    }
    final existe = _articles.any(
      (a) => a.productName.toLowerCase() == nom.toLowerCase(),
    );
    if (!existe) {
      setState(() => _articles.add(RecurringItem(productName: nom)));
    }
    _product.clear();
  }

  void _quantite(int index, int delta) {
    final a = _articles[index];
    final cible = (a.quantity + delta).clamp(1, 99);
    if (cible == a.quantity) return;
    setState(
      () =>
          _articles[index] = RecurringItem(
            productName: a.productName,
            quantity: cible,
            unit: a.unit,
            optional: a.optional,
          ),
    );
  }

  /// Un article du modèle : son nom, sa quantité réglable, et le
  /// retrait.
  Widget _ligneArticle(AppLocalizations l10n, int index, RecurringItem a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              a.unit != null && a.unit!.isNotEmpty
                  ? '${a.productName} (${a.unit})'
                  : a.productName,
              style: TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.inventoryMinusOne,
            onPressed: a.quantity > 1 ? () => _quantite(index, -1) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          Text(
            '${a.quantity}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          IconButton(
            tooltip: l10n.inventoryPlusOne,
            onPressed: () => _quantite(index, 1),
            icon: const Icon(Icons.add_rounded),
          ),
          IconButton(
            tooltip: l10n.delete,
            onPressed: () => setState(() => _articles.removeAt(index)),
            icon: Icon(Icons.close_rounded, color: AppColors.errorInk),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final weekdays = DateFormat.EEEE(
      Localizations.localeOf(context).languageCode,
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder:
            (context, scrollController) => ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  widget.existing == null ? l10n.newRecurringList : l10n.edit,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: l10n.listName,
                    hintText: l10n.recurringNameHint,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final (value, label) in [
                      ('weekly', l10n.recurrenceWeekly),
                      ('biweekly', l10n.recurrenceBiweekly),
                      ('monthly', l10n.recurrenceMonthly),
                    ])
                      ChoiceChip(
                        label: Text(label),
                        selected: _type == value,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _type = value),
                      ),
                  ],
                ),
                if (_type != 'monthly') ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      for (var d = 1; d <= 7; d++)
                        ChoiceChip(
                          label: Text(
                            weekdays
                                .format(DateTime(2024, 1, d))
                                .substring(0, 3),
                          ),
                          selected: _weekday == d,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _weekday = d),
                        ),
                    ],
                  ),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.autoGenerateLabel,
                    style: const TextStyle(fontSize: 16),
                  ),
                  subtitle: Text(
                    l10n.autoGenerateHint,
                    style: const TextStyle(fontSize: 16),
                  ),
                  value: _autoGenerate,
                  onChanged: (v) => setState(() => _autoGenerate = v),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.recurringProducts,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                // Un article par ligne, avec sa quantite : « lait,
                // oeufs, pain... » en une phrase ne se modifiait pas.
                for (final (n, a) in _articles.indexed)
                  _ligneArticle(l10n, n, a),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _product,
                  decoration: InputDecoration(
                    labelText: l10n.recurringAddItem,
                    suffixIcon: IconButton(
                      tooltip: l10n.recurringAddItem,
                      icon: const Icon(Icons.add),
                      onPressed: () => _ajoute(_product.text),
                    ),
                  ),
                  onSubmitted: _ajoute,
                ),
                const SizedBox(height: AppSpacing.md),
                // La confusion la plus frequente avec les listes
                // recurrentes : croire que modifier le modele change la
                // liste deja creee.
                Text(
                  l10n.recurringEditHint,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child:
                      _saving
                          ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text(l10n.save),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
      ),
    );
  }
}
