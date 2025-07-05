import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/smart_snackbar_manager.dart';

class PrivacyPolicyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Politique de confidentialité'),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Politique de confidentialité',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Dernière mise à jour : 5 juillet 2025',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            SizedBox(height: 24),

            _buildPolicySection(
              '1. Collecte des informations',
              'EpiList collecte les informations suivantes pour son fonctionnement :\n\n'
                  '• Informations de compte : nom, prénom, email, mot de passe (chiffré)\n'
                  '• Données de listes d\'épicerie : noms des listes, articles, quantités, prix, magasins (optionnel)\n'
                  '• Données de partage : liens de partage, permissions d\'accès (lecture, modification, administration)\n'
                  '• Données d\'usage : statut d\'achat des articles, calculs de totaux et pourcentages\n'
                  '• Données techniques : logs d\'erreur, performances de l\'application\n\n'
                  'Nous ne collectons aucune information personnelle sensible au-delà de ce qui est nécessaire au fonctionnement.',
            ),

            _buildPolicySection(
              '2. Utilisation des données',
              'Vos données sont utilisées exclusivement pour :\n\n'
                  '• Créer et gérer votre compte utilisateur\n'
                  '• Créer, modifier et supprimer vos listes d\'épicerie\n'
                  '• Calculer les totaux et pourcentages d\'articles achetés\n'
                  '• Dupliquer vos listes existantes\n'
                  '• Partager vos listes avec des membres de la famille ou amis via des liens sécurisés\n'
                  '• Gérer les permissions d\'accès (lecture, modification, administration)\n'
                  '• Synchroniser vos données entre vos appareils\n'
                  '• Fournir un support technique\n\n'
                  'Nous ne vendons ni ne louons vos données personnelles à des tiers.',
            ),

            _buildPolicySection(
              '3. Stockage et sécurité',
              'Vos données sont protégées par :\n\n'
                  '• Stockage sécurisé sur nos serveurs avec chiffrement\n'
                  '• Chiffrement des mots de passe avec des algorithmes sécurisés\n'
                  '• Protection des données lors du transit et au repos\n'
                  '• Liens de partage sécurisés avec contrôle d\'accès\n'
                  '• Sauvegarde régulière de vos listes et données\n'
                  '• Mesures de sécurité conformes aux standards de l\'industrie\n\n'
                  'Nous appliquons les meilleures pratiques de sécurité pour protéger vos informations.',
            ),

            _buildPolicySection(
              '4. Partage des données',
              'Vos données personnelles sont uniquement partagées dans les cas suivants :\n\n'
                  '• Avec les personnes que vous autorisez via les liens de partage de listes\n'
                  '• Avec nos prestataires de services techniques (hébergement, support)\n'
                  '• Avec les autorités légales si requis par la loi\n\n'
                  'Le partage de listes se fait selon les permissions que vous définissez :\n'
                  '• Lecture seule : consultation des listes sans modification\n'
                  '• Modification : ajout, suppression et modification d\'articles\n'
                  '• Administration : gestion complète incluant suppression de liste\n\n'
                  'Aucun partage commercial de vos données n\'est effectué.',
            ),

            _buildPolicySection(
              '5. Vos droits',
              'Vous avez le droit de :\n\n'
                  '• Accéder à toutes vos données personnelles\n'
                  '• Modifier vos informations de compte (nom, prénom, email)\n'
                  '• Supprimer votre compte et toutes vos données associées\n'
                  '• Exporter vos listes d\'épicerie\n'
                  '• Révoquer les liens de partage à tout moment\n'
                  '• Modifier les permissions d\'accès des utilisateurs invités\n'
                  '• Supprimer individuellement vos listes ou articles\n\n'
                  'Contactez-nous pour exercer ces droits.',
            ),

            _buildPolicySection(
              '6. Fonctionnalités de l\'application',
              'EpiList traite vos données pour offrir les fonctionnalités suivantes :\n\n'
                  '• Création et gestion de comptes utilisateurs\n'
                  '• Création, duplication, modification et suppression de listes\n'
                  '• Ajout d\'articles avec nom, quantité, prix et magasin (optionnel)\n'
                  '• Marquage d\'articles comme achetés ou suppression d\'articles\n'
                  '• Calcul automatique des totaux et pourcentages d\'achat\n'
                  '• Génération de liens de partage sécurisés\n'
                  '• Gestion des permissions d\'accès collaboratif\n\n'
                  'Toutes ces données restent sous votre contrôle.',
            ),

            _buildPolicySection(
              '7. Cookies et technologies similaires',
              'EpiList utilise des technologies de suivi pour :\n\n'
                  '• Maintenir votre session active\n'
                  '• Mémoriser vos préférences d\'utilisation\n'
                  '• Analyser l\'utilisation de l\'application (données anonymes)\n'
                  '• Optimiser les performances de l\'application\n\n'
                  'Vous pouvez désactiver ces fonctions dans les paramètres de l\'application.',
            ),

            _buildPolicySection(
              '8. Modifications',
              'Cette politique peut être mise à jour pour refléter les évolutions de l\'application. '
                  'Nous vous informerons des changements importants par :\n\n'
                  '• Email à l\'adresse associée à votre compte\n'
                  '• Mise à jour de la date en haut de cette politique\n\n'
                  'Votre utilisation continue de l\'application après les modifications constitue votre acceptation.',
            ),

            _buildContactSection(
              context,
              '9. Contact',
              'Pour toute question concernant cette politique de confidentialité ou vos données, '
                  'veuillez nous contacter via notre site web.\n\n'
                  'Nous nous engageons à répondre sous 48h ouvrées.',
            ),

            SizedBox(height: 32),
            Center(
              child: Text(
                '© 2025 EpiList - Tous droits réservés',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(
    BuildContext context,
    String title,
    String content,
  ) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final Uri url = Uri.parse('https://epilist.app/contact');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                // Fallback si l'URL ne peut pas être ouverte
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Impossible d\'ouvrir le lien. Visitez https://epilist.app/contact',
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Nous contacter'),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection(String title, String content) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
