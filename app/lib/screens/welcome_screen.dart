// screens/welcome_screen.dart - VERSION AVEC LOGO SANS BACKGROUND
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart';
import 'package:epilist/screens/login_screen.dart';
import 'package:epilist/screens/about_screen.dart';
import 'package:epilist/screens/privacy_policy_screen.dart';
import 'package:epilist/screens/terms_of_service.dart';
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // ✅ Logo sans background
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Colors.transparent, // ✅ Background transparent
                ),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain, // ✅ Changé de cover à contain
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.green[400]!, Colors.green[600]!],
                        ),
                      ),
                      child: const Icon(
                        Icons.shopping_cart_rounded,
                        size: 50,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Titre
              Text(
                l10n.welcomeToEpiList,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                l10n.groceryListApp,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Section sélection de langue
              _buildLanguageSection(context, l10n),
              const SizedBox(height: 32),

              // Message principal
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.login, size: 48, color: Colors.blue[600]),
                    const SizedBox(height: 16),
                    Text(
                      l10n.loginTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.manageGroceryLists,
                      style: TextStyle(fontSize: 14, color: Colors.blue[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Bouton de connexion principal
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _navigateToLogin(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    '${l10n.login} / ${l10n.register}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Section des pages d'information accessibles
              _buildInfoSection(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  // Widget pour la sélection de langue
  Widget _buildLanguageSection(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
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
                l10n.language,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Sélecteurs de langue
          BlocBuilder<LocalizationBloc, LocalizationState>(
            builder: (context, state) {
              String currentLanguage = 'fr';
              if (state is LocalizationLoaded) {
                currentLanguage = state.locale.languageCode;
              }

              return Row(
                children: [
                  Expanded(
                    child: _buildLanguageOption(
                      context,
                      'fr',
                      l10n.french,
                      '🇫🇷',
                      currentLanguage == 'fr',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLanguageOption(
                      context,
                      'en',
                      l10n.english,
                      '🇺🇸',
                      currentLanguage == 'en',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String languageCode,
    String languageName,
    String flag,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        context.read<LocalizationBloc>().add(ChangeLanguage(languageCode));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[600] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.green[600]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                languageName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              const Icon(Icons.check_circle, color: Colors.white, size: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          'Informations', // TODO: Ajouter à l10n si nécessaire
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 16),

        // Card contenant les liens d'information
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildInfoTile(
                context,
                icon: Icons.info_outline,
                title: 'À propos d\'EpiList', // TODO: Ajouter à l10n
                onTap: () => _navigateToAbout(context),
              ),
              const Divider(height: 1),
              _buildInfoTile(
                context,
                icon: Icons.privacy_tip_outlined,
                title: 'Politique de confidentialité', // TODO: Ajouter à l10n
                onTap: () => _navigateToPrivacyPolicy(context),
              ),
              const Divider(height: 1),
              _buildInfoTile(
                context,
                icon: Icons.article_outlined,
                title: 'Conditions d\'utilisation', // TODO: Ajouter à l10n
                onTap: () => _navigateToTerms(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Note informative
        Text(
          'Ces informations sont disponibles sans connexion', // TODO: Ajouter à l10n
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _navigateToAbout(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AboutPage()),
    );
  }

  void _navigateToPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
    );
  }

  void _navigateToTerms(BuildContext context) {
    // Version temporaire avec dialog si le fichier n'existe pas
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Conditions d\'utilisation'),
            content: const Text(
              'En utilisant EpiList, vous acceptez nos conditions d\'utilisation.\n\n'
              'Cette application vous permet de gérer vos listes de courses de manière sécurisée et respectueuse de votre vie privée.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Compris'),
              ),
            ],
          ),
    );

    /* 
    // Décommentez cette partie quand vous aurez créé le fichier :
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TermsOfServicePage()),
    );
    */
  }
}
