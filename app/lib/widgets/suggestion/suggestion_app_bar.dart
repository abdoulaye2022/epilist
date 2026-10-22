// widgets/suggestion/suggestion_app_bar.dart - VERSION I18N
import 'package:epilist/widgets/common/app_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';

class SuggestionAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onClearAll;

  const SuggestionAppBar({super.key, required this.onClearAll});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppTopBar(
      title: l10n.manageSuggestions,
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
