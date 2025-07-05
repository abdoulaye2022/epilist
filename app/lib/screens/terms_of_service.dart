import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/smart_snackbar_manager.dart';

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
              'Dernière mise à jour : 5 juillet 2025',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            SizedBox(height: 24),

            _buildTermSection(
              '1. Acceptation des conditions',
              'En utilisant l\'application EpiList, vous acceptez d\'être lié par ces conditions d\'utilisation. '
                  'Si vous n\'acceptez pas ces termes dans leur intégralité, veuillez ne pas utiliser l\'application.',
            ),

            _buildTermSection(
              '2. Description du service',
              'EpiList est une application mobile de gestion de listes d\'épicerie qui permet :\n\n'
                  '• De créer un compte avec nom, prénom, email et mot de passe\n'
                  '• De créer, modifier et supprimer des listes d\'épicerie\n'
                  '• D\'ajouter des articles avec nom, quantité, prix et magasin (optionnel)\n'
                  '• De marquer les articles comme achetés ou les supprimer\n'
                  '• De calculer automatiquement les totaux et pourcentages d\'achat\n'
                  '• De dupliquer des listes existantes\n'
                  '• De partager des listes avec des liens sécurisés\n'
                  '• De gérer les permissions d\'accès (lecture, modification, administration)\n\n'
                  'Le service est fourni "en l\'état" et "selon disponibilité".',
            ),

            _buildTermSection(
              '3. Compte utilisateur et sécurité',
              'Pour utiliser EpiList, vous devez :\n\n'
                  '• Créer un compte avec des informations exactes (nom, prénom, email)\n'
                  '• Choisir un mot de passe sécurisé et le maintenir confidentiel\n'
                  '• Être responsable de toutes les activités effectuées sous votre compte\n'
                  '• Nous informer immédiatement de tout usage non autorisé\n'
                  '• Mettre à jour vos informations personnelles si nécessaire\n\n'
                  'Vous êtes seul responsable de la sécurité de vos identifiants de connexion.',
            ),

            _buildTermSection(
              '4. Utilisation des listes et partage',
              'Concernant l\'utilisation des fonctionnalités de l\'application :\n\n'
                  '• Vous pouvez créer un nombre illimité de listes d\'épicerie\n'
                  '• Les liens de partage sont sous votre responsabilité\n'
                  '• Vous contrôlez les permissions d\'accès que vous accordez\n'
                  '• Les personnes invitées doivent respecter les permissions définies\n'
                  '• Vous pouvez révoquer l\'accès à tout moment\n'
                  '• Le contenu partagé doit rester approprié et légal\n\n'
                  'Vous êtes responsable de la gestion de vos listes partagées.',
            ),

            _buildTermSection(
              '5. Utilisation acceptable',
              'Vous vous engagez à :\n\n'
                  '• Utiliser l\'application uniquement pour la gestion de listes d\'épicerie\n'
                  '• Ne pas tenter de perturber le fonctionnement du service\n'
                  '• Ne pas accéder illégalement aux données d\'autres utilisateurs\n'
                  '• Respecter les droits de propriété intellectuelle\n'
                  '• Ne pas utiliser l\'application à des fins commerciales sans autorisation\n'
                  '• Ne pas partager de contenu offensant ou illégal\n\n'
                  'Tout usage abusif peut entraîner la suspension immédiate du compte.',
            ),

            _buildTermSection(
              '6. Propriété du contenu',
              'Concernant le contenu que vous créez dans EpiList :\n\n'
                  '• Vous conservez la propriété de vos listes et données personnelles\n'
                  '• Vous nous accordez une licence limitée pour fournir le service\n'
                  '• Vous êtes responsable de l\'exactitude de vos informations\n'
                  '• Nous ne revendiquons aucun droit sur vos données personnelles\n'
                  '• Vous pouvez exporter vos données à tout moment\n\n'
                  'Vos données vous appartiennent et restent sous votre contrôle.',
            ),

            _buildTermSection(
              '7. Calculs et prix',
              'Concernant les fonctionnalités de calcul :\n\n'
                  '• Les totaux et pourcentages sont calculés automatiquement\n'
                  '• Nous ne garantissons pas l\'exactitude absolue des calculs\n'
                  '• Les prix saisis sont sous votre responsabilité\n'
                  '• Vérifiez toujours les calculs pour vos achats importants\n'
                  '• Nous ne sommes pas responsables des erreurs de prix\n\n'
                  'Utilisez les calculs comme aide, non comme référence absolue.',
            ),

            _buildTermSection(
              '8. Disponibilité du service',
              'Nous nous efforçons d\'assurer la disponibilité continue du service, '
                  'mais nous ne garantissons pas :\n\n'
                  '• Un accès ininterrompu 24h/24 et 7j/7\n'
                  '• L\'absence totale de bugs ou d\'erreurs\n'
                  '• La compatibilité avec tous les appareils\n'
                  '• La sauvegarde permanente de toutes les données\n\n'
                  'Des maintenances programmées peuvent occasionner des interruptions temporaires.',
            ),

            _buildTermSection(
              '9. Limitation de responsabilité',
              'EpiList et ses développeurs ne peuvent être tenus responsables :\n\n'
                  '• Des dommages indirects ou consécutifs\n'
                  '• De la perte de données due à des problèmes techniques\n'
                  '• Des erreurs dans les calculs de prix ou totaux\n'
                  '• De l\'utilisation incorrecte des informations fournies\n'
                  '• Des problèmes liés au partage de listes\n'
                  '• Des achats effectués sur la base des listes créées\n\n'
                  'Votre utilisation de l\'application se fait à vos propres risques.',
            ),

            _buildTermSection(
              '10. Suspension et résiliation',
              'Nous nous réservons le droit de suspendre ou résilier votre accès :\n\n'
                  '• En cas de violation de ces conditions d\'utilisation\n'
                  '• Pour des raisons de sécurité ou de maintenance\n'
                  '• Si le compte est inactif depuis plus de 24 mois\n'
                  '• En cas d\'usage abusif des fonctionnalités de partage\n\n'
                  'Vous pouvez supprimer votre compte à tout moment depuis les paramètres de l\'application.',
            ),

            _buildTermSection(
              '11. Modifications',
              'Nous nous réservons le droit de :\n\n'
                  '• Modifier ou améliorer les fonctionnalités de l\'application\n'
                  '• Mettre à jour ces conditions d\'utilisation\n'
                  '• Suspendre temporairement le service pour maintenance\n'
                  '• Arrêter définitivement le service avec un préavis de 60 jours\n\n'
                  'Les modifications importantes vous seront notifiées par email ou dans l\'application.',
            ),

            _buildTermSection(
              '12. Droit applicable et juridiction',
              'Ces conditions d\'utilisation sont régies par le droit canadien. '
                  'Tout litige relatif à l\'utilisation d\'EpiList sera soumis à la juridiction '
                  'des tribunaux compétents du Nouveau-Brunswick, Canada.',
            ),

            _buildContactSection(
              context,
              '13. Contact et support',
              'Pour toute question concernant ces conditions d\'utilisation ou pour '
                  'obtenir de l\'aide, veuillez nous contacter via notre site web.\n\n'
                  'Nous nous engageons à répondre dans les meilleurs délais.',
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
              final Uri url = Uri.parse('https://epilist.app/terms');
              try {
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  SmartSnackBarManager.showMessage(
                    context,
                    'Impossible d\'ouvrir le lien. Visitez https://epilist.app/terms',
                    type: SnackBarType.error,
                  );
                }
              } catch (e) {
                SmartSnackBarManager.showMessage(
                  context,
                  'Erreur lors de l\'ouverture du lien. Visitez https://epilist.app/terms',
                  type: SnackBarType.error,
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
