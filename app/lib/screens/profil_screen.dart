// screens/profile_screen.dart - VERSION CORRIGÉE
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
import 'package:flutter/foundation.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser; // ✅ Stocker l'utilisateur localement

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      debugPrint('🔍 ProfileScreen initState - État: ${authState.runtimeType}');

      if (authState is AuthSuccess) {
        _currentUser = authState.user;
        debugPrint('✅ Utilisateur déjà disponible: ${_currentUser?.email}');
      } else if (authState is ProfileUpdated) {
        _currentUser = authState.user;
        debugPrint(
          '✅ Utilisateur mis à jour disponible: ${_currentUser?.email}',
        );
      } else {
        debugPrint('🔄 Chargement de l\'utilisateur...');
        context.read<AuthBloc>().add(GetCurrentUser());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: _handleAuthStateChanges,
      buildWhen: (previous, current) {
        debugPrint(
          '🔍 ProfileScreen buildWhen: ${previous.runtimeType} → ${current.runtimeType}',
        );

        // ✅ Reconstruire seulement pour les états d'authentification principaux
        return current is AuthLoading ||
            current is AuthSuccess ||
            current is ProfileUpdated ||
            current is AuthFailure ||
            current is Unauthenticated;
      },
      builder: (context, state) => _buildContent(state),
    );
  }

  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    debugPrint('🎧 ProfileScreen Listener - État: ${state.runtimeType}');

    if (state is Unauthenticated) {
      debugPrint('🔴 Utilisateur déconnecté, redirection vers login');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }

    // ✅ Mettre à jour l'utilisateur local quand nécessaire
    if (state is AuthSuccess) {
      _currentUser = state.user;
      debugPrint('✅ Utilisateur mis à jour: ${_currentUser?.email}');
    } else if (state is ProfileUpdated) {
      _currentUser = state.user;
      debugPrint('✅ Profil mis à jour: ${_currentUser?.email}');
    }

    // ✅ Gérer les états de suppression de compte avec SnackBar
    if (state is AccountDeletionCodeSent) {
      SmartSnackBarManager.showSuccessSnackBar(
        context,
        'Code de suppression envoyé ! Vérifiez votre email.',
      );
    } else if (state is AccountDeletionConfirmed) {
      SmartSnackBarManager.showInfoSnackBar(
        context,
        'Votre compte sera supprimé dans 30 jours. Vous pouvez annuler cette action.',
        duration: const Duration(seconds: 5),
      );
    } else if (state is AccountDeletionCancelled) {
      SmartSnackBarManager.showSuccessSnackBar(
        context,
        'Suppression de compte annulée avec succès !',
      );
    }
  }

  Widget _buildContent(AuthState state) {
    debugPrint('🎨 ProfileScreen _buildContent - État: ${state.runtimeType}');
    debugPrint('👤 Utilisateur actuel: ${_currentUser?.email ?? 'null'}');

    // ✅ État de chargement SEULEMENT si on n'a pas d'utilisateur
    if (state is AuthLoading && _currentUser == null) {
      debugPrint('⏳ Affichage du loading (pas d\'utilisateur)');
      return const ProfileLoadingState();
    }

    // ✅ Utilisateur disponible (soit dans l'état, soit stocké localement)
    User? user;
    if (state is AuthSuccess) {
      user = state.user;
    } else if (state is ProfileUpdated) {
      user = state.user;
    } else if (_currentUser != null) {
      user = _currentUser; // Utiliser l'utilisateur stocké
    }

    if (user != null) {
      debugPrint('✅ Affichage du profil pour: ${user.email}');
      return _buildProfileView(user);
    }

    // ✅ État d'erreur seulement si vraiment en erreur ET pas d'utilisateur en backup
    if (state is AuthFailure && _currentUser == null) {
      debugPrint('❌ Affichage de l\'erreur: ${state.error}');
      return ProfileErrorState(
        onRetry: () {
          debugPrint('🔄 Retry demandé...');
          context.read<AuthBloc>().add(GetCurrentUser());
        },
        onLogout: () {
          debugPrint('🔴 Logout demandé...');
          context.read<AuthBloc>().add(LogoutRequested());
        },
      );
    }

    // ✅ Si on a un utilisateur en backup, l'afficher même en cas d'erreur temporaire
    if (_currentUser != null) {
      debugPrint(
        '✅ Affichage du profil en backup pour: ${_currentUser!.email}',
      );
      return _buildProfileView(_currentUser!);
    }

    // ✅ Fallback: état de chargement
    debugPrint('⏳ Fallback vers loading');
    return const ProfileLoadingState();
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

            // ✅ Widget de statut de suppression
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
