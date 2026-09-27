// screens/receipt_validation_screen.dart - Validation d'un reçu scanné.
//
// Règle d'or : l'OCR PROPOSE, l'utilisateur DISPOSE. Tout est éditable,
// les lignes incertaines sont signalées, et rien n'est enregistré tant
// que l'utilisateur n'a pas appuyé sur « Enregistrer le reçu ».
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/parsed_receipt.dart';
import 'package:epilist/models/store.dart';
import 'package:epilist/services/price_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReceiptValidationScreen extends StatefulWidget {
  final int listId;
  final ParsedReceipt receipt;
  final List<Store> knownStores;

  /// 'receipt_ocr' quand le reçu vient du scanner, 'manual' sinon.
  final String source;

  const ReceiptValidationScreen({
    super.key,
    required this.listId,
    required this.receipt,
    this.knownStores = const [],
    this.source = 'receipt_ocr',
  });

  @override
  State<ReceiptValidationScreen> createState() =>
      _ReceiptValidationScreenState();
}

class _ReceiptValidationScreenState extends State<ReceiptValidationScreen> {
  late final TextEditingController _storeController;
  late final TextEditingController _totalController;
  late final TextEditingController _numberController;
  DateTime _date = DateTime.now();
  bool _saving = false;

  late final List<_EditableItem> _items;

  @override
  void initState() {
    super.initState();
    final r = widget.receipt;
    _storeController = TextEditingController(text: r.storeName ?? '');
    _totalController = TextEditingController(
      text: r.total?.toStringAsFixed(2) ?? '',
    );
    _numberController = TextEditingController(text: r.receiptNumber ?? '');
    _date = r.purchaseDate ?? DateTime.now();
    _items = r.items.map(_EditableItem.new).toList();
    _resolveLabels();
  }

  @override
  void dispose() {
    _storeController.dispose();
    _totalController.dispose();
    _numberController.dispose();
    for (final it in _items) {
      it.dispose();
    }
    super.dispose();
  }

  /// Pré-remplit les noms de produits à partir des correspondances
  /// serveur (alias appris, historique). Ne remplace jamais une saisie.
  Future<void> _resolveLabels() async {
    final labels = _items
        .where((it) => it.nameController.text.trim().isEmpty ||
            it.nameController.text == it.item.rawLabel)
        .map((it) => it.item.rawLabel)
        .toList();
    if (labels.isEmpty) return;
    try {
      final store = widget.knownStores
          .where((s) => s.name.toLowerCase() ==
              _storeController.text.trim().toLowerCase())
          .toList();
      final resolutions = await context.read<PriceService>().resolveLabels(
        labels,
        storeId: store.isEmpty ? null : store.first.id,
      );
      if (!mounted) return;
      setState(() {
        for (final res in resolutions) {
          if (res.match == null || res.confidence < 70) continue;
          for (final it in _items) {
            if (it.item.rawLabel == res.label &&
                (it.nameController.text.trim().isEmpty ||
                    it.nameController.text == it.item.rawLabel)) {
              it.nameController.text = res.match!;
              it.suggested = true;
            }
          }
        }
      });
    } catch (_) {
      // Hors ligne ou erreur : l'utilisateur saisit lui-même, rien ne bloque.
    }
  }

