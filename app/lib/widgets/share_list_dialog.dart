// widgets/share_list_dialog.dart - VERSION AVEC DESIGN COHÉRENT
import 'package:epilist/models/shared_enums.dart';
import 'package:epilist/utils/smart_snackbar_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_event.dart';
import 'package:epilist/blocs/shared_list/shared_list_state.dart';
import 'package:epilist/services/deep_link_handler.dart';

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
  String? _shareToken;

  final List<int> _expirationOptions = [7, 30, 60, 90];

  @override
  Widget build(BuildContext context) {
    return BlocListener<SharedListBloc, SharedListState>(
      listener: (context, state) {
        if (state is ShareLinkCreated) {
          setState(() {
            _generatedLink = state.shareUrl;
            _shareToken = _extractTokenFromLink(state.shareUrl);
            _isGeneratingLink = false;
          });

          SmartSnackBarManager.showSuccessSnackBar(
            context,
            'Lien de partage créé avec succès !',
            duration: const Duration(seconds: 2),
          );
        } else if (state is SharedListError) {
          setState(() {
            _isGeneratingLink = false;
          });

          SmartSnackBarManager.showErrorSnackBar(
            context,
            state.message,
            duration: const Duration(seconds: 3),
          );
        }
      },
      child: Dialog(
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
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIcon(),
                const SizedBox(height: 20),
                _buildTitle(),
                const SizedBox(height: 12),
                _buildDescription(),
                const SizedBox(height: 24),
                _buildPermissionsSection(),
                const SizedBox(height: 20),
                _buildExpirationSection(),
                const SizedBox(height: 24),
                if (_generatedLink == null)
                  _buildGenerateLinkSection()
                else
                  _buildGeneratedLinkSection(),
                const SizedBox(height: 16),
                _buildInfoSection(),
                const SizedBox(height: 24),
                _buildButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
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
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Partager la liste',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      'Créez un lien de partage pour "${widget.listName}"',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey[600],
        height: 1.4,
      ),
    );
  }

  Widget _buildPermissionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Permissions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: SharePermission.values.asMap().entries.map((entry) {
              final index = entry.key;
              final permission = entry.value;
              final isSelected = _selectedPermission == permission;
              
              return Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[50] : Colors.transparent,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(index == 0 ? 12 : 0),
                    topRight: Radius.circular(index == 0 ? 12 : 0),
                    bottomLeft: Radius.circular(
                      index == SharePermission.values.length - 1 ? 12 : 0,
                    ),
                    bottomRight: Radius.circular(
                      index == SharePermission.values.length - 1 ? 12 : 0,
                    ),
                  ),
                ),
                child: RadioListTile<SharePermission>(
                  value: permission,
                  groupValue: _selectedPermission,
                  onChanged: (value) {
                    setState(() {
                      _selectedPermission = value!;
                    });
                  },
                  title: Text(
                    _getPermissionTitle(permission),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.blue[700] : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    _getPermissionDescription(permission),
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.blue[600] : Colors.grey[600],
                    ),
                  ),
                  activeColor: Colors.blue[600],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildExpirationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expiration du lien',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: _expirationDays,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.schedule_outlined, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          items: _expirationOptions.map((days) {
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
      ],
    );
  }

  Widget _buildGenerateLinkSection() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isGeneratingLink ? null : _generateShareLink,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.blue[300],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _isGeneratingLink
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Création...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
      ],
    );
  }

  Widget _buildGeneratedLinkSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle_outline, 
                       color: Colors.green[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Lien créé avec succès',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                        _generatedLink!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _copyToClipboard(_generatedLink!),
                      icon: Icon(Icons.copy_outlined, 
                                 color: Colors.grey[600], size: 18),
                      tooltip: 'Copier',
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _copyToClipboard(_generatedLink!),
                icon: const Icon(Icons.copy_outlined, size: 18),
                label: const Text('Copier'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey[400]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _shareLink(_generatedLink!),
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text('Partager'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber[700], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Le lien expire après $_expirationDays jours. Vous pouvez révoquer l\'accès à tout moment.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: _isGeneratingLink ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Text(
              'Fermer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
        ),
        if (_generatedLink != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _generatedLink = null;
                  _shareToken = null;
                });
              },
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
                'Nouveau lien',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
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
    SmartSnackBarManager.showSuccessSnackBar(
      context,
      'Lien copié dans le presse-papiers !',
      duration: const Duration(seconds: 2),
    );
  }

  void _shareLink(String link) async {
    try {
      if (_shareToken != null) {
        final shareData = DeepLinkHandler.generateShareData(
          _shareToken!,
          widget.listName,
          'Vous',
        );
        await Share.share(link, subject: shareData['subject']);
      } else {
        await Share.share(
          link,
          subject: 'Invitation EpiList - ${widget.listName}',
        );
      }
    } catch (e) {
      SmartSnackBarManager.showErrorSnackBar(
        context,
        'Erreur lors du partage',
        duration: const Duration(seconds: 2),
      );
    }
  }

  String? _extractTokenFromLink(String link) {
    try {
      return DeepLinkHandler.extractTokenFromLink(link);
    } catch (e) {
      return null;
    }
  }
}