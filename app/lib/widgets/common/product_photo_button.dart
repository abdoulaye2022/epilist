// widgets/common/product_photo_button.dart - La photo d'un article,
// VISIBLE sur sa ligne.
//
// La photo existait depuis longtemps, mais rien ne l'annonçait : il
// fallait déplier le menu ⋮ pour apprendre qu'elle existait, et l'audit
// comptait six appuis pour l'ajouter. Le menu est passé à trois appuis ;
// restait le vrai défaut, que ce widget corrige — rien, à l'écran, ne
// disait qu'un article pouvait porter une photo.
//
// Deux états, deux gestes :
//   photo absente et liste modifiable → un cadre pointillé « ajouter »,
//     l'appui demande la source ;
//   photo présente → la vignette elle-même, l'appui l'ouvre en grand
//     (et propose de la remplacer si la liste est modifiable).
//
// Photo absente ET liste en lecture seule : rien du tout. Une invitation
// à faire ce qu'on n'a pas le droit de faire ne vaut rien.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/list_item.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/utils/product_photo_flow.dart';
import 'package:flutter/material.dart';

class ProductPhotoButton extends StatelessWidget {
  const ProductPhotoButton({
    super.key,
    required this.item,
    required this.canEdit,
    this.size = 40,
    this.onChanged,
  });

  final ListItem item;
  final bool canEdit;
  final double size;

  /// Appelé après un envoi réussi. Sans lui, la vignette n'apparaîtrait
  /// qu'au prochain chargement de la liste : l'utilisateur prend une
  /// photo et ne voit rien changer.
  final VoidCallback? onChanged;

  bool get _hasPhoto => item.imageUrl?.isNotEmpty == true;

  @override
  Widget build(BuildContext context) {
    if (!_hasPhoto && !canEdit) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    return Tooltip(
      message: _hasPhoto ? l10n.productPhoto : l10n.addPhoto,
      child: Semantics(
        button: true,
        label: _hasPhoto ? l10n.productPhoto : l10n.addPhoto,
        child: InkWell(
          onTap: () async {
            if (_hasPhoto) {
              await showProductPhoto(
                context,
                item,
                canEdit: canEdit,
                onChanged: onChanged,
              );
              return;
            }
            if (await uploadPhotoForItem(context, item)) onChanged?.call();
          },
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: SizedBox(
            width: size,
            height: size,
            child: _hasPhoto ? _thumbnail() : _placeholder(),
          ),
        ),
      ),
    );
  }

  Widget _thumbnail() => ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.sm),
    child: CachedNetworkImage(
      imageUrl: item.imageUrl!,
      fit: BoxFit.cover,
      placeholder: (_, _) => ColoredBox(color: AppColors.surfaceAlt),
      errorWidget: (_, _, _) => DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(
          Icons.broken_image_outlined,
          size: size * 0.5,
          color: AppColors.textSecondary,
        ),
      ),
    ),
  );

  Widget _placeholder() => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      border: Border.all(color: AppColors.border),
    ),
    child: Icon(
      Icons.add_a_photo_outlined,
      size: size * 0.5,
      color: AppColors.textSecondary,
    ),
  );
}

/// Ouvre la photo en grand. Le fond est [AppColors.backdrop] — noir dans
/// les deux modes, parce que ce qu'il entoure est une image et non une
/// surface de l'application.
Future<void> showProductPhoto(
  BuildContext context,
  ListItem item, {
  bool canEdit = false,
  VoidCallback? onChanged,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog.fullscreen(
      backgroundColor: AppColors.backdrop,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: item.imageUrl!,
                fit: BoxFit.contain,
                errorWidget: (_, _, _) => Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 64,
                    color: AppColors.onOverlay,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: Icon(Icons.close, color: AppColors.onOverlay),
                tooltip: l10n.close,
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ),
          if (canEdit)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.onOverlay,
                      backgroundColor: AppColors.scrim,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm + 2,
                      ),
                    ),
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: Text(l10n.replacePhoto),
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      if (!context.mounted) return;
                      if (await uploadPhotoForItem(context, item)) {
                        onChanged?.call();
                      }
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
