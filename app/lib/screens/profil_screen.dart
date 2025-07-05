// screens/profile_screen.dart - VERSION REFACTORISÉE
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/models/user.dart';
import 'package:epilist/screens/about_screen.dart';
import 'package:epilist/screens/login_screen.dart';
import 'package:epilist/screens/privacy_policy_screen.dart';
import 'package:epilist/screens/shopping_list_screen.dart';
import 'package:epilist/screens/terms_of_service.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/widgets/dialogs/edit_profile_dialog.dart';
import 'package:epilist/widgets/dialogs/help_support_dialog.dart';
import 'package:epilist/widgets/dialogs/logout_confirmation_dialog.dart';
import 'package:epilist/widgets/dialogs/notifications_settings_dialog.dart';
import 'package:epilist/widgets/dialogs/security_settings_dialog.dart';
import 'package:epilist/widgets/profile/account_deletion_status_widget.dart';
import 'package:epilist/widgets/profile/logout_button.dart';
import 'package:epilist/widgets/profile/profile_action_tile.dart';
import 'package:epilist/widgets/profile/profile_app_bar.dart';
import 'package:epilist/widgets/profile/profile_error_state.dart';
import 'package:epilist/widgets/profile/profile_header_card.dart';
import 'package:epilist/widgets/profile/profile_loading_state.dart';
import 'package:epilist/widgets/profile/profile_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthSuccess && authState is! ProfileUpdated) {
        context.read<AuthBloc>().add(GetCurrentUser());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: _handleAuthStateChanges,
      builder: (context, state) => _buildContent(state),
    );
  }

  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    if (state is Unauthenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Widget _buildContent(AuthState state) {
    // État de chargement
    if (state is AuthLoading) {
      return const ProfileLoadingState();
    }

    // État d'erreur
    if (state is! AuthSuccess && state is! ProfileUpdated) {
      return ProfileErrorState(
        onRetry: () => context.read<AuthBloc>().add(GetCurrentUser()),
        onLogout: () => context.read<AuthBloc>().add(LogoutRequested()),
      );
    }

    // Récupérer l'utilisateur
    final User user =
        state is AuthSuccess ? state.user : (state as ProfileUpdated).user;

    return _buildProfileView(user);
  }

  Widget _buildProfileView(User user) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const ProfileAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ProfileHeaderCard(
              user: user,
              onEditProfile: () => _showEditProfileDialog(user),
            ),
            const SizedBox(height: 20),

            // ✅ NOUVEAU: Widget de statut de suppression
            const AccountDeletionStatusWidget(),

            _buildDataSection(),
            const SizedBox(height: 16),
            _buildSettingsSection(),
            const SizedBox(height: 16),
            _buildInfoSection(),
            const SizedBox(height: 24),
            LogoutButton(onLogout: _showLogoutDialog),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSection() {
    return ProfileSection(
      title: 'Mes données',
      children: [
        ProfileActionTile(
          icon: Icons.list_alt,
          title: 'Mes listes de courses',
          onTap: _navigateToShoppingLists,
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return ProfileSection(
      title: 'Paramètres',
      children: [
        ProfileActionTile(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          onTap: _showNotificationsDialog,
        ),
        ProfileActionTile(
          icon: Icons.security_outlined,
          title: 'Sécurité',
          onTap: _showSecurityDialog,
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return ProfileSection(
      title: 'Informations',
      children: [
        ProfileActionTile(
          icon: Icons.info_outline,
          title: 'À propos d\'EpiList',
          onTap: _navigateToAbout,
        ),
        ProfileActionTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Politique de confidentialité',
          onTap: _navigateToPrivacyPolicy,
        ),
        ProfileActionTile(
          icon: Icons.article_outlined,
          title: 'Conditions d\'utilisation',
          onTap: _navigateToTerms,
        ),
        ProfileActionTile(
          icon: Icons.help_outline,
          title: 'Aide & Support',
          onTap: _showHelpDialog,
        ),
      ],
    );
  }

  // Actions de navigation
  void _navigateToShoppingLists() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ShoppingListScreen()),
    );
  }

  void _navigateToAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AboutPage()),
    );
  }

  void _navigateToPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
    );
  }

  void _navigateToTerms() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TermsOfServicePage()),
    );
  }

  // Dialogues
  void _showEditProfileDialog(User user) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<AuthBloc>(),
            child: EditProfileDialog(currentUser: user),
          ),
    );
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => const NotificationsSettingsDialog(),
    );
  }

  void _showSecurityDialog() {
    showDialog(
      context: context,
      builder: (context) => const SecuritySettingsDialog(),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => const HelpSupportDialog(),
    );
  }

  void _showLogoutDialog() {
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
