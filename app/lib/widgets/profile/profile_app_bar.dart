// widgets/profile/profile_app_bar.dart
import 'package:flutter/material.dart';

class ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ProfileAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        'Mon Profil',
        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
      ),
      backgroundColor: Colors.white,
      elevation: 1,
      foregroundColor: Colors.black87,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
