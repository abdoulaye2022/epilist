// screens/welcome_screen.dart - VERSION SIMPLIFIÉE POUR PAGES INFO UNIQUEMENT
import 'package:flutter/material.dart';
import 'package:epilist/screens/login_screen.dart';
import 'package:epilist/screens/about_screen.dart';
import 'package:epilist/screens/privacy_policy_screen.dart';
import 'package:epilist/screens/terms_of_service.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),

              // Logo de votre app avec design amélioré
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.green[400]!, Colors.green[600]!],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback avec design amélioré si l'image n'est pas trouvée
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.green[400]!, Colors.green[600]!],
                          ),
                        ),
                        child: Icon(
                          Icons.shopping_cart_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Titre
              Text(
                'Bienvenue sur EpiList',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'Gérez vos listes de courses facilement et efficacement',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

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
                      'Connectez-vous pour accéder à toutes les fonctionnalités',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Créez et gérez vos listes de courses, suivez vos dépenses et bien plus encore !',
                      style: TextStyle(fontSize: 14, color: Colors.blue[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

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
                  child: const Text(
                    'Se connecter / S\'inscrire',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Section des pages d'information accessibles
              _buildInfoSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Column(
      children: [
        Text(
          'Informations',
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
                title: 'À propos d\'EpiList',
                onTap: () => _navigateToAbout(context),
              ),
              const Divider(height: 1),
              _buildInfoTile(
                context,
                icon: Icons.privacy_tip_outlined,
                title: 'Politique de confidentialité',
                onTap: () => _navigateToPrivacyPolicy(context),
              ),
              const Divider(height: 1),
              _buildInfoTile(
                context,
                icon: Icons.article_outlined,
                title: 'Conditions d\'utilisation',
                onTap: () => _navigateToTerms(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Note informative
        Text(
          'Ces informations sont disponibles sans connexion',
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

    // Décommentez cette partie quand vous aurez créé le fichier :
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TermsOfServicePage()),
    );
  }
}
