import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/smart_snackbar_manager.dart';

class PrivacyPolicyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Privacy Policy'),
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
              'Privacy Policy',
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

            _buildPolicySection(
              '1. Information Collection',
              'EpiList collects the following information for its operation:\n\n'
                  '• Account information: first name, last name, email, password (encrypted)\n'
                  '• Grocery list data: list names, items, quantities, prices, stores (optional)\n'
                  '• Sharing data: sharing links, access permissions (read, edit, administration)\n'
                  '• Usage data: item purchase status, totals and percentage calculations\n'
                  '• Technical data: error logs, application performance\n\n'
                  'We do not collect any sensitive personal information beyond what is necessary for operation.',
            ),

            _buildPolicySection(
              '2. Data Usage',
              'Your data is used exclusively to:\n\n'
                  '• Create and manage your user account\n'
                  '• Create, edit and delete your grocery lists\n'
                  '• Calculate totals and percentages of purchased items\n'
                  '• Duplicate your existing lists\n'
                  '• Share your lists with family members or friends via secure links\n'
                  '• Manage access permissions (read, edit, administration)\n'
                  '• Synchronize your data across your devices\n'
                  '• Provide technical support\n\n'
                  'We do not sell or rent your personal data to third parties.',
            ),

            _buildPolicySection(
              '3. Storage and Security',
              'Your data is protected by:\n\n'
                  '• Secure storage on our servers with encryption\n'
                  '• Password encryption with secure algorithms\n'
                  '• Data protection during transit and at rest\n'
                  '• Secure sharing links with access control\n'
                  '• Regular backup of your lists and data\n'
                  '• Security measures compliant with industry standards\n\n'
                  'We apply security best practices to protect your information.',
            ),

            _buildPolicySection(
              '4. Data Sharing',
              'Your personal data is only shared in the following cases:\n\n'
                  '• With people you authorize via list sharing links\n'
                  '• With our technical service providers (hosting, support)\n'
                  '• With legal authorities if required by law\n\n'
                  'List sharing is done according to the permissions you define:\n'
                  '• Read-only: viewing lists without modification\n'
                  '• Edit: adding, deleting and modifying items\n'
                  '• Administration: complete management including list deletion\n\n'
                  'No commercial sharing of your data is performed.',
            ),

            _buildPolicySection(
              '5. Your Rights',
              'You have the right to:\n\n'
                  '• Access all your personal data\n'
                  '• Modify your account information (first name, last name, email)\n'
                  '• Delete your account and all associated data\n'
                  '• Export your grocery lists\n'
                  '• Revoke sharing links at any time\n'
                  '• Modify access permissions for invited users\n'
                  '• Delete your lists or items individually\n\n'
                  'Contact us to exercise these rights.',
            ),

            _buildPolicySection(
              '6. Application Features',
              'EpiList processes your data to offer the following features:\n\n'
                  '• Creation and management of user accounts\n'
                  '• Creation, duplication, modification and deletion of lists\n'
                  '• Adding items with name, quantity, price and store (optional)\n'
                  '• Marking items as purchased or deleting items\n'
                  '• Automatic calculation of totals and purchase percentages\n'
                  '• Generation of secure sharing links\n'
                  '• Management of collaborative access permissions\n\n'
                  'All this data remains under your control.',
            ),

            _buildPolicySection(
              '7. Cookies and Similar Technologies',
              'EpiList uses tracking technologies to:\n\n'
                  '• Maintain your active session\n'
                  '• Remember your usage preferences\n'
                  '• Analyze application usage (anonymous data)\n'
                  '• Optimize application performance\n\n'
                  'You can disable these functions in the application settings.',
            ),

            _buildPolicySection(
              '8. Changes',
              'This policy may be updated to reflect application developments. '
                  'We will inform you of important changes by:\n\n'
                  '• Email to the address associated with your account\n'
                  '• Updating the date at the top of this policy\n\n'
                  'Your continued use of the application after changes constitutes your acceptance.',
            ),

            _buildContactSection(
              context,
              '9. Contact',
              'For any questions regarding this privacy policy or your data, '
                  'please contact us through our website.\n\n'
                  'We are committed to responding within 48 business hours.',
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
              final Uri url = Uri.parse('https://epilist.app/contact');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                // Fallback if URL cannot be opened
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Unable to open link. Visit https://epilist.app/contact',
                    ),
                  ),
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

  Widget _buildPolicySection(String title, String content) {
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
