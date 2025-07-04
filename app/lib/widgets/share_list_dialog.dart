// widgets/share_list_dialog.dart - VERSION RESPONSIVE SANS DÉBORDEMENT
import 'package:epilist/models/shared_enums.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 400;
    final isMobile = screenWidth < 600;

    return BlocListener<SharedListBloc, SharedListState>(
      listener: (context, state) {
        if (state is ShareLinkCreated) {
          setState(() {
            _generatedLink = state.shareUrl;
            _shareToken = _extractTokenFromLink(state.shareUrl);
            _isGeneratingLink = false;
          });

          _showSuccessMessage('Lien de partage créé avec succès !');
        } else if (state is SharedListError) {
          setState(() {
            _isGeneratingLink = false;
          });

          _showErrorMessage(state.message);
        } else if (state is SharedListLoading && _isGeneratingLink) {
          debugPrint('🔄 Génération du lien en cours...');
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 40,
          vertical: 24,
        ),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxWidth: isMobile ? screenWidth - 32 : 500,
            maxHeight: screenHeight - 100,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Contenu dans un Flexible pour éviter le débordement
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête responsive
                      _buildHeader(isSmallScreen),

                      SizedBox(height: isMobile ? 16 : 24),

                      // Configuration des permissions
                      _buildPermissionsSection(isMobile),

                      SizedBox(height: isMobile ? 16 : 24),

                      // Configuration de l'expiration
                      _buildExpirationSection(),

                      SizedBox(height: isMobile ? 16 : 24),

                      // Section génération/affichage du lien
                      if (_generatedLink == null)
                        _buildGenerateLinkSection(isMobile)
                      else
                        _buildGeneratedLinkSection(isMobile),

                      SizedBox(height: isMobile ? 12 : 16),

                      // Informations
                      _buildInfoSections(isMobile),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.share,
            color: Colors.blue[600],
            size: isSmallScreen ? 20 : 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Partager la liste',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                widget.listName,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          iconSize: isSmallScreen ? 20 : 24,
        ),
      ],
    );
  }

  Widget _buildPermissionsSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Permissions',
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...SharePermission.values.map((permission) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
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
                style: TextStyle(fontSize: isMobile ? 14 : 16),
              ),
              subtitle: Text(
                _getPermissionDescription(permission),
                style: TextStyle(fontSize: isMobile ? 12 : 14),
              ),
              activeColor: Colors.blue[600],
              contentPadding: EdgeInsets.zero,
              dense: isMobile,
            ),
          );
        }).toList(),
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
            fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _expirationDays,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: Icon(Icons.schedule, color: Colors.grey[600]),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
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
      ],
    );
  }

  Widget _buildGenerateLinkSection(bool isMobile) {
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
              padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child:
                _isGeneratingLink
                    ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: isMobile ? 16 : 20,
                          width: isMobile ? 16 : 20,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Création...',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                    : Text(
                      isMobile
                          ? 'Générer le lien'
                          : 'Générer le lien de partage',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.link, color: Colors.blue[600], size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Lien universel avec redirection automatique',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratedLinkSection(bool isMobile) {
    return Column(
      children: [
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
                  Icon(Icons.check_circle, color: Colors.green[600], size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Lien créé !',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'App',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _generatedLink!,
                        style: const TextStyle(fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () => _copyToClipboard(_generatedLink!),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.copy,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Boutons de partage adaptés
        if (isMobile)
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _copyToClipboard(_generatedLink!),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copier'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _shareLink(_generatedLink!),
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Partager'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyToClipboard(_generatedLink!),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copier'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _shareLink(_generatedLink!),
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Partager'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _generatedLink = null;
              _shareToken = null;
            });
          },
          icon: const Icon(Icons.refresh, size: 14),
          label: Text(
            'Nouveau lien',
            style: TextStyle(fontSize: isMobile ? 12 : 14),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSections(bool isMobile) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 8 : 12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Expire après $_expirationDays jours. Vous pouvez révoquer l\'accès à tout moment.',
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 11,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(isMobile ? 8 : 12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.smartphone, color: Colors.green[600], size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Ouvre l\'app si installée, sinon redirige vers le store.',
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 11,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
        ),
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

    debugPrint('🔄 Démarrage de la génération du lien de partage...');
    debugPrint('📋 Liste: ${widget.listName} (ID: ${widget.listId})');
    debugPrint('🔐 Permission: $_selectedPermission');
    debugPrint('⏰ Expiration: $_expirationDays jours');

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
    _showSuccessMessage('Lien copié !');
  }

  void _shareLink(String link) async {
    debugPrint('📤 Partage du lien: $link');

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

      debugPrint('✅ Partage lancé avec succès');
    } catch (e) {
      debugPrint('❌ Erreur lors du partage: $e');
      _showErrorMessage('Erreur lors du partage');
    }
  }

  String? _extractTokenFromLink(String link) {
    try {
      return DeepLinkHandler.extractTokenFromLink(link);
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'extraction du token: $e');
      return null;
    }
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
        action: SnackBarAction(
          label: 'Réessayer',
          textColor: Colors.white,
          onPressed: () {
            if (!_isGeneratingLink && _generatedLink == null) {
              _generateShareLink();
            }
          },
        ),
      ),
    );
  }
}
