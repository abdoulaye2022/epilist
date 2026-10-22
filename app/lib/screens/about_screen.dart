import 'package:epilist/widgets/common/app_top_bar.dart';
import 'package:epilist/widgets/common/app_drawer.dart';
import 'package:epilist/widgets/common/main_bottom_bar.dart';
import 'package:epilist/widgets/common/main_shell_scope.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:epilist/l10n/app_localizations.dart';
import '../utils/smart_snackbar_manager.dart';
import 'package:epilist/widgets/common/app_card.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      bottomNavigationBar: const AppPageBottomBar(tab: MainTab.sections),
      appBar: AppTopBar(title: l10n.aboutEpiList),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App logo and name
            AppCard(
              radius: 20,
              bordered: false,
              padding: const EdgeInsets.all(24),
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
                              colors: [AppColors.primary, AppColors.primary],
                            ),
                          ),
                          child: Icon(
                            Icons.shopping_cart_rounded,
                            size: 50,
                            color: AppColors.onPrimary,
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
                      color: AppColors.primaryDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.manageGroceryListsEasily,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
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
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.successBorder),
                    ),
                    child: Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.primaryDark,
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
                  AppColors.info,
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  l10n.aboutRateApp,
                  Icons.star,
                  () => _rateApp(context, l10n),
                  AppColors.warning,
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  l10n.aboutShareApp,
                  Icons.share,
                  () => _shareApp(context, l10n),
                  AppColors.success,
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  l10n.aboutWebsite,
                  Icons.language,
                  () => _launchWebsite(context, l10n),
                  AppColors.violet,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Copyright
            Text(
              '© 2025 EpiList. ${l10n.aboutRightsReserved}',
              style: TextStyle(color: AppColors.textDisabled, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.aboutDevelopedWith} ❤️ ${l10n.aboutByCompany}',
              style: TextStyle(color: AppColors.textDisabled, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Moncton, New Brunswick, Canada',
              style: TextStyle(color: AppColors.textDisabled, fontSize: 14.5),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
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
          foregroundColor: AppColors.onPrimary,
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
        if (!context.mounted) return;
        SmartSnackBarManager.showMessage(
          context,
          l10n.aboutContactError,
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
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
        if (!context.mounted) return;
        SmartSnackBarManager.showMessage(
          context,
          l10n.aboutWebsiteError,
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
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
    const String iosUrl = 'https://apps.apple.com/ca/app/epilist/id6748285596';

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
        if (!context.mounted) return;
        SmartSnackBarManager.showMessage(
          context,
          l10n.aboutStoreUnavailable,
          type: SnackBarType.info,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
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
      await SharePlus.instance.share(
        ShareParams(text: shareText, subject: l10n.aboutShareSubject),
      );
    } catch (e) {
      if (!context.mounted) return;
      SmartSnackBarManager.showMessage(
        context,
        l10n.aboutShareError,
        type: SnackBarType.error,
      );
    }
  }
}
