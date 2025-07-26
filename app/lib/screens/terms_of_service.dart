import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:epilist/l10n/app_localizations.dart';
import '../utils/smart_snackbar_manager.dart';

class TermsOfServicePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(l10n.termsOfService),
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
              l10n.termsOfService,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              l10n.termsLastUpdated ?? 'Dernière mise à jour : 5 juillet 2025',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            SizedBox(height: 24),

            _buildTermSection(
              l10n.termsAcceptanceTitle ?? '1. Acceptation des conditions',
              l10n.termsAcceptanceText ??
                  'En utilisant l\'application EpiList, vous acceptez d\'être lié par ces conditions d\'utilisation. '
                      'Si vous n\'acceptez pas ces conditions dans leur intégralité, veuillez ne pas utiliser l\'application.',
            ),

            _buildTermSection(
              l10n.termsServiceTitle ?? '2. Description du service',
              l10n.termsServiceText ??
                  'EpiList est une application mobile de gestion de listes d\'épicerie qui permet :\n\n'
                      '• Créer un compte avec prénom, nom, email et mot de passe\n'
                      '• Créer, modifier et supprimer des listes d\'épicerie\n'
                      '• Ajouter des articles avec nom, quantité, prix et magasin (optionnel)\n'
                      '• Marquer les articles comme achetés ou les supprimer\n'
                      '• Calculer automatiquement les totaux et pourcentages d\'achats\n'
                      '• Dupliquer les listes existantes\n'
                      '• Partager les listes avec des liens sécurisés\n'
                      '• Gérer les permissions d\'accès (lecture, édition, administration)\n\n'
                      'Le service est fourni "en l\'état" et "selon disponibilité".',
            ),

            _buildTermSection(
              l10n.termsAccountTitle ?? '3. Compte utilisateur et sécurité',
              l10n.termsAccountText ??
                  'Pour utiliser EpiList, vous devez :\n\n'
                      '• Créer un compte avec des informations exactes (prénom, nom, email)\n'
                      '• Choisir un mot de passe sécurisé et le garder confidentiel\n'
                      '• Être responsable de toutes les activités effectuées sous votre compte\n'
                      '• Nous notifier immédiatement de toute utilisation non autorisée\n'
                      '• Mettre à jour vos informations personnelles si nécessaire\n\n'
                      'Vous êtes seul responsable de la sécurité de vos identifiants de connexion.',
            ),

            _buildTermSection(
              l10n.termsUsageTitle ?? '4. Utilisation des listes et partage',
              l10n.termsUsageText ??
                  'Concernant l\'utilisation des fonctionnalités de l\'application :\n\n'
                      '• Vous pouvez créer des listes d\'épicerie illimitées\n'
                      '• Les liens de partage sont de votre responsabilité\n'
                      '• Vous contrôlez les permissions d\'accès que vous accordez\n'
                      '• Les personnes invitées doivent respecter les permissions définies\n'
                      '• Vous pouvez révoquer l\'accès à tout moment\n'
                      '• Le contenu partagé doit rester approprié et légal\n\n'
                      'Vous êtes responsable de la gestion de vos listes partagées.',
            ),

            _buildTermSection(
              l10n.termsAcceptableTitle ?? '5. Utilisation acceptable',
              l10n.termsAcceptableText ??
                  'Vous acceptez de :\n\n'
                      '• Utiliser l\'application uniquement pour la gestion de listes d\'épicerie\n'
                      '• Ne pas tenter de perturber le fonctionnement du service\n'
                      '• Ne pas accéder illégalement aux données d\'autres utilisateurs\n'
                      '• Respecter les droits de propriété intellectuelle\n'
                      '• Ne pas utiliser l\'application à des fins commerciales sans autorisation\n'
                      '• Ne pas partager de contenu offensant ou illégal\n\n'
                      'Toute utilisation abusive peut entraîner une suspension immédiate du compte.',
            ),

            _buildTermSection(
              l10n.termsOwnershipTitle ?? '6. Propriété du contenu',
              l10n.termsOwnershipText ??
                  'Concernant le contenu que vous créez dans EpiList :\n\n'
                      '• Vous conservez la propriété de vos listes et données personnelles\n'
                      '• Vous nous accordez une licence limitée pour fournir le service\n'
                      '• Vous êtes responsable de l\'exactitude de vos informations\n'
                      '• Nous ne revendiquons aucun droit sur vos données personnelles\n'
                      '• Vous pouvez exporter vos données à tout moment\n\n'
                      'Vos données vous appartiennent et restent sous votre contrôle.',
            ),

            _buildTermSection(
              l10n.termsCalculationsTitle ?? '7. Calculs et prix',
              l10n.termsCalculationsText ??
                  'Concernant les fonctionnalités de calcul :\n\n'
                      '• Les totaux et pourcentages sont calculés automatiquement\n'
                      '• Nous ne garantissons pas l\'exactitude absolue des calculs\n'
                      '• Les prix saisis sont de votre responsabilité\n'
                      '• Vérifiez toujours les calculs pour vos achats importants\n'
                      '• Nous ne sommes pas responsables des erreurs de prix\n\n'
                      'Utilisez les calculs comme aide, pas comme référence absolue.',
            ),

            _buildTermSection(
              l10n.termsAvailabilityTitle ?? '8. Disponibilité du service',
              l10n.termsAvailabilityText ??
                  'Nous nous efforçons d\'assurer une disponibilité continue du service, '
                      'mais nous ne garantissons pas :\n\n'
                      '• Un accès ininterrompu 24h/24\n'
                      '• L\'absence complète de bugs ou d\'erreurs\n'
                      '• La compatibilité avec tous les appareils\n'
                      '• La sauvegarde permanente de toutes les données\n\n'
                      'Des maintenances programmées peuvent causer des interruptions temporaires.',
            ),

            _buildTermSection(
              l10n.termsLiabilityTitle ?? '9. Limitation de responsabilité',
              l10n.termsLiabilityText ??
                  'EpiList et ses développeurs ne peuvent être tenus responsables de :\n\n'
                      '• Dommages indirects ou consécutifs\n'
                      '• Perte de données due à des problèmes techniques\n'
                      '• Erreurs dans les calculs de prix ou totaux\n'
                      '• Utilisation incorrecte des informations fournies\n'
                      '• Problèmes liés au partage de listes\n'
                      '• Achats effectués basés sur les listes créées\n\n'
                      'Votre utilisation de l\'application se fait à vos propres risques.',
            ),

            _buildTermSection(
              l10n.termsTerminationTitle ?? '10. Suspension et résiliation',
              l10n.termsTerminationText ??
                  'Nous nous réservons le droit de suspendre ou résilier votre accès :\n\n'
                      '• En cas de violation de ces conditions d\'utilisation\n'
                      '• Pour des raisons de sécurité ou de maintenance\n'
                      '• Si le compte est inactif depuis plus de 24 mois\n'
                      '• En cas d\'utilisation abusive des fonctionnalités de partage\n\n'
                      'Vous pouvez supprimer votre compte à tout moment depuis les paramètres de l\'application.',
            ),

            _buildTermSection(
              l10n.termsModificationsTitle ?? '11. Modifications',
              l10n.termsModificationsText ??
                  'Nous nous réservons le droit de :\n\n'
                      '• Modifier ou améliorer les fonctionnalités de l\'application\n'
                      '• Mettre à jour ces conditions d\'utilisation\n'
                      '• Suspendre temporairement le service pour maintenance\n'
                      '• Discontinuer définitivement le service avec préavis de 60 jours\n\n'
                      'Les changements importants vous seront notifiés par email ou dans l\'application.',
            ),

            _buildTermSection(
              l10n.termsJurisdictionTitle ??
                  '12. Loi applicable et juridiction',
              l10n.termsJurisdictionText ??
                  'Ces conditions d\'utilisation sont régies par la loi canadienne. '
                      'Tout litige relatif à l\'utilisation d\'EpiList sera soumis à la juridiction '
                      'des tribunaux compétents du Nouveau-Brunswick, Canada.',
            ),

            _buildContactSection(
              context,
              l10n.termsContactTitle ?? '13. Contact et support',
              l10n.termsContactText ??
                  'Pour toute question concernant ces conditions d\'utilisation ou pour '
                      'de l\'assistance, veuillez nous contacter via notre site web.\n\n'
                      'Nous nous engageons à répondre le plus rapidement possible.',
              l10n,
            ),

            SizedBox(height: 32),
            Center(
              child: Text(
                '© 2025 EpiList - ${l10n.aboutRightsReserved ?? "Tous droits réservés"}',
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
    AppLocalizations l10n,
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
                    l10n.aboutContactError ??
                        'Impossible d\'ouvrir le lien. Visitez https://epilist.app/terms',
                    type: SnackBarType.error,
                  );
                }
              } catch (e) {
                SmartSnackBarManager.showMessage(
                  context,
                  l10n.aboutContactError ??
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
            child: Text(l10n.aboutContact ?? 'Nous contacter'),
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
