// widgets/receipts/receipt_photo.dart — la photo d'un reçu, qui va
// chercher son URL avant de s'afficher.
//
// Avant, l'image avait une URL publique et permanente : un `Image.network`
// suffisait. Elle n'en a plus. Le serveur délivre une URL signée de
// quinze minutes, et seulement à qui a le droit de voir la liste.
//
// Ce widget fait donc deux choses qu'un `Image.network` ne fait pas :
// il demande l'URL avant de charger, et il en redemande UNE fois si le
// chargement échoue — entre le moment où l'URL a été obtenue et celui
// où l'image se charge, le quart d'heure a pu s'écouler (application
// laissée ouverte, téléphone en veille, réseau revenu plus tard).
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/services/receipt_image_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReceiptPhoto extends StatefulWidget {
  const ReceiptPhoto({
    super.key,
    required this.listId,
    required this.receiptId,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final int listId;
  final int receiptId;

  /// `double.infinity` pour l'aperçu plein écran.
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  State<ReceiptPhoto> createState() => _ReceiptPhotoState();
}

class _ReceiptPhotoState extends State<ReceiptPhoto> {
  Future<String?>? _url;

  /// Une seule reprise. Si la deuxième URL ne charge pas non plus, le
  /// problème n'est pas l'expiration, et insister ferait tourner le
  /// widget en boucle sur le réseau.
  bool _dejaReessaye = false;

  @override
  void initState() {
    super.initState();
    _demander();
  }

  void _demander({bool forcer = false}) {
    _url = context.read<ReceiptImageService>().urlPour(
      widget.listId,
      widget.receiptId,
      forcer: forcer,
    );
  }

  void _reessayer() {
    if (_dejaReessaye || !mounted) return;
    setState(() {
      _dejaReessaye = true;
      _demander(forcer: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final contenu = FutureBuilder<String?>(
      future: _url,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _cadre(
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final url = snapshot.data;
        if (url == null) {
          return _indisponible(l10n.receiptPhotoUnavailable);
        }

        return Image.network(
          url,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: (context, error, stack) {
            // L'URL a probablement expiré pendant que l'écran dormait.
            WidgetsBinding.instance.addPostFrameCallback((_) => _reessayer());
            return _indisponible(l10n.receiptPhotoUnavailable);
          },
        );
      },
    );

    if (widget.borderRadius == null) return contenu;
    return ClipRRect(borderRadius: widget.borderRadius!, child: contenu);
  }

  Widget _cadre({required Widget child}) => SizedBox(
    width: widget.width,
    height: widget.height,
    child: ColoredBox(color: AppColors.background, child: child),
  );

  /// Pas d'icône seule : l'écran dit en toutes lettres ce qui se passe.
  Widget _indisponible(String message) => _cadre(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 20,
              color: AppColors.textDisabled,
            ),
            if (widget.height.isInfinite || widget.height > 80) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
