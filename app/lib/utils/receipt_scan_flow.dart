// utils/receipt_scan_flow.dart - Flux « Scanner un reçu » : choix de la
// photo, OCR local (ML Kit), parsing, puis écran de validation. En cas
// d'échec OCR, on n'abandonne pas : l'écran de validation s'ouvre vide
// pour une saisie manuelle.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/models/parsed_receipt.dart';
import 'package:epilist/models/store.dart';
import 'package:epilist/screens/receipt_validation_screen.dart';
import 'package:epilist/services/receipt_ocr_service.dart';
import 'package:epilist/services/receipt_parser_service.dart';
import 'package:epilist/services/store_service.dart';
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

/// Lance le scan d'un reçu pour la liste [listId].
/// Retourne true si un reçu a été enregistré.
Future<bool> startReceiptScan(BuildContext context, {required int listId}) async {
  final l10n = AppLocalizations.of(context)!;

  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.receiptFromCamera),
            onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.receiptFromGallery),
            onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    ),
  );
  if (source == null || !context.mounted) return false;

  final picked = await ImagePicker().pickImage(
    source: source,
    // 2800/q95 : le modèle ML Kit embarqué sur iOS est moins tolérant au
    // petit texte que celui de Play Services sur Android — une entrée plus
    // fine comble l'écart sur les reçus longs, sans exploser la mémoire.
    maxWidth: 2800,
    imageQuality: 95,
  );
  if (picked == null || !context.mounted) return false;

  // OCR + parsing sous un voile de chargement
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.readingReceipt),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  List<Store> stores = const [];
  ParsedReceipt parsed;
  final ocr = MlKitReceiptOcrService();
  try {
    try {
      stores = await context.read<StoreService>().getStores();
    } catch (_) {
      // Hors ligne sans cache : la détection du magasin sera heuristique.
    }
    final lines = await ocr.extractLines(picked.path);
    parsed = ReceiptParserService().parse(
      lines,
      knownStoreNames: stores.map((s) => s.name).toList(),
    );
  } catch (e) {
    // Trace indispensable au diagnostic (ex. échec spécifique iOS) :
    // sans elle, tout échec OCR est muet.
    debugPrint('❌ [ReceiptScan] OCR/parsing échoué: $e');
    parsed = ParsedReceipt(); // OCR raté : validation vide, saisie manuelle
    if (context.mounted) {
      SmartSnackBarManager.showErrorSnackBar(context, l10n.ocrFailed);
    }
  } finally {
    ocr.dispose();
    if (context.mounted) Navigator.of(context).pop(); // ferme le voile
  }
  if (!context.mounted) return false;

  final saved = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => ReceiptValidationScreen(
        listId: listId,
        receipt: parsed,
        knownStores: stores,
      ),
    ),
  );
  return saved == true;
}
