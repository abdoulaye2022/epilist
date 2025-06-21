// screens/list_detail_screen.dart
import 'package:epilist/blocs/list_item/list_item_bloc.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/models/list_item.dart';
import 'package:epilist/services/list_item_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListDetailScreen extends StatefulWidget {
  final ShoppingList shoppingList;

  const ListDetailScreen({super.key, required this.shoppingList});

  @override
  // ignore: library_private_types_in_public_api
  _ListDetailScreenState createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<ListItemBloc>(
      create:
          (context) =>
              ListItemBloc(listItemService: context.read<ListItemService>())
                ..add(LoadListItems(widget.shoppingList.id)),
      child: _ListDetailView(shoppingList: widget.shoppingList),
    );
  }
}

class _ListDetailView extends StatefulWidget {
  final ShoppingList shoppingList;

  const _ListDetailView({required this.shoppingList});

  @override
  _ListDetailViewState createState() => _ListDetailViewState();
}

class _ListDetailViewState extends State<_ListDetailView> {
  late ShoppingList currentList;
  String _formatPrice(double price) {
    return '${price.toStringAsFixed(2)} \$CAD';
  }

  @override
  void initState() {
    super.initState();
    currentList = widget.shoppingList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(currentList.name),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _addNewItem,
            icon: Icon(Icons.add),
            tooltip: 'Ajouter un article',
          ),
        ],
      ),
      body: BlocConsumer<ListItemBloc, ListItemState>(
        listener: (context, state) {
          if (state is ListItemError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is ListItemOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            // Ne PAS recharger ici car le BLoC gère déjà le rechargement
          }
        },
        builder: (context, state) {
          List<ListItem> items = [];
          bool isLoading = false;

          if (state is ListItemLoading) {
            isLoading = true;
          } else if (state is ListItemLoaded) {
            items = state.items;
          }

          final totalItems = items.length;
          final purchasedItems = items.where((item) => item.isPurchased).length;
          final totalPrice = items.fold(
            0.0,
            (sum, item) => sum + (item.price ?? 0) * item.quantity,
          );

          return Column(
            children: [
              // En-tête avec statistiques
              Container(
                color: Colors.white,
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Articles', '$purchasedItems/$totalItems'),
                    _buildStatItem('Total', _formatPrice(totalPrice)),
                    _buildStatItem(
                      'Progression',
                      '${totalItems > 0 ? ((purchasedItems / totalItems) * 100).round() : 0}%',
                    ),
                  ],
                ),
              ),

              Expanded(
                child:
                    isLoading
                        ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.green[600]!,
                            ),
                          ),
                        )
                        : items.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                          onRefresh: () async {
                            context.read<ListItemBloc>().add(
                              LoadListItems(currentList.id),
                            );
                          },
                          child: ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              return _buildItemCard(items[index]);
                            },
                          ),
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green[600],
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_shopping_cart, size: 60, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Liste vide',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Ajoutez votre premier article',
            style: TextStyle(color: Colors.grey[500]),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _addNewItem,
            icon: Icon(Icons.add),
            label: Text('Ajouter un article'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(ListItem item) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: item.isPurchased,
          onChanged: (value) {
            context.read<ListItemBloc>().add(
              TogglePurchasedStatus(
                listId: currentList.id, // ✅ Ajouter le listId
                itemId: item.id,
                isPurchased: value!,
              ),
            );
          },
          activeColor: Colors.green[600],
        ),
        title: Text(
          item.productName,
          style: TextStyle(
            decoration: item.isPurchased ? TextDecoration.lineThrough : null,
            color: item.isPurchased ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Première ligne : Quantité et prix
            Row(
              children: [
                Text('Qté: ${item.quantity}'),
                if (item.price != null) ...[
                  Text(' • ${_formatPrice(item.price!)}'),
                ],
              ],
            ),
            // Deuxième ligne : Magasin avec ellipsis si trop long
            if (item.storeName != null) ...[
              SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.store, size: 12, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.storeName!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red[400]),
          onPressed: () => _confirmDeleteItem(item),
        ),
      ),
    );
  }

  void _confirmDeleteItem(ListItem item) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text('Supprimer l\'article'),
            content: Text(
              'Voulez-vous vraiment supprimer "${item.productName}" ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  // Utiliser le context parent pour accéder au BLoC
                  context.read<ListItemBloc>().add(
                    DeleteListItem(
                      listId: currentList.id, // ✅ Ajouter le listId
                      itemId: item.id,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Supprimer'),
              ),
            ],
          ),
    );
  }

  void _addNewItem() {
    final productController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final priceController = TextEditingController();
    final storeController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<ListItemBloc>(),
            child: AlertDialog(
              title: Text('Nouvel Article'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: productController,
                      decoration: InputDecoration(
                        labelText: 'Nom du produit*',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: quantityController,
                      decoration: InputDecoration(
                        labelText: 'Quantité',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      decoration: InputDecoration(
                        labelText: 'Prix (\$CAD)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: storeController,
                      decoration: InputDecoration(
                        labelText: 'Magasin',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Annuler'),
                ),
                BlocBuilder<ListItemBloc, ListItemState>(
                  builder: (dialogContext, state) {
                    final isLoading = state is ListItemLoading;
                    return ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () {
                                if (productController.text.trim().isNotEmpty) {
                                  dialogContext.read<ListItemBloc>().add(
                                    AddListItem(
                                      listId: currentList.id,
                                      productName:
                                          productController.text.trim(),
                                      quantity:
                                          int.tryParse(
                                            quantityController.text,
                                          ) ??
                                          1,
                                      price: double.tryParse(
                                        priceController.text,
                                      ),
                                      storeName:
                                          storeController.text.trim().isEmpty
                                              ? null
                                              : storeController.text.trim(),
                                    ),
                                  );
                                  Navigator.pop(dialogContext);
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                      ),
                      child:
                          isLoading
                              ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : Text('Ajouter'),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }
}
