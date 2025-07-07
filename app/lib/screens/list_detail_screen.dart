// screens/list_detail_screen.dart - VERSION AVEC CARTES BLANCHES
import 'package:epilist/blocs/list_item/list_item_bloc.dart';
import 'package:epilist/models/shopping_list.dart';
import 'package:epilist/models/list_item.dart';
import 'package:epilist/services/list_item_service.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:epilist/widgets/dialogs/add_item_dialog.dart';
import 'package:epilist/widgets/list_detail/list_stats_header.dart';
import 'package:epilist/widgets/list_detail/empty_items_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListDetailScreen extends StatefulWidget {
  final ShoppingList shoppingList;

  const ListDetailScreen({super.key, required this.shoppingList});

  @override
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
      appBar: _buildAppBar(),
      body: BlocConsumer<ListItemBloc, ListItemState>(
        listener: (context, state) {
          // Utiliser SmartSnackBarManager pour gérer les notifications
          SmartSnackBarManager.showForState(context, state);
        },
        builder: (context, state) => _buildBody(state),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentList.name,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (currentList.isShared) _buildSharingSubtitle(),
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 1,
      actions: [
        if (currentList.canManageItems)
          IconButton(
            onPressed: _addNewItem,
            icon: Icon(Icons.add),
            tooltip: 'Ajouter un article',
          )
        else
          IconButton(
            onPressed: () => _showPermissionDenied('ajouter des articles'),
            icon: Icon(Icons.add, color: Colors.grey),
            tooltip: 'Permission insuffisante',
          ),
        _buildOptionsMenu(),
      ],
    );
  }

  Widget _buildSharingSubtitle() {
    String subtitle;
    Color color;

    if (currentList.isOwner) {
      subtitle = 'Liste partagée';
      color = Colors.blue[600]!;
    } else {
      subtitle = currentList.permissionDisplayName ?? 'Liste partagée';
      color = currentList.isReadOnly ? Colors.blue[600]! : Colors.green[600]!;
    }

    return Text(
      subtitle,
      style: TextStyle(
        fontSize: 12,
        color: color,
        fontWeight: FontWeight.normal,
      ),
    );
  }

  Widget _buildOptionsMenu() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert),
      onSelected: _handleMenuAction,
      itemBuilder:
          (context) => [
            if (currentList.canEdit)
              PopupMenuItem(
                value: 'edit_list',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: Colors.blue[600]),
                    SizedBox(width: 8),
                    Text('Modifier la liste'),
                  ],
                ),
              ),
            if (currentList.canShare)
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20, color: Colors.green[600]),
                    SizedBox(width: 8),
                    Text('Partager'),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text('Informations'),
                ],
              ),
            ),
            if (!currentList.isOwner || currentList.canDelete)
              PopupMenuDivider(),
            if (!currentList.isOwner)
              PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(
                      Icons.exit_to_app,
                      size: 20,
                      color: Colors.orange[600],
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Quitter',
                      style: TextStyle(color: Colors.orange[600]),
                    ),
                  ],
                ),
              ),
            if (currentList.canDelete)
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red[600]),
                    SizedBox(width: 8),
                    Text('Supprimer', style: TextStyle(color: Colors.red[600])),
                  ],
                ),
              ),
          ],
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit_list':
        if (currentList.canEdit) {
          // TODO: Naviguer vers l'écran d'édition de liste
          SmartSnackBarManager.showMessage(
            context,
            'Fonctionnalité d\'édition à venir',
            type: SnackBarType.info,
          );
        } else {
          _showPermissionDenied('modifier cette liste');
        }
        break;
      case 'share':
        if (currentList.canShare) {
          // TODO: Ouvrir le dialogue de partage
          SmartSnackBarManager.showMessage(
            context,
            'Fonctionnalité de partage à venir',
            type: SnackBarType.info,
          );
        } else {
          _showPermissionDenied('partager cette liste');
        }
        break;
      case 'info':
        _showListInfo();
        break;
      case 'leave':
        _showLeaveConfirmation();
        break;
      case 'delete':
        if (currentList.canDelete) {
          _showDeleteConfirmation();
        } else {
          _showPermissionDenied('supprimer cette liste');
        }
        break;
    }
  }

  Widget? _buildFloatingActionButton() {
    if (!currentList.canManageItems) return null;

    return FloatingActionButton(
      onPressed: _addNewItem,
      backgroundColor: Colors.green[600],
      child: Icon(Icons.add, color: Colors.white),
      tooltip: 'Ajouter un article',
    );
  }

  Widget _buildBody(ListItemState state) {
    List<ListItem> items = [];
    bool isLoading = false;

    if (state is ListItemLoading) {
      isLoading = true;
    } else if (state is ListItemLoaded) {
      items = state.items;
    }

    return Column(
      children: [
        if (!currentList.isOwner) _buildPermissionBanner(),
        ListStatsHeader(
          totalItems: items.length,
          purchasedItems: items.where((item) => item.isPurchased).length,
          totalPrice: items.fold(
            0.0,
            (sum, item) => sum + (item.price ?? 0) * item.quantity,
          ),
        ),
        Expanded(child: _buildContent(items, isLoading)),
      ],
    );
  }

  Widget _buildPermissionBanner() {
    Color bannerColor;
    String bannerText;
    IconData bannerIcon;

    if (currentList.isReadOnly) {
      bannerColor = Colors.blue;
      bannerText =
          'Mode lecture seule - Vous ne pouvez pas modifier cette liste';
      bannerIcon = Icons.visibility;
    } else if (currentList.canEdit) {
      bannerColor = Colors.green;
      bannerText = 'Liste partagée - Vous pouvez modifier les articles';
      bannerIcon = Icons.edit;
    } else {
      bannerColor = Colors.orange;
      bannerText = 'Accès limité à cette liste';
      bannerIcon = Icons.lock;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bannerColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(bannerIcon, size: 16, color: bannerColor),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              bannerText,
              style: TextStyle(
                fontSize: 13,
                color: bannerColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (currentList.sharedBy != null) ...[
            SizedBox(width: 8),
            Text(
              'Par ${currentList.sharedBy!.name}',
              style: TextStyle(
                fontSize: 12,
                color: bannerColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(List<ListItem> items, bool isLoading) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
        ),
      );
    }

    if (items.isEmpty) {
      return EmptyItemsState(
        shoppingList: currentList,
        onAddItem: currentList.canManageItems ? _addNewItem : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ListItemBloc>().add(LoadListItems(currentList.id));
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _buildItemCard(items[index]);
        },
      ),
    );
  }

  Widget _buildItemCard(ListItem item) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      // CORRECTION: Fond blanc pour toutes les cartes
      color: Colors.white,
      // Bordure spéciale si lecture seule
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side:
            currentList.isReadOnly
                ? BorderSide(color: Colors.blue[200]!, width: 1)
                : BorderSide.none,
      ),
      child: ListTile(
        leading: _buildCheckbox(item),
        title: Text(
          item.productName,
          style: TextStyle(
            decoration: item.isPurchased ? TextDecoration.lineThrough : null,
            color:
                currentList.isReadOnly
                    ? (item.isPurchased ? Colors.grey[500] : Colors.grey[700])
                    : (item.isPurchased ? Colors.grey : Colors.black87),
            fontWeight:
                currentList.isReadOnly ? FontWeight.normal : FontWeight.w500,
          ),
        ),
        subtitle: _buildItemSubtitle(item),
        trailing: _buildItemTrailing(item),
      ),
    );
  }

  Widget _buildCheckbox(ListItem item) {
    // En mode lecture seule, afficher un indicateur visuel
    if (currentList.isReadOnly) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: item.isPurchased ? Colors.green[100] : Colors.grey[100],
          border: Border.all(
            color: item.isPurchased ? Colors.green[300]! : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child:
            item.isPurchased
                ? Icon(Icons.check, size: 16, color: Colors.green[600])
                : null,
      );
    }

    return Checkbox(
      value: item.isPurchased,
      onChanged:
          currentList.canManageItems
              ? (value) {
                context.read<ListItemBloc>().add(
                  TogglePurchasedStatus(
                    listId: currentList.id,
                    itemId: item.id,
                    isPurchased: value!,
                  ),
                );
              }
              : (value) =>
                  _showPermissionDenied('modifier le statut des articles'),
      activeColor: Colors.green[600],
      fillColor:
          currentList.canManageItems
              ? null
              : MaterialStateProperty.all(Colors.grey[300]),
    );
  }

  Widget _buildItemSubtitle(ListItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Qté: ${item.quantity}',
              style: TextStyle(
                color:
                    currentList.isReadOnly
                        ? Colors.grey[500]
                        : Colors.grey[600],
              ),
            ),
            if (item.price != null) ...[
              Text(
                ' • ${_formatPrice(item.price!)}',
                style: TextStyle(
                  color:
                      currentList.isReadOnly
                          ? Colors.grey[500]
                          : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        if (item.storeName != null && item.storeName!.isNotEmpty) ...[
          SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.store,
                size: 12,
                color:
                    currentList.isReadOnly
                        ? Colors.grey[400]
                        : Colors.grey[600],
              ),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.storeName!,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        currentList.isReadOnly
                            ? Colors.grey[400]
                            : Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildItemTrailing(ListItem item) {
    // En mode lecture seule, afficher un badge
    if (currentList.isReadOnly) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility, size: 14, color: Colors.blue[600]),
            SizedBox(width: 4),
            Text(
              'Lecture seule',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return IconButton(
      icon: Icon(Icons.delete, color: Colors.red[400]),
      onPressed:
          currentList.canEdit
              ? () => _confirmDeleteItem(item)
              : () => _showPermissionDenied('supprimer des articles'),
      tooltip:
          currentList.canEdit
              ? 'Supprimer l\'article'
              : 'Permission insuffisante',
    );
  }

  // Méthodes de dialogue et d'action
  void _showPermissionDenied(String action) {
    String title;
    String message;
    String permission;

    if (currentList.isReadOnly) {
      title = 'Accès en lecture seule';
      permission = currentList.permissionDisplayName ?? 'Lecture seule';
      message =
          'Vous ne pouvez pas $action car cette liste est en mode lecture seule.\n\n'
          'Votre permission actuelle : $permission';
    } else {
      title = 'Permission insuffisante';
      permission = currentList.permissionDisplayName ?? 'Limitée';
      message =
          'Vous n\'avez pas la permission de $action.\n\n'
          'Votre permission actuelle : $permission';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                currentList.isReadOnly ? Icons.visibility : Icons.lock,
                color:
                    currentList.isReadOnly
                        ? Colors.blue[600]
                        : Colors.orange[600],
                size: 24,
              ),
              SizedBox(width: 8),
              Expanded(child: Text(title)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              SizedBox(height: 16),
              if (!currentList.isOwner && currentList.sharedBy != null) ...[
                Text(
                  'Cette liste a été partagée par ${currentList.sharedBy!.name}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Compris'),
            ),
          ],
        );
      },
    );
  }

  void _showListInfo() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 10,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildListInfoIcon(),
                  const SizedBox(height: 20),
                  _buildListInfoTitle(),
                  const SizedBox(height: 12),
                  _buildListInfoDescription(),
                  const SizedBox(height: 24),
                  _buildListInfoContent(),
                  const SizedBox(height: 24),
                  _buildListInfoButton(),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildListInfoIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(40),
      ),
      child: Icon(Icons.info_rounded, size: 40, color: Colors.blue[600]),
    );
  }

  Widget _buildListInfoTitle() {
    return const Text(
      'Informations de la liste',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildListInfoDescription() {
    return Text(
      'Détails et permissions de "${currentList.name}"',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
    );
  }

  Widget _buildListInfoContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRowStyled(
            'Nom',
            currentList.name,
            Icons.list_alt_rounded,
            Colors.blue[600]!,
          ),
          const SizedBox(height: 16),
          _buildInfoRowStyled(
            'Statut',
            currentList.isShared ? 'Partagée' : 'Privée',
            currentList.isShared ? Icons.people_rounded : Icons.lock_rounded,
            currentList.isShared ? Colors.green[600]! : Colors.orange[600]!,
          ),
          if (currentList.isShared) ...[
            const SizedBox(height: 16),
            _buildInfoRowStyled(
              'Votre rôle',
              currentList.isOwner
                  ? 'Propriétaire'
                  : (currentList.permissionDisplayName ?? 'Collaborateur'),
              currentList.isOwner ? Icons.crop_rounded : Icons.person_rounded,
              currentList.isOwner ? Colors.amber[600]! : Colors.purple[600]!,
            ),
            if (!currentList.isOwner && currentList.sharedBy != null) ...[
              const SizedBox(height: 16),
              _buildInfoRowStyled(
                'Partagée par',
                currentList.sharedBy!.name,
                Icons.share_rounded,
                Colors.teal[600]!,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRowStyled(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListInfoButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: const Text(
          'Fermer',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(child: Text(value, style: TextStyle(color: Colors.black87))),
      ],
    );
  }

  void _showLeaveConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Quitter la liste'),
            content: Text(
              'Êtes-vous sûr de vouloir quitter "${currentList.name}" ?\n\n'
              'Vous perdrez l\'accès à cette liste et ne pourrez plus voir son contenu.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  SmartSnackBarManager.showMessage(
                    context,
                    'Vous avez quitté la liste "${currentList.name}"',
                    type: SnackBarType.warning,
                  );
                  Navigator.of(context).pop(); // Retour à l'écran précédent
                },
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                child: Text('Quitter'),
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Supprimer la liste'),
            content: Text(
              'Êtes-vous sûr de vouloir supprimer "${currentList.name}" ?\n\n'
              'Cette action est irréversible et supprimera tous les articles.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  SmartSnackBarManager.showMessage(
                    context,
                    'Liste "${currentList.name}" supprimée',
                    type: SnackBarType.success,
                  );
                  Navigator.of(context).pop(); // Retour à l'écran précédent
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Supprimer'),
              ),
            ],
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
                  Text(
                    'Supprimer l\'article',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12),
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
                  Row(
                    children: [
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
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
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
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            'Supprimer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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
    if (!currentList.canManageItems) {
      _showPermissionDenied('ajouter des articles');
      return;
    }

    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<ListItemBloc>(),
            child: AddItemDialog(listId: currentList.id),
          ),
    );
  }
}
