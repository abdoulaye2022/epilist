// widgets/suggestion/suggestion_error_state.dart
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/widgets/common/app_card.dart';

class SuggestionErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const SuggestionErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: AppCard(
            radius: 20,
            bordered: false,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIcon(),
                const SizedBox(height: 24),
                _buildTitle(l10n),
                const SizedBox(height: 12),
                _buildMessage(),
                const SizedBox(height: 24),
                _buildRetryButton(l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.errorTint, AppColors.errorBorder],
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Icon(Icons.error_outline, size: 40, color: AppColors.error),
    );
  }

  Widget _buildTitle(AppLocalizations l10n) {
    return Text(
      l10n.errorLoadingSuggestions,
      style: TextStyle(
        color: AppColors.error,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage() {
    return Text(
      message,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 16,
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildRetryButton(AppLocalizations l10n) {
    return ElevatedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh, size: 18),
      label: Text(
        l10n.retry,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        elevation: 2,
      ),
    );
  }
}
