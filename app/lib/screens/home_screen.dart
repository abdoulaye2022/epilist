// screens/home_screen.dart
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/screens/profil_screen.dart';
import 'package:epilist/screens/list_detail_screen.dart';
import 'package:epilist/screens/shopping_list_screen.dart';
import 'package:epilist/services/shopping_list_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Charger les listes au démarrage
    context.read<ShoppingListBloc>().add(LoadShoppingLists());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Recharger quand l'app devient active
    if (state == AppLifecycleState.resumed) {
      context.read<ShoppingListBloc>().add(LoadShoppingLists());
    }
  }

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
          // Bouton refresh
          IconButton(
            onPressed: () {
              context.read<ShoppingListBloc>().add(LoadShoppingLists());
            },
            icon: Icon(Icons.refresh, color: Colors.grey[700]),
            tooltip: 'Actualiser',
          ),
          // Bouton Voir toutes les listes
          IconButton(
            onPressed: () => _goToAllLists(context),
            icon: Icon(Icons.list, color: Colors.grey[700]),
            tooltip: 'Toutes les listes',
          ),
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
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<ShoppingListBloc>().add(LoadShoppingLists());
        },
        child: Padding(
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

              // Section des listes - responsive
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxWidth < 400;

                  if (isSmallScreen) {
                    // Layout vertical pour petits écrans
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mes Listes d\'Épicerie',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => _goToAllLists(context),
                              child: Text(
                                'Voir tout',
                                style: TextStyle(color: Colors.blue[600]),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _createNewList(context),
                              icon: Icon(Icons.add, size: 16),
                              label: Text('Nouvelle'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                elevation: 2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    // Layout horizontal pour grands écrans
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Mes Listes d\'Épicerie',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => _goToAllLists(context),
                              child: Text(
                                'Voir tout',
                                style: TextStyle(color: Colors.blue[600]),
                              ),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _createNewList(context),
                              icon: Icon(Icons.add, size: 18),
                              label: Text('Nouvelle'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                elevation: 2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                },
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

                      // Afficher seulement les 5 dernières listes sur la page d'accueil
                      final displayLists = state.lists.take(5).toList();

                      return ListView.builder(
                        itemCount: displayLists.length,
                        itemBuilder: (context, index) {
                          return _buildEnhancedListCard(
                            context,
                            displayLists[index],
                          );
                        },
                      );
                    } else if (state is ShoppingListError) {
                      return _buildErrorState(context, state.message);
                    }

                    // État initial
                    return _buildEmptyState(context);
                  },
                ),
              ),
            ],
          ),
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

  Widget _buildEnhancedListCard(BuildContext context, ShoppingList list) {
    // Utiliser les getters du modèle comme dans ShoppingListScreen
    final totalItems = list.itemsCount;
    final completedItems = list.purchasedItemsCount;
    final progress = list.progress;
    final totalPrice = list.totalPrice;

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
              // Nom de la liste et menu
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
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  SizedBox(width: 8), // Espace entre le titre et le menu
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
                            _handleListAction(value.toString(), list, context),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Informations détaillées - responsive
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxWidth < 300;

                  if (isSmallScreen && totalPrice > 0) {
                    // Layout vertical pour très petits écrans
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.shopping_cart,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 6),
                            Text(
                              '$totalItems articles',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.attach_money,
                              size: 16,
                              color: Colors.green[600],
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${totalPrice.toStringAsFixed(2)} \$CAD',
                                style: TextStyle(
                                  color: Colors.green[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    // Layout horizontal pour écrans normaux
                    return Row(
                      children: [
                        Icon(
                          Icons.shopping_cart,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 6),
                        Text(
                          '$totalItems articles',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        if (totalPrice > 0) ...[
                          SizedBox(width: 16),
                          Icon(
                            Icons.attach_money,
                            size: 16,
                            color: Colors.green[600],
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${totalPrice.toStringAsFixed(2)} \$CAD',
                              style: TextStyle(
                                color: Colors.green[600],
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    );
                  }
                },
              ),

              if (totalItems > 0) ...[
                SizedBox(height: 8),

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
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

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
                      fontSize: 11,
                      color:
                          list.isCompleted
                              ? Colors.green[700]
                              : Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

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

  void _createNewList(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final nameController = TextEditingController();
        return BlocProvider.value(
          value: context.read<ShoppingListBloc>(),
          child: Dialog(
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
                  // Icône de création
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
                    'Nouvelle Liste',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: 12),

                  // Message
                  Text(
                    'Donnez un nom à votre nouvelle liste d\'épicerie',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),

                  SizedBox(height: 24),

                  // Champ de saisie
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nom de la liste',
                      hintText: 'Ex: Courses de la semaine',
                      prefixIcon: Icon(
                        Icons.list_alt,
                        color: Colors.green[600],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
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
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    autofocus: true,
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

                      // Bouton Créer
                      Expanded(
                        child: BlocBuilder<ShoppingListBloc, ShoppingListState>(
                          builder: (dialogContext, state) {
                            final isLoading = state is ShoppingListLoading;
                            return ElevatedButton(
                              onPressed:
                                  isLoading
                                      ? null
                                      : () {
                                        if (nameController.text
                                            .trim()
                                            .isNotEmpty) {
                                          dialogContext
                                              .read<ShoppingListBloc>()
                                              .add(
                                                CreateShoppingList(
                                                  nameController.text.trim(),
                                                ),
                                              );
                                          Navigator.pop(dialogContext);
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
                                      : Text(
                                        'Créer',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
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
    ).then((_) {
      // Recharger les listes au retour
      context.read<ShoppingListBloc>().add(LoadShoppingLists());
    });
  }

  void _goToAllLists(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ShoppingListScreen()),
    ).then((_) {
      // Recharger les listes au retour
      context.read<ShoppingListBloc>().add(LoadShoppingLists());
    });
  }

  void _handleListAction(
    String action,
    ShoppingList list,
    BuildContext context,
  ) {
    switch (action) {
      case 'edit':
        _editListName(list, context);
        break;
      case 'duplicate':
        context.read<ShoppingListBloc>().add(DuplicateShoppingList(list.id));
        break;
      case 'delete':
        _deleteList(list, context);
        break;
    }
  }

  void _deleteList(ShoppingList list, BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<ShoppingListBloc>(),
            child: Dialog(
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
                      'Supprimer la liste',
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
                            text: '"${list.name}"',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          TextSpan(text: ' ?'),
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
                          child: BlocBuilder<
                            ShoppingListBloc,
                            ShoppingListState
                          >(
                            builder: (dialogContext, state) {
                              final isLoading = state is ShoppingListLoading;
                              return ElevatedButton(
                                onPressed:
                                    isLoading
                                        ? null
                                        : () {
                                          dialogContext
                                              .read<ShoppingListBloc>()
                                              .add(DeleteShoppingList(list.id));
                                          Navigator.pop(dialogContext);
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
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  void _editListName(ShoppingList list, BuildContext context) {
    final nameController = TextEditingController(text: list.name);

    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<ShoppingListBloc>(),
            child: Dialog(
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
                    // Icône de modification
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 40,
                        color: Colors.blue[600],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Titre
                    Text(
                      'Modifier le nom',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    SizedBox(height: 12),

                    // Message
                    Text(
                      'Modifiez le nom de votre liste d\'épicerie',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),

                    SizedBox(height: 24),

                    // Champ de saisie
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom de la liste',
                        prefixIcon: Icon(
                          Icons.list_alt,
                          color: Colors.blue[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
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
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      autofocus: true,
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

                        // Bouton Sauvegarder
                        Expanded(
                          child: BlocBuilder<
                            ShoppingListBloc,
                            ShoppingListState
                          >(
                            builder: (dialogContext, state) {
                              final isLoading = state is ShoppingListLoading;
                              return ElevatedButton(
                                onPressed:
                                    isLoading
                                        ? null
                                        : () {
                                          if (nameController.text
                                              .trim()
                                              .isNotEmpty) {
                                            dialogContext
                                                .read<ShoppingListBloc>()
                                                .add(
                                                  UpdateShoppingList(
                                                    list.id,
                                                    nameController.text.trim(),
                                                  ),
                                                );
                                            Navigator.pop(dialogContext);
                                          }
                                        },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.blue[300],
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
                                          'Sauvegarder',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
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

  void _goToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen()),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Empêcher la fermeture accidentelle
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
                  // Icône de déconnexion
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      size: 40,
                      color: Colors.red[600],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Titre
                  Text(
                    'Déconnexion',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: 12),

                  // Message
                  Text(
                    'Voulez-vous vraiment vous déconnecter de votre compte ?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.4,
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

                      // Bouton Déconnecter
                      Expanded(
                        child: BlocConsumer<AuthBloc, AuthState>(
                          listener: (context, state) {
                            // Fermer le dialog quand la déconnexion est terminée
                            if (state is Unauthenticated ||
                                state is AuthFailure) {
                              Navigator.of(dialogContext).pop();
                            }
                          },
                          builder: (context, state) {
                            final isLoading = state is AuthLoading;

                            return ElevatedButton(
                              onPressed:
                                  isLoading
                                      ? null
                                      : () {
                                        print('🔴 Demande de déconnexion...');
                                        context.read<AuthBloc>().add(
                                          LogoutRequested(),
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
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : Text(
                                        'Déconnecter',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
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
