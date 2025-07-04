// widgets/home/shopping_lists_content.dart
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/widgets/home/empty_state_widget.dart';
import 'package:epilist/widgets/home/error_state_widget.dart';
import 'package:epilist/widgets/home/shopping_list_card.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart'; // Import du gestionnaire intelligent
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShoppingListsContent extends StatelessWidget {
  final VoidCallback onCreateNew;
  final Function(ShoppingList) onListTap;
  final Function(String action, ShoppingList list) onListAction;
  final int? maxDisplayLists;

  const ShoppingListsContent({
    super.key,
    required this.onCreateNew,
    required this.onListTap,
    required this.onListAction,
    this.maxDisplayLists,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ShoppingListBloc, ShoppingListState>(
      listener: (context, state) {
        // ✨ MAGIE ! Une seule ligne pour gérer tous les types d'états
        SmartSnackBarManager.showForState(context, state);

        // Alternative si vous voulez personnaliser certains états :
        /*
        if (state is ShoppingListError) {
          SmartSnackBarManager.showForState(
            context, 
            state, 
            duration: const Duration(seconds: 5), // Durée personnalisée pour les erreurs
          );
        } else if (state is ShoppingListOperationSuccess) {
          SmartSnackBarManager.showForState(context, state);
        }
        */
      },
      builder: (context, state) {
        if (state is ShoppingListLoading) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
            ),
          );
        } else if (state is ShoppingListLoaded) {
          if (state.lists.isEmpty) {
            return EmptyStateWidget(onCreateNew: onCreateNew);
          }

          // Limiter l'affichage si nécessaire
          final displayLists =
              maxDisplayLists != null
                  ? state.lists.take(maxDisplayLists!).toList()
                  : state.lists;

          return ListView.builder(
            itemCount: displayLists.length,
            itemBuilder: (context, index) {
              return ShoppingListCard(
                list: displayLists[index],
                onTap: () => onListTap(displayLists[index]),
                onAction: (action) => onListAction(action, displayLists[index]),
              );
            },
          );
        } else if (state is ShoppingListError) {
          return ErrorStateWidget(
            message: state.message,
            onRetry:
                () => context.read<ShoppingListBloc>().add(LoadShoppingLists()),
          );
        }

        // État initial
        return EmptyStateWidget(onCreateNew: onCreateNew);
      },
    );
  }
}
