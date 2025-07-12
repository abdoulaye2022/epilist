// widgets/profile/profile_loading_state.dart - VERSION I18N
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';

class ProfileLoadingState extends StatelessWidget {
  const ProfileLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.green),
            const SizedBox(height: 16),
            Text(l10n.loadingProfile),
          ],
        ),
      ),
    );
  }
}
