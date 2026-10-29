// services/analytics_tracker.dart — la mesure d'usage.
//
// À NE PAS CONFONDRE avec `analytics_service.dart`, qui porte un nom
// trompeur : celui-là interroge les points d'entrée `/analytics/*` de
// l'API et rend les DÉPENSES de la personne. Il n'envoie aucun
// événement nulle part. Celui-ci est le seul outil de mesure de
// l'application.
//
// CE QUI SORT D'ICI, ET CE QUI N'EN SORT JAMAIS.
//
// Jamais : un nom d'article, un nom de liste, un montant, un magasin,
// une adresse courriel, un identifiant de compte, un identifiant
// publicitaire. Aucun événement ne porte de texte libre. Les propriétés
// sont des mots d'une liste fermée (« google », « email », « done »,
// « skip ») ou des nombres.
//
// C'est volontaire et c'est vérifiable : `analytics_test.dart` échoue
// si un paramètre sort de cette liste.
//
// Conséquence directe : pas d'IDFA, donc **pas de fenêtre ATT sur
// iOS**. Le SDK est configuré sans identifiant publicitaire
// (`firebase_analytics` n'en collecte pas par défaut ; AdSupport n'est
// pas lié au projet), et rien ici ne demande de permission de suivi.
//
// L'opt-out est immédiat : couper la mesure dans le profil appelle
// `setAnalyticsCollectionEnabled(false)`, et plus rien ne part.
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Les noms d'événements, au même endroit.
///
/// Des constantes et pas des chaînes libres : un événement mal
/// orthographié ne se voit pas — il crée simplement une statistique
/// vide que personne ne regarde.
abstract final class EvenementMesure {
  static const premiereOuverture = 'app_first_open';
  static const compteCree = 'account_created';
  static const etapeParcours = 'onboarding_step';
  static const listeCreee = 'list_created';
  static const articleAjoute = 'item_added';
  static const listePartagee = 'list_shared';
  static const codeInvitationSaisi = 'invite_code_entered';
  static const invitationAcceptee = 'invite_accepted';
  static const budgetCree = 'budget_created';
  static const scanRecuCommence = 'receipt_scan_started';
  static const recuConfirme = 'receipt_confirmed';
  static const avisEnvoye = 'feedback_submitted';
}

class AnalyticsTracker {
  AnalyticsTracker({FirebaseAnalytics? analytics}) : _analytics = analytics;

  final FirebaseAnalytics? _analytics;

  static const _cleOptOut = 'mesure_desactivee';
  static const _clePremiereOuverture = 'mesure_premiere_ouverture_envoyee';
  static const _cleArticlesAjoutes = 'mesure_articles_ajoutes';

  /// Les seules valeurs qu'une propriété a le droit de prendre.
  ///
  /// Tout ce qui n'est pas dans cette liste est refusé AVANT l'envoi :
  /// c'est la barrière qui empêche un nom d'article ou un courriel de
  /// partir par accident, le jour où quelqu'un ajoutera un appel.
  static const valeursAutorisees = <String, Set<String>>{
    'method': {'google', 'apple', 'email'},
    'source': {'organic', 'invite'},
    'step': {'first_list', 'invite', 'budget'},
    'action': {'done', 'skip'},
    'channel': {'link', 'code', 'native_sheet'},
    'rank': {'first', 'fifth'},
  };

  FirebaseAnalytics? get _instance {
    if (_analytics != null) return _analytics;

    try {
      return FirebaseAnalytics.instance;
    } catch (e) {
      // Firebase non initialisé (tests, démarrage dégradé) : la mesure
      // n'a pas le droit de faire tomber l'application.
      debugPrint('[Mesure] Firebase indisponible : $e');
      return null;
    }
  }

  // ===================== LE CHOIX DE LA PERSONNE =====================

