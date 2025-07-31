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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(l10n.aboutEpiList),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App logo and name
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ✅ Logo sans background (comme WelcomeScreen)
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
                        // ✅ Fallback avec design amélioré si l'image n'est pas trouvée
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
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
                  const SizedBox(height: 20),
                  Text(
                    'EpiList',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.manageGroceryListsEasily,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
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

            const SizedBox(height: 32),

            // Description
            _buildSection(l10n.aboutMission, l10n.aboutMissionText),

            _buildSection(l10n.aboutFeatures, l10n.aboutFeaturesText),

            _buildSection(l10n.aboutCollaboration, l10n.aboutCollaborationText),

            _buildSection(l10n.aboutDevelopment, l10n.aboutDevelopmentText),

            const SizedBox(height: 24),

            // Action buttons
            Column(
              children: [
                _buildActionButton(
                  l10n.aboutContact,
                  Icons.email,
                  () => _launchContactPage(context, l10n),
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  l10n.aboutRateApp,
                  Icons.star,
                  () => _rateApp(context, l10n),
                  Colors.orange,
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  l10n.aboutShareApp,
                  Icons.share,
                  () => _shareApp(context, l10n),
                  Colors.green,
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  l10n.aboutWebsite,
                  Icons.language,
                  () => _launchWebsite(context, l10n),
                  Colors.purple,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Copyright
            Text(
              '© 2025 EpiList. ${l10n.aboutRightsReserved}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.aboutDevelopedWith} ❤️ ${l10n.aboutByCompany}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
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
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
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
          padding: const EdgeInsets.symmetric(vertical: 12),
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
          l10n.aboutContactError,
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      SmartSnackBarManager.showMessage(
        context,
        l10n.aboutContactError,
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
          l10n.aboutWebsiteError,
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      SmartSnackBarManager.showMessage(
        context,
        l10n.aboutWebsiteError,
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
          l10n.aboutStoreUnavailable,
          type: SnackBarType.info,
        );
      }
    } catch (e) {
      SmartSnackBarManager.showMessage(
        context,
        l10n.aboutStoreError,
        type: SnackBarType.warning,
      );
    }
  }

  void _shareApp(BuildContext context, AppLocalizations l10n) async {
    const String appName = 'EpiList';
    final String appDescription = l10n.aboutShareDescription;
    const String websiteLink = 'https://epilist.app';

    final String shareText =
        '$appName 🛒\n\n'
        '$appDescription\n\n'
        '${l10n.aboutDiscoverApp}:\n'
        '$websiteLink\n\n'
        '#EpiList #Groceries #Organization #Family';

    try {
      await Share.share(shareText, subject: l10n.aboutShareSubject);
    } catch (e) {
      SmartSnackBarManager.showMessage(
        context,
        l10n.aboutShareError,
        type: SnackBarType.error,
      );
    }
  }
}
