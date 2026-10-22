// screens/more_screen.dart - Onglet « Plus » : l'index complet de
// l'application, et la seule recherche qui existe.
//
// Mesure de départ : 42 écrans, 18 atteignables depuis une entrée
// nommée. Douze écrans fonctionnels — mode courses, comparaison de
// magasins, prédictions, code-barres, membres et activité de l'espace,
// création d'espace, messages, préférences de courriel… — n'étaient
// listés NULLE PART : on y tombait, ou pas.
//
// Une entrée qui a besoin d'une liste (mode courses, comparaison,
// discussion, code-barres) la demande au moment du clic au lieu
// d'exister ailleurs ; la mention « demande une liste » le dit avant.
import 'package:epilist/widgets/common/app_top_bar.dart';
import 'package:epilist/widgets/common/app_drawer.dart';
import 'package:epilist/widgets/common/main_bottom_bar.dart';
import 'package:epilist/widgets/common/main_shell_scope.dart';
import 'package:epilist/utils/shopping_mode_launcher.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/space.dart';
import 'package:epilist/screens/about_screen.dart';
import 'package:epilist/screens/analytics_screen.dart';
import 'package:epilist/screens/appearance_screen.dart';
import 'package:epilist/screens/budget_screen.dart';
import 'package:epilist/screens/category_management_screen.dart';
import 'package:epilist/screens/create_space_screen.dart';
import 'package:epilist/screens/email_preferences_screen.dart';
import 'package:epilist/screens/intelligence_settings_screen.dart';
import 'package:epilist/screens/inventory_screen.dart';
import 'package:epilist/screens/list_detail_screen.dart';
import 'package:epilist/screens/meal_planner_screen.dart';
import 'package:epilist/screens/pre_shopping_screen.dart';
import 'package:epilist/screens/predictions_screen.dart';
import 'package:epilist/screens/price_alerts_screen.dart';
import 'package:epilist/screens/profil_screen.dart';
import 'package:epilist/screens/purchase_requests_screen.dart';
import 'package:epilist/screens/recurring_lists_screen.dart';
import 'package:epilist/screens/space_activity_screen.dart';
import 'package:epilist/screens/space_members_screen.dart';
import 'package:epilist/screens/store_comparison_screen.dart';
import 'package:epilist/screens/stores_screen.dart';
import 'package:epilist/screens/suppliers_screen.dart';
import 'package:epilist/services/space_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/utils/chat_flow.dart';
import 'package:epilist/utils/list_picker.dart';
import 'package:epilist/widgets/common/app_action_tile.dart';
import 'package:epilist/widgets/common/app_card.dart';
import 'package:epilist/widgets/common/app_section_header.dart';
import 'package:epilist/widgets/common/app_search_field.dart';
import 'package:flutter/material.dart';

/// Une destination de l'index.
class _Destination {
  const _Destination({
    required this.icon,
    required this.label,
    required this.open,
    this.hint,
  });

  final IconData icon;
  final String label;
  final String? hint;
  final void Function(BuildContext context) open;
}

class _Section {
  const _Section(this.title, this.entries);

