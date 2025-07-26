import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:epilist/l10n/app_localizations.dart';
import '../utils/smart_snackbar_manager.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(l10n.aboutEpiList),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App logo and name
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
                  // Application logo with improved design
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
                          // Fallback with improved design if image is not found
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
                    l10n.manageGroceryListsEasily,
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
              l10n.aboutMission ?? 'Notre Mission',
              l10n.aboutMissionText ??
                  'EpiList révolutionne la façon dont vous gérez vos courses. '
                      'Créez des listes intelligentes, suivez vos dépenses en temps réel, '
                      'partagez avec votre famille et ne manquez plus jamais un article important '
                      'grâce à notre système de gestion collaborative.',
            ),

            _buildSection(
              l10n.aboutFeatures ?? 'Fonctionnalités principales',
              l10n.aboutFeaturesText ??
                  '• Création de compte sécurisée (prénom, nom, email)\n'
                      '• Listes d\'épicerie personnalisées et intelligentes\n'
                      '• Ajout d\'articles avec quantité, prix et magasin\n'
                      '• Calcul automatique des totaux et pourcentages\n'
                      '• Marquage en temps réel des articles achetés\n'
                      '• Duplication rapide des listes existantes\n'
                      '• Partage sécurisé via liens avec permissions\n'
                      '• Gestion des droits (lecture, édition, administration)\n'
                      '• Synchronisation sur tous vos appareils\n'
                      '• Interface moderne et intuitive',
            ),

            _buildSection(
              l10n.aboutCollaboration ?? 'Collaboration familiale',
              l10n.aboutCollaborationText ??
                  'EpiList facilite les courses en famille avec son système de partage avancé. '
                      'Partagez vos listes d\'un simple lien, définissez qui peut voir, modifier '
                      'ou administrer chaque liste. Tout le monde reste synchronisé en temps réel!',
            ),

            _buildSection(
              l10n.aboutDevelopment ?? 'Développement',
              l10n.aboutDevelopmentText ??
                  'EpiList est développé avec passion par M2atech Solutions Inc. pour vous offrir la meilleure '
                      'expérience de gestion d\'épicerie. Nous sommes constamment à l\'écoute de vos retours pour améliorer l\'app et ajouter '
                      'de nouvelles fonctionnalités innovantes.',
            ),

            SizedBox(height: 24),

            // Action buttons
            Column(
              children: [
                _buildActionButton(
                  l10n.aboutContact ?? 'Nous contacter',
                  Icons.email,
                  () => _launchContactPage(context, l10n),
                  Colors.blue,
                ),
                SizedBox(height: 12),
                _buildActionButton(
                  l10n.aboutRateApp ?? 'Évaluer l\'app',
                  Icons.star,
                  () => _rateApp(context, l10n),
                  Colors.orange,
                ),
                SizedBox(height: 12),
                _buildActionButton(
                  l10n.aboutShareApp ?? 'Partager EpiList',
                  Icons.share,
                  () => _shareApp(context, l10n),
                  Colors.green,
                ),
                SizedBox(height: 12),
                _buildActionButton(
                  l10n.aboutWebsite ?? 'Site web',
                  Icons.language,
                  () => _launchWebsite(context, l10n),
                  Colors.purple,
                ),
              ],
            ),

            SizedBox(height: 32),

            // Copyright
            Text(
              '© 2025 EpiList. ${l10n.aboutRightsReserved ?? "Tous droits réservés."}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              '${l10n.aboutDevelopedWith ?? "Développé avec"} ❤️ ${l10n.aboutByCompany ?? "par M2atech Solutions Inc."}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              'Moncton, New Brunswick, Canada',
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

  void _launchContactPage(BuildContext context, AppLocalizations l10n) async {
    final Uri contactUrl = Uri.parse('https://epilist.app/contact');

    try {
      if (await canLaunchUrl(contactUrl)) {
        await launchUrl(contactUrl, mode: LaunchMode.externalApplication);
      } else {
        SmartSnackBarManager.showMessage(
          context,
          l10n.aboutContactError ??
              'Impossible d\'ouvrir le lien. Visitez https://epilist.app/contact',
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      SmartSnackBarManager.showMessage(
        context,
        l10n.aboutContactError ??
            'Erreur lors de l\'ouverture du lien de contact',
        type: SnackBarType.error,
      );
    }
  }

  void _launchWebsite(BuildContext context, AppLocalizations l10n) async {
    final Uri websiteUrl = Uri.parse('https://epilist.app');

    try {
      if (await canLaunchUrl(websiteUrl)) {
        await launchUrl(websiteUrl, mode: LaunchMode.externalApplication);
      } else {
        SmartSnackBarManager.showMessage(
          context,
          l10n.aboutWebsiteError ??
              'Impossible d\'ouvrir le site web. Visitez https://epilist.app',
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      SmartSnackBarManager.showMessage(
        context,
        l10n.aboutWebsiteError ?? 'Erreur lors de l\'ouverture du site web',
        type: SnackBarType.error,
      );
    }
  }

  void _rateApp(BuildContext context, AppLocalizations l10n) async {
    // Store URLs - update with your actual URLs
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
          l10n.aboutStoreUnavailable ??
              'Magasin indisponible. Évaluez EpiList sur votre magasin habituel!',
          type: SnackBarType.info,
        );
      }
    } catch (e) {
      SmartSnackBarManager.showMessage(
        context,
        l10n.aboutStoreError ??
            'Impossible d\'ouvrir le magasin pour le moment',
        type: SnackBarType.warning,
      );
    }
  }

  void _shareApp(BuildContext context, AppLocalizations l10n) async {
    const String appName = 'EpiList';
    final String appDescription =
        l10n.aboutShareDescription ??
        'Organisez vos courses en famille avec EpiList! '
            'Listes partagées, calculs automatiques, synchronisation temps réel.';
    const String websiteLink = 'https://epilist.app';

    final String shareText =
        '$appName 🛒\n\n'
        '$appDescription\n\n'
        '${l10n.aboutDiscoverApp ?? "Découvrez l\'app"}:\n'
        '$websiteLink\n\n'
        '#EpiList #Groceries #Organization #Family';

    try {
      await Share.share(
        shareText,
        subject:
            l10n.aboutShareSubject ??
            'Découvrez EpiList - Votre assistant épicerie familial!',
      );
    } catch (e) {
      SmartSnackBarManager.showMessage(
        context,
        l10n.aboutShareError ?? 'Impossible de partager pour le moment',
        type: SnackBarType.error,
      );
    }
  }
}
