// widgets/profile/profile_error_state.dart - VERSION I18N
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/connectivity/connectivity_wrapper.dart';

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
    final isConnected = context.isConnected;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(l10n.myProfile),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isConnected ? Icons.person_off : Icons.wifi_off,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                isConnected
                    ? l10n.cannotLoadProfile
                    : l10n.offlineMode ?? 'Mode hors ligne',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (!isConnected)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Connectez-vous à Internet pour charger votre profil',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
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
      ),
    );
  }
}
