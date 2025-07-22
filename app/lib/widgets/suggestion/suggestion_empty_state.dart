// widgets/suggestion/suggestion_empty_state.dart
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';

class SuggestionEmptyState extends StatelessWidget {
  const SuggestionEmptyState({super.key});

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
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.grey[50]!, Colors.grey[100]!],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIcon(),
                const SizedBox(height: 24),
                _buildTitle(l10n),
                const SizedBox(height: 12),
                _buildDescription(l10n),
                const SizedBox(height: 24),
                _buildInfoCard(l10n),
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
          colors: [Colors.grey[200]!, Colors.grey[300]!],
        ),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Icon(Icons.lightbulb_outline, size: 40, color: Colors.grey[600]),
    );
  }

  Widget _buildTitle(AppLocalizations l10n) {
    return Text(
      l10n.noSuggestionsYet,
      style: TextStyle(
        color: Colors.grey[700],
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription(AppLocalizations l10n) {
    return Text(
      l10n.suggestionHelper,
      style: TextStyle(color: Colors.grey[600], fontSize: 16, height: 1.4),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildInfoCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[50]!, Colors.indigo[50]!],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[600], size: 24),
          const SizedBox(height: 8),
          Text(
            l10n.basedOnHistory,
            style: TextStyle(
              color: Colors.blue[700],
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.startTypingForSuggestions,
            style: TextStyle(color: Colors.blue[600], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
