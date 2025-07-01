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
          (dialogContext) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 10,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icône de suppression
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Icon(
                      Icons.delete_rounded,
                      size: 40,
                      color: Colors.red[600],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Titre
                  Text(
                    'Supprimer l\'article',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: 12),

                  // Message
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(text: 'Êtes-vous sûr de vouloir supprimer '),
                        TextSpan(
                          text: '"${item.productName}"',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        TextSpan(text: ' de votre liste ?'),
                      ],
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    'Cette action est irréversible.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  SizedBox(height: 24),

                  // Boutons
                  Row(
                    children: [
                      // Bouton Annuler
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: Text(
                            'Annuler',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 12),

                      // Bouton Supprimer
                      Expanded(
                        child: BlocProvider.value(
                          value: context.read<ListItemBloc>(),
                          child: BlocBuilder<ListItemBloc, ListItemState>(
                            builder: (dialogContext, state) {
                              final isLoading = state is ListItemLoading;
                              return ElevatedButton(
                                onPressed:
                                    isLoading
                                        ? null
                                        : () {
                                          Navigator.pop(dialogContext);
                                          // Utiliser le context parent pour accéder au BLoC
                                          context.read<ListItemBloc>().add(
                                            DeleteListItem(
                                              listId: currentList.id,
                                              itemId: item.id,
                                            ),
                                          );
                                        },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[600],
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.red[300],
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child:
                                    isLoading
                                        ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                        : Text(
                                          'Supprimer',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 10,
              child: Container(
                padding: EdgeInsets.all(24),
                constraints: BoxConstraints(
                  maxWidth: 500,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icône d'ajout
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Icon(
                        Icons.add_shopping_cart_rounded,
                        size: 40,
                        color: Colors.green[600],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Titre
                    Text(
                      'Nouvel Article',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    SizedBox(height: 12),

                    // Message
                    Text(
                      'Ajoutez un nouvel article à votre liste d\'épicerie',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),

                    SizedBox(height: 24),

                    // Formulaire
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Nom du produit
                            TextField(
                              controller: productController,
                              decoration: InputDecoration(
                                labelText: 'Nom du produit*',
                                hintText: 'Ex: Bananes, Pain, Lait...',
                                prefixIcon: Icon(
                                  Icons.shopping_basket,
                                  color: Colors.green[600],
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.green[600]!,
                                    width: 2,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              autofocus: true,
                              textCapitalization: TextCapitalization.words,
                            ),

                            SizedBox(height: 16),

                            // Quantité et Prix sur la même ligne
                            Row(
                              children: [
                                // Quantité
                                Expanded(
                                  flex: 1,
                                  child: TextField(
                                    controller: quantityController,
                                    decoration: InputDecoration(
                                      labelText: 'Quantité',
                                      hintText: '1',
                                      prefixIcon: Icon(
                                        Icons.numbers,
                                        color: Colors.blue[600],
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.blue[600]!,
                                          width: 2,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),

                                SizedBox(width: 12),

                                // Prix
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: priceController,
                                    decoration: InputDecoration(
                                      labelText: 'Prix (\$CAD)',
                                      hintText: '0.00',
                                      prefixIcon: Icon(
                                        Icons.attach_money,
                                        color: Colors.amber[700],
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.amber[700]!,
                                          width: 2,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 16),

                            // Magasin
                            TextField(
                              controller: storeController,
                              decoration: InputDecoration(
                                labelText: 'Magasin (optionnel)',
                                hintText: 'Ex: IGA, Metro, Provigo...',
                                prefixIcon: Icon(
                                  Icons.store,
                                  color: Colors.purple[600],
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.purple[600]!,
                                    width: 2,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              textCapitalization: TextCapitalization.words,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Boutons
                    Row(
                      children: [
                        // Bouton Annuler
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: Text(
                              'Annuler',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: 12),

                        // Bouton Ajouter
                        Expanded(
                          child: BlocBuilder<ListItemBloc, ListItemState>(
                            builder: (dialogContext, state) {
                              final isLoading = state is ListItemLoading;
                              return ElevatedButton(
                                onPressed:
                                    isLoading
                                        ? null
                                        : () {
                                          if (productController.text
                                              .trim()
                                              .isNotEmpty) {
                                            dialogContext
                                                .read<ListItemBloc>()
                                                .add(
                                                  AddListItem(
                                                    listId: currentList.id,
                                                    productName:
                                                        productController.text
                                                            .trim(),
                                                    quantity:
                                                        int.tryParse(
                                                          quantityController
                                                              .text,
                                                        ) ??
                                                        1,
                                                    price: double.tryParse(
                                                      priceController.text,
                                                    ),
                                                    storeName:
                                                        storeController.text
                                                                .trim()
                                                                .isEmpty
                                                            ? null
                                                            : storeController
                                                                .text
                                                                .trim(),
                                                  ),
                                                );
                                            Navigator.pop(dialogContext);
                                          } else {
                                            // Afficher un message d'erreur si le nom est vide
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Le nom du produit est obligatoire',
                                                ),
                                                backgroundColor: Colors.red,
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[600],
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.green[300],
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child:
                                    isLoading
                                        ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                        : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add, size: 18),
                                            SizedBox(width: 6),
                                            Text(
                                              'Ajouter',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
