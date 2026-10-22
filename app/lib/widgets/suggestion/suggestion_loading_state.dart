// widgets/suggestion/suggestion_loading_state.dart
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/common/app_card.dart';

class SuggestionLoadingState extends StatelessWidget {
  const SuggestionLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Card(
        margin: const EdgeInsets.all(32),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        child: AppCard(
          radius: 20,
          bordered: false,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.infoTint, AppColors.infoBorder],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.info),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.searchingSuggestions,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
