import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/screens/list_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  @override
  void initState() {
    super.initState();
    // Recharger les listes au démarrage de cette page
    context.read<ShoppingListBloc>().add(LoadShoppingLists());
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(2)} \$CAD';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Mes Listes de Courses',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black87),
            onPressed: () {
              context.read<ShoppingListBloc>().add(LoadShoppingLists());
            },
          ),
        ],
      ),
      body: BlocConsumer<ShoppingListBloc, ShoppingListState>(
        listener: (context, state) {
          if (state is ShoppingListError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          } else if (state is ShoppingListOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ShoppingListLoading) {
            return Center(
              child: CircularProgressIndicator(color: Colors.green[600]),
            );
          }

          if (state is ShoppingListLoaded) {
            if (state.lists.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<ShoppingListBloc>().add(LoadShoppingLists());
              },
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: state.lists.length,
                itemBuilder: (context, index) {
                  final list = state.lists[index];
                  return _buildShoppingListCard(list, index);
                },
              ),
            );
          }

          if (state is ShoppingListError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ShoppingListBloc>().add(LoadShoppingLists());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                    ),
                    child: Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          return _buildEmptyState();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewList,
        backgroundColor: Colors.green[600],
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Aucune liste de courses',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Créez votre première liste pour commencer',
            style: TextStyle(color: Colors.grey[500]),
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: _createNewList,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text('Créer une liste'),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingListCard(ShoppingList list, int index) {
    // Utiliser les getters du modèle
    final totalItems = list.itemsCount;
    final completedItems = list.purchasedItemsCount;
    final progress = list.progress;
    final totalPrice = list.totalPrice;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openListDetails(list),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      list.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  PopupMenuButton(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                    itemBuilder:
                        (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Modifier'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                Icon(Icons.copy, size: 20),
                                SizedBox(width: 8),
                                Text('Dupliquer'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Supprimer',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                    onSelected:
                        (value) => _handleListAction(value.toString(), list),
                  ),
                ],
              ),

              SizedBox(height: 8),

              Text(
                '${_formatDate(list.createdAt)} • $totalItems articles',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),

              if (totalPrice > 0) ...[
                SizedBox(height: 4),
                Text(
                  'Budget estimé: ${_formatPrice(totalPrice)}',
                  style: TextStyle(
                    color: Colors.green[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              SizedBox(height: 12),

              // Barre de progression
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.green[600]!,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '$completedItems/$totalItems',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Status
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      list.isCompleted ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color:
                        list.isCompleted
                            ? Colors.green[200]!
                            : Colors.orange[200]!,
                  ),
                ),
                child: Text(
                  list.isCompleted ? '✅ Terminée' : '🛒 En cours',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        list.isCompleted
                            ? Colors.green[700]
                            : Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createNewList() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<ShoppingListBloc>(),
            child: AlertDialog(
              title: Text('Nouvelle liste de courses'),
              content: TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nom de la liste',
                  hintText: 'Ex: Courses de la semaine',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Annuler'),
                ),
                BlocBuilder<ShoppingListBloc, ShoppingListState>(
                  builder: (dialogContext, state) {
                    final isLoading = state is ShoppingListLoading;
                    return ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () {
                                if (nameController.text.trim().isNotEmpty) {
                                  dialogContext.read<ShoppingListBloc>().add(
                                    CreateShoppingList(
                                      nameController.text.trim(),
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
                                  color: Colors.white,
                                ),
                              )
                              : Text('Créer'),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _openListDetails(ShoppingList list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListDetailScreen(shoppingList: list),
      ),
    ).then((_) {
      // Recharger les listes au retour
      context.read<ShoppingListBloc>().add(LoadShoppingLists());
    });
  }

  void _handleListAction(String action, ShoppingList list) {
    switch (action) {
      case 'edit':
        _editListName(list);
        break;
      case 'duplicate':
        context.read<ShoppingListBloc>().add(DuplicateShoppingList(list.id));
        break;
      case 'delete':
        _deleteList(list);
        break;
    }
  }

  void _editListName(ShoppingList list) {
    final nameController = TextEditingController(text: list.name);

    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<ShoppingListBloc>(),
            child: AlertDialog(
              title: Text('Modifier le nom'),
              content: TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nom de la liste',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Annuler'),
                ),
                BlocBuilder<ShoppingListBloc, ShoppingListState>(
                  builder: (dialogContext, state) {
                    final isLoading = state is ShoppingListLoading;
                    return ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () {
                                if (nameController.text.trim().isNotEmpty) {
                                  dialogContext.read<ShoppingListBloc>().add(
                                    UpdateShoppingList(
                                      list.id,
                                      nameController.text.trim(),
                                    ),
                                  );
                                  Navigator.pop(dialogContext);
                                }
                              },
                      child:
                          isLoading
                              ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text('Sauvegarder'),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _deleteList(ShoppingList list) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<ShoppingListBloc>(),
            child: AlertDialog(
              title: Text('Supprimer la liste'),
              content: Text(
                'Êtes-vous sûr de vouloir supprimer "${list.name}" ?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Annuler'),
                ),
                BlocBuilder<ShoppingListBloc, ShoppingListState>(
                  builder: (dialogContext, state) {
                    final isLoading = state is ShoppingListLoading;
                    return ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () {
                                dialogContext.read<ShoppingListBloc>().add(
                                  DeleteShoppingList(list.id),
                                );
                                Navigator.pop(dialogContext);
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child:
                          isLoading
                              ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text('Supprimer'),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Aujourd\'hui';
    } else if (difference == 1) {
      return 'Hier';
    } else if (difference < 7) {
      return 'Il y a $difference jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
