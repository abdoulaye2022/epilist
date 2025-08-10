// widgets/profile/profile_action_tile.dart - VERSION CORRIGÉE AVEC NOUVELLES FONCTIONNALITÉS

import 'package:flutter/material.dart';

class ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle; // ✅ NOUVEAU: pour le sous-titre
  final VoidCallback onTap;
  final Color? iconColor; // ✅ NOUVEAU: couleur de l'icône
  final Color? iconBackgroundColor; // ✅ NOUVEAU: couleur de fond de l'icône

  const ProfileActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle, // ✅ NOUVEAU
    required this.onTap,
    this.iconColor, // ✅ NOUVEAU
    this.iconBackgroundColor, // ✅ NOUVEAU
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        8,
      ), // Ajout pour un meilleur effet visuel
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // ✅ AMÉLIORATION: Conteneur avec couleur de fond personnalisable
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBackgroundColor ?? Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor ?? Colors.green[600],
                size: 22,
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500, // Légèrement plus bold
                    ),
                  ),
                  // ✅ NOUVEAU: Affichage conditionnel du sous-titre
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
