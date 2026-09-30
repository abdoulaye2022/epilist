// screens/purchase_requests_screen.dart - Demandes d'achat (§20,
// Phase 3, espaces restaurant/organisation). Un employé demande, un
// gestionnaire approuve ou refuse (motif obligatoire), l'achat clôt la
// demande. Les droits sont tranchés par le serveur ; l'UI se contente
// de masquer les actions hors rôle.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/space.dart';
import 'package:epilist/services/space_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/widgets/common/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PurchaseRequestsScreen extends StatefulWidget {
  const PurchaseRequestsScreen({super.key});

  @override
  State<PurchaseRequestsScreen> createState() => _PurchaseRequestsScreenState();
}

class _PurchaseRequestsScreenState extends State<PurchaseRequestsScreen> {
  List<PurchaseRequestInfo>? _requests;
  bool _error = false;

  SpaceService get _service => context.read<SpaceService>();
  Space? get _space => ActiveSpaceStore.current.value;
  bool get _canApprove =>
      ['owner', 'admin', 'manager'].contains(_space?.myRole);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final (list, _) = await _service.getPurchaseRequests();
      if (!mounted) return;
      setState(() {
        _requests = list;
        _error = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = true);
    }
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context)!;
    final product = TextEditingController();
    final qty = TextEditingController();
    final unit = TextEditingController();
    final note = TextEditingController();

    final sent = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppDialogHeader(
                icon: Icons.assignment_add,
                title: l10n.purchaseRequestNew,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: product,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.purchaseRequestProduct,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: qty,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.purchaseRequestQuantity,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: unit,
                      decoration: InputDecoration(
                        labelText: l10n.purchaseRequestUnit,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: note,
                decoration: InputDecoration(
                  labelText: l10n.purchaseRequestNote,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppDialogActions(
                cancelLabel: l10n.cancel,
                submitLabel: l10n.purchaseRequestNew,
                onCancel: () => Navigator.pop(dialogContext, false),
                onSubmit: () async {
                  final name = product.text.trim();
                  if (name.isEmpty) return;
                  try {
                    await _service.createPurchaseRequest(
                      productName: name,
                      quantity: double.tryParse(
                          qty.text.trim().replaceAll(',', '.')),
                      unit: unit.text.trim(),
                      note: note.text.trim(),
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
    );

    if (!mounted) return;
    if (sent == true) {
      SmartSnackBarManager.showSuccessSnackBar(
          context, l10n.purchaseRequestCreated);
      _load();
    }
  }

  Future<void> _act(PurchaseRequestInfo r, String action) async {
    final l10n = AppLocalizations.of(context)!;
    String? comment;

    if (action == 'reject') {
      final controller = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppDialogHeader(
                  icon: Icons.block_rounded,
                  title: l10n.prReject,
                  color: AppColors.error,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: l10n.prRejectReason,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppDialogActions(
                  cancelLabel: l10n.cancel,
                  submitLabel: l10n.prReject,
                  destructive: true,
                  onCancel: () => Navigator.pop(dialogContext, false),
                  onSubmit: () {
                    if (controller.text.trim().isEmpty) return;
                    Navigator.pop(dialogContext, true);
                  },
                ),
              ],
            ),
          ),
        ),
      );
      if (ok != true) return;
      comment = controller.text.trim();
    }

    try {
      await _service.actOnPurchaseRequest(r.id, action, comment: comment);
      _load();
    } catch (_) {
      if (!mounted) return;
      SmartSnackBarManager.showErrorSnackBar(context, l10n.anErrorOccurred);
    }
  }

  (Color, String) _statusStyle(String status, AppLocalizations l10n) =>
      switch (status) {
        'pending' => (const Color(0xFFB45309), l10n.prStatusPending),
        'approved' => (AppColors.primaryDark, l10n.prStatusApproved),
        'rejected' => (AppColors.error, l10n.prStatusRejected),
        'purchased' => (AppColors.textSecondary, l10n.prStatusPurchased),
        'cancelled' => (AppColors.textDisabled, l10n.prStatusCancelled),
        _ => (AppColors.textSecondary, l10n.prStatusDraft),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.purchaseRequests)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.purchaseRequestNew),
      ),
      body: _requests == null && !_error
          ? const Center(child: CircularProgressIndicator())
          : _error
              ? Center(
                  child: Text(l10n.anErrorOccurred,
                      style: const TextStyle(color: AppColors.textSecondary)))
              : _requests!.isEmpty
                  ? Center(
                      child: Text(l10n.purchaseRequestEmpty,
                          style: const TextStyle(
                              color: AppColors.textSecondary)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                            AppSpacing.md, AppSpacing.md, 96),
                        itemCount: _requests!.length,
                        itemBuilder: (context, i) =>
                            _requestCard(_requests![i], l10n),
                      ),
                    ),
    );
  }

  Widget _requestCard(PurchaseRequestInfo r, AppLocalizations l10n) {
    final (color, label) = _statusStyle(r.status, l10n);
    final qty = r.quantity == null
        ? ''
        : ' · ${r.quantity!.toStringAsFixed(r.quantity! % 1 == 0 ? 0 : 1)}${r.unit ?? ''}';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${r.productName}$qty',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.prRequestedBy(r.requesterName),
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          if (r.approverName != null)
            Text(
              l10n.prDecidedBy(r.approverName!),
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          if (r.decisionComment != null && r.decisionComment!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '« ${r.decisionComment} »',
                style: const TextStyle(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary),
              ),
            ),
          if (r.status == 'pending' || r.status == 'approved') ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (r.status == 'pending' && _canApprove) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _act(r, 'approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(l10n.prApprove),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _act(r, 'reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(l10n.prReject),
                    ),
                  ),
                ],
                if (r.status == 'approved')
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _act(r, 'purchased'),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(l10n.prMarkPurchased),
                    ),
                  ),
                if (r.status == 'pending' && !_canApprove)
                  TextButton(
                    onPressed: () => _act(r, 'cancel'),
                    child: Text(l10n.prCancel,
                        style: const TextStyle(
                            color: AppColors.textSecondary)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
