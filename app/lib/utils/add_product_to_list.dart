// utils/add_product_to_list.dart - « Ajouter à ma liste », d'un seul geste.
//
// La planche pose ce bouton partout où un produit est NOMMÉ sans être
// dans une liste : un stock bas à la maison, une baisse de prix repérée,
// un ingrédient d'un repas de la semaine. Jusqu'ici, il fallait retenir
// le nom du produit, ouvrir une liste, ouvrir le formulaire d'ajout et
// le retaper.
import 'package:epilist/l10n/app_localizations.dart';
import 'package:epilist/services/list_item_service.dart';
import 'package:epilist/utils/list_picker.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Demande dans quelle liste, ajoute le produit, et le CONFIRME par
/// écrit — en nommant le produit et la liste, parce qu'un « ajouté ! »
/// seul laisse un doute sur ce qui est parti où.
///
/// Rend `true` si le produit est maintenant dans la liste (déjà présent
/// compris).
Future<bool> addProductToList(BuildContext context, String productName) async {
  final l10n = AppLocalizations.of(context)!;
  final list = await pickShoppingList(context, where: (l) => l.canEdit);
  if (list == null || !context.mounted) return false;

  final service = context.read<ListItemService>();
  try {
    final result = await service.addListItem(
      listId: list.id,
      productName: productName,
    );
    if (!context.mounted) return result.isSuccess;

    if (result.isSuccess) {
      SmartSnackBarManager.showSuccessSnackBar(
        context,
        l10n.productAddedToList(productName, list.name),
      );
      return true;
    }
    if (result.isDuplicateDetected) {
      SmartSnackBarManager.showInfoSnackBar(
        context,
        l10n.alreadyInList(productName, list.name),
      );
      return true;
    }
    SmartSnackBarManager.showErrorSnackBar(
      context,
      result.message ?? l10n.anErrorOccurred,
    );
    return false;
  } catch (_) {
    if (context.mounted) {
      SmartSnackBarManager.showErrorSnackBar(context, l10n.anErrorOccurred);
    }
    return false;
  }
}
