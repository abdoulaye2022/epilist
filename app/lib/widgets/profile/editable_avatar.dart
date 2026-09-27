// widgets/profile/editable_avatar.dart
// Avatar du profil, modifiable : appui -> feuille (appareil photo, galerie,
// supprimer) -> compression locale -> upload API (assainissement + GCS).
import 'dart:io';

import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/user.dart';
import 'package:epilist/services/image_upload_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/widgets/common/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class EditableAvatar extends StatefulWidget {
  final User user;
  final double radius;

  const EditableAvatar({super.key, required this.user, this.radius = 40});

  @override
  State<EditableAvatar> createState() => _EditableAvatarState();
}

class _EditableAvatarState extends State<EditableAvatar> {
  String? _localUrl; // URL fraîche après upload, avant refresh du bloc
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _busy ? null : () => _showOptions(context),
      child: Stack(
        children: [
          UserAvatar(
            user: widget.user,
            overrideUrl: _localUrl,
            radius: widget.radius,
          ),
          if (_busy)
            Positioned.fill(
              child: CircleAvatar(
                backgroundColor: Colors.black38,
                child: const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                child: const Icon(
                  Icons.photo_camera,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasAvatar =
        (_localUrl ?? widget.user.avatarUrl)?.isNotEmpty == true;

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.takePhoto),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAndUpload(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.chooseFromGallery),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAndUpload(ImageSource.gallery);
              },
            ),
            if (hasAvatar)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppColors.error),
                title: Text(
                  l10n.removePhoto,
                  style: const TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _removeAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      setState(() => _busy = true);
      final url = await context
          .read<ImageUploadService>()
          .uploadAvatar(File(picked.path));
      if (!mounted) return;
      setState(() {
        _localUrl = url;
        _busy = false;
      });
      // Rafraîchir l'utilisateur du bloc (avatar_url inclus dans /auth/me)
      context.read<AuthBloc>().add(GetCurrentUser());
      SmartSnackBarManager.showSuccessSnackBar(context, l10n.photoUpdated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      SmartSnackBarManager.showErrorSnackBar(context, l10n.photoUploadFailed);
    }
  }

  Future<void> _removeAvatar() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      setState(() => _busy = true);
      await context.read<ImageUploadService>().deleteAvatar();
      if (!mounted) return;
      setState(() {
        _localUrl = '';
        _busy = false;
      });
      context.read<AuthBloc>().add(GetCurrentUser());
      SmartSnackBarManager.showSuccessSnackBar(context, l10n.photoRemoved);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      SmartSnackBarManager.showErrorSnackBar(context, l10n.photoUploadFailed);
    }
  }
}
