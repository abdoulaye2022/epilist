// screens/welcome_screen.dart - Première impression : sobre, aérée, ancrée
// sur la marque. Sélecteur de langue compact en haut, promesses de l'app au
// centre, action principale en bas.
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart';
import 'package:epilist/screens/login_screen.dart';
import 'package:epilist/screens/about_screen.dart';
import 'package:epilist/screens/privacy_policy_screen.dart';
import 'package:epilist/l10n/app_localizations.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: _buildLanguageToggle(context),
                      ),
                      const Spacer(flex: 2),
                      _buildLogo(),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n.welcomeToEpiList,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.groceryListApp,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _buildFeatureRow(
                        Icons.group_outlined,
                        l10n.shareAndCollaborate,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildFeatureRow(
                        Icons.route_outlined,
                        l10n.sortByAisle,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildFeatureRow(
                        Icons.savings_outlined,
                        l10n.trackYourBudget,
                      ),
                      const Spacer(flex: 3),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => _navigateToLogin(context),
                          child: Text(l10n.getStarted),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildFooterLinks(context, l10n),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 104,
        height: 104,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border),
        ),
        child: Image.asset(
          'assets/images/app_logo.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.shopping_cart_rounded,
            size: 48,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  /// Sélecteur de langue compact : deux segments FR / EN.
  Widget _buildLanguageToggle(BuildContext context) {
    return BlocBuilder<LocalizationBloc, LocalizationState>(
      builder: (context, state) {
        final current =
            state is LocalizationLoaded ? state.locale.languageCode : 'fr';

        Widget segment(String code, String label) {
          final selected = current == code;
          return GestureDetector(
            onTap: () =>
                context.read<LocalizationBloc>().add(ChangeLanguage(code)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: selected ? AppColors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? AppColors.border : Colors.transparent,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF1EF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [segment('fr', 'FR'), segment('en', 'EN')],
          ),
        );
      },
    );
  }

  Widget _buildFeatureRow(IconData icon, String label) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, size: 21, color: AppColors.primaryDark),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterLinks(BuildContext context, AppLocalizations l10n) {
    Widget link(String label, VoidCallback onTap) => TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            textStyle: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          child: Text(label),
        );

    Widget dot() => const Text(
          '·',
          style: TextStyle(color: AppColors.textDisabled, fontSize: 12),
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        link(l10n.aboutEpiList, () => _navigateToAbout(context)),
        dot(),
        link(l10n.privacyPolicy, () => _navigateToPrivacyPolicy(context)),
        dot(),
        link(l10n.termsOfService, () => _showTerms(context)),
      ],
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _navigateToAbout(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AboutPage()),
    );
  }

  void _navigateToPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PrivacyPolicyPage()),
    );
  }

  void _showTerms(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.termsOfService),
        content: Text(AppLocalizations.of(context)!.termsAcceptanceText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.understood),
          ),
        ],
      ),
    );
  }
}
