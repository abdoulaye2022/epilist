import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/smart_snackbar_manager.dart';

class TermsOfServicePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Terms of Service'),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Last updated: July 5, 2025',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            SizedBox(height: 24),

            _buildTermSection(
              '1. Acceptance of Terms',
              'By using the EpiList application, you agree to be bound by these terms of service. '
                  'If you do not accept these terms in their entirety, please do not use the application.',
            ),

            _buildTermSection(
              '2. Service Description',
              'EpiList is a mobile grocery list management application that allows:\n\n'
                  '• Creating an account with first name, last name, email and password\n'
                  '• Creating, editing and deleting grocery lists\n'
                  '• Adding items with name, quantity, price and store (optional)\n'
                  '• Marking items as purchased or deleting them\n'
                  '• Automatically calculating totals and purchase percentages\n'
                  '• Duplicating existing lists\n'
                  '• Sharing lists with secure links\n'
                  '• Managing access permissions (read, edit, administration)\n\n'
                  'The service is provided "as is" and "as available".',
            ),

            _buildTermSection(
              '3. User Account and Security',
              'To use EpiList, you must:\n\n'
                  '• Create an account with accurate information (first name, last name, email)\n'
                  '• Choose a secure password and keep it confidential\n'
                  '• Be responsible for all activities performed under your account\n'
                  '• Notify us immediately of any unauthorized use\n'
                  '• Update your personal information as necessary\n\n'
                  'You are solely responsible for the security of your login credentials.',
            ),

            _buildTermSection(
              '4. List Usage and Sharing',
              'Regarding the use of the application\'s features:\n\n'
                  '• You can create unlimited grocery lists\n'
                  '• Sharing links are your responsibility\n'
                  '• You control the access permissions you grant\n'
                  '• Invited people must respect the defined permissions\n'
                  '• You can revoke access at any time\n'
                  '• Shared content must remain appropriate and legal\n\n'
                  'You are responsible for managing your shared lists.',
            ),

            _buildTermSection(
              '5. Acceptable Use',
              'You agree to:\n\n'
                  '• Use the application only for grocery list management\n'
                  '• Not attempt to disrupt the service operation\n'
                  '• Not illegally access other users\' data\n'
                  '• Respect intellectual property rights\n'
                  '• Not use the application for commercial purposes without authorization\n'
                  '• Not share offensive or illegal content\n\n'
                  'Any abusive use may result in immediate account suspension.',
            ),

            _buildTermSection(
              '6. Content Ownership',
              'Regarding the content you create in EpiList:\n\n'
                  '• You retain ownership of your lists and personal data\n'
                  '• You grant us a limited license to provide the service\n'
                  '• You are responsible for the accuracy of your information\n'
                  '• We claim no rights to your personal data\n'
                  '• You can export your data at any time\n\n'
                  'Your data belongs to you and remains under your control.',
            ),

            _buildTermSection(
              '7. Calculations and Prices',
              'Regarding calculation features:\n\n'
                  '• Totals and percentages are calculated automatically\n'
                  '• We do not guarantee absolute accuracy of calculations\n'
                  '• Prices entered are your responsibility\n'
                  '• Always verify calculations for your important purchases\n'
                  '• We are not responsible for price errors\n\n'
                  'Use calculations as an aid, not as an absolute reference.',
            ),

            _buildTermSection(
              '8. Service Availability',
              'We strive to ensure continuous service availability, '
                  'but we do not guarantee:\n\n'
                  '• Uninterrupted 24/7 access\n'
                  '• Complete absence of bugs or errors\n'
                  '• Compatibility with all devices\n'
                  '• Permanent backup of all data\n\n'
                  'Scheduled maintenance may cause temporary interruptions.',
            ),

            _buildTermSection(
              '9. Limitation of Liability',
              'EpiList and its developers cannot be held responsible for:\n\n'
                  '• Indirect or consequential damages\n'
                  '• Data loss due to technical problems\n'
                  '• Errors in price calculations or totals\n'
                  '• Incorrect use of provided information\n'
                  '• Problems related to list sharing\n'
                  '• Purchases made based on created lists\n\n'
                  'Your use of the application is at your own risk.',
            ),

            _buildTermSection(
              '10. Suspension and Termination',
              'We reserve the right to suspend or terminate your access:\n\n'
                  '• In case of violation of these terms of service\n'
                  '• For security or maintenance reasons\n'
                  '• If the account is inactive for more than 24 months\n'
                  '• In case of abusive use of sharing features\n\n'
                  'You can delete your account at any time from the application settings.',
            ),

            _buildTermSection(
              '11. Modifications',
              'We reserve the right to:\n\n'
                  '• Modify or improve the application\'s features\n'
                  '• Update these terms of service\n'
                  '• Temporarily suspend the service for maintenance\n'
                  '• Permanently discontinue the service with 60 days\' notice\n\n'
                  'Important changes will be notified to you by email or in the application.',
            ),

            _buildTermSection(
              '12. Applicable Law and Jurisdiction',
              'These terms of service are governed by Canadian law. '
                  'Any dispute relating to the use of EpiList will be subject to the jurisdiction '
                  'of the competent courts of New Brunswick, Canada.',
            ),

            _buildContactSection(
              context,
              '13. Contact and Support',
              'For any questions regarding these terms of service or for '
                  'assistance, please contact us through our website.\n\n'
                  'We are committed to responding as quickly as possible.',
            ),

            SizedBox(height: 32),
            Center(
              child: Text(
                '© 2025 EpiList - All rights reserved',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
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
  ) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
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
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final Uri url = Uri.parse('https://epilist.app/terms');
              try {
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  SmartSnackBarManager.showMessage(
                    context,
                    'Unable to open link. Visit https://epilist.app/terms',
                    type: SnackBarType.error,
                  );
                }
              } catch (e) {
                SmartSnackBarManager.showMessage(
                  context,
                  'Error opening link. Visit https://epilist.app/terms',
                  type: SnackBarType.error,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Contact us'),
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
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
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
}
