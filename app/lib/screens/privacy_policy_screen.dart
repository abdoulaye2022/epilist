import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:epilist/l10n/app_localizations.dart';
import '../utils/smart_snackbar_manager.dart';

class PrivacyPolicyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(l10n.privacyPolicy),
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
              l10n.privacyPolicy,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              l10n.privacyLastUpdated ??
                  'Dernière mise à jour : 5 juillet 2025',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            SizedBox(height: 24),

            _buildPolicySection(
              l10n.privacyCollectionTitle ?? '1. Collecte d\'informations',
              l10n.privacyCollectionText ??
                  'EpiList collecte les informations suivantes pour son fonctionnement :\n\n'
                      '• Informations de compte : prénom, nom, email, mot de passe (chiffré)\n'
                      '• Données de listes d\'épicerie : noms de listes, articles, quantités, prix, magasins (optionnel)\n'
                      '• Données de partage : liens de partage, permissions d\'accès (lecture, édition, administration)\n'
                      '• Données d\'utilisation : statut d\'achat des articles, totaux et calculs de pourcentages\n'
                      '• Données techniques : journaux d\'erreurs, performance de l\'application\n\n'
                      'Nous ne collectons aucune information personnelle sensible au-delà de ce qui est nécessaire au fonctionnement.',
            ),

            _buildPolicySection(
              l10n.privacyUsageTitle ?? '2. Utilisation des données',
              l10n.privacyUsageText ??
                  'Vos données sont utilisées exclusivement pour :\n\n'
                      '• Créer et gérer votre compte utilisateur\n'
                      '• Créer, modifier et supprimer vos listes d\'épicerie\n'
                      '• Calculer les totaux et pourcentages d\'articles achetés\n'
                      '• Dupliquer vos listes existantes\n'
                      '• Partager vos listes avec des membres de la famille ou amis via des liens sécurisés\n'
                      '• Gérer les permissions d\'accès (lecture, édition, administration)\n'
                      '• Synchroniser vos données sur tous vos appareils\n'
                      '• Fournir un support technique\n\n'
                      'Nous ne vendons ni ne louons vos données personnelles à des tiers.',
            ),

            _buildPolicySection(
              l10n.privacyStorageTitle ?? '3. Stockage et sécurité',
              l10n.privacyStorageText ??
                  'Vos données sont protégées par :\n\n'
                      '• Stockage sécurisé sur nos serveurs avec chiffrement\n'
                      '• Chiffrement des mots de passe avec des algorithmes sécurisés\n'
                      '• Protection des données en transit et au repos\n'
                      '• Liens de partage sécurisés avec contrôle d\'accès\n'
                      '• Sauvegarde régulière de vos listes et données\n'
                      '• Mesures de sécurité conformes aux standards de l\'industrie\n\n'
                      'Nous appliquons les meilleures pratiques de sécurité pour protéger vos informations.',
            ),

            _buildPolicySection(
              l10n.privacySharingTitle ?? '4. Partage des données',
              l10n.privacySharingText ??
                  'Vos données personnelles ne sont partagées que dans les cas suivants :\n\n'
                      '• Avec les personnes que vous autorisez via les liens de partage de listes\n'
                      '• Avec nos prestataires de services techniques (hébergement, support)\n'
                      '• Avec les autorités légales si requis par la loi\n\n'
                      'Le partage de listes se fait selon les permissions que vous définissez :\n'
                      '• Lecture seule : consultation des listes sans modification\n'
                      '• Édition : ajout, suppression et modification d\'articles\n'
                      '• Administration : gestion complète incluant suppression de listes\n\n'
                      'Aucun partage commercial de vos données n\'est effectué.',
            ),

            _buildPolicySection(
              l10n.privacyRightsTitle ?? '5. Vos droits',
              l10n.privacyRightsText ??
                  'Vous avez le droit de :\n\n'
                      '• Accéder à toutes vos données personnelles\n'
                      '• Modifier vos informations de compte (prénom, nom, email)\n'
                      '• Supprimer votre compte et toutes les données associées\n'
                      '• Exporter vos listes d\'épicerie\n'
                      '• Révoquer les liens de partage à tout moment\n'
                      '• Modifier les permissions d\'accès pour les utilisateurs invités\n'
                      '• Supprimer vos listes ou articles individuellement\n\n'
                      'Contactez-nous pour exercer ces droits.',
            ),

            _buildPolicySection(
              l10n.privacyFeaturesTitle ??
                  '6. Fonctionnalités de l\'application',
              l10n.privacyFeaturesText ??
                  'EpiList traite vos données pour offrir les fonctionnalités suivantes :\n\n'
                      '• Création et gestion de comptes utilisateurs\n'
                      '• Création, duplication, modification et suppression de listes\n'
                      '• Ajout d\'articles avec nom, quantité, prix et magasin (optionnel)\n'
                      '• Marquage d\'articles comme achetés ou suppression d\'articles\n'
                      '• Calcul automatique des totaux et pourcentages d\'achats\n'
                      '• Génération de liens de partage sécurisés\n'
                      '• Gestion des permissions d\'accès collaboratif\n\n'
                      'Toutes ces données restent sous votre contrôle.',
            ),

            _buildPolicySection(
              l10n.privacyCookiesTitle ??
                  '7. Cookies et technologies similaires',
              l10n.privacyCookiesText ??
                  'EpiList utilise des technologies de suivi pour :\n\n'
                      '• Maintenir votre session active\n'
                      '• Mémoriser vos préférences d\'utilisation\n'
                      '• Analyser l\'usage de l\'application (données anonymes)\n'
                      '• Optimiser les performances de l\'application\n\n'
                      'Vous pouvez désactiver ces fonctions dans les paramètres de l\'application.',
            ),

            _buildPolicySection(
              l10n.privacyChangesTitle ?? '8. Modifications',
              l10n.privacyChangesText ??
                  'Cette politique peut être mise à jour pour refléter les évolutions de l\'application. '
                      'Nous vous informerons des changements importants par :\n\n'
                      '• Email à l\'adresse associée à votre compte\n'
                      '• Mise à jour de la date en haut de cette politique\n\n'
                      'Votre utilisation continue de l\'application après les changements constitue votre acceptation.',
            ),

            _buildContactSection(
              context,
              l10n.privacyContactTitle ?? '9. Contact',
              l10n.privacyContactText ??
                  'Pour toute question concernant cette politique de confidentialité ou vos données, '
                      'veuillez nous contacter via notre site web.\n\n'
                      'Nous nous engageons à répondre dans les 48 heures ouvrables.',
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
              final Uri url = Uri.parse('https://epilist.app/contact');
              try {
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  SmartSnackBarManager.showMessage(
                    context,
                    l10n.aboutContactError ??
                        'Impossible d\'ouvrir le lien. Visitez https://epilist.app/contact',
                    type: SnackBarType.error,
                  );
                }
              } catch (e) {
                SmartSnackBarManager.showMessage(
                  context,
                  l10n.aboutContactError ??
                      'Erreur lors de l\'ouverture du lien de contact',
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
