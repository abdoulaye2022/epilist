// widgets/suggestion/suggestion_app_bar.dart - VERSION I18N
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';

class SuggestionAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onClearAll;

  const SuggestionAppBar({super.key, required this.onClearAll});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppBar(
      title: Text(
        l10n.manageSuggestions,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 1,
      foregroundColor: Colors.black87,
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_sweep),
          onPressed: onClearAll,
          tooltip: l10n.clearAllSuggestions,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
