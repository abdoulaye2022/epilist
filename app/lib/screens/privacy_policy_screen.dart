import 'package:flutter/material.dart';

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
              'Dernière mise à jour : 20 juin 2025',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            SizedBox(height: 24),

            _buildPolicySection(
              '1. Collecte des informations',
              'EpiList collecte uniquement les informations nécessaires au fonctionnement de l\'application :\n\n'
                  '• Informations de compte : email, nom d\'utilisateur\n'
                  '• Données d\'usage : listes d\'épicerie, articles, prix\n'
                  '• Données techniques : logs d\'erreur, performances\n\n'
                  'Nous ne collectons aucune information personnelle sensible.',
            ),

            _buildPolicySection(
              '2. Utilisation des données',
              'Vos données sont utilisées exclusivement pour :\n\n'
                  '• Fournir les fonctionnalités de l\'application\n'
                  '• Synchroniser vos listes entre appareils\n'
                  '• Améliorer l\'expérience utilisateur\n'
                  '• Fournir un support technique\n\n'
                  'Nous ne vendons ni ne louons vos données personnelles.',
            ),

            _buildPolicySection(
              '3. Stockage et sécurité',
              'Vos données sont :\n\n'
                  '• Stockées de manière sécurisée sur nos serveurs\n'
                  '• Chiffrées lors du transit et au repos\n'
                  '• Protégées par des mesures de sécurité appropriées\n'
                  '• Sauvegardées régulièrement\n\n'
                  'Nous appliquons les meilleures pratiques de sécurité.',
            ),

            _buildPolicySection(
              '4. Partage des données',
              'Nous ne partageons vos données personnelles qu\'avec :\n\n'
                  '• Des prestataires de services nécessaires au fonctionnement\n'
                  '• Les autorités légales si requis par la loi\n\n'
                  'Aucun partage commercial de vos données n\'est effectué.',
            ),

            _buildPolicySection(
              '5. Vos droits',
              'Vous avez le droit de :\n\n'
                  '• Accéder à vos données personnelles\n'
                  '• Modifier ou corriger vos informations\n'
                  '• Supprimer votre compte et vos données\n'
                  '• Exporter vos données\n\n'
                  'Contactez-nous pour exercer ces droits.',
            ),

            _buildPolicySection(
              '6. Cookies et technologies similaires',
              'EpiList utilise des technologies de suivi pour :\n\n'
                  '• Maintenir votre session active\n'
                  '• Mémoriser vos préférences\n'
                  '• Analyser l\'utilisation de l\'app (données anonymes)\n\n'
                  'Vous pouvez désactiver ces fonctions dans les paramètres.',
            ),

            _buildPolicySection(
              '7. Modifications',
              'Cette politique peut être mise à jour. Nous vous informerons '
                  'des changements importants par notification dans l\'application '
                  'ou par email.',
            ),

            _buildPolicySection(
              '8. Contact',
              'Pour toute question concernant cette politique :\n\n'
                  'Email : privacy@epilist.app\n'
                  'Adresse : [Votre adresse]\n\n'
                  'Nous répondons sous 48h ouvrées.',
            ),

            SizedBox(height: 32),
            Center(
              child: Text(
                '© 2025 EpiList',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
          ],
        ),
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
