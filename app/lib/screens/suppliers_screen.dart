// screens/suppliers_screen.dart - Fournisseurs (§22, Phase 3).
// CRUD léger : nom, contact, téléphone, email, notes, actif/inactif.
// Écriture réservée à manage_suppliers (le serveur tranche).
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/space.dart';
import 'package:epilist/services/screen_cache.dart';
import 'package:epilist/services/space_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/widgets/common/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  List<SupplierInfo>? _suppliers;
  bool _error = false;

  SpaceService get _service => context.read<SpaceService>();
  bool get _canManage => ['owner', 'admin', 'manager']
      .contains(ActiveSpaceStore.current.value?.myRole);

  @override
  void initState() {
    super.initState();
    // Afficher d'abord la derniere version connue (pas de spinner
    // si on est deja venu), puis rafraichir en silence.
    _suppliers = ScreenCache.read<List<SupplierInfo>>('suppliers');
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _service.getSuppliers();
      ScreenCache.write('suppliers', list);
      if (!mounted) return;
      setState(() {
        _suppliers = list;
        _error = false;
      });
    } catch (_) {
      if (!mounted) return;
      // Un rafraichissement rate n'efface pas les donnees affichees.
      if (_suppliers == null) setState(() => _error = true);
    }
  }

  Future<void> _edit([SupplierInfo? existing]) async {
    final l10n = AppLocalizations.of(context)!;
    final name = TextEditingController(text: existing?.name ?? '');
    final contact = TextEditingController(text: existing?.contactName ?? '');
    final phone = TextEditingController(text: existing?.phone ?? '');
    final email = TextEditingController(text: existing?.email ?? '');
    final notes = TextEditingController(text: existing?.notes ?? '');
    bool active = existing?.isActive ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocal) => Dialog(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppDialogHeader(
                  icon: Icons.local_shipping_outlined,
                  title: existing == null ? l10n.supplierNew : existing.name,
                ),
                const SizedBox(height: AppSpacing.md),
                for (final (controller, label, keyboard) in [
                  (name, l10n.supplierName, TextInputType.text),
                  (contact, l10n.supplierContact, TextInputType.name),
                  (phone, l10n.supplierPhone, TextInputType.phone),
                  (email, l10n.supplierEmail, TextInputType.emailAddress),
                  (notes, l10n.supplierNotes, TextInputType.multiline),
                ]) ...[
                  TextField(
                    controller: controller,
                    keyboardType: keyboard,
                    decoration: InputDecoration(
                      labelText: label,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (existing != null)
                  SwitchListTile(
                    title: Text(l10n.supplierInactive),
                    value: !active,
                    onChanged: (v) => setLocal(() => active = !v),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                const SizedBox(height: AppSpacing.sm),
                AppDialogActions(
                  cancelLabel: l10n.cancel,
                  submitLabel: l10n.save,
                  onCancel: () => Navigator.pop(dialogContext, false),
                  onSubmit: () async {
                    if (name.text.trim().isEmpty) return;
                    try {
                      await _service.saveSupplier(
                        id: existing?.id,
                        name: name.text.trim(),
                        contactName: contact.text.trim(),
                        phone: phone.text.trim(),
                        email: email.text.trim(),
                        notes: notes.text.trim(),
                        isActive: active,
                      );
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext, true);
                      }
                    } catch (_) {
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext, false);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (saved == true) {
      SmartSnackBarManager.showSuccessSnackBar(context, l10n.supplierSaved);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.suppliers)),
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
              onPressed: () => _edit(),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(l10n.supplierNew),
            )
          : null,
      body: _suppliers == null && !_error
          ? const Center(child: CircularProgressIndicator())
          : _error
              ? Center(
                  child: Text(l10n.anErrorOccurred,
                      style: const TextStyle(color: AppColors.textSecondary)))
              : _suppliers!.isEmpty
                  ? Center(
                      child: Text(l10n.supplierEmpty,
                          style: const TextStyle(
                              color: AppColors.textSecondary)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                            AppSpacing.md, AppSpacing.md, 96),
                        itemCount: _suppliers!.length,
                        itemBuilder: (context, i) {
                          final s = _suppliers![i];
                          return Container(
                            margin:
                                const EdgeInsets.only(bottom: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                    Icons.local_shipping_outlined,
                                    size: 20,
                                    color: AppColors.primaryDark),
                              ),
                              title: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      s.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: s.isActive
                                            ? AppColors.textPrimary
                                            : AppColors.textDisabled,
                                      ),
                                    ),
                                  ),
                                  if (!s.isActive) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      l10n.supplierInactive,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textDisabled),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: (s.phone != null || s.email != null)
                                  ? Text(
                                      [s.phone, s.email]
                                          .whereType<String>()
                                          .join(' · '),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary),
                                    )
                                  : null,
                              trailing: _canManage
                                  ? const Icon(Icons.chevron_right_rounded,
                                      color: AppColors.textSecondary)
                                  : null,
                              onTap: _canManage ? () => _edit(s) : null,
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
