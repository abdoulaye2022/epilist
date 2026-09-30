// screens/space_activity_screen.dart - Journal d'activité d'un espace
// (§12, Phase 2). Les événements arrivent STRUCTURÉS (type + payload) :
// le texte est rendu ici, traduit fr/en.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/space.dart';
import 'package:epilist/services/space_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class SpaceActivityScreen extends StatefulWidget {
  final Space space;

  const SpaceActivityScreen({super.key, required this.space});

  @override
  State<SpaceActivityScreen> createState() => _SpaceActivityScreenState();
}

class _SpaceActivityScreenState extends State<SpaceActivityScreen> {
  List<Map<String, dynamic>>? _activities;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await context
          .read<SpaceService>()
          .dio
          .get('/spaces/${widget.space.id}/activity?limit=50');
      if (!mounted) return;
      setState(() {
        _activities = ((res.data['data']['activities'] as List? ?? []))
            .cast<Map<String, dynamic>>();
        _error = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = true);
    }
  }

  (IconData, String) _render(Map<String, dynamic> a, AppLocalizations l10n) {
    final payload = (a['payload'] as Map?)?.cast<String, dynamic>() ?? {};
    final name = (a['user_name'] as String?)?.trim();
    final who = (name == null || name.isEmpty) ? 'EpiList' : name;
    final product = payload['product_name'] as String? ?? '';
    final listName = payload['list_name'] as String? ?? '';
    final budgetName = payload['budget_name'] as String? ?? '';
    final storeName = payload['store_name'] as String? ?? '';

    return switch (a['type'] as String? ?? '') {
      'list_created' => (Icons.playlist_add_rounded, l10n.actListCreated(who, listName)),
      'item_added' => (Icons.add_shopping_cart_rounded, l10n.actItemAdded(who, product)),
      'item_purchased' => (Icons.check_circle_outline_rounded, l10n.actItemPurchased(who, product)),
      'receipt_added' => (Icons.receipt_long_rounded, l10n.actReceiptAdded(who, storeName)),
      'budget_created' => (Icons.savings_outlined, l10n.actBudgetCreated(who, budgetName)),
      'member_joined' => (Icons.person_add_alt_1_rounded, l10n.actMemberJoined(who)),
      'member_left' => (Icons.logout_rounded, l10n.actMemberLeft(who)),
      'inventory_out' => (Icons.remove_shopping_cart_outlined, l10n.actInventoryOut(product)),
      'purchase_request_created' => (Icons.assignment_outlined, l10n.actPurchaseRequestCreated(who, product)),
      'purchase_request_approved' => (Icons.assignment_turned_in_outlined, l10n.actPurchaseRequestApproved(who, product)),
      'purchase_request_rejected' => (Icons.assignment_late_outlined, l10n.actPurchaseRequestRejected(who, product)),
      'price_alert_triggered' => (
          Icons.trending_down_rounded,
          l10n.actPriceAlertTriggered(
              product, ((payload['price'] as num?) ?? 0).toStringAsFixed(2))
        ),
      _ => (Icons.bolt_rounded, who),
    };
  }

  String _when(String? raw) {
    if (raw == null) return '';
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return '';
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return DateFormat('HH:mm').format(date);
    }
    return DateFormat('d MMM HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.space.name,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              l10n.spaceActivity,
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: _activities == null && !_error
          ? const Center(child: CircularProgressIndicator())
          : _error
              ? Center(
                  child: Text(l10n.anErrorOccurred,
                      style: const TextStyle(color: AppColors.textSecondary)))
              : _activities!.isEmpty
                  ? Center(
                      child: Text(
                        l10n.spaceActivityEmpty,
                        style:
                            const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: _activities!.length,
                        itemBuilder: (context, i) {
                          final a = _activities![i];
                          final (icon, text) = _render(a, l10n);
                          return Container(
                            margin:
                                const EdgeInsets.only(bottom: AppSpacing.xs),
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm + 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(icon,
                                      size: 18,
                                      color: AppColors.primaryDark),
                                ),
                                const SizedBox(width: AppSpacing.sm + 4),
                                Expanded(
                                  child: Text(
                                    text,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: AppColors.textPrimary,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  _when(a['created_at'] as String?),
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textDisabled),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