  double get _itemsSum => _items
      .where((it) => !it.item.isDiscount && !it.removed)
      .fold(0.0, (s, it) => s + (double.tryParse(
          it.priceController.text.replaceAll(',', '.')) ?? 0));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save({bool force = false}) async {
    final l10n = AppLocalizations.of(context)!;
    final store = _storeController.text.trim();
    final total = double.tryParse(_totalController.text.replaceAll(',', '.'));
    final items = _items.where((it) => !it.removed && !it.item.isDiscount);

    if (store.isEmpty || total == null || items.isEmpty) {
      SmartSnackBarManager.showErrorSnackBar(
        context, l10n.allFieldsRequired);
      return;
    }

    setState(() => _saving = true);
    try {
      final payload = items.map((it) {
        final i = it.item;
        return ParsedReceiptItem(
          rawLabel: i.rawLabel,
          productName: it.nameController.text.trim().isEmpty
              ? null
              : it.nameController.text.trim(),
          quantity: double.tryParse(
                  it.qtyController.text.replaceAll(',', '.')) ??
              i.quantity,
          unit: i.unit,
          unitPrice: i.unitPrice,
          linePrice: double.tryParse(
                  it.priceController.text.replaceAll(',', '.')) ??
              i.linePrice,
          confidence: i.confidence,
        );
      }).toList();

      await context.read<PriceService>().importReceipt(
        listId: widget.listId,
        storeName: store,
        purchaseDate: _date,
        totalAmount: total,
        subtotal: widget.receipt.subtotal,
        taxes: widget.receipt.taxes,
        receiptNumber: _numberController.text.trim(),
        items: payload,
        source: widget.source,
        force: force,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      SmartSnackBarManager.showSuccessSnackBar(context, l10n.receiptSaved);
    } on DuplicateReceiptException {
      if (!mounted) return;
      setState(() => _saving = false);
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.duplicateReceiptTitle),
          content: Text(l10n.duplicateReceiptMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.saveAnyway),
            ),
          ],
        ),
      );
      if (confirm == true) await _save(force: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      SmartSnackBarManager.showErrorSnackBar(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visibleItems = _items.where((it) => !it.removed).toList();
    final total = double.tryParse(_totalController.text.replaceAll(',', '.'));
    final mismatch =
        total != null && (_itemsSum - total).abs() > 0.02 && total > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.reviewReceipt)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            l10n.reviewReceiptHint,
            style: const TextStyle(
              fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),

          // --- Métadonnées du reçu -------------------------------------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _storeField(l10n),
                  const SizedBox(height: AppSpacing.sm + 4),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: l10n.purchaseDateLabel,
                              suffixIcon:
                                  const Icon(Icons.calendar_today, size: 18),
                            ),
                            child: Text(DateFormat(
                                    'd MMM yyyy',
                                    Localizations.localeOf(context)
                                        .languageCode)
                                .format(_date)),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: _totalController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: l10n.receiptTotalLabel,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm + 4),
                  TextField(
                    controller: _numberController,
                    decoration: InputDecoration(
                      labelText: l10n.receiptNumberLabel,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Avertissement de cohérence -------------------------------
          if (mismatch) ...[
            const SizedBox(height: AppSpacing.sm),
            _warningBanner(
              l10n.totalMismatchWarning(
                _itemsSum.toStringAsFixed(2),
                total.toStringAsFixed(2),
              ),
            ),
          ],

          // --- Articles ---------------------------------------------------
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.receiptItemsSection(
              visibleItems.where((i) => !i.item.isDiscount).length),
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...visibleItems.map((it) => _itemCard(it, l10n)),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _items.add(_EditableItem(
                    ParsedReceiptItem(
                        rawLabel: '', linePrice: 0, confidence: 100),
                  ))),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.addReceiptItem),
            ),
          ),

          // --- Lignes non reconnues (repli, informatif) --------------------
          if (widget.receipt.unrecognizedLines.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                l10n.unrecognizedLinesTitle(
                    widget.receipt.unrecognizedLines.length),
                style: const TextStyle(
                    fontSize: 13.5, color: AppColors.textSecondary),
              ),
              children: widget.receipt.unrecognizedLines
                  .map((l) => Padding(
                        padding: const EdgeInsets.only(
                            left: AppSpacing.sm, bottom: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(l,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textDisabled)),
                        ),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 90),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
          child: FilledButton(
            onPressed: _saving ? null : () => _save(),
            child: _saving
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.saveReceipt),
          ),
        ),
      ),
    );
  }

  Widget _storeField(AppLocalizations l10n) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: _storeController.text),
      optionsBuilder: (value) {
        final q = value.text.toLowerCase();
        return widget.knownStores
            .map((s) => s.name)
            .where((n) => q.isEmpty || n.toLowerCase().contains(q));
      },
      onSelected: (v) => _storeController.text = v,
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        controller.addListener(() => _storeController.text = controller.text);
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(labelText: l10n.storeLabel),
        );
      },
    );
  }

  Widget _warningBanner(String text) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(_EditableItem it, AppLocalizations l10n) {
    final item = it.item;
    final uncertain = item.isUncertain && !it.suggested;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: it.nameController,
                    enabled: !item.isDiscount,
                    decoration: InputDecoration(
                      labelText: l10n.itemNameLabel,
                      isDense: true,
                      helperText: item.rawLabel.isNotEmpty &&
                              item.rawLabel != it.nameController.text
                          ? l10n.rawLabelHint(item.rawLabel)
                          : null,
                      helperMaxLines: 1,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 18, color: AppColors.textDisabled),
                  onPressed: () => setState(() => it.removed = true),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                SizedBox(
                  width: 72,
                  child: TextField(
                    controller: it.qtyController,
                    enabled: !item.isDiscount,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.quantityShort +
                          (item.unit != null ? ' (${item.unit})' : ''),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: it.priceController,
                    enabled: !item.isDiscount,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: InputDecoration(
                      labelText: l10n.priceLabel,
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const Spacer(),
                if (item.isDiscount)
                  _flag(l10n.discountLine, AppColors.textDisabled,
                      Icons.remove_circle_outline)
                else if (uncertain)
                  _flag(l10n.uncertainLine, AppColors.warning,
                      Icons.help_outline),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _flag(String text, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11.5, color: color)),
        ],
      ),
    );
  }
}

/// Contrôleurs d'édition d'une ligne d'article.
class _EditableItem {
  final ParsedReceiptItem item;
  final TextEditingController nameController;
  final TextEditingController qtyController;
  final TextEditingController priceController;
  bool suggested = false;
  bool removed = false;

  _EditableItem(this.item)
      : nameController =
            TextEditingController(text: item.productName ?? item.rawLabel),
        qtyController = TextEditingController(
            text: item.quantity == item.quantity.roundToDouble()
                ? item.quantity.toInt().toString()
                : item.quantity.toStringAsFixed(3)),
        priceController =
            TextEditingController(text: item.linePrice.toStringAsFixed(2));

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    priceController.dispose();
  }
}
