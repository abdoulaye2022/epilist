// screens/shopping_list_screen.dart - VERSION FINALE COMPLÈTE AVEC PARTAGE
import 'package:epilist/blocs/shared_list/shared_list_event.dart';
import 'package:epilist/blocs/shared_list/shared_list_state.dart';
import 'package:epilist/blocs/shopping_list/shopping_list_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/screens/list_detail_screen.dart';
import 'package:epilist/widgets/share_list_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
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
      body: MultiBlocListener(
        listeners: [
          // Listener pour les opérations de liste
          BlocListener<ShoppingListBloc, ShoppingListState>(
            listener: (context, state) {
              if (state is ShoppingListError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ ${state.message}'),
                    backgroundColor: Colors.red[600],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: EdgeInsets.all(16),
                    duration: Duration(seconds: 3),
                  ),
                );
              } else if (state is ShoppingListOperationSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ ${state.message}'),
                    backgroundColor: Colors.green[600],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: EdgeInsets.all(16),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          // Listener pour les opérations de partage
          BlocListener<SharedListBloc, SharedListState>(
            listener: (context, state) {
              if (state is SharedListError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ ${state.message}'),
                    backgroundColor: Colors.red[600],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: EdgeInsets.all(16),
                    duration: Duration(seconds: 3),
                  ),
                );
              } else if (state is ShareOperationSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ ${state.message}'),
                    backgroundColor: Colors.blue[600],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: EdgeInsets.all(16),
                    duration: Duration(seconds: 2),
                  ),
                );
                // Recharger les listes après une opération de partage
                context.read<ShoppingListBloc>().add(LoadShoppingLists());
              }
            },
          ),
        ],
        child: BlocBuilder<ShoppingListBloc, ShoppingListState>(
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                        context.read<ShoppingListBloc>().add(
                          LoadShoppingLists(),
                        );
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
        // Bordure pour les listes partagées
        border:
            list.isShared
                ? Border.all(
                  color: list.isOwner ? Colors.blue[200]! : Colors.green[200]!,
                  width: 1,
                )
                : null,
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
                    child: Row(
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
                        // Indicateur de partage
                        if (list.isShared) ...[
                          SizedBox(width: 8),
                          _buildSharingIndicator(list),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                    itemBuilder: (context) => _buildMenuItems(list),
                    onSelected:
                        (value) => _handleListAction(value.toString(), list),
                  ),
                ],
              ),

              SizedBox(height: 8),

              // Informations de base et partage
              Row(
                children: [
                  Text(
                    '${_formatDate(list.createdAt)} • $totalItems articles',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  if (list.isShared) ...[
                    Text(' • ', style: TextStyle(color: Colors.grey[600])),
                    Text(
                      list.sharingStatus,
                      style: TextStyle(
                        color:
                            list.isOwner ? Colors.blue[600] : Colors.green[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),

              // Propriétaire si ce n'est pas l'utilisateur
              if (!list.isOwner && list.owner != null) ...[
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.grey[500]),
                    SizedBox(width: 4),
                    Text(
                      'Propriétaire: ${list.owner!.name}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],

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

              // Status et permissions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          list.isCompleted
                              ? Colors.green[50]
                              : Colors.orange[50],
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
                  // Indicateur de permissions pour les listes partagées
                  if (!list.isOwner) _buildPermissionIndicator(list),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget pour l'indicateur de partage
  Widget _buildSharingIndicator(ShoppingList list) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: list.isOwner ? Colors.blue[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: list.isOwner ? Colors.blue[200]! : Colors.green[200]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            list.isOwner ? Icons.people : Icons.share,
            size: 12,
            color: list.isOwner ? Colors.blue[600] : Colors.green[600],
          ),
          if (list.isOwner) ...[
            SizedBox(width: 2),
            Text(
              '${list.sharedWithCount}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Widget pour l'indicateur de permissions
  Widget _buildPermissionIndicator(ShoppingList list) {
    String text;
    Color color;
    IconData icon;

    if (list.isReadOnly) {
      text = 'Lecture seule';
      color = Colors.blue[600]!;
      icon = Icons.visibility;
    } else if (list.canEdit) {
      text = 'Modification';
      color = Colors.green[600]!;
      icon = Icons.edit;
    } else {
      text = 'Admin';
      color = Colors.purple[600]!;
      icon = Icons.admin_panel_settings;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Construction des éléments du menu contextuel
  List<PopupMenuEntry<String>> _buildMenuItems(ShoppingList list) {
    List<PopupMenuEntry<String>> items = [];

    // Modifier (seulement si l'utilisateur peut éditer)
    if (list.canEdit) {
      items.add(
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
      );
    }

    // Dupliquer (toujours disponible)
    items.add(
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
    );

    // Partager (seulement si l'utilisateur peut partager)
    if (list.canShare) {
      items.add(
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, size: 20, color: Colors.blue[600]),
              SizedBox(width: 8),
              Text('Partager', style: TextStyle(color: Colors.blue[600])),
            ],
          ),
        ),
      );
    }

    // Gérer les partages (seulement pour le propriétaire de listes partagées)
    if (list.isOwner && list.isShared) {
      items.add(
        PopupMenuItem(
          value: 'manage_shares',
          child: Row(
            children: [
              Icon(Icons.people_outline, size: 20, color: Colors.purple[600]),
              SizedBox(width: 8),
              Text(
                'Gérer les partages',
                style: TextStyle(color: Colors.purple[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Séparateur avant les actions destructives
    if (list.canDelete || !list.isOwner) {
      items.add(PopupMenuDivider());
    }

    // Quitter (pour les listes partagées où l'utilisateur n'est pas propriétaire)
    if (!list.isOwner) {
      items.add(
        PopupMenuItem(
          value: 'leave',
          child: Row(
            children: [
              Icon(Icons.exit_to_app, size: 20, color: Colors.orange),
              SizedBox(width: 8),
              Text('Quitter', style: TextStyle(color: Colors.orange)),
            ],
          ),
        ),
      );
    }

    // Supprimer (seulement si l'utilisateur peut supprimer)
    if (list.canDelete) {
      items.add(
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red),
              SizedBox(width: 8),
              Text('Supprimer', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      );
    }

    return items;
  }

  void _createNewList() {
    final nameController = TextEditingController();

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
                      'Nouvelle liste de courses',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    SizedBox(height: 12),

                    // Message
                    Text(
                      'Donnez un nom à votre nouvelle liste de courses',
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
        if (list.canEdit) {
          _editListName(list);
        }
        break;
      case 'duplicate':
        context.read<ShoppingListBloc>().add(DuplicateShoppingList(list.id));
        break;
      case 'share':
        if (list.canShare) {
          _showShareDialog(list);
        }
        break;
      case 'manage_shares':
        if (list.isOwner && list.isShared) {
          _showManageSharesDialog(list);
        }
        break;
      case 'leave':
        if (!list.isOwner) {
          _leaveSharedList(list);
        }
        break;
      case 'delete':
        if (list.canDelete) {
          _deleteList(list);
        }
        break;
    }
  }

  // Afficher le dialogue de partage
  void _showShareDialog(ShoppingList list) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<SharedListBloc>(),
            child: ShareListDialog(listId: list.id, listName: list.name),
          ),
    );
  }

  // Afficher le dialogue de gestion des partages
  void _showManageSharesDialog(ShoppingList list) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<SharedListBloc>(),
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: EdgeInsets.all(20),
                constraints: BoxConstraints(maxHeight: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Gérer les partages',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: Icon(Icons.close),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Liste: ${list.name}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child:
                          list.sharedWith.isEmpty
                              ? Center(
                                child: Text(
                                  'Aucun partage actif',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              )
                              : ListView.builder(
                                itemCount: list.sharedWith.length,
                                itemBuilder: (context, index) {
                                  final share = list.sharedWith[index];
                                  return Card(
                                    margin: EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.blue[100],
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.blue[600],
                                        ),
                                      ),
                                      title: Text(
                                        share.sharedWithUser?.name ??
                                            'Utilisateur',
                                      ),
                                      subtitle: Text(
                                        share.sharedWithUser?.email ?? '',
                                      ),
                                      trailing: PopupMenuButton(
                                        icon: Icon(Icons.more_vert),
                                        itemBuilder:
                                            (context) => [
                                              PopupMenuItem(
                                                value: 'change_permission',
                                                child: Text(
                                                  'Modifier permissions',
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 'revoke',
                                                child: Text(
                                                  'Révoquer',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                        onSelected: (value) {
                                          if (value == 'revoke') {
                                            context.read<SharedListBloc>().add(
                                              RevokeShare(share.id),
                                            );
                                            Navigator.pop(dialogContext);
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _showShareDialog(list);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                        ),
                        child: Text(
                          'Créer un nouveau partage',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  // Quitter une liste partagée
  void _leaveSharedList(ShoppingList list) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.exit_to_app, color: Colors.orange[600]),
                SizedBox(width: 8),
                Text('Quitter la liste'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Êtes-vous sûr de vouloir quitter "${list.name}" ?'),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange[600], size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Vous perdrez l\'accès à cette liste et à tous ses éléments.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<SharedListBloc>().add(LeaveSharedList(list.id));
                  Navigator.pop(dialogContext);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                ),
                child: Text('Quitter', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  void _editListName(ShoppingList list) {
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
                      'Modifiez le nom de votre liste de courses',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),

                    if (list.isShared) ...[
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue[600], size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Cette liste est partagée. Le nouveau nom sera visible par tous les collaborateurs.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

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

  void _deleteList(ShoppingList list) {
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

                    // Message principal
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

                    // Avertissement
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_rounded,
                            color: Colors.red[600],
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Cette action est irréversible',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Avertissement de partage
                    if (list.isShared) ...[
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber[200]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  color: Colors.amber[700],
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Cette liste est partagée avec ${list.sharedWithCount} personne${list.sharedWithCount > 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.amber[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Les autres utilisateurs perdront également l\'accès à cette liste.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.amber[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Afficher les statistiques de la liste si elle contient des éléments
                    if (list.itemsCount > 0) ...[
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue[700],
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Cette liste contient ${list.itemsCount} article${list.itemsCount > 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (list.totalPrice > 0) ...[
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.attach_money,
                                    color: Colors.blue[700],
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Budget estimé: ${list.totalPrice.toStringAsFixed(2)} \$CAD',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

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
