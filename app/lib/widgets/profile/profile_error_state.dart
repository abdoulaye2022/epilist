// widgets/profile/profile_error_state.dart - VERSION I18N
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';

class ProfileErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onLogout;

  const ProfileErrorState({
    super.key,
    required this.onRetry,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(l10n.myProfile),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.cannotLoadProfile,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onLogout, child: Text(l10n.logoutButton)),
          ],
        ),
      ),
    );
  }
}
