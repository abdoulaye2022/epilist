// screens/profile_screen.dart - VERSION AVEC FEEDBACK

import 'package:dio/dio.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/blocs/currency/currency_bloc.dart';
import 'package:epilist/blocs/currency/currency_event.dart';
import 'package:epilist/blocs/currency/currency_state.dart';
import 'package:epilist/blocs/contact/contact_bloc.dart'; // ✅ NOUVEAU
import 'package:epilist/models/currency.dart';
import 'package:epilist/models/user.dart';
import 'package:epilist/screens/about_screen.dart';
import 'package:epilist/screens/privacy_policy_screen.dart';
import 'package:epilist/screens/shopping_list_screen.dart';
import 'package:epilist/screens/terms_of_service.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/widgets/currency/currency_selector_dialog.dart';
import 'package:epilist/widgets/profile/edit_profile_dialog.dart';
import 'package:epilist/widgets/dialogs/logout_confirmation_dialog.dart';
import 'package:epilist/widgets/dialogs/security_settings_dialog.dart';
import 'package:epilist/widgets/dialogs/feedback_dialog.dart'; // ✅ NOUVEAU
import 'package:epilist/widgets/profile/account_deletion_status_widget.dart';
import 'package:epilist/widgets/profile/logout_button.dart';
import 'package:epilist/widgets/profile/profile_action_tile.dart';
import 'package:epilist/widgets/profile/profile_app_bar.dart';
import 'package:epilist/widgets/profile/profile_error_state.dart';
import 'package:epilist/widgets/profile/profile_header_card.dart';
import 'package:epilist/widgets/profile/profile_loading_state.dart';
import 'package:epilist/widgets/profile/profile_section.dart';
import 'package:epilist/widgets/profile/language_setting_tile.dart';
import 'package:epilist/screens/suggestion_management_widget.dart';
import 'package:epilist/screens/email_preferences_screen.dart';
import 'package:epilist/screens/stores_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser;

  /// null tant que le réglage n'est pas connu du serveur
  bool? _twoFactorEnabled;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadTwoFactor();
  }

  Future<void> _loadTwoFactor() async {
    try {
      final enabled = await context.read<AuthService>().getTwoFactorEnabled();
      if (!mounted) return;
      setState(() => _twoFactorEnabled = enabled);
    } catch (_) {
      // hors ligne : la tuile reste discrète
    }
  }

  void _loadUserProfile() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;

      if (authState is AuthSuccess) {
        _currentUser = authState.user;
      } else if (authState is ProfileUpdated) {
        _currentUser = authState.user;
      }

      // Auto-réparation : quel que soit l'état porté par le bloc (cache
      // périmé, user sans avatar...), on recharge le profil canonique
      // depuis l'API. Silencieux, le listener mettra _currentUser à jour.
      context.read<AuthBloc>().add(RefreshCurrentUser());

      if (authState is! AuthSuccess && authState is! ProfileUpdated) {
        // ✅ Seulement recharger si on n'a vraiment pas d'utilisateur
        // En mode offline, cela évitera des erreurs inutiles
        if (_currentUser == null) {
          context.read<AuthBloc>().add(GetCurrentUser());
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<AuthBloc, AuthState>(
      listener:
          (context, state) => _handleAuthStateChanges(context, state, l10n),
      buildWhen: (previous, current) {
        return current is AuthLoading ||
            current is AuthSuccess ||
            current is ProfileUpdated ||
            current is AuthFailure;
      },
      builder: (context, state) => _buildContent(state, l10n),
    );
  }

  void _handleAuthStateChanges(
    BuildContext context,
    AuthState state,
    AppLocalizations l10n,
  ) {
    if (state is AuthSuccess) {
      _currentUser = state.user;
    } else if (state is ProfileUpdated) {
      _currentUser = state.user;
    }

    if (state is AccountDeletionCodeSent) {
      SmartSnackBarManager.showSuccessSnackBar(context, l10n.deletionCodeSent);
    } else if (state is AccountDeletionConfirmed) {
      SmartSnackBarManager.showInfoSnackBar(
        context,
        l10n.accountWillBeDeletedIn30Days,
        duration: const Duration(seconds: 5),
      );
    } else if (state is AccountDeletionCancelled) {
      SmartSnackBarManager.showSuccessSnackBar(
        context,
        l10n.accountDeletionCancelled,
      );
    }

    if (state is Unauthenticated) {
      // Géré par AuthWrapper
    }
  }

  Widget _buildContent(AuthState state, AppLocalizations l10n) {
    if (state is AuthLoading && _currentUser == null) {
      return const ProfileLoadingState();
    }

    User? user;
    if (state is AuthSuccess) {
      user = state.user;
    } else if (state is ProfileUpdated) {
      user = state.user;
    } else if (_currentUser != null) {
      user = _currentUser;
    }

    if (user != null) {
      return _buildProfileView(user, l10n);
    }

    // ✅ Ne pas afficher ProfileErrorState en mode offline sans cache
    // L'utilisateur est authentifié (sinon AuthWrapper l'aurait redirigé)
    // On affiche juste un loading ou on attend
    if (state is AuthFailure && _currentUser == null) {
      // Vérifier si on est offline
      return ProfileErrorState(
        onRetry: () {
          context.read<AuthBloc>().add(GetCurrentUser());
        },
        onLogout: () {
          context.read<AuthBloc>().add(LogoutRequested());
        },
      );
    }

    if (_currentUser != null) {
      return _buildProfileView(_currentUser!, l10n);
    }

    // ✅ Si on arrive ici sans utilisateur, essayer de charger
    return const ProfileLoadingState();
  }

  Widget _buildProfileView(User user, AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: AppColors.background,
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

            const AccountDeletionStatusWidget(),

            _buildDataSection(l10n),
            const SizedBox(height: 16),

            _buildAppSettingsSection(l10n, user),
            const SizedBox(height: 16),

            _buildSettingsSection(l10n),
            const SizedBox(height: 16),

            // ✅ NOUVELLE SECTION SUPPORT
            _buildSupportSection(l10n),
            const SizedBox(height: 16),

            _buildInfoSection(l10n),
            const SizedBox(height: 24),
            LogoutButton(onLogout: _showLogoutDialog),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSection(AppLocalizations l10n) {
    return ProfileSection(
      title: l10n.myData,
      children: [
        ProfileActionTile(
          icon: Icons.list_alt,
          title: l10n.myShoppingLists,
          onTap: _navigateToShoppingLists,
        ),
        ProfileActionTile(
          icon: Icons.auto_awesome,
          title: l10n.manageSuggestions,
          subtitle:
              AppLocalizations.of(context)!.manageYourSuggestions, // Exemple de sous-titre
          onTap: _navigateToSuggestionManagement,
          iconColor: AppColors.warning,
          iconBackgroundColor: Colors.orange.withValues(alpha: 0.1),
        ),
        ProfileActionTile(
          icon: Icons.storefront,
          title: l10n.myStores,
          subtitle: l10n.aisleOrder,
          onTap: _navigateToStores,
          iconColor: AppColors.primary,
          iconBackgroundColor: Colors.green.withValues(alpha: 0.1),
        ),
      ],
    );
  }

  void _navigateToStores() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StoresScreen()),
    );
  }

  Widget _buildAppSettingsSection(AppLocalizations l10n, User user) {
    return ProfileSection(
      title: l10n.appSettings,
      children: [
        _buildCurrencySettingTile(l10n),
        const SizedBox(height: 12),
        const LanguageSettingTile(),
        const SizedBox(height: 12),
        ProfileActionTile(
          icon: Icons.mail_outline,
          title: AppLocalizations.of(context)!.emailPreferences,
          subtitle: AppLocalizations.of(context)!.manageEmailNotifications,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EmailPreferencesScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCurrencySettingTile(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showCurrencySelectionDialog,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: BlocBuilder<CurrencyBloc, CurrencyState>(
              builder: (context, state) {
                Currency? currentCurrency;

                if (state is UserCurrencyLoaded) {
                  currentCurrency = state.userCurrency.currency;
                } else if (state is UserCurrencyUpdated) {
                  currentCurrency = state.userCurrency.currency;
                } else if (state is CurrenciesLoaded &&
                    state.userCurrency != null) {
                  currentCurrency = state.userCurrency!.currency;
                }

                if (currentCurrency == null && _currentUser?.currency != null) {
                  currentCurrency = _currentUser!.currency;
                }

                currentCurrency ??= Currency.cad;

                return Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.primary],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Center(
                        child: Text(
                          currentCurrency.symbol,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.currency,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${currentCurrency.name} (${currentCurrency.code.toUpperCase()})',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textDisabled,
                      size: 24,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showCurrencySelectionDialog() {
    context.read<CurrencyBloc>().add(const LoadCurrencies());
    context.read<CurrencyBloc>().add(const LoadUserCurrency());

    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (dialogContext) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<CurrencyBloc>()),
              BlocProvider.value(value: context.read<AuthBloc>()),
            ],
            child: CurrencySelectionDialog(
              currentCurrency: _currentUser?.currency,
              onCurrencySelected: (Currency selectedCurrency) {
                setState(() {
                  if (_currentUser != null) {
                    _currentUser = _currentUser!.copyWith(
                      currency: selectedCurrency,
                    );
                  }
                });
              },
            ),
          ),
    );
  }

  Widget _buildSettingsSection(AppLocalizations l10n) {
    return ProfileSection(
      title: l10n.security,
      children: [
        ProfileActionTile(
          icon: Icons.security_outlined,
          title: l10n.security,
          onTap: _showSecurityDialog,
          // Utilise les couleurs par défaut (pas besoin de spécifier)
        ),
        // Vérification en deux étapes : OPTIONNELLE, par email.
        ProfileActionTile(
          icon: _twoFactorEnabled == true
              ? Icons.verified_user_outlined
              : Icons.shield_outlined,
          title: l10n.twoFactorSetting,
          subtitle: _twoFactorEnabled == null
              ? '…'
              : (_twoFactorEnabled! ? l10n.enabled : l10n.disabled),
          onTap: _toggleTwoFactor,
        ),
      ],
    );
  }

  /// Active/désactive la vérification en deux étapes. Le serveur exige le
  /// mot de passe courant : on le demande avant d'envoyer.
  Future<void> _toggleTwoFactor() async {
    final l10n = AppLocalizations.of(context)!;
    if (_twoFactorEnabled == null) return;
    final target = !_twoFactorEnabled!;

    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.twoFactorSetting),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.twoFactorSettingHint,
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            Text(l10n.twoFactorPasswordPrompt,
                style: const TextStyle(fontSize: 12.5)),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.password),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(target ? l10n.activate : l10n.deactivate),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      await context
          .read<AuthService>()
          .setTwoFactorEnabled(target, passwordController.text);
      if (!mounted) return;
      setState(() => _twoFactorEnabled = target);
      SmartSnackBarManager.showSuccessSnackBar(
          context, target ? l10n.twoFactorEnabled : l10n.twoFactorDisabled);
    } on DioException catch (e) {
      if (!mounted) return;
      SmartSnackBarManager.showErrorSnackBar(
        context,
        e.response?.statusCode == 401
            ? l10n.twoFactorWrongPassword
            : l10n.anErrorOccurred,
      );
    } catch (_) {
      if (!mounted) return;
      SmartSnackBarManager.showErrorSnackBar(context, l10n.anErrorOccurred);
    }
  }

  // ✅ NOUVELLE SECTION SUPPORT AVEC BOUTON FEEDBACK
  Widget _buildSupportSection(AppLocalizations l10n) {
    return ProfileSection(
      title: l10n.support,
      children: [
        ProfileActionTile(
          icon: Icons.feedback_outlined,
          title: l10n.sendFeedback,
          subtitle: l10n.feedbackSubtitle,
          onTap: _showFeedbackDialog,
          iconColor: AppColors.primary, // Couleur verte pour l'icône
          iconBackgroundColor: Colors.green.withValues(alpha: 0.1), // Fond vert clair
        ),
        // Vous pouvez ajouter d'autres éléments de support ici si nécessaire
      ],
    );
  }

  Widget _buildInfoSection(AppLocalizations l10n) {
    return ProfileSection(
      title: l10n.information,
      children: [
        ProfileActionTile(
          icon: Icons.info_outline,
          title: l10n.aboutEpiList,
          onTap: _navigateToAbout,
        ),
        ProfileActionTile(
          icon: Icons.privacy_tip_outlined,
          title: l10n.privacyPolicy,
          onTap: _navigateToPrivacyPolicy,
        ),
        ProfileActionTile(
          icon: Icons.article_outlined,
          title: l10n.termsOfService,
          onTap: _navigateToTerms,
        ),
      ],
    );
  }

  void _navigateToShoppingLists() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ShoppingListScreen()),
    );
  }

  void _navigateToSuggestionManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SuggestionManagementWidget(),
      ),
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

  void _showSecurityDialog() {
    showDialog(
      context: context,
      builder: (context) => const SecuritySettingsDialog(),
    );
  }

  // ✅ NOUVELLE MÉTHODE POUR AFFICHER LE DIALOG DE FEEDBACK
  void _showFeedbackDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<ContactBloc>(),
            child: const FeedbackDialog(),
          ),
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
