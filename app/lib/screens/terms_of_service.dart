import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Conditions d\'utilisation'),
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
              'Conditions d\'utilisation',
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

            _buildTermSection(
              '1. Acceptation des conditions',
              'En utilisant EpiList, vous acceptez ces conditions d\'utilisation. '
                  'Si vous n\'acceptez pas ces termes, veuillez ne pas utiliser l\'application.',
            ),

            _buildTermSection(
              '2. Description du service',
              'EpiList est une application de gestion de listes d\'épicerie qui permet :\n\n'
                  '• De créer et gérer des listes de courses\n'
                  '• De suivre vos habitudes d\'achat\n'
                  '• De calculer vos budgets\n'
                  '• De synchroniser vos données\n\n'
                  'Le service est fourni "en l\'état".',
            ),

            _buildTermSection(
              '3. Compte utilisateur',
              'Pour utiliser EpiList, vous devez :\n\n'
                  '• Créer un compte avec des informations exactes\n'
                  '• Maintenir la sécurité de votre mot de passe\n'
                  '• Être responsable de toutes les activités sur votre compte\n'
                  '• Nous informer immédiatement en cas d\'usage non autorisé',
            ),

            _buildTermSection(
              '4. Utilisation acceptable',
              'Vous vous engagez à :\n\n'
                  '• Utiliser l\'application conformément à sa destination\n'
                  '• Ne pas perturber le fonctionnement du service\n'
                  '• Ne pas tenter d\'accéder aux données d\'autres utilisateurs\n'
                  '• Respecter les droits de propriété intellectuelle\n\n'
                  'Tout usage abusif peut entraîner la suspension du compte.',
            ),

            _buildTermSection(
              '5. Contenu utilisateur',
              'Concernant le contenu que vous créez :\n\n'
                  '• Vous conservez la propriété de vos listes et données\n'
                  '• Vous nous accordez une licence pour fournir le service\n'
                  '• Vous êtes responsable du contenu que vous publiez\n'
                  '• Nous pouvons supprimer du contenu inapproprié',
            ),

            _buildTermSection(
              '6. Disponibilité du service',
              'Nous nous efforçons d\'assurer la disponibilité continue du service, '
                  'mais nous ne garantissons pas :\n\n'
                  '• Un accès ininterrompu\n'
                  '• L\'absence de bugs ou d\'erreurs\n'
                  '• La compatibilité avec tous les appareils\n\n'
                  'Des maintenances peuvent occasionner des interruptions.',
            ),

            _buildTermSection(
              '7. Limitation de responsabilité',
              'EpiList ne peut être tenu responsable :\n\n'
                  '• Des dommages indirects ou consécutifs\n'
                  '• De la perte de données due à des problèmes techniques\n'
                  '• Des erreurs dans les calculs de prix\n'
                  '• De l\'utilisation des informations fournies\n\n'
                  'Utilisez l\'application à vos propres risques.',
            ),

            _buildTermSection(
              '8. Suspension et résiliation',
              'Nous pouvons suspendre ou résilier votre accès :\n\n'
                  '• En cas de violation de ces conditions\n'
                  '• Pour des raisons de sécurité\n'
                  '• Si le compte est inactif depuis 12 mois\n\n'
                  'Vous pouvez supprimer votre compte à tout moment.',
            ),

            _buildTermSection(
              '9. Modifications du service',
              'Nous nous réservons le droit de :\n\n'
                  '• Modifier les fonctionnalités de l\'application\n'
                  '• Mettre à jour ces conditions d\'utilisation\n'
                  '• Arrêter le service avec un préavis de 30 jours\n\n'
                  'Les modifications importantes vous seront notifiées.',
            ),

            _buildTermSection(
              '10. Droit applicable',
              'Ces conditions sont régies par le droit français. '
                  'Tout litige sera soumis aux tribunaux compétents de [Votre ville].',
            ),

            _buildTermSection(
              '11. Contact',
              'Pour toute question sur ces conditions :\n\n'
                  'Email : legal@epilist.app\n'
                  'Adresse : [Votre adresse légale]\n\n'
                  'Nous répondons sous 5 jours ouvrés.',
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

  Widget _buildTermSection(String title, String content) {
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
