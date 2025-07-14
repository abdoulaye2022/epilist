// widgets/profile/profile_header_card.dart - VERSION I18N
import 'package:epilist/models/user.dart';
import 'package:flutter/material.dart';
import 'package:epilist/l10n/app_localizations.dart';

class ProfileHeaderCard extends StatelessWidget {
  final User user;
  final VoidCallback onEditProfile;

  const ProfileHeaderCard({
    super.key,
    required this.user,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAvatar(),
          const SizedBox(height: 16),
          _buildUserInfo(),
          const SizedBox(height: 8),
          _buildEmailVerificationBadge(l10n),
          const SizedBox(height: 16),
          _buildEditButton(l10n),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 40,
      backgroundColor: Colors.green[100],
      child: Text(
        user.initials,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.green[600],
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      children: [
        Text(
          user.fullName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildEmailVerificationBadge(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: user.isEmailVerified ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              user.isEmailVerified ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            user.isEmailVerified ? Icons.verified : Icons.warning,
            size: 16,
            color:
                user.isEmailVerified ? Colors.green[600] : Colors.orange[600],
          ),
          const SizedBox(width: 4),
          Text(
            user.isEmailVerified
                ? l10n.emailVerified
                : l10n.emailNotVerifiedStatus,
            style: TextStyle(
              fontSize: 12,
              color:
                  user.isEmailVerified ? Colors.green[600] : Colors.orange[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton(AppLocalizations l10n) {
    return ElevatedButton.icon(
      onPressed: onEditProfile,
      icon: const Icon(Icons.edit, size: 18),
      label: Text(l10n.editProfile),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
