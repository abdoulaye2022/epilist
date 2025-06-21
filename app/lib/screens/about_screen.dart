import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

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
                  () => _launchEmail(context),
                  Colors.blue,
                ),
                SizedBox(height: 12),
                _buildActionButton(
                  'Noter l\'application',
                  Icons.star,
                  () => _rateApp(context),
                  Colors.orange,
                ),
                SizedBox(height: 12),
                _buildActionButton(
                  'Partager EpiList',
                  Icons.share,
                  () => _shareApp(context),
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
            SizedBox(height: 8),
            Text(
              'Développé par M2A Tech',
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

  void _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'contact@m2atech.com',
      query:
          'subject=Support EpiList&body=Bonjour,%0A%0AJe vous contacte concernant l\'application EpiList.%0A%0A',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        // Si l'email ne peut pas être ouvert, proposer d'autres options
        _showContactDialog(context);
      }
    } catch (e) {
      _showContactDialog(context);
    }
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Nous contacter'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vous pouvez nous contacter par email :'),
              SizedBox(height: 8),
              SelectableText(
                'contact@m2atech.com',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
              SizedBox(height: 16),
              Text('Ou essayer d\'ouvrir votre client email :'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Fermer'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _copyEmailToClipboard(context);
              },
              child: Text('Copier l\'email'),
            ),
          ],
        );
      },
    );
  }

  void _copyEmailToClipboard(BuildContext context) {
    // Copy to clipboard
    final data = ClipboardData(text: 'contact@m2atech.com');
    Clipboard.setData(data);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Email copié dans le presse-papiers'),
        backgroundColor: Colors.green[600],
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _rateApp(BuildContext context) async {
    // URLs pour les stores
    const String androidUrl =
        'https://play.google.com/store/apps/details?id=com.m2atech.epilist';
    const String iosUrl = 'https://apps.apple.com/app/epilist/id123456789';

    try {
      // Détecter la plateforme et utiliser l'URL appropriée
      final Uri storeUri;
      if (Theme.of(context).platform == TargetPlatform.android) {
        storeUri = Uri.parse(androidUrl);
      } else {
        storeUri = Uri.parse(iosUrl);
      }

      if (await canLaunchUrl(storeUri)) {
        await launchUrl(storeUri, mode: LaunchMode.externalApplication);
      } else {
        _showRatingDialog(context);
      }
    } catch (e) {
      _showRatingDialog(context);
    }
  }

  void _showRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Noter l\'application'),
          content: Text(
            'Merci de vouloir noter EpiList ! '
            'Vous pouvez nous laisser un avis sur votre store d\'applications habituel.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Plus tard'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Merci pour votre soutien ! 🌟'),
                    backgroundColor: Colors.orange[600],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text('Merci !'),
            ),
          ],
        );
      },
    );
  }

  void _shareApp(BuildContext context) async {
    const String appName = 'EpiList';
    const String appDescription =
        'Organisez vos courses facilement avec EpiList !';
    const String downloadLink =
        'https://play.google.com/store/apps/details?id=com.m2atech.epilist';

    const String shareText =
        '$appName\n\n'
        '$appDescription\n\n'
        'Téléchargez l\'application :\n'
        '$downloadLink\n\n'
        '#EpiList #Courses #Organisation';

    try {
      // ignore: deprecated_member_use
      await Share.share(
        shareText,
        subject: 'Découvrez EpiList - Votre assistant courses !',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de partager pour le moment'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }
}
