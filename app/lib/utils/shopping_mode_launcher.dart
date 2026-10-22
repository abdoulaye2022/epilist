// utils/shopping_mode_launcher.dart - Ouvrir le mode courses, d'où que
// l'on vienne.
//
// Le mode courses a besoin d'un `ListItemBloc` et des catégories (sans
// elles, tous les articles tombent dans « Sans rayon »). Ce montage
// vivait en privé dans l'écran « Plus » : c'est pour cela que le mode
// courses ne s'ouvrait que de là, ou depuis l'écran de détail d'une
// liste. « Avant les courses » se termine maintenant par « Je suis
// prêt, ouvrir ma liste », et a besoin du même montage.
import 'package:epilist/blocs/category/category_bloc.dart';
import 'package:epilist/blocs/list_item/list_item_bloc.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart';
import 'package:epilist/screens/shopping_mode_screen.dart';
import 'package:epilist/services/list_item_service.dart';
import 'package:epilist/utils/list_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Demande quelle liste, puis ouvre le mode courses dessus.
///
/// Ne fait rien si l'utilisateur ferme le sélecteur sans choisir.
Future<void> openShoppingMode(BuildContext context) async {
  final list = await pickShoppingList(context);
  if (!context.mounted || list == null) return;

  final itemService = context.read<ListItemService>();
  final localization = context.read<LocalizationBloc>();
  context.read<CategoryBloc>().add(const LoadCategories());

  if (!context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => BlocProvider<ListItemBloc>(
        create: (_) => ListItemBloc(
          listItemService: itemService,
          localizationBloc: localization,
        )..add(LoadListItems(list.id)),
        child: ShoppingModeScreen(shoppingList: list),
      ),
    ),
  );
}
