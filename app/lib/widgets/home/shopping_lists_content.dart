// widgets/home/shopping_lists_content.dart - VERSION AVEC MODE HORIZONTAL
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/widgets/home/empty_state_widget.dart';
import 'package:epilist/widgets/home/error_state_widget.dart';
import 'package:epilist/widgets/home/shopping_list_card.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShoppingListsContent extends StatelessWidget {
  final VoidCallback onCreateNew;
  final Function(ShoppingList) onListTap;
  final Function(String action, ShoppingList list) onListAction;
  final int? maxDisplayLists;
  final bool horizontalLayout; // ✅ NOUVEAU: Mode d'affichage

  const ShoppingListsContent({
    super.key,
    required this.onCreateNew,
    required this.onListTap,
    required this.onListAction,
    this.maxDisplayLists,
    this.horizontalLayout = false, // ✅ NOUVEAU: Par défaut vertical
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ShoppingListBloc, ShoppingListState>(
      listener: (context, state) {
        // ✨ Gestion intelligente des états avec SnackBar
        SmartSnackBarManager.showForState(context, state);
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

          // ✅ NOUVEAU: Choix du layout selon le mode
          return horizontalLayout
              ? _buildHorizontalLayout(displayLists)
              : _buildVerticalLayout(displayLists);
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

  // ✅ NOUVEAU: Layout vertical (pour ShoppingListScreen)
  Widget _buildVerticalLayout(List<ShoppingList> lists) {
    return ListView.builder(
      itemCount: lists.length,
      itemBuilder: (context, index) {
        return ShoppingListCard(
          list: lists[index],
          onTap: () => onListTap(lists[index]),
          onAction: (action) => onListAction(action, lists[index]),
        );
      },
    );
  }

  // ✅ NOUVEAU: Layout horizontal (pour HomeScreen)
  Widget _buildHorizontalLayout(List<ShoppingList> lists) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: lists.length,
      itemBuilder: (context, index) {
        return Container(
          width: 280, // Largeur fixe pour chaque carte
          margin: const EdgeInsets.only(right: 16),
          child: ShoppingListCard(
            list: lists[index],
            onTap: () => onListTap(lists[index]),
            onAction: (action) => onListAction(action, lists[index]),
          ),
        );
      },
    );
  }
}
