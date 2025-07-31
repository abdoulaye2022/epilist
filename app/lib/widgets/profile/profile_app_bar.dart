// widgets/profile/profile_app_bar.dart - VERSION CORRIGÉE AVEC STYLE UNIFORME
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';

class ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ProfileAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppBar(
      title: Text(
        l10n.myProfile,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      // ✅ FOND BLANC UNIFORME (comme les autres AppBars)
      backgroundColor: Colors.white,

      // ✅ SUPPRESSION DE L'OMBRE (comme HomeAppBar et ListDetailAppBar)
      elevation: 0,

      // ✅ COULEUR DES ICÔNES NOIRE POUR FOND BLANC
      iconTheme: const IconThemeData(color: Colors.black87),

      // ✅ COULEUR DU TEXTE DE L'APPBAR
      foregroundColor: Colors.black87,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
