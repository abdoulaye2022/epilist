// widgets/suggestion/suggestion_error_state.dart
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';

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
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
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
          colors: [Colors.red[100]!, Colors.red[200]!],
        ),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Icon(Icons.error_outline, size: 40, color: Colors.red[600]),
    );
  }

  Widget _buildTitle(AppLocalizations l10n) {
    return Text(
      l10n.errorLoadingSuggestions,
      style: TextStyle(
        color: Colors.red[700],
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessage() {
    return Text(
      message,
      style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.4),
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
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    );
  }
}
