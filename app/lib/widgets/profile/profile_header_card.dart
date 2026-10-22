// widgets/profile/profile_header_card.dart - VERSION I18N
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/models/user.dart';
import 'package:epilist/widgets/profile/editable_avatar.dart';
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
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
    // Avatar reel, modifiable (upload securise vers GCS via l'API)
    return EditableAvatar(user: user, radius: 40);
  }

  Widget _buildUserInfo() {
    return Column(
      children: [
        Text(
          user.fullName,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildEmailVerificationBadge(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color:
            user.isEmailVerified
                ? AppColors.primaryLight
                : AppColors.warningTint,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color:
              user.isEmailVerified
                  ? AppColors.successBorder
                  : AppColors.warningBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            user.isEmailVerified ? Icons.verified : Icons.warning,
            size: 16,
            color: user.isEmailVerified ? AppColors.primary : AppColors.warning,
          ),
          const SizedBox(width: 4),
          Text(
            user.isEmailVerified
                ? l10n.emailVerified
                : l10n.emailNotVerifiedStatus,
            style: TextStyle(
              fontSize: 16,
              color:
                  user.isEmailVerified ? AppColors.primary : AppColors.warning,
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
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
    );
  }
}
