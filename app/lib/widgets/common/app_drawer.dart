// widgets/common/app_drawer.dart - Navigation centrale de l'application.
// Le drawer remplace les sections « actions rapides » qui encombraient
// l'accueil : identité en tête, navigation claire, déconnexion en pied.
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/user.dart';
import 'package:epilist/screens/about_screen.dart';
import 'package:epilist/screens/analytics_screen.dart';
import 'package:epilist/screens/budget_screen.dart';
import 'package:epilist/screens/category_management_screen.dart';
import 'package:epilist/screens/profil_screen.dart';
import 'package:epilist/screens/stores_screen.dart';
import 'package:epilist/theme/app_theme.dart';
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(AppRadius.lg),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                children: [
                  _item(
                    context,
                    icon: Icons.checklist_rounded,
                    label: l10n.myShoppingLists,
                    selected: true, // l'accueil est l'écran des listes
                    onTap: () => Navigator.pop(context),
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
                  const Divider(indent: AppSpacing.md, endIndent: AppSpacing.md),
                  _item(
                    context,
                    icon: Icons.storefront_outlined,
                    label: l10n.myStores,
                    onTap: () => _push(context, const StoresScreen()),
                  ),
                  _item(
                    context,
                    icon: Icons.category_outlined,
                    label: l10n.categories,
                    onTap: () =>
                        _push(context, const CategoryManagementScreen()),
                  ),
                  const Divider(indent: AppSpacing.md, endIndent: AppSpacing.md),
                  _item(
                    context,
                    icon: Icons.person_outline,
                    label: l10n.profile,
                    onTap: () => _push(context, const ProfileScreen()),
                  ),
                  _item(
                    context,
                    icon: Icons.info_outline,
                    label: l10n.aboutEpiList,
                    onTap: () => _push(context, const AboutPage()),
                  ),
                ],
              ),
            ),
            const Divider(),
            _item(
              context,
              icon: Icons.logout_rounded,
              label: l10n.logout,
              color: AppColors.error,
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  /// En-tête : avatar aux initiales, nom et email de l'utilisateur.
  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        User? user;
        if (state is AuthSuccess) {
          user = state.user;
        } else if (state is ProfileUpdated) {
          user = state.user;
        }

        final name = user?.fullName ?? 'EpiList';
        final email = user?.email ?? '';

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              UserAvatar(user: user, radius: 26),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: ListTile(
        leading: Icon(
          icon,
          size: 22,
          color: color ?? (selected ? AppColors.primaryDark : AppColors.textSecondary),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: color ?? (selected ? AppColors.primaryDark : AppColors.textPrimary),
          ),
        ),
        selected: selected,
        selectedTileColor: AppColors.primaryLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        visualDensity: const VisualDensity(vertical: -1),
        onTap: onTap,
      ),
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
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: const LogoutConfirmationDialog(),
      ),
    );
  }
}
