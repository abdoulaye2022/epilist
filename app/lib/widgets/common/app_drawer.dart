// widgets/common/app_drawer.dart - Le menu latéral, planche « Version B ».
//
// Il présente les DIX sections à plat, dans l'ordre de la planche, sans
// aucun regroupement : Tableau de bord, Mes listes, Budgets, Analyses,
// Avant les courses, Alertes de prix, À la maison, Listes récurrentes,
// Planifier mes repas, Mes magasins. Les trois séparateurs ne groupent
// rien — ils respirent, et toutes les entrées restent de premier niveau.
//
// Ce qui a changé, et pourquoi :
//
//  — PLUS DE COURRIEL dans l'en-tête. Le nom suffit à dire de quel
//    compte il s'agit ; l'adresse, elle, s'affichait en clair devant
//    quiconque regardait l'écran par-dessus l'épaule.
//
//  — BUDGETS, ANALYSES, ALERTES et LISTES RÉCURRENTES remontent au même
//    rang que Mes listes. Elles vivaient après deux séparateurs, dans
//    un second bloc qui les faisait passer pour des dépendances des
//    listes. Ce ne sont pas des sous-sections.
//
//  — RÉGLAGES, PROFIL, CATÉGORIES, À PROPOS tiennent désormais en une
//    entrée, « Réglages et plus », qui ouvre l'index déjà existant. Ils
//    occupaient sept lignes du menu et noyaient les dix sections.
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/space.dart';
import 'package:epilist/models/user.dart';
import 'package:epilist/screens/all_receipts_screen.dart';
import 'package:epilist/screens/analytics_screen.dart';
import 'package:epilist/screens/budget_screen.dart';
import 'package:epilist/screens/inventory_screen.dart';
import 'package:epilist/screens/meal_planner_screen.dart';
import 'package:epilist/screens/more_screen.dart';
import 'package:epilist/screens/purchase_requests_screen.dart';
import 'package:epilist/screens/recurring_lists_screen.dart';
import 'package:epilist/screens/stores_screen.dart';
import 'package:epilist/screens/suppliers_screen.dart';
import 'package:epilist/services/space_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/main_shell_scope.dart';
import 'package:epilist/widgets/common/space_selector_sheet.dart';
import 'package:epilist/widgets/common/user_avatar.dart';
import 'package:epilist/widgets/dialogs/logout_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
      backgroundColor: AppColors.surface,
      width: 350,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 4,
                  vertical: AppSpacing.sm + 2,
                ),
                children: [
                  // ── Les dix sections, à plat ──────────────────────
                  _tab(
                    context,
                    icon: Icons.space_dashboard_outlined,
                    label: l10n.dashboardTitle,
                    tab: MainTab.home,
                  ),
                  _tab(
                    context,
                    icon: Icons.checklist_rounded,
                    label: l10n.myShoppingLists,
                    tab: MainTab.lists,
                  ),
                  _item(
                    context,
                    icon: Icons.savings_outlined,
                    label: l10n.budgets,
                    onTap: () => _push(context, const BudgetScreen()),
                  ),
                  _item(
                    context,
                    icon: Icons.insights_outlined,
                    label: l10n.analytics,
                    onTap: () => _push(context, const AnalyticsScreen()),
                  ),
                  _tab(
                    context,
                    icon: Icons.assistant_outlined,
                    label: l10n.preShopping,
                    tab: MainTab.preShopping,
                  ),
                  _tab(
                    context,
                    icon: Icons.notifications_active_outlined,
                    label: l10n.priceAlerts,
                    tab: MainTab.alerts,
                  ),
                  _separator(),
                  _item(
                    context,
                    icon: Icons.kitchen_outlined,
                    label: l10n.inventoryTitle,
                    onTap: () => _push(context, const InventoryScreen()),
                  ),
                  _item(
                    context,
                    icon: Icons.event_repeat_outlined,
                    label: l10n.recurringListsTitle,
                    onTap: () => _push(context, const RecurringListsScreen()),
                  ),
                  _item(
                    context,
                    icon: Icons.restaurant_menu_outlined,
                    label: l10n.mealPlannerTitle,
                    onTap: () => _push(context, const MealPlannerScreen()),
                  ),
                  _separator(),
                  _item(
                    context,
                    icon: Icons.storefront_outlined,
                    label: l10n.myStores,
                    onTap: () => _push(context, const StoresScreen()),
                  ),

                  // ── Ce que la planche ne modélise pas, et qui doit
                  //    rester joignable : les reçus (lus depuis
                  //    Budgets, mais aussi en entier), les réglages, et
                  //    les deux écrans des espaces professionnels.
                  _separator(),
                  _item(
                    context,
                    icon: Icons.receipt_long_outlined,
                    label: l10n.receipts,
                    onTap: () => _push(context, const AllReceiptsScreen()),
                  ),
                  ValueListenableBuilder<Space?>(
                    valueListenable: ActiveSpaceStore.current,
                    builder: (context, space, _) {
                      final pro =
                          space != null &&
                          (space.type == 'restaurant' ||
                              space.type == 'organization');
                      if (!pro) return const SizedBox.shrink();
                      return Column(
                        children: [
                          _item(
                            context,
                            icon: Icons.assignment_outlined,
                            label: l10n.purchaseRequests,
                            onTap:
                                () => _push(
                                  context,
                                  const PurchaseRequestsScreen(),
                                ),
                          ),
                          _item(
                            context,
                            icon: Icons.local_shipping_outlined,
                            label: l10n.suppliers,
                            onTap:
                                () => _push(context, const SuppliersScreen()),
                          ),
                        ],
                      );
                    },
                  ),
                  _item(
                    context,
                    icon: Icons.settings_outlined,
                    label: l10n.settingsAndMore,
                    onTap: () => _push(context, const MoreScreen()),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.primaryLight, thickness: 2, height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 4,
                vertical: AppSpacing.sm,
              ),
              child: _item(
                context,
                icon: Icons.logout_rounded,
                label: l10n.logout,
                color: AppColors.errorInk,
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// En-tête sur fond teinté de marque : l'avatar, le nom, et le
  /// sélecteur d'espace. Aucun courriel.
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColors.primaryLight,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md + 2,
        AppSpacing.md + 2,
        AppSpacing.md + 2,
        AppSpacing.md - 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              User? user;
              if (state is AuthSuccess) {
                user = state.user;
              } else if (state is ProfileUpdated) {
                user = state.user;
              }
              final name = user?.fullName ?? 'EpiList';

              return Row(
                children: [
                  UserAvatar(user: user, radius: 28),
                  const SizedBox(width: AppSpacing.md - 4),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.displayStyle(
                        size: 21,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md - 2),
          _buildSpaceSelector(context),
        ],
      ),
    );
  }

  /// Sélecteur d'espace : « Personnel ▼ » ou « Famille Diallo ▼ », sur
  /// toute la largeur et 54 dp de haut, comme sur la planche.
  Widget _buildSpaceSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<Space?>(
      valueListenable: ActiveSpaceStore.current,
      builder: (context, space, _) {
        final label = space?.name ?? l10n.spacePersonal;
        final icon = switch (space?.type) {
          'household' => Icons.family_restroom_rounded,
          'restaurant' => Icons.restaurant_rounded,
          'organization' => Icons.apartment_rounded,
          _ => Icons.person_rounded,
        };
        return Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            side: BorderSide(color: AppColors.primary, width: 2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            onTap: () {
              // Le drawer se ferme : on ouvre la feuille depuis le
              // contexte du Navigator (sous les providers), qui survit.
              final navContext = Navigator.of(context).context;
              Navigator.pop(context);
              SpaceSelectorSheet.show(navContext);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md - 2,
                vertical: AppSpacing.sm + 4,
              ),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm + 2),
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 22,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Un filet qui fait respirer la liste. Il ne groupe rien : les dix
  /// sections restent au même rang de part et d'autre.
  Widget _separator() => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.xs,
      vertical: AppSpacing.sm,
    ),
    child: Divider(color: AppColors.primaryLight, thickness: 2, height: 2),
  );

  /// Entree qui designe un ONGLET : elle bascule la coquille et se
  /// marque comme selectionnee quand c'est l'onglet courant. Hors de la
  /// coquille (drawer ouvert depuis un ecran pousse), elle se contente
  /// de fermer le tiroir.
  Widget _tab(
    BuildContext context, {
    required IconData icon,
    required String label,
    required MainTab tab,
  }) {
    final scope = MainShellScope.maybeOf(context);
    return _item(
      context,
      icon: icon,
      label: label,
      selected: scope?.currentTab == tab,
      onTap: () {
        Navigator.pop(context);
        scope?.goToTab(tab);
      },
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        size: 27,
        color:
            color ?? (selected ? AppColors.primary : AppColors.textSecondary),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 18.5,
          height: 1.25,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          color: color ?? AppColors.textPrimary,
        ),
      ),
      minTileHeight: 58,
      selected: selected,
      selectedTileColor: AppColors.primaryLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      onTap: onTap,
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.pop(context); // fermer le drawer d'abord
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<AuthBloc>(),
            child: const LogoutConfirmationDialog(),
          ),
    );
  }
}
