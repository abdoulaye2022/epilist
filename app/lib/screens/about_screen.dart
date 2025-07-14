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
        title: Text('About'),
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
                    'Organize your groceries',
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
              'Our Mission',
              'EpiList revolutionizes how you manage your grocery shopping. '
                  'Create smart lists, track your expenses in real-time, '
                  'share with your family and never miss an important item again '
                  'thanks to our collaborative management system.',
            ),

            _buildSection(
              'Main Features',
              '• Secure account creation (first name, last name, email)\n'
                  '• Personalized and smart grocery lists\n'
                  '• Add items with quantity, price and store\n'
                  '• Automatic calculation of totals and percentages\n'
                  '• Real-time marking of purchased items\n'
                  '• Quick duplication of existing lists\n'
                  '• Secure sharing via links with permissions\n'
                  '• Rights management (read, edit, administration)\n'
                  '• Synchronization across all your devices\n'
                  '• Modern and intuitive interface',
            ),

            _buildSection(
              'Family Collaboration',
              'EpiList makes family shopping easy with its advanced sharing system. '
                  'Share your lists with a simple link, define who can view, edit '
                  'or administer each list. Everyone stays synchronized in real-time!',
            ),

            _buildSection(
              'Development',
              'EpiList is passionately developed by M2atech Solutions Inc. to provide you with the best '
                  'grocery management experience. We are constantly listening to your feedback to improve the app and add '
                  'new innovative features.',
            ),

            SizedBox(height: 24),

            // Action buttons
            Column(
              children: [
                _buildActionButton(
                  'Contact us',
                  Icons.email,
                  () => _launchContactPage(context),
                  Colors.blue,
                ),
                SizedBox(height: 12),
                _buildActionButton(
                  'Rate the app',
                  Icons.star,
                  () => _rateApp(context),
                  Colors.orange,
                ),
                SizedBox(height: 12),
                _buildActionButton(
                  'Share EpiList',
                  Icons.share,
                  () => _shareApp(context),
                  Colors.green,
                ),
                SizedBox(height: 12),
                _buildActionButton(
                  'Website',
                  Icons.language,
                  () => _launchWebsite(context),
                  Colors.purple,
                ),
              ],
            ),

            SizedBox(height: 32),

            // Copyright
            Text(
              '© 2025 EpiList. All rights reserved.',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Developed with ❤️ by M2atech Solutions Inc.',
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

  void _launchContactPage(BuildContext context) async {
    final Uri contactUrl = Uri.parse('https://epilist.app/contact');

    try {
      if (await canLaunchUrl(contactUrl)) {
        await launchUrl(contactUrl, mode: LaunchMode.externalApplication);
      } else {
        SmartSnackBarManager.showMessage(
          context,
          'Unable to open link. Visit https://epilist.app/contact',
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      SmartSnackBarManager.showMessage(
        context,
        'Error opening contact link',
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
          'Unable to open website. Visit https://epilist.app',
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      SmartSnackBarManager.showMessage(
        context,
        'Error opening website',
        type: SnackBarType.error,
      );
    }
  }

  void _rateApp(BuildContext context) async {
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
          'Store unavailable. Please rate EpiList on your usual store!',
          type: SnackBarType.info,
        );
      }
    } catch (e) {
      SmartSnackBarManager.showMessage(
        context,
        'Unable to open store at the moment',
        type: SnackBarType.warning,
      );
    }
  }

  void _shareApp(BuildContext context) async {
    const String appName = 'EpiList';
    const String appDescription =
        'Organize your grocery shopping with family using EpiList! '
        'Shared lists, automatic calculations, real-time synchronization.';
    const String websiteLink = 'https://epilist.app';

    const String shareText =
        '$appName 🛒\n\n'
        '$appDescription\n\n'
        'Discover the app:\n'
        '$websiteLink\n\n'
        '#EpiList #Groceries #Organization #Family';

    try {
      await Share.share(
        shareText,
        subject: 'Discover EpiList - Your family grocery assistant!',
      );
    } catch (e) {
      SmartSnackBarManager.showMessage(
        context,
        'Unable to share at the moment',
        type: SnackBarType.error,
      );
    }
  }
}
