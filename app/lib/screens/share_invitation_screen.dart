// screens/share_invitation_screen.dart - VERSION AVEC VALIDATION API
import 'package:epilist/blocs/shared_list/shared_list_event.dart';
import 'package:epilist/blocs/shared_list/shared_list_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/shared_list/shared_list_bloc.dart';
import 'package:epilist/models/shared_list.dart';
import 'package:epilist/screens/list_detail_screen.dart';
import 'package:epilist/screens/home_screen.dart';

class ShareInvitationScreen extends StatefulWidget {
  final String shareToken;

  const ShareInvitationScreen({super.key, required this.shareToken});

  @override
  State<ShareInvitationScreen> createState() => _ShareInvitationScreenState();
}

class _ShareInvitationScreenState extends State<ShareInvitationScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('🔍 ShareInvitationScreen - Token reçu: ${widget.shareToken}');

    // ✅ Charger l'invitation via l'API
    context.read<SharedListBloc>().add(LoadShareInvitation(widget.shareToken));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Invitation de partage'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // Retourner à l'écran d'accueil au lieu de pop
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: BlocConsumer<SharedListBloc, SharedListState>(
        listener: (context, state) {
          if (state is ShareInvitationAccepted) {
            debugPrint('✅ Invitation acceptée, redirection vers la liste');

            // Afficher un message de succès
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Invitation acceptée avec succès !'),
                  ],
                ),
                backgroundColor: Colors.green[600],
                duration: const Duration(seconds: 2),
              ),
            );

            // Rediriger vers la liste acceptée
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        ListDetailScreen(shoppingList: state.shoppingList),
              ),
            );
          } else if (state is ShareInvitationDeclined) {
            debugPrint('✅ Invitation refusée');

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Invitation refusée'),
                  ],
                ),
                backgroundColor: Colors.orange[600],
                duration: const Duration(seconds: 2),
              ),
            );

            // Retourner à l'écran d'accueil
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
              }
            });
          } else if (state is SharedListError) {
            debugPrint('❌ Erreur: ${state.message}');

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text('❌ ${state.message}')),
                  ],
                ),
                backgroundColor: Colors.red[600],
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SharedListLoading) {
            return _buildLoadingContent();
          }

          if (state is ShareInvitationLoaded) {
            debugPrint('✅ Invitation chargée: ${state.invitation.listName}');
            return _buildInvitationContent(state.invitation);
          }

          if (state is SharedListError) {
            return _buildErrorContent(state.message);
          }

          return _buildLoadingContent();
        },
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation de chargement
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.green,
                strokeWidth: 3,
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Validation de l\'invitation...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Vérification du token de partage',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),

          const SizedBox(height: 32),

          // Informations sur le token (pour debug)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'Token',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.shareToken,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[800],
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationContent(ShareInvitation invitation) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // ✅ Statut de l'invitation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: invitation.isExpired ? Colors.red[50] : Colors.green[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    invitation.isExpired
                        ? Colors.red[200]!
                        : Colors.green[200]!,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  invitation.isExpired ? Icons.warning : Icons.check_circle,
                  size: 16,
                  color:
                      invitation.isExpired
                          ? Colors.red[600]
                          : Colors.green[600],
                ),
                const SizedBox(width: 6),
                Text(
                  invitation.isExpired ? 'Expirée' : 'Valide',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color:
                        invitation.isExpired
                            ? Colors.red[600]
                            : Colors.green[600],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Icône d'invitation
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(60),
              border: Border.all(color: Colors.green[200]!, width: 2),
            ),
            child: Icon(
              Icons.share_rounded,
              size: 60,
              color: Colors.green[600],
            ),
          ),

          const SizedBox(height: 32),

          // Titre
          const Text(
            'Invitation de partage',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Message principal
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: invitation.ownerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const TextSpan(text: ' vous invite à accéder à la liste '),
                TextSpan(
                  text: '"${invitation.listName}"',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Carte d'information de la liste
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom de la liste
                Row(
                  children: [
                    Icon(
                      Icons.shopping_cart,
                      color: Colors.green[600],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        invitation.listName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Propriétaire
                _buildInfoRow(
                  icon: Icons.person,
                  title: 'Partagé par',
                  value: '${invitation.ownerName} (${invitation.ownerEmail})',
                ),

                const SizedBox(height: 12),

                // Permissions
                _buildInfoRow(
                  icon: Icons.security,
                  title: 'Permissions',
                  value: invitation.permissionDisplayName,
                  valueColor: _getPermissionColor(invitation.permission),
                ),

                const SizedBox(height: 12),

                // Expiration
                _buildInfoRow(
                  icon: Icons.schedule,
                  title: 'Expire le',
                  value: _formatDate(invitation.expiresAt),
                  valueColor: invitation.isExpired ? Colors.red[600] : null,
                ),

                if (invitation.shoppingList != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Statistiques de la liste
                  Text(
                    'Aperçu de la liste',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.list_alt,
                          title: 'Articles',
                          value: '${invitation.shoppingList!.itemsCount}',
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.check_circle,
                          title: 'Complétés',
                          value:
                              '${invitation.shoppingList!.purchasedItemsCount}',
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  if (invitation.shoppingList!.totalPrice > 0) ...[
                    const SizedBox(height: 12),
                    _buildStatCard(
                      icon: Icons.attach_money,
                      title: 'Budget estimé',
                      value:
                          '${invitation.shoppingList!.totalPrice.toStringAsFixed(2)} \$CAD',
                      color: Colors.orange,
                    ),
                  ],
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Description des permissions
          _buildPermissionDescription(invitation.permission),

          const SizedBox(height: 40),

          // ✅ Boutons d'action améliorés
          if (!invitation.isExpired) ...[
            // Boutons pour invitation valide
            Row(
              children: [
                // Bouton Refuser
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showDeclineConfirmation(invitation);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.red[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Refuser',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[600],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Bouton Accepter
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _showAcceptConfirmation(invitation);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Accepter',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Bouton pour invitation expirée
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Retour à l\'accueil',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Note sur l'expiration
          if (invitation.isExpired)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red[600], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cette invitation a expiré. Contactez ${invitation.ownerName} pour recevoir une nouvelle invitation.',
                      style: TextStyle(color: Colors.red[600], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ✅ Confirmation pour accepter l'invitation
  void _showAcceptConfirmation(ShareInvitation invitation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Accepter l\'invitation'),
          content: Text(
            'Voulez-vous accepter l\'invitation de ${invitation.ownerName} pour la liste "${invitation.listName}" ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                debugPrint(
                  '🤝 Acceptation de l\'invitation: ${invitation.token}',
                );
                context.read<SharedListBloc>().add(
                  AcceptShareInvitation(invitation.token),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                'Accepter',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // ✅ Confirmation pour refuser l'invitation
  void _showDeclineConfirmation(ShareInvitation invitation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Refuser l\'invitation'),
          content: Text(
            'Voulez-vous refuser l\'invitation de ${invitation.ownerName} pour la liste "${invitation.listName}" ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                debugPrint('❌ Refus de l\'invitation: ${invitation.token}');
                context.read<SharedListBloc>().add(
                  DeclineShareInvitation(invitation.token),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Refuser',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: valueColor ?? Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: color[600], size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color[700],
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDescription(SharePermission permission) {
    String title;
    String description;
    List<String> abilities;
    Color color;

    switch (permission) {
      case SharePermission.readOnly:
        title = 'Lecture seule';
        description = 'Vous pourrez consulter la liste mais pas la modifier';
        abilities = [
          'Voir les articles et leur statut',
          'Consulter les prix et quantités',
        ];
        color = Colors.blue[600]!;
        break;
      case SharePermission.edit:
        title = 'Modification';
        description = 'Vous pourrez modifier la liste mais pas la supprimer';
        abilities = [
          'Ajouter et modifier des articles',
          'Marquer des articles comme achetés',
          'Modifier les prix et quantités',
        ];
        color = Colors.green[600]!;
        break;
      case SharePermission.admin:
        title = 'Administration';
        description = 'Vous aurez tous les droits sur cette liste';
        abilities = [
          'Modifier et supprimer la liste',
          'Gérer tous les articles',
          'Partager avec d\'autres utilisateurs',
        ];
        color = Colors.purple[600]!;
        break;
    }

    return Container(
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          ...abilities.map(
            (ability) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ability,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
            const SizedBox(height: 24),
            const Text(
              'Invitation invalide',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    );
  }

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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference < 0) {
      return 'Expirée';
    } else if (difference == 0) {
      return 'Aujourd\'hui';
    } else if (difference == 1) {
      return 'Demain';
    } else if (difference < 7) {
      return 'Dans $difference jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
