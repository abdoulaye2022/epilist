import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onRefresh;
  final VoidCallback onViewAllLists;
  final VoidCallback onProfile;
  final VoidCallback onLogout;

  const HomeAppBar({
    super.key,
    required this.onRefresh,
    required this.onViewAllLists,
    required this.onProfile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: Text(
        l10n.welcome,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          onPressed: onRefresh,
          icon: Icon(Icons.refresh, color: Colors.grey[700]),
          tooltip: l10n.refresh,
        ),
        IconButton(
          onPressed: onViewAllLists,
          icon: Icon(Icons.list, color: Colors.grey[700]),
          tooltip: l10n.allLists,
        ),
        IconButton(
          onPressed: onProfile,
          icon: Icon(Icons.person, color: Colors.grey[700]),
          tooltip: l10n.profile,
        ),
        IconButton(
          onPressed: onLogout,
          icon: Icon(Icons.logout, color: Colors.red[600]),
          tooltip: l10n.logout,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