  final String title;
  final List<_Destination> entries;
}

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
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

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      bottomNavigationBar: const AppPageBottomBar(tab: MainTab.sections),
      appBar: AppTopBar(title: l10n.settingsAndMore),
      body: ValueListenableBuilder<Space?>(
        valueListenable: ActiveSpaceStore.current,
        builder: (context, space, _) {
          final sections = _sections(l10n, space);
          final q = _query.trim().toLowerCase();

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: [
              AppSearchField(
                controller: _search,
                hintText: l10n.moreSearchHint,
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: AppSpacing.md),
              ...sections.expand((section) {
                final shown =
                    q.isEmpty
                        ? section.entries
                        : section.entries
                            .where((e) => e.label.toLowerCase().contains(q))
                            .toList();
                if (shown.isEmpty) return const <Widget>[];
                return [
                  AppSectionHeader(
                    title: section.title,
                    count: q.isEmpty ? null : '${shown.length}',
                  ),
                  AppCard.tight(
                    child: Column(
                      children: [
                        for (var i = 0; i < shown.length; i++) ...[
                          if (i > 0)
                            const Divider(
                              height: 1,
                              indent: AppSpacing.md,
                              endIndent: AppSpacing.md,
                            ),
                          AppActionTile(
                            icon: shown[i].icon,
                            title: shown[i].label,
                            subtitle: shown[i].hint,
                            onTap: () => shown[i].open(context),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm + 4),
                ];
              }),
              if (q.isNotEmpty &&
                  sections.every(
                    (s) => s.entries.every(
                      (e) => !e.label.toLowerCase().contains(q),
                    ),
                  ))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Column(
                    children: [
                      Text(
                        l10n.noResultsFound,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.tryOtherKeywords,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<_Section> _sections(AppLocalizations l10n, Space? space) {
    final pro =
        space != null &&
        (space.type == 'restaurant' || space.type == 'organization');

    return [
      _Section(l10n.moreSectionSpending, [
        _Destination(
          icon: Icons.insights_outlined,
          label: l10n.statistics,
          open: (c) => _push(c, const AnalyticsScreen()),
        ),
        _Destination(
          icon: Icons.savings_outlined,
          label: l10n.budgets,
          open: (c) => _push(c, const BudgetScreen()),
        ),
        _Destination(
          icon: Icons.notifications_active_outlined,
          label: l10n.priceAlerts,
          open: (c) => _push(c, const PriceAlertsScreen()),
        ),
        _Destination(
          icon: Icons.balance_outlined,
          label: l10n.compareStores,
          hint: l10n.needsAList,
          open: _compareStores,
        ),
      ]),
      _Section(l10n.moreSectionShopping, [
        _Destination(
          icon: Icons.shopping_cart_checkout_rounded,
          label: l10n.shoppingModeTitle,
          hint: l10n.needsAList,
          open: openShoppingMode,
        ),
        _Destination(
          icon: Icons.assistant_outlined,
          label: l10n.preShopping,
          open: (c) => _push(c, const PreShoppingScreen()),
        ),
        _Destination(
          icon: Icons.auto_graph_rounded,
          label: l10n.predictionsTitle,
          open: (c) => _push(c, const PredictionsScreen()),
        ),
        _Destination(
          icon: Icons.event_repeat_outlined,
          label: l10n.recurringListsTitle,
          open: (c) => _push(c, const RecurringListsScreen()),
        ),
        _Destination(
          icon: Icons.restaurant_menu_outlined,
          label: l10n.mealPlannerTitle,
          open: (c) => _push(c, const MealPlannerScreen()),
        ),
        _Destination(
          icon: Icons.kitchen_outlined,
          label: l10n.inventoryTitle,
          open: (c) => _push(c, const InventoryScreen()),
        ),
        _Destination(
          icon: Icons.qr_code_scanner_rounded,
          label: l10n.scanBarcode,
          hint: l10n.needsAList,
          open: _scanBarcode,
        ),
        _Destination(
          icon: Icons.storefront_outlined,
          label: l10n.myStores,
          hint: l10n.aisleOrder,
          open: (c) => _push(c, const StoresScreen()),
        ),
        _Destination(
          icon: Icons.category_outlined,
          label: l10n.categories,
          open: (c) => _push(c, const CategoryManagementScreen()),
        ),
      ]),
      _Section(l10n.moreSectionSpace, [
        if (space != null)
          _Destination(
            icon: Icons.group_outlined,
            label: l10n.spaceMembers,
            hint: space.name,
            open: (c) => _push(c, SpaceMembersScreen(space: space)),
          ),
        if (space != null)
          _Destination(
            icon: Icons.history_rounded,
            label: l10n.spaceActivity,
            hint: space.name,
            open: (c) => _push(c, SpaceActivityScreen(space: space)),
          ),
        _Destination(
          icon: Icons.add_home_outlined,
          label: l10n.createSpace,
          open: (c) => _push(c, const CreateSpaceScreen()),
        ),
        _Destination(
          icon: Icons.forum_outlined,
          label: l10n.chatTitle,
          hint: l10n.needsAList,
          open: _openChat,
        ),
        if (pro)
          _Destination(
            icon: Icons.assignment_outlined,
            label: l10n.purchaseRequests,
            open: (c) => _push(c, const PurchaseRequestsScreen()),
          ),
        if (pro)
          _Destination(
            icon: Icons.local_shipping_outlined,
            label: l10n.suppliers,
            open: (c) => _push(c, const SuppliersScreen()),
          ),
      ]),
      _Section(l10n.moreSectionSettings, [
        _Destination(
          icon: Icons.person_outline,
          label: l10n.profile,
          open: (c) => _push(c, const ProfileScreen()),
        ),
        _Destination(
          icon: Icons.contrast_outlined,
          label: l10n.appearance,
          hint: l10n.appearanceHint,
          open: (c) => _push(c, const AppearanceScreen()),
        ),
        _Destination(
          icon: Icons.auto_awesome_outlined,
          label: l10n.intelligenceSettings,
          open: (c) => _push(c, const IntelligenceSettingsScreen()),
        ),
        _Destination(
          icon: Icons.mark_email_read_outlined,
          label: l10n.emailPreferences,
          open: (c) => _push(c, const EmailPreferencesScreen()),
        ),
        _Destination(
          icon: Icons.info_outline,
          label: l10n.aboutEpiList,
          open: (c) => _push(c, const AboutPage()),
        ),
      ]),
    ];
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _compareStores(BuildContext context) async {
    final list = await pickShoppingList(context);
    if (list == null || !context.mounted) return;
    _push(context, StoreComparisonScreen(listId: list.id, listName: list.name));
  }

  Future<void> _scanBarcode(BuildContext context) async {
    final list = await pickShoppingList(context, where: (l) => l.canEdit);
    if (list == null || !context.mounted) return;
    _push(
      context,
      ListDetailScreen(
        shoppingList: list,
        initialAction: ListDetailAction.barcodeItem,
      ),
    );
  }

  /// La discussion n'existe que pour une liste partagée : on ne propose
  /// donc que celles-là, au lieu d'ouvrir un refus.
  Future<void> _openChat(BuildContext context) async {
    final list = await pickShoppingList(context, where: (l) => l.isShared);
    if (list == null || !context.mounted) return;
    await openListChat(context, listId: list.id, listName: list.name);
  }
}
