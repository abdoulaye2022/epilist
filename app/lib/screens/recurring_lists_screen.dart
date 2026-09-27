// screens/recurring_lists_screen.dart - Listes récurrentes intelligentes :
// modèles (hebdo / 2 semaines / mensuel), génération avec aperçu
// pré-coché selon les habitudes (validation en quelques secondes, §34).
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/intelligence.dart';
import 'package:epilist/services/intelligence_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
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
    _load();
  }

  Future<void> _load() async {
    try {
      final lists =
          await context.read<IntelligenceService>().getRecurringLists();
      if (!mounted) return;
      setState(() {
        _lists = lists;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _recurrenceLabel(AppLocalizations l10n, String type) =>
      switch (type) {
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
      builder: (_) => _PreviewSheet(listName: list.name, items: items),
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

  // --- Création / édition du modèle ------------------------------------

  Future<void> _edit([RecurringListModel? existing]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditSheet(
        existing: existing,
        service: context.read<IntelligenceService>(),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(RecurringListModel list) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(list.name),
        content: Text(l10n.deleteRecurringConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.delete)),
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
      appBar: AppBar(title: Text(l10n.recurringListsTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(),
        backgroundColor: AppColors.primary,
        tooltip: l10n.newRecurringList,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _lists.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        Icon(Icons.event_repeat_outlined,
                            size: 56, color: Colors.grey[400]),
                        const SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl),
                          child: Text(
                            l10n.recurringEmpty,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 13.5,
                                color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md, AppSpacing.sm, AppSpacing.md, 96),
                      itemCount: _lists.length,
                      itemBuilder: (context, index) {
                        final list = _lists[index];
                        return Card(
                          margin:
                              const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(list.name,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert,
                                          size: 20,
                                          color: AppColors.textDisabled),
                                      onSelected: (v) => v == 'edit'
                                          ? _edit(list)
                                          : _delete(list),
                                      itemBuilder: (_) => [
                                        PopupMenuItem(
                                            value: 'edit',
                                            child: Text(l10n.edit)),
                                        PopupMenuItem(
                                            value: 'delete',
                                            child: Text(l10n.delete)),
                                      ],
                                    ),
                                  ],
                                ),
                                Text(
                                  '${_recurrenceLabel(l10n, list.recurrenceType)}'
                                  '${list.nextRunAt != null ? ' · ${l10n.nextRunOn(DateFormat('d MMM', locale).format(list.nextRunAt!))}' : ''}'
                                  ' · ${list.items.length} ${l10n.items}',
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.tonalIcon(
                                    onPressed: () => _prepare(list),
                                    icon: const Icon(Icons.playlist_add_check,
                                        size: 18),
                                    label: Text(l10n.prepareMyList),
                                  ),
                                ),
                              ],
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
  final String listName;
  final List<RecurringPreviewItem> items;

  const _PreviewSheet({required this.listName, required this.items});

  @override
  State<_PreviewSheet> createState() => _PreviewSheetState();
}

class _PreviewSheetState extends State<_PreviewSheet> {
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
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
        child: Column(
          children: [
            Text(l10n.recurringListReady,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800)),
            Text(widget.listName,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  return CheckboxListTile(
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: item.suggested,
                    onChanged: (v) =>
                        setState(() => item.suggested = v ?? false),
                    title: Text(item.productName,
                        style: const TextStyle(fontSize: 14)),
                    subtitle: Text(reasonLabel(item.reason),
                        style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary)),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(
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
  late List<String> _products;
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
    _products = e?.items.map((i) => i.productName).toList() ?? [];
  }

  @override
  void dispose() {
    _name.dispose();
    _product.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_name.text.trim().isEmpty || _products.isEmpty) {
      SmartSnackBarManager.showErrorSnackBar(context, l10n.allFieldsRequired);
      return;
    }
    setState(() => _saving = true);
    try {
      if (widget.existing == null) {
        await widget.service.createRecurringList(
          name: _name.text.trim(),
          recurrenceType: _type,
          weekday: _type == 'monthly' ? null : _weekday,
          autoGenerate: _autoGenerate,
          productNames: _products,
        );
      } else {
        await widget.service.updateRecurringList(widget.existing!.id, {
          'name': _name.text.trim(),
          'recurrence_type': _type,
          'weekday': _type == 'monthly' ? null : _weekday,
          'auto_generate': _autoGenerate,
          'items': _products.map((n) => {'product_name': n}).toList(),
        });
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      SmartSnackBarManager.showErrorSnackBar(context, l10n.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final weekdays = DateFormat.EEEE(Localizations.localeOf(context).languageCode);

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              widget.existing == null
                  ? l10n.newRecurringList
                  : l10n.edit,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
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
              title: Text(l10n.autoGenerateLabel,
                  style: const TextStyle(fontSize: 14)),
              subtitle: Text(l10n.autoGenerateHint,
                  style: const TextStyle(fontSize: 12)),
              value: _autoGenerate,
              onChanged: (v) => setState(() => _autoGenerate = v),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.recurringProducts,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final p in _products)
                  Chip(
                    label: Text(p, style: const TextStyle(fontSize: 12.5)),
                    onDeleted: () => setState(() => _products.remove(p)),
                  ),
              ],
            ),
            TextField(
              controller: _product,
              decoration: InputDecoration(
                labelText: l10n.inventoryProductName,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final v = _product.text.trim();
                    if (v.isNotEmpty && !_products.contains(v)) {
                      setState(() => _products.add(v));
                    }
                    _product.clear();
                  },
                ),
              ),
              onSubmitted: (v) {
                if (v.trim().isNotEmpty && !_products.contains(v.trim())) {
                  setState(() => _products.add(v.trim()));
                }
                _product.clear();
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.save),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
