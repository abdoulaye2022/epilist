// widgets/home/space_dashboard_card.dart - Dashboard adaptatif (§45).
// Affiché à l'accueil UNIQUEMENT dans un espace partagé ; le personnel
// garde l'expérience actuelle. Le contenu s'adapte au type :
//  - foyer : à racheter, ruptures, activité de l'espace ;
//  - restaurant/organisation : demandes d'achat en attente, stock
//    critique (sous le seuil), à racheter, fournisseurs.
// Les données viennent de /assistant/pre-shopping (§28) — une requête.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/space.dart';
import 'package:epilist/screens/inventory_screen.dart';
import 'package:epilist/screens/pre_shopping_screen.dart';
import 'package:epilist/screens/purchase_requests_screen.dart';
import 'package:epilist/screens/space_activity_screen.dart';
import 'package:epilist/screens/suppliers_screen.dart';
import 'package:epilist/services/space_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SpaceDashboardCard extends StatefulWidget {
  final Space space;

  const SpaceDashboardCard({super.key, required this.space});

  @override
  State<SpaceDashboardCard> createState() => _SpaceDashboardCardState();
}

class _SpaceDashboardCardState extends State<SpaceDashboardCard> {
  Map<String, dynamic>? _brief;

  bool get _isPro =>
      widget.space.type == 'restaurant' || widget.space.type == 'organization';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SpaceDashboardCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.space.id != widget.space.id) {
      setState(() => _brief = null);
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final brief = await context.read<SpaceService>().getPreShopping();
      if (!mounted) return;
      setState(() => _brief = brief);
    } catch (_) {
      // Silencieux : la carte reste minimale hors ligne
    }
  }

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final restock = (_brief?['restock'] as List? ?? []);
    final inventoryAlerts = (_brief?['inventory_alerts'] as List? ?? []);
    final pending = _brief?['pending_requests'] as int?;

    final icon = switch (widget.space.type) {
      'household' => Icons.family_restroom_rounded,
      'restaurant' => Icons.restaurant_rounded,
      'organization' => Icons.apartment_rounded,
      _ => Icons.person_rounded,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
              Icon(icon, size: 18, color: AppColors.primaryDark),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  widget.space.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary),
                ),
              ),
              // Activité de l'espace, toujours à portée (§12)
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: l10n.spaceActivity,
                icon: const Icon(Icons.history_rounded,
                    size: 20, color: AppColors.textSecondary),
                onPressed: () =>
                    _push(SpaceActivityScreen(space: widget.space)),
              ),
            ],
          ),
          if (_brief == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: LinearProgressIndicator(minHeight: 2),
            )
          else ...[
            const SizedBox(height: AppSpacing.xs),
            // Espaces pro : demandes d'achat en premier (§18-20)
            if (_isPro && pending != null)
              _row(
                icon: Icons.assignment_outlined,
                label: l10n.spaceDashPending(pending),
                highlight: pending > 0,
                onTap: () => _push(const PurchaseRequestsScreen()),
              ),
            // Stock critique (§21, §45)
            if (inventoryAlerts.isNotEmpty)
              _row(
                icon: Icons.warning_amber_rounded,
                label: l10n.spaceDashCritical(inventoryAlerts.length,
                    _names(inventoryAlerts)),
                highlight: true,
                onTap: () => _push(const InventoryScreen()),
              ),
            // À racheter probablement (§17)
            _row(
              icon: Icons.replay_rounded,
              label: restock.isEmpty
                  ? l10n.preShoppingRestockEmpty
                  : l10n.spaceDashRestock(restock.length, _names(restock)),
              onTap: () => _push(const PreShoppingScreen()),
            ),
            if (_isPro)
              _row(
                icon: Icons.local_shipping_outlined,
                label: l10n.suppliers,
                onTap: () => _push(const SuppliersScreen()),
              ),
          ],
        ],
      ),
    );
  }

  String _names(List entries) => entries
      .take(3)
      .map((e) => (e as Map)['product_name'] as String? ?? '')
      .where((s) => s.isNotEmpty)
      .join(', ');

  Widget _row({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    final color = highlight ? AppColors.error : AppColors.textSecondary;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: highlight
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}
