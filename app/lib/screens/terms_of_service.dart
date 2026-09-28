import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:epilist/l10n/app_localizations.dart';
import '../utils/smart_snackbar_manager.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.termsOfService),
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
              l10n.termsOfService,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              l10n.termsLastUpdated,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            SizedBox(height: 24),

            _buildTermSection(
              l10n.termsAcceptanceTitle,
              l10n.termsAcceptanceText,
            ),

            _buildTermSection(
              l10n.termsServiceTitle,
              l10n.termsServiceText,
            ),

            _buildTermSection(
              l10n.termsAccountTitle,
              l10n.termsAccountText,
            ),

            _buildTermSection(
              l10n.termsUsageTitle,
              l10n.termsUsageText,
            ),

            _buildTermSection(
              l10n.termsAcceptableTitle,
              l10n.termsAcceptableText,
            ),

            _buildTermSection(
              l10n.termsOwnershipTitle,
              l10n.termsOwnershipText,
            ),

            _buildTermSection(
              l10n.termsCalculationsTitle,
              l10n.termsCalculationsText,
            ),

            _buildTermSection(
              l10n.termsAvailabilityTitle,
              l10n.termsAvailabilityText,
            ),

            _buildTermSection(
              l10n.termsLiabilityTitle,
              l10n.termsLiabilityText,
            ),

            _buildTermSection(
              l10n.termsTerminationTitle,
              l10n.termsTerminationText,
            ),

            _buildTermSection(
              l10n.termsModificationsTitle,
              l10n.termsModificationsText,
            ),

            _buildTermSection(
              l10n.termsJurisdictionTitle,
              l10n.termsJurisdictionText,
            ),

            _buildContactSection(
              context,
              l10n.termsContactTitle,
              l10n.termsContactText,
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
              final Uri url = Uri.parse('https://epilist.app/terms');
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

  Widget _buildTermSection(String title, String content) {
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
