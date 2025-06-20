import 'package:flutter/material.dart';

class ShoppingListScreen extends StatefulWidget {
  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  List<ShoppingList> shoppingLists = [
    ShoppingList(
      id: '1',
      name: 'Courses de la semaine',
      items: [
        ShoppingItem(
          name: 'Tomates cerises',
          quantity: '500g',
          isCompleted: true,
          price: 2.50,
        ),
        ShoppingItem(
          name: 'Pain complet',
          quantity: '1 pièce',
          isCompleted: false,
          price: 1.80,
        ),
        ShoppingItem(
          name: 'Lait bio',
          quantity: '1L',
          isCompleted: false,
          price: 1.40,
        ),
        ShoppingItem(
          name: 'Pommes',
          quantity: '1kg',
          isCompleted: true,
          price: 3.20,
        ),
      ],
      createdAt: DateTime.now().subtract(Duration(days: 1)),
    ),
    ShoppingList(
      id: '2',
      name: 'Réception amis',
      items: [
        ShoppingItem(
          name: 'Fromage camembert',
          quantity: '1 pièce',
          isCompleted: false,
          price: 4.50,
        ),
        ShoppingItem(
          name: 'Baguette tradition',
          quantity: '2 pièces',
          isCompleted: false,
          price: 2.60,
        ),
        ShoppingItem(
          name: 'Vin rouge',
          quantity: '1 bouteille',
          isCompleted: false,
          price: 8.90,
        ),
      ],
      createdAt: DateTime.now().subtract(Duration(days: 3)),
    ),
  ];

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
            icon: Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              // Recherche dans les listes
            },
          ),
        ],
      ),
      body:
          shoppingLists.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: shoppingLists.length,
                itemBuilder: (context, index) {
                  final list = shoppingLists[index];
                  return _buildShoppingListCard(list, index);
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
    final completedItems = list.items.where((item) => item.isCompleted).length;
    final totalItems = list.items.length;
    final progress = totalItems > 0 ? completedItems / totalItems : 0.0;
    final totalPrice = list.items.fold(
      0.0,
      (sum, item) => sum + (item.price ?? 0),
    );

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
                        (value) =>
                            _handleListAction(value.toString(), list, index),
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
                  'Budget estimé: ${totalPrice.toStringAsFixed(2)}€',
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

              // Aperçu des premiers articles
              ...list.items
                  .take(3)
                  .map(
                    (item) => Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            item.isCompleted
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 16,
                            color:
                                item.isCompleted
                                    ? Colors.green[600]
                                    : Colors.grey[400],
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${item.name} (${item.quantity})',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    item.isCompleted
                                        ? Colors.grey[500]
                                        : Colors.black87,
                                decoration:
                                    item.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                              ),
                            ),
                          ),
                          if (item.price != null)
                            Text(
                              '${item.price!.toStringAsFixed(2)}€',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                  .toList(),

              if (list.items.length > 3)
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    '... et ${list.items.length - 3} autres articles',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
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
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        return AlertDialog(
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
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    shoppingLists.insert(
                      0,
                      ShoppingList(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text,
                        items: [],
                        createdAt: DateTime.now(),
                      ),
                    );
                  });
                  Navigator.pop(context);
                  _openListDetails(shoppingLists.first);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
              ),
              child: Text('Créer'),
            ),
          ],
        );
      },
    );
  }

  void _openListDetails(ShoppingList list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ShoppingListDetailPage(
              shoppingList: list,
              onListUpdated: (updatedList) {
                setState(() {
                  final index = shoppingLists.indexWhere(
                    (l) => l.id == updatedList.id,
                  );
                  if (index != -1) {
                    shoppingLists[index] = updatedList;
                  }
                });
              },
            ),
      ),
    );
  }

  void _handleListAction(String action, ShoppingList list, int index) {
    switch (action) {
      case 'edit':
        _editListName(list, index);
        break;
      case 'duplicate':
        _duplicateList(list);
        break;
      case 'delete':
        _deleteList(index);
        break;
    }
  }

  void _editListName(ShoppingList list, int index) {
    final nameController = TextEditingController(text: list.name);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    setState(() {
                      shoppingLists[index] = list.copyWith(
                        name: nameController.text,
                      );
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text('Sauvegarder'),
              ),
            ],
          ),
    );
  }

  void _duplicateList(ShoppingList list) {
    setState(() {
      shoppingLists.insert(
        0,
        list.copyWith(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: '${list.name} (copie)',
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  void _deleteList(int index) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Supprimer la liste'),
            content: Text('Êtes-vous sûr de vouloir supprimer cette liste ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    shoppingLists.removeAt(index);
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Supprimer'),
              ),
            ],
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

// Page de détail d'une liste de courses
class ShoppingListDetailPage extends StatefulWidget {
  final ShoppingList shoppingList;
  final Function(ShoppingList) onListUpdated;

  ShoppingListDetailPage({
    required this.shoppingList,
    required this.onListUpdated,
  });

  @override
  _ShoppingListDetailPageState createState() => _ShoppingListDetailPageState();
}

class _ShoppingListDetailPageState extends State<ShoppingListDetailPage> {
  late ShoppingList currentList;
  final _newItemController = TextEditingController();
  final _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    currentList = widget.shoppingList;
  }

  @override
  Widget build(BuildContext context) {
    final completedItems =
        currentList.items.where((item) => item.isCompleted).length;
    final totalItems = currentList.items.length;
    final totalPrice = currentList.items.fold(
      0.0,
      (sum, item) => sum + (item.price ?? 0),
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          currentList.name,
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.black87),
            onPressed: _shareList,
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête avec statistiques
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn('Articles', '$completedItems/$totalItems'),
                    _buildStatColumn(
                      'Budget',
                      '${totalPrice.toStringAsFixed(2)}€',
                    ),
                    _buildStatColumn(
                      'Progression',
                      '${((completedItems / (totalItems > 0 ? totalItems : 1)) * 100).round()}%',
                    ),
                  ],
                ),
                SizedBox(height: 16),
                LinearProgressIndicator(
                  value: totalItems > 0 ? completedItems / totalItems : 0,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                ),
              ],
            ),
          ),

          // Ajouter un article
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _newItemController,
                    decoration: InputDecoration(
                      hintText: 'Ajouter un article...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    decoration: InputDecoration(
                      hintText: 'Quantité',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.all(12),
                  ),
                  child: Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),

          // Liste des articles
          Expanded(
            child:
                currentList.items.isEmpty
                    ? _buildEmptyListState()
                    : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: currentList.items.length,
                      itemBuilder: (context, index) {
                        final item = currentList.items[index];
                        return _buildItemCard(item, index);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green[600],
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildEmptyListState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_shopping_cart, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Liste vide',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          Text(
            'Ajoutez votre premier article ci-dessus',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(ShoppingItem item, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.isCompleted ? Colors.green[200]! : Colors.grey[200]!,
        ),
      ),
      child: ListTile(
        leading: Checkbox(
          value: item.isCompleted,
          onChanged: (value) => _toggleItem(index),
          activeColor: Colors.green[600],
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
            color: item.isCompleted ? Colors.grey[500] : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              item.quantity,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            if (item.price != null) ...[
              Text(' • ', style: TextStyle(color: Colors.grey[400])),
              Text(
                '${item.price!.toStringAsFixed(2)}€',
                style: TextStyle(
                  color: Colors.green[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red[400]),
          onPressed: () => _deleteItem(index),
        ),
      ),
    );
  }

  void _addItem() {
    if (_newItemController.text.isNotEmpty) {
      setState(() {
        currentList.items.add(
          ShoppingItem(
            name: _newItemController.text,
            quantity:
                _quantityController.text.isNotEmpty
                    ? _quantityController.text
                    : '1',
            isCompleted: false,
          ),
        );
      });
      _newItemController.clear();
      _quantityController.clear();
      _updateList();
    }
  }

  void _toggleItem(int index) {
    setState(() {
      currentList.items[index].isCompleted =
          !currentList.items[index].isCompleted;
    });
    _updateList();
  }

  void _deleteItem(int index) {
    setState(() {
      currentList.items.removeAt(index);
    });
    _updateList();
  }

  void _shareList() {
    final listText = currentList.items
        .map(
          (item) =>
              '${item.isCompleted ? "✓" : "○"} ${item.name} (${item.quantity})',
        )
        .join('\n');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Partager la liste'),
            content: Text('Liste: ${currentList.name}\n\n$listText'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Fermer'),
              ),
            ],
          ),
    );
  }

  void _updateList() {
    widget.onListUpdated(currentList);
  }

  @override
  void dispose() {
    _newItemController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}

// Modèles de données
class ShoppingList {
  final String id;
  final String name;
  final List<ShoppingItem> items;
  final DateTime createdAt;

  ShoppingList({
    required this.id,
    required this.name,
    required this.items,
    required this.createdAt,
  });

  ShoppingList copyWith({
    String? id,
    String? name,
    List<ShoppingItem>? items,
    DateTime? createdAt,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? List.from(this.items),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ShoppingItem {
  final String name;
  final String quantity;
  bool isCompleted;
  final double? price;

  ShoppingItem({
    required this.name,
    required this.quantity,
    this.isCompleted = false,
    this.price,
  });

  ShoppingItem copyWith({
    String? name,
    String? quantity,
    bool? isCompleted,
    double? price,
  }) {
    return ShoppingItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      isCompleted: isCompleted ?? this.isCompleted,
      price: price ?? this.price,
    );
  }
}
