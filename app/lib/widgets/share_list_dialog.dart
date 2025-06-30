// widgets/share_list_dialog.dart
import 'package:epilist/blocs/shared_list/shared_list_event.dart';
import 'package:epilist/blocs/shared_list/shared_list_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:epilist/models/shared_list.dart';
import 'package:share_plus/share_plus.dart';

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
          setState(() => _isGeneratingLink = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${state.message}'),
              backgroundColor: Colors.red[600],
            ),
          );
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Icon(
                        Icons.share,
                        color: Colors.green[600],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

                if (_generatedLink == null) ...[
                  // Configuration du partage
                  Text(
                    'Permissions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sélection des permissions
                  _buildPermissionSelector(),

                  const SizedBox(height: 24),

                  // Durée d'expiration
                  Text(
                    'Expiration',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildExpirationSelector(),

                  const SizedBox(height: 32),

                  // Bouton générer le lien
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isGeneratingLink ? null : _generateShareLink,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                  _buildGeneratedLink(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionSelector() {
    return Column(
      children:
          SharePermission.values.map((permission) {
            String title;
            String description;
            IconData icon;
            Color color;

            switch (permission) {
              case SharePermission.readOnly:
                title = 'Lecture seule';
                description = 'Peut voir la liste mais pas la modifier';
                icon = Icons.visibility;
                color = Colors.blue[600]!;
                break;
              case SharePermission.edit:
                title = 'Modification';
                description = 'Peut ajouter et modifier des articles';
                icon = Icons.edit;
                color = Colors.green[600]!;
                break;
              case SharePermission.admin:
                title = 'Administration';
                description = 'Contrôle total sur la liste';
                icon = Icons.admin_panel_settings;
                color = Colors.purple[600]!;
                break;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      _selectedPermission == permission
                          ? color
                          : Colors.grey[300]!,
                  width: _selectedPermission == permission ? 2 : 1,
                ),
                color:
                    _selectedPermission == permission
                        ? color.withOpacity(0.05)
                        : Colors.white,
              ),
              child: RadioListTile<SharePermission>(
                value: permission,
                groupValue: _selectedPermission,
                onChanged: (value) {
                  setState(() => _selectedPermission = value!);
                },
                activeColor: color,
                title: Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                controlAffinity: ListTileControlAffinity.trailing,
              ),
            );
          }).toList(),
    );
  }

  Widget _buildExpirationSelector() {
    final options = [
      {'days': 1, 'label': '1 jour'},
      {'days': 7, 'label': '1 semaine'},
      {'days': 30, 'label': '1 mois'},
      {'days': 90, 'label': '3 mois'},
      {'days': 365, 'label': '1 an'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          options.map((option) {
            final days = option['days'] as int;
            final label = option['label'] as String;
            final isSelected = _expirationDays == days;

            return GestureDetector(
              onTap: () => setState(() => _expirationDays = days),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green[600] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.green[600]! : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildGeneratedLink() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Succès
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Lien de partage généré avec succès !',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Lien généré
        Text(
          'Lien de partage',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _generatedLink!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontFamily: 'monospace',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => _copyToClipboard(_generatedLink!),
                icon: Icon(Icons.copy, color: Colors.grey[600]),
                tooltip: 'Copier',
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Résumé des permissions
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[600], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Paramètres du partage',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Permission: ${_getPermissionDisplayName(_selectedPermission)}',
                style: TextStyle(fontSize: 13, color: Colors.blue[700]),
              ),
              Text(
                'Expire dans: ${_expirationDays} jour${_expirationDays > 1 ? 's' : ''}',
                style: TextStyle(fontSize: 13, color: Colors.blue[700]),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Boutons d'action
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _shareLink(_generatedLink!),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.green[600]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.share, color: Colors.green[600], size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Partager',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _copyToClipboard(_generatedLink!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.copy, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Copier',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Générer un nouveau lien
        TextButton(
          onPressed: () {
            setState(() {
              _generatedLink = null;
              _isGeneratingLink = false;
            });
          },
          child: Text(
            'Générer un nouveau lien',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
      ],
    );
  }

  void _generateShareLink() {
    setState(() => _isGeneratingLink = true);
    context.read<SharedListBloc>().add(
      CreateShareLink(
        listId: widget.listId,
        permission: _selectedPermission,
        expirationDays: _expirationDays,
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Text('Lien copié dans le presse-papiers'),
          ],
        ),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _shareLink(String link) {
    Share.share(
      'Rejoignez ma liste de courses "${widget.listName}" sur EpiList :\n$link',
      subject: 'Invitation - Liste de courses ${widget.listName}',
    );
  }

  String _getPermissionDisplayName(SharePermission permission) {
    switch (permission) {
      case SharePermission.readOnly:
        return 'Lecture seule';
      case SharePermission.edit:
        return 'Modification';
      case SharePermission.admin:
        return 'Administration';
    }
  }
}
