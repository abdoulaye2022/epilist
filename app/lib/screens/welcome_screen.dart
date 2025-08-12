// screens/welcome_screen.dart - VERSION OPTIMISÉE ET SIMPLIFIÉE
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
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // ✅ LOGO SIMPLIFIÉ
              _buildLogo(),

              const SizedBox(height: 32),

              // ✅ TITRE ET DESCRIPTION
              _buildHeader(l10n),

              const SizedBox(height: 40),

              // ✅ SÉLECTION DE LANGUE SIMPLIFIÉE
              _buildLanguageSelector(context, l10n),

              const SizedBox(height: 40),

              // ✅ BOUTON PRINCIPAL SIMPLIFIÉ
              _buildMainButton(context, l10n),

              const SizedBox(height: 32),

              // ✅ LIENS INFORMATIFS SIMPLIFIÉS
              _buildInfoLinks(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ LOGO SIMPLIFIÉ SANS BACKGROUND
  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: const BoxDecoration(
        color: Colors.transparent, // ✅ Background transparent
      ),
      child: Image.asset(
        'assets/images/app_logo.png',
        width: 120,
        height: 120,
        fit: BoxFit.contain,
        errorBuilder:
            (_, __, ___) => Icon(
              Icons.shopping_cart_rounded,
              size: 60,
              color: Colors.green[600],
            ),
      ),
    );
  }

  // ✅ TITRE ET DESCRIPTION SIMPLIFIÉS
  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          l10n.welcomeToEpiList,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.groceryListApp,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ✅ SÉLECTEUR DE LANGUE SIMPLIFIÉ
  Widget _buildLanguageSelector(BuildContext context, AppLocalizations l10n) {
    return BlocBuilder<LocalizationBloc, LocalizationState>(
      builder: (context, state) {
        String currentLanguage = 'fr';
        if (state is LocalizationLoaded) {
          currentLanguage = state.locale.languageCode;
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.language, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.selectLanguage,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildLanguageButton(
                      context,
                      'fr',
                      '🇫🇷 ${l10n.french}',
                      currentLanguage == 'fr',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLanguageButton(
                      context,
                      'en',
                      '🇺🇸 ${l10n.english}',
                      currentLanguage == 'en',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ BOUTON DE LANGUE SIMPLIFIÉ
  Widget _buildLanguageButton(
    BuildContext context,
    String languageCode,
    String label,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        context.read<LocalizationBloc>().add(ChangeLanguage(languageCode));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[600] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.green[600]! : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // ✅ BOUTON PRINCIPAL SIMPLIFIÉ
  Widget _buildMainButton(BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => _navigateToLogin(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Text(
          l10n.getStarted,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ✅ LIENS INFORMATIFS SIMPLIFIÉS
  Widget _buildInfoLinks(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          l10n.information,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildInfoButton(
              context,
              icon: Icons.info_outline,
              label: l10n.aboutEpiList,
              onTap: () => _navigateToAbout(context),
            ),
            _buildInfoButton(
              context,
              icon: Icons.privacy_tip_outlined,
              label: l10n.privacyPolicy,
              onTap: () => _navigateToPrivacyPolicy(context),
            ),
            _buildInfoButton(
              context,
              icon: Icons.article_outlined,
              label: l10n.termsOfService,
              onTap: () => _navigateToTerms(context),
            ),
          ],
        ),
      ],
    );
  }

  // ✅ BOUTON D'INFO SIMPLIFIÉ
  Widget _buildInfoButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.grey[600], size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ MÉTHODES DE NAVIGATION SIMPLIFIÉES
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

  void _navigateToTerms(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
