// screens/home_screen.dart
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/screens/profil_screen.dart';
import 'package:epilist/screens/list_detail_screen.dart';
import 'package:epilist/services/shopping_list_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<ShoppingListBloc>(
      create:
          (context) => ShoppingListBloc(
            shoppingListService: context.read<ShoppingListService>(),
          )..add(LoadShoppingLists()),
      child: _HomeScreenView(),
    );
  }
}

class _HomeScreenView extends StatelessWidget {
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
            onPressed: () => _goToProfile(context),
            icon: Icon(Icons.person, color: Colors.grey[700]),
            tooltip: 'Profil',
          ),
          // Bouton Déconnexion
          IconButton(
            onPressed: () => _logout(context),
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
                  onPressed: () => _createNewList(context),
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

            // Liste des épiceries avec BLoC
            Expanded(
              child: BlocConsumer<ShoppingListBloc, ShoppingListState>(
                listener: (context, state) {
                  if (state is ShoppingListError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else if (state is ShoppingListCreated) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Liste créée avec succès !'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is ShoppingListLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.green[600]!,
                        ),
                      ),
                    );
                  } else if (state is ShoppingListLoaded) {
                    if (state.lists.isEmpty) {
                      return _buildEmptyState(context);
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<ShoppingListBloc>().add(
                          LoadShoppingLists(),
                        );
                      },
                      child: ListView.builder(
                        itemCount: state.lists.length,
                        itemBuilder: (context, index) {
                          return _buildSimpleListCard(
                            context,
                            state.lists[index],
                          );
                        },
                      ),
                    );
                  } else if (state is ShoppingListError) {
                    return _buildErrorState(context, state.message);
                  }

                  // État initial ou autres états
                  return _buildEmptyState(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
            onPressed: () => _createNewList(context),
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

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
          SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.red[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<ShoppingListBloc>().add(LoadShoppingLists());
            },
            icon: Icon(Icons.refresh),
            label: Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleListCard(BuildContext context, ShoppingList list) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openListDetails(context, list),
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
                    'Cliquez pour voir les articles',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),

              SizedBox(height: 8),

              // Date
              Text(
                'Créée ${_formatDate(list.createdAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              if (list.updatedAt != null) ...[
                Text(
                  'Modifiée ${_formatDate(list.updatedAt!)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _createNewList(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final nameController = TextEditingController();
        return BlocProvider.value(
          value: context.read<ShoppingListBloc>(),
          child: AlertDialog(
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Text('Créer'),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openListDetails(BuildContext context, ShoppingList list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListDetailScreen(shoppingList: list),
      ),
    );
  }

  void _goToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen()),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text('Déconnexion'),
            content: Text('Voulez-vous vraiment vous déconnecter ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
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
