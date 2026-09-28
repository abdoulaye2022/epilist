import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:epilist/l10n/app_localizations.dart';
import '../utils/smart_snackbar_manager.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.privacyPolicy),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.privacyPolicy,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              l10n.privacyLastUpdated,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            SizedBox(height: 24),

            _buildPolicySection(
              l10n.privacyCollectionTitle,
              l10n.privacyCollectionText,
            ),

            _buildPolicySection(
              l10n.privacyUsageTitle,
              l10n.privacyUsageText,
            ),

            _buildPolicySection(
              l10n.privacyStorageTitle,
              l10n.privacyStorageText,
            ),

            _buildPolicySection(
              l10n.privacySharingTitle,
              l10n.privacySharingText,
            ),

            _buildPolicySection(
              l10n.privacyRightsTitle,
              l10n.privacyRightsText,
            ),

            _buildPolicySection(
              l10n.privacyFeaturesTitle,
              l10n.privacyFeaturesText,
            ),

            _buildPolicySection(
              l10n.privacyCookiesTitle,
              l10n.privacyCookiesText,
            ),

            _buildPolicySection(
              l10n.privacyChangesTitle,
              l10n.privacyChangesText,
            ),

            _buildContactSection(
              context,
              l10n.privacyContactTitle,
              l10n.privacyContactText,
              l10n,
            ),

            SizedBox(height: 32),
            Center(
              child: Text(
                '© 2025 EpiList - ${l10n.aboutRightsReserved}',
                style: TextStyle(color: AppColors.textDisabled, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(
    BuildContext context,
    String title,
    String content,
    AppLocalizations l10n,
  ) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final Uri url = Uri.parse('https://epilist.app/contact');
              try {
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(l10n.aboutContact),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection(String title, String content) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
