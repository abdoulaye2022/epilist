// utils/product_photo_flow.dart - « Photo d'un produit », accessible
// d'où que l'on soit.
//
// La photo d'un article n'existait QUE dans EditItemDialog : liste →
// article → ⋮ → Modifier → zone photo → source, six appuis, et rien à
// l'écran n'indiquait qu'elle existait. Ce flux la rend atteignable
// depuis le bouton + : liste (sautée s'il n'y en a qu'une) → article →
// source.
import 'dart:io';

import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/list_item.dart';
import 'package:epilist/services/image_upload_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/utils/list_picker.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

/// Choisit une liste, un article, une source, puis envoie la photo.
/// Retourne true si une photo a bien été enregistrée.
Future<bool> startProductPhoto(BuildContext context) async {
  final list = await pickShoppingList(context, where: (l) => l.canEdit);
  if (list == null || !context.mounted) return false;

  final item = await pickListItem(
    context,
    listId: list.id,
    title: AppLocalizations.of(context)!.pickItemTitle,
  );
  if (item == null || !context.mounted) return false;

  return uploadPhotoForItem(context, item);
}

/// Demande la source puis envoie la photo de [item]. Extrait ici pour
/// que le menu d'un article (dans la liste) puisse l'appeler directement
/// — trois appuis au lieu de six.
Future<bool> uploadPhotoForItem(BuildContext context, ListItem item) async {
  final l10n = AppLocalizations.of(context)!;

  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.takePhoto),
            onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.chooseFromGallery),
            onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    ),
  );
  if (source == null || !context.mounted) return false;

  final uploader = context.read<ImageUploadService>();
  final picked = await ImagePicker().pickImage(
    source: source,
    maxWidth: 1600,
    imageQuality: 85,
  );
  if (picked == null || !context.mounted) return false;

  // Voile de chargement : l'envoi passe par le réseau, et sans retour
  // visible l'utilisateur appuie une seconde fois.
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );

  try {
    await uploader.uploadItemImage(item.listId, item.id, File(picked.path));
    if (!context.mounted) return true;
    Navigator.of(context).pop();
    SmartSnackBarManager.showSuccessSnackBar(context, l10n.photoUpdated);
    return true;
  } catch (_) {
    if (!context.mounted) return false;
    Navigator.of(context).pop();
    SmartSnackBarManager.showErrorSnackBar(context, l10n.photoUploadFailed);
    return false;
  }
}
