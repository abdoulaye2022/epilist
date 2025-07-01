// widgets/share_list_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_event.dart';
import 'package:epilist/blocs/shared_list/shared_list_state.dart';
import 'package:epilist/models/shared_list.dart';
import 'package:epilist/services/deep_link_handler.dart';
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
  int _selectedExpirationDays = 30;
  String? _generatedShareUrl;

  final List<int> _expirationOptions = [7, 14, 30, 60, 90];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: BlocConsumer<SharedListBloc, SharedListState>(
          listener: (context, state) {
            if (state is ShareLinkCreated) {
              setState(() {
                _generatedShareUrl = state.shareUrl;
              });
            } else if (state is SharedListError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ ${state.message}'),
                  backgroundColor: Colors.red[600],
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is SharedListLoading;

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icône et titre
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Icon(
                      Icons.share_rounded,
                      size: 40,
                      color: Colors.blue[600],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Partager la liste',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Créez un lien de partage pour "${widget.listName}"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Configuration des permissions
                  if (_generatedShareUrl == null) ...[
                    _buildPermissionSection(),
                    const SizedBox(height: 20),
                    _buildExpirationSection(),
                    const SizedBox(height: 24),
                    _buildActionButtons(isLoading),
                  ] else ...[
                    _buildShareUrlSection(),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPermissionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Permissions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),

        // Options de permissions
        ...SharePermission.values.map((permission) {
          return RadioListTile<SharePermission>(
            title: Text(_getPermissionTitle(permission)),
            subtitle: Text(
              _getPermissionDescription(permission),
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            value: permission,
            groupValue: _selectedPermission,
            onChanged: (SharePermission? value) {
              if (value != null) {
                setState(() {
                  _selectedPermission = value;
                });
              }
            },
            activeColor: _getPermissionColor(permission),
            contentPadding: EdgeInsets.zero,
          );
        }),
      ],
    );
  }

  Widget _buildExpirationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expiration',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedExpirationDays,
              isExpanded: true,
              items:
                  _expirationOptions.map((days) {
                    return DropdownMenuItem<int>(
                      value: days,
                      child: Text(_getExpirationText(days)),
                    );
                  }).toList(),
              onChanged: (int? value) {
                if (value != null) {
                  setState(() {
                    _selectedExpirationDays = value;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isLoading) {
    return Row(
      children: [
        // Bouton Annuler
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
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

        const SizedBox(width: 12),

        // Bouton Créer le lien
        Expanded(
          child: ElevatedButton(
            onPressed: isLoading ? null : _createShareLink,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.blue[300],
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child:
                isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Text(
                      'Créer le lien',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildShareUrlSection() {
    return Column(
      children: [
        // URL générée
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.link, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Lien de partage créé',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // URL
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _generatedShareUrl!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _copyToClipboard(_generatedShareUrl!),
                      icon: Icon(Icons.copy, color: Colors.blue[600]),
                      tooltip: 'Copier',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Informations du partage
              _buildShareInfo(),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Boutons de partage
        _buildShareButtons(),

        const SizedBox(height: 16),

        // Boutons d'action finaux
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _generatedShareUrl = null;
                  });
                },
                child: const Text('Créer un autre lien'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                ),
                child: const Text(
                  'Terminé',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShareInfo() {
    return Column(
      children: [
        _buildInfoRow(
          icon: Icons.security,
          title: 'Permissions',
          value: _getPermissionTitle(_selectedPermission),
          valueColor: _getPermissionColor(_selectedPermission),
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          icon: Icons.schedule,
          title: 'Expire',
          value: _getExpirationText(_selectedExpirationDays),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$title: ',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildShareButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Partager via',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            // Bouton partage système
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _shareViaSystem,
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Partager'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Bouton copier
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _copyToClipboard(_generatedShareUrl!),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copier'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.blue[300]!),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _createShareLink() {
    context.read<SharedListBloc>().add(
      CreateShareLink(
        listId: widget.listId,
        permission: _selectedPermission,
        expirationDays: _selectedExpirationDays,
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
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

  void _shareViaSystem() {
    if (_generatedShareUrl != null) {
      // Utiliser les nouvelles méthodes du DeepLinkHandler
      final shareData = DeepLinkHandler.generateShareData(
        DeepLinkHandler.extractTokenFromLink(_generatedShareUrl!)!,
        widget.listName,
        'Vous', // Ou récupérer le nom de l'utilisateur actuel
      );

      Share.share(
        '${shareData['text']}\n\n${shareData['url']}',
        subject: shareData['subject'],
      );
    }
  }

  // 🆕 FONCTIONS MANQUANTES

  /// Retourne la couleur associée à chaque type de permission
  Color _getPermissionColor(SharePermission permission) {
    switch (permission) {
      case SharePermission.readOnly:
        return Colors.blue[600]!;
      case SharePermission.edit:
        return Colors.green[600]!;
      case SharePermission.admin:
        return Colors.purple[600]!;
    }
  }

  /// Retourne le texte d'expiration formaté
  String _getExpirationText(int days) {
    if (days == 7) return 'Dans 1 semaine';
    if (days == 14) return 'Dans 2 semaines';
    if (days == 30) return 'Dans 1 mois';
    if (days == 60) return 'Dans 2 mois';
    if (days == 90) return 'Dans 3 mois';
    return 'Dans $days jours';
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
        return 'Peut ajouter et modifier des articles';
      case SharePermission.admin:
        return 'Peut tout faire, y compris supprimer la liste';
    }
  }
}
