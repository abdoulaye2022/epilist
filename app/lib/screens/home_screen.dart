import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/screens/profil_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Données d'exemple pour les listes d'épicerie
  List<ShoppingList> shoppingLists = [
    ShoppingList(
      id: 1,
      userId: 1,
      name: 'Courses de la semaine',
      createdAt: DateTime.now().subtract(Duration(days: 1)),
      items: [
        ListItem(
          id: 1,
          listId: 1,
          productName: 'Tomates',
          quantity: 2,
          price: 2.50,
          storeName: 'Carrefour',
          isPurchased: false,
        ),
        ListItem(
          id: 2,
          listId: 1,
          productName: 'Pain',
          quantity: 1,
          price: 1.80,
          storeName: 'Boulangerie',
          isPurchased: true,
        ),
      ],
    ),
    ShoppingList(
      id: 2,
      userId: 1,
      name: 'Repas de dimanche',
      createdAt: DateTime.now().subtract(Duration(days: 2)),
      items: [
        ListItem(
          id: 3,
          listId: 2,
          productName: 'Poulet',
          quantity: 1,
          price: 8.50,
          storeName: 'Boucherie',
          isPurchased: false,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Bienvenue',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Bouton Profile
          IconButton(
            onPressed: _goToProfile,
            icon: Icon(Icons.person, color: Colors.grey[700]),
            tooltip: 'Profil',
          ),
          // Bouton Déconnexion
          IconButton(
            onPressed: _logout,
            icon: Icon(Icons.logout, color: Colors.red[600]),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message de bienvenue
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour ! 👋',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Gérez vos listes d\'épicerie facilement',
                    style: TextStyle(fontSize: 16, color: Colors.blue[700]),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Section des listes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mes Listes d\'Épicerie',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _createNewList,
                  icon: Icon(Icons.add, size: 18),
                  label: Text('Nouvelle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Liste des épiceries
            Expanded(
              child:
                  shoppingLists.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                        itemCount: shoppingLists.length,
                        itemBuilder: (context, index) {
                          return _buildSimpleListCard(shoppingLists[index]);
                        },
                      ),
            ),
          ],
        ),
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
            'Aucune liste d\'épicerie',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Créez votre première liste',
            style: TextStyle(color: Colors.grey[500]),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewList,
            icon: Icon(Icons.add),
            label: Text('Créer une liste'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleListCard(ShoppingList list) {
    final totalItems = list.items.length;
    final purchasedItems = list.items.where((item) => item.isPurchased).length;
    final totalPrice = list.items.fold(
      0.0,
      (sum, item) => sum + (item.price ?? 0) * item.quantity,
    );

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openListDetails(list),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nom de la liste
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
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),

              SizedBox(height: 12),

              // Informations de base
              Row(
                children: [
                  Icon(Icons.shopping_cart, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 6),
                  Text(
                    '$purchasedItems/$totalItems articles',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(width: 16),
                  Icon(Icons.euro, size: 16, color: Colors.green[600]),
                  SizedBox(width: 6),
                  Text(
                    '${totalPrice.toStringAsFixed(2)}€',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Barre de progression simple
              LinearProgressIndicator(
                value: totalItems > 0 ? purchasedItems / totalItems : 0,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                minHeight: 6,
              ),

              SizedBox(height: 8),

              // Date
              Text(
                'Créée ${_formatDate(list.createdAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
          title: Text('Nouvelle Liste'),
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
                if (nameController.text.trim().isNotEmpty) {
                  setState(() {
                    shoppingLists.insert(
                      0,
                      ShoppingList(
                        id: DateTime.now().millisecondsSinceEpoch,
                        userId: 1,
                        name: nameController.text.trim(),
                        createdAt: DateTime.now(),
                        items: [],
                      ),
                    );
                  });
                  Navigator.pop(context);
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
        builder: (context) => ListDetailPage(shoppingList: list),
      ),
    );
  }

  void _goToProfile() {
    // Navigation vers la page profil
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen()),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Déconnexion'),
            content: Text('Voulez-vous vraiment vous déconnecter ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Appeler le BLoC pour déclencher la déconnexion
                  context.read<AuthBloc>().add(LogoutRequested());
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Déconnecter'),
              ),
            ],
          ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inHours < 24) {
      return 'aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'hier';
    } else if (difference.inDays < 7) {
      return 'il y a ${difference.inDays} jours';
    } else {
      return 'le ${date.day}/${date.month}';
    }
  }
}

// Page de détail simplifiée
class ListDetailPage extends StatefulWidget {
  final ShoppingList shoppingList;

  ListDetailPage({required this.shoppingList});

  @override
  _ListDetailPageState createState() => _ListDetailPageState();
}

class _ListDetailPageState extends State<ListDetailPage> {
  late ShoppingList currentList;

  @override
  void initState() {
    super.initState();
    currentList = widget.shoppingList;
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = currentList.items.length;
    final purchasedItems =
        currentList.items.where((item) => item.isPurchased).length;
    final totalPrice = currentList.items.fold(
      0.0,
      (sum, item) => sum + (item.price ?? 0) * item.quantity,
    );

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
      body: Column(
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
                _buildStatItem('Total', '${totalPrice.toStringAsFixed(2)}€'),
                _buildStatItem(
                  'Progression',
                  '${totalItems > 0 ? ((purchasedItems / totalItems) * 100).round() : 0}%',
                ),
              ],
            ),
          ),

          Expanded(
            child:
                currentList.items.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: currentList.items.length,
                      itemBuilder: (context, index) {
                        return _buildItemCard(currentList.items[index]);
                      },
                    ),
          ),
        ],
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
            setState(() {
              item.isPurchased = value!;
            });
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
        subtitle: Row(
          children: [
            Text('Qté: ${item.quantity}'),
            if (item.price != null) ...[
              Text(' • ${item.price!.toStringAsFixed(2)}€'),
            ],
            if (item.storeName != null) ...[Text(' • ${item.storeName}')],
          ],
        ),
      ),
    );
  }

  void _addNewItem() {
    final productController = TextEditingController();
    final quantityController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Nouvel Article'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: productController,
                  decoration: InputDecoration(
                    labelText: 'Nom du produit',
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
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (productController.text.trim().isNotEmpty) {
                    setState(() {
                      currentList.items.add(
                        ListItem(
                          id: DateTime.now().millisecondsSinceEpoch,
                          listId: currentList.id,
                          productName: productController.text.trim(),
                          quantity: int.tryParse(quantityController.text) ?? 1,
                          isPurchased: false,
                        ),
                      );
                    });
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                ),
                child: Text('Ajouter'),
              ),
            ],
          ),
    );
  }
}

// Modèles de données
class ShoppingList {
  final int id;
  final int userId;
  final String name;
  final DateTime createdAt;
  final List<ListItem> items;

  ShoppingList({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
    required this.items,
  });
}

class ListItem {
  final int id;
  final int listId;
  final String productName;
  final int quantity;
  final double? price;
  final String? storeName;
  bool isPurchased;

  ListItem({
    required this.id,
    required this.listId,
    required this.productName,
    this.quantity = 1,
    this.price,
    this.storeName,
    this.isPurchased = false,
  });
}