  /// La mesure est-elle coupée ? (réglage du profil)
  Future<bool> estDesactivee() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      return prefs.getBool(_cleOptOut) ?? false;
    } catch (_) {
      // Dans le doute, on ne mesure pas.
      return true;
    }
  }

  /// Coupe ou rallume la mesure. Pris en compte tout de suite : le SDK
  /// cesse de collecter, il n'y a rien à redémarrer.
  Future<void> definirDesactivee(bool desactivee) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cleOptOut, desactivee);
    } catch (e) {
      debugPrint('[Mesure] choix non enregistré : $e');
    }

    try {
      await _instance?.setAnalyticsCollectionEnabled(!desactivee);
    } catch (e) {
      debugPrint('[Mesure] collecte non modifiée : $e');
    }
  }

  /// À appeler au démarrage : applique le choix déjà fait.
  Future<void> appliquerLeChoixAuDemarrage() async {
    await definirDesactivee(await estDesactivee());
  }

  // ===================== L'ENVOI =====================

  /// Envoie un événement, après l'avoir vérifié.
  ///
  /// Rend false quand rien n'est parti — mesure coupée, paramètre
  /// refusé, Firebase absent. L'appelant n'a jamais à s'en soucier :
  /// aucune erreur ne remonte.
  Future<bool> envoyer(String nom, {Map<String, Object>? parametres}) async {
    if (await estDesactivee()) {
      return false;
    }

    final propres = <String, Object>{};

    for (final entree in (parametres ?? const <String, Object>{}).entries) {
      final autorisees = valeursAutorisees[entree.key];

      if (autorisees == null) {
        // Une propriété inconnue est refusée, pas nettoyée : accepter
        // « product_name » parce qu'il ressemble à un nom de champ
        // serait exactement la fuite qu'on veut éviter.
        debugPrint('[Mesure] propriété refusée : ${entree.key}');
        return false;
      }

      final valeur = entree.value;

      if (valeur is num) {
        propres[entree.key] = valeur;
        continue;
      }

      if (!autorisees.contains(valeur.toString())) {
        debugPrint('[Mesure] valeur refusée pour ${entree.key}');
        return false;
      }

      propres[entree.key] = valeur.toString();
    }

    try {
      await _instance?.logEvent(
        name: nom,
        parameters: propres.isEmpty ? null : propres,
      );
      return true;
    } catch (e) {
      debugPrint('[Mesure] envoi impossible ($nom) : $e');
      return false;
    }
  }

  // ===================== LES ÉVÉNEMENTS =====================

  /// La toute première ouverture, une seule fois dans la vie de
  /// l'installation.
  Future<void> premiereOuverture() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (prefs.getBool(_clePremiereOuverture) == true) {
        return;
      }

      await prefs.setBool(_clePremiereOuverture, true);
    } catch (_) {
      return;
    }

    await envoyer(EvenementMesure.premiereOuverture);
  }

  Future<void> compteCree({required String methode, required String source}) =>
      envoyer(
        EvenementMesure.compteCree,
        parametres: {'method': methode, 'source': source},
      );

  Future<void> etapeParcours({required String etape, required String action}) =>
      envoyer(
        EvenementMesure.etapeParcours,
        parametres: {'step': etape, 'action': action},
      );

  Future<void> listeCreee() => envoyer(EvenementMesure.listeCreee);

  /// Le PREMIER et le CINQUIÈME article, pas les autres.
  ///
  /// Mesurer chaque article dirait surtout à quelle vitesse les gens
  /// tapent. Ces deux-là disent autre chose : le premier, que la liste
  /// a servi ; le cinquième, qu'elle est devenue une vraie liste de
  /// courses et pas un essai.
  Future<void> articleAjoute() async {
    int total;

    try {
      final prefs = await SharedPreferences.getInstance();
      total = (prefs.getInt(_cleArticlesAjoutes) ?? 0) + 1;

      // On s'arrête de compter après le cinquième : le compteur n'a
      // aucune raison de grandir indéfiniment.
      if (total <= 5) {
        await prefs.setInt(_cleArticlesAjoutes, total);
      }
    } catch (_) {
      return;
    }

    if (total == 1) {
      await envoyer(EvenementMesure.articleAjoute, parametres: {'rank': 'first'});
    } else if (total == 5) {
      await envoyer(EvenementMesure.articleAjoute, parametres: {'rank': 'fifth'});
    }
  }

  Future<void> listePartagee({required String canal}) => envoyer(
    EvenementMesure.listePartagee,
    parametres: {'channel': canal},
  );

  Future<void> codeInvitationSaisi() =>
      envoyer(EvenementMesure.codeInvitationSaisi);

  Future<void> invitationAcceptee() =>
      envoyer(EvenementMesure.invitationAcceptee);

  Future<void> budgetCree() => envoyer(EvenementMesure.budgetCree);

  Future<void> scanRecuCommence() =>
      envoyer(EvenementMesure.scanRecuCommence);

  Future<void> recuConfirme() => envoyer(EvenementMesure.recuConfirme);

  Future<void> avisEnvoye() => envoyer(EvenementMesure.avisEnvoye);

  /// Remet les compteurs locaux à zéro (déconnexion, suppression de
  /// compte) : le téléphone peut servir à quelqu'un d'autre.
  Future<void> oublierLesCompteurs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cleArticlesAjoutes);
    } catch (e) {
      debugPrint('[Mesure] compteurs non effacés : $e');
    }
  }
}
