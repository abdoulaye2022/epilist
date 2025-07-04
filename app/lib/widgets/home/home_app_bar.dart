// widgets/home/home_app_bar.dart
import 'package:flutter/material.dart';

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
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: Text(
        'Bienvenue',
        style: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        // Bouton refresh
        IconButton(
          onPressed: onRefresh,
          icon: Icon(Icons.refresh, color: Colors.grey[700]),
          tooltip: 'Actualiser',
        ),
        // Bouton Voir toutes les listes
        IconButton(
          onPressed: onViewAllLists,
          icon: Icon(Icons.list, color: Colors.grey[700]),
          tooltip: 'Toutes les listes',
        ),
        // Bouton Profile
        IconButton(
          onPressed: onProfile,
          icon: Icon(Icons.person, color: Colors.grey[700]),
          tooltip: 'Profil',
        ),
        // Bouton Déconnexion
        IconButton(
          onPressed: onLogout,
          icon: Icon(Icons.logout, color: Colors.red[600]),
          tooltip: 'Déconnexion',
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
