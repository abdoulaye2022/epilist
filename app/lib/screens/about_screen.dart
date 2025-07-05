import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/smart_snackbar_manager.dart';

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
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Logo de l'application avec design amélioré
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
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
                      borderRadius: BorderRadius.circular(20),
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
                                colors: [
                                  Colors.green[400]!,
                                  Colors.green[600]!,
                                ],
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
                  SizedBox(height: 20),
                  Text(
                    'EpiList',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Organisez vos courses',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),

            // Description
            _buildSection(
              'Notre Mission',
              'EpiList révolutionne la façon dont vous gérez vos courses d\'épicerie. '
                  'Créez des listes intelligentes, suivez vos dépenses en temps réel, '
                  'partagez avec votre famille et ne manquez plus jamais un article important '
                  'grâce à notre système de gestion collaborative.',
            ),

            _buildSection(
              'Fonctionnalités Principales',
              '• Création de compte sécurisé (nom, prénom, email)\n'
                  '• Listes d\'épicerie personnalisées et intelligentes\n'
                  '• Ajout d\'articles avec quantité, prix et magasin\n'
                  '• Calcul automatique des totaux et pourcentages\n'
                  '• Marquage des articles achetés en temps réel\n'
                  '• Duplication rapide de listes existantes\n'
                  '• Partage sécurisé via liens avec permissions\n'
                  '• Gestion des droits (lecture, modification, administration)\n'
                  '• Synchronisation entre tous vos appareils\n'
                  '• Interface moderne et intuitive',
            ),

            _buildSection(
              'Collaboration Familiale',
              'EpiList facilite les courses en famille grâce à son système de partage avancé. '
                  'Partagez vos listes avec un simple lien, définissez qui peut voir, modifier '
                  'ou administrer chaque liste. Tout le monde reste synchronisé en temps réel !',
            ),

            _buildSection(
              'Développement',
              'EpiList est développé avec passion par M2atech Solutions Inc. pour vous offrir la meilleure '
                  'expérience de gestion de vos courses. Nous sommes constamment à '
                  'l\'écoute de vos retours pour améliorer l\'application et ajouter '
                  'de nouvelles fonctionnalités innovantes.',
            ),

            SizedBox(height: 24),

            // Boutons d'action
            Column(
              children: [
                _buildActionButton(
                  'Nous contacter',
                  Icons.email,
                  () => _launchContactPage(context),
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
                SizedBox(height: 12),
                _buildActionButton(
                  'Site Web',
                  Icons.language,
                  () => _launchWebsite(context),
                  Colors.purple,
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
              'Développé avec ❤️ par M2atech Solutions Inc.',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              'Moncton, Nouveau-Brunswick, Canada',
              style: TextStyle(color: Colors.grey[400], fontSize: 10),
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

  void _launchContactPage(BuildContext context) async {
    final Uri contactUrl = Uri.parse('https://epilist.app/contact');

    try {
      if (await canLaunchUrl(contactUrl)) {
        await launchUrl(contactUrl, mode: LaunchMode.externalApplication);
      } else {
        SmartSnackBarManager.showMessage(
          context,
          'Impossible d\'ouvrir le lien. Visitez https://epilist.app/contact',
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      SmartSnackBarManager.showMessage(
        context,
        'Erreur lors de l\'ouverture du lien de contact',
        type: SnackBarType.error,
      );
    }
  }

  void _launchWebsite(BuildContext context) async {
    final Uri websiteUrl = Uri.parse('https://epilist.app');

    try {
      if (await canLaunchUrl(websiteUrl)) {
        await launchUrl(websiteUrl, mode: LaunchMode.externalApplication);
      } else {
        SmartSnackBarManager.showMessage(
          context,
          'Impossible d\'ouvrir le site web. Visitez https://epilist.app',
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      SmartSnackBarManager.showMessage(
        context,
        'Erreur lors de l\'ouverture du site web',
        type: SnackBarType.error,
      );
    }
  }

  void _rateApp(BuildContext context) async {
    // URLs pour les stores - à mettre à jour avec vos vraies URLs
    const String androidUrl =
        'https://play.google.com/store/apps/details?id=com.m2atech.epilist';
    const String iosUrl = 'https://apps.apple.com/app/epilist/id123456789';

    try {
      final Uri storeUri;
      if (Theme.of(context).platform == TargetPlatform.android) {
        storeUri = Uri.parse(androidUrl);
      } else {
        storeUri = Uri.parse(iosUrl);
      }

      if (await canLaunchUrl(storeUri)) {
        await launchUrl(storeUri, mode: LaunchMode.externalApplication);
      } else {
        SmartSnackBarManager.showMessage(
          context,
          'Store non disponible. Merci de noter EpiList sur votre store habituel !',
          type: SnackBarType.info,
        );
      }
    } catch (e) {
      SmartSnackBarManager.showMessage(
        context,
        'Impossible d\'ouvrir le store pour le moment',
        type: SnackBarType.warning,
      );
    }
  }

  void _shareApp(BuildContext context) async {
    const String appName = 'EpiList';
    const String appDescription =
        'Organisez vos courses d\'épicerie en famille avec EpiList ! '
        'Listes partagées, calculs automatiques, synchronisation temps réel.';
    const String websiteLink = 'https://epilist.app';

    const String shareText =
        '$appName 🛒\n\n'
        '$appDescription\n\n'
        'Découvrez l\'application :\n'
        '$websiteLink\n\n'
        '#EpiList #Courses #Organisation #Famille';

    try {
      await Share.share(
        shareText,
        subject: 'Découvrez EpiList - Votre assistant courses en famille !',
      );
    } catch (e) {
      SmartSnackBarManager.showMessage(
        context,
        'Impossible de partager pour le moment',
        type: SnackBarType.error,
      );
    }
  }
}
