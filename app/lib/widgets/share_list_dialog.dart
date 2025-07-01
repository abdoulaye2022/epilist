// widgets/share_list_dialog.dart - WIDGET DE PARTAGE AVEC BRANCH.IO
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_event.dart';
import 'package:epilist/blocs/shared_list/shared_list_state.dart';
import 'package:epilist/models/shared_list.dart';
import 'package:epilist/services/branch_links_service.dart';

class ShareListDialog extends StatefulWidget {
  final int listId;
  final String listName;

  const ShareListDialog({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  State<ShareListDialog> createState() => _ShareListDialogState();
}

class _ShareListDialogState extends State<ShareListDialog> {
  SharePermission _selectedPermission = SharePermission.edit;
  int _expirationDays = 30;
  String? _generatedLink;
  bool _isGeneratingLink = false;

  final List<int> _expirationOptions = [7, 30, 60, 90];

  @override
  Widget build(BuildContext context) {
    return BlocListener<SharedListBloc, SharedListState>(
      listener: (context, state) {
        if (state is ShareLinkCreated) {
          setState(() {
            _generatedLink = state.shareUrl;
            _isGeneratingLink = false;
          });
        } else if (state is SharedListError) {
          setState(() {
            _isGeneratingLink = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${state.message}'),
              backgroundColor: Colors.red[600],
            ),
          );
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.share, color: Colors.blue[600], size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Partager la liste',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          widget.listName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Configuration des permissions
              Text(
                'Permissions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              ...SharePermission.values.map((permission) {
                return RadioListTile<SharePermission>(
                  value: permission,
                  groupValue: _selectedPermission,
                  onChanged: (value) {
                    setState(() {
                      _selectedPermission = value!;
                    });
                  },
                  title: Text(_getPermissionTitle(permission)),
                  subtitle: Text(_getPermissionDescription(permission)),
                  activeColor: Colors.blue[600],
                );
              }).toList(),

              const SizedBox(height: 24),

              // Configuration de l'expiration
              Text(
                'Expiration du lien',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                value: _expirationDays,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.schedule, color: Colors.grey[600]),
                ),
                items:
                    _expirationOptions.map((days) {
                      return DropdownMenuItem(
                        value: days,
                        child: Text('$days jours'),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _expirationDays = value!;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Bouton de génération du lien
              if (_generatedLink == null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isGeneratingLink ? null : _generateShareLink,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        _isGeneratingLink
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text(
                              'Générer le lien de partage',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),
                ),
              ] else ...[
                // Lien généré
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Lien de partage créé !',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _generatedLink!,
                                style: const TextStyle(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              onPressed:
                                  () => _copyToClipboard(_generatedLink!),
                              icon: Icon(
                                Icons.copy,
                                size: 18,
                                color: Colors.grey[600],
                              ),
                              tooltip: 'Copier',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Boutons de partage
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copyToClipboard(_generatedLink!),
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copier'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _shareLink(_generatedLink!),
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Partager'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Bouton pour générer un nouveau lien
                TextButton(
                  onPressed: () {
                    setState(() {
                      _generatedLink = null;
                    });
                  },
                  child: const Text('Générer un nouveau lien'),
                ),
              ],

              const SizedBox(height: 16),

              // Information de sécurité
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Le lien expire automatiquement après $_expirationDays jours. Vous pouvez révoquer l\'accès à tout moment.',
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPermissionTitle(SharePermission permission) {
    switch (permission) {
      case SharePermission.readOnly:
        return 'Lecture seule';
      case SharePermission.edit:
        return 'Modification';
      case SharePermission.admin:
        return 'Administration';
    }
  }

  String _getPermissionDescription(SharePermission permission) {
    switch (permission) {
      case SharePermission.readOnly:
        return 'Peut voir la liste mais pas la modifier';
      case SharePermission.edit:
        return 'Peut ajouter, modifier et marquer des articles';
      case SharePermission.admin:
        return 'Peut tout faire, y compris partager et supprimer';
    }
  }

  void _generateShareLink() {
    setState(() {
      _isGeneratingLink = true;
    });

    context.read<SharedListBloc>().add(
      CreateShareLink(
        listId: widget.listId,
        permission: _selectedPermission,
        expirationDays: _expirationDays,
      ),
    );
  }

  void _copyToClipboard(String link) {
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check, color: Colors.white),
            SizedBox(width: 8),
            Text('Lien copié dans le presse-papiers'),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareLink(String link) async {
    // Tracker l'événement de partage
    await BranchLinksService.trackShareEvent(
      shareToken: _extractTokenFromLink(link),
      listName: widget.listName,
      shareMethod: 'native_share',
    );

    // Créer les données de partage
    final shareData = BranchLinksService.createShareData(
      shareToken: _extractTokenFromLink(link),
      listName: widget.listName,
      ownerName: 'Vous', // Ou récupérer le nom de l'utilisateur actuel
      branchUrl: link,
    );

    // Partager via l'interface native
    await Share.share(link, subject: shareData['subject']);
  }

  String _extractTokenFromLink(String link) {
    // Extraire le token du lien Branch.io
    final uri = Uri.parse(link);
    return uri.pathSegments.last;
  }
}
