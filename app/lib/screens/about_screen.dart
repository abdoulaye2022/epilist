import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('À propos'),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo et nom de l'app
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(Icons.shopping_cart, size: 80, color: Colors.green[600]),
                  SizedBox(height: 16),
                  Text(
                    'EpiList',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),

            // Description
            _buildSection(
              'Notre Mission',
              'EpiList vous aide à organiser vos courses de manière simple et efficace. '
                  'Suivez vos habitudes d\'achat, gérez vos budgets et ne manquez plus jamais '
                  'un article important grâce à notre système de listes intelligentes.',
            ),

            _buildSection(
              'Fonctionnalités',
              '• Création de listes d\'épicerie personnalisées\n'
                  '• Suivi semaine après semaine de vos achats\n'
                  '• Calcul automatique des totaux\n'
                  '• Historique de vos courses\n'
                  '• Interface simple et intuitive\n'
                  '• Synchronisation de vos données',
            ),

            _buildSection(
              'Développement',
              'EpiList est développé avec passion pour vous offrir la meilleure '
                  'expérience de gestion de vos courses. Nous sommes constamment à '
                  'l\'écoute de vos retours pour améliorer l\'application.',
            ),

            SizedBox(height: 24),

            // Boutons d'action
            Column(
              children: [
                _buildActionButton(
                  'Nous contacter',
                  Icons.email,
                  () => _launchEmail(),
                  Colors.blue,
                ),
                SizedBox(height: 12),
                _buildActionButton(
                  'Noter l\'application',
                  Icons.star,
                  () => _rateApp(),
                  Colors.orange,
                ),
                SizedBox(height: 12),
                _buildActionButton(
                  'Partager EpiList',
                  Icons.share,
                  () => _shareApp(),
                  Colors.green,
                ),
              ],
            ),

            SizedBox(height: 32),

            // Copyright
            Text(
              '© 2025 EpiList. Tous droits réservés.',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 24),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    VoidCallback onPressed,
    Color color,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  void _launchEmail() async {
    // if (await canLaunchUrl(emailUri)) {
    //   await launchUrl(emailUri);
    // }
  }

  void _rateApp() {
    // Logique pour noter l'app sur les stores
    print('Redirection vers le store pour noter l\'app');
  }

  void _shareApp() {
    // Logique pour partager l'app
    print('Partage de l\'application');
  }
}
