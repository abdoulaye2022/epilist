// services/invitation_service.dart — l'invitation qui survit à
// l'installation.
//
// LE PROBLÈME, dans l'ordre où il se produit :
//
//   1. quelqu'un reçoit un lien de partage et le touche ;
//   2. l'application n'est pas installée, le magasin s'ouvre ;
//   3. il installe, il ouvre l'application — et il arrive sur l'écran
//      de bienvenue. Le jeton a disparu entre le clic et le premier
//      lancement. L'invitation est perdue, et personne ne sait qu'elle
//      a existé.
//
// Il y avait aussi un trou plus discret : le jeton en attente vivait
// dans une variable statique (`_pendingShareToken`). Fermer
// l'application pendant l'inscription — pour aller chercher le code de
// vérification dans sa boîte de courriel, par exemple — le perdait.
//
// CE SERVICE répond aux deux :
//
//   - il garde le jeton sur le disque, donc il survit à la fermeture ;
//   - sur Android, il lit le « referrer » que Google Play transmet au
//     premier lancement : le lien de partage y a glissé le jeton, et
//     c'est le seul chemin automatique qui traverse le magasin ;
//   - et quand tout cela échoue — iOS n'a pas d'équivalent du
//     referrer — il reste le code à six caractères, que la personne
//     tape elle-même.
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// D'où vient une inscription. Les mêmes valeurs que côté API, qui
/// refuse tout ce qu'elle ne connaît pas (`AuthController::tracerProvenance`).
class SourceInscription {
  static const direct = 'direct';
  static const lienPartage = 'share_link';
  static const codeInvitation = 'invite_code';
  static const referrerInstallation = 'install_referrer';
}

class InvitationService {
  InvitationService({required Dio dio}) : _dio = dio;

  final Dio _dio;

  static const _cleJeton = 'invitation_jeton_en_attente';
  static const _cleSource = 'invitation_source';
  static const _cleReferrerLu = 'invitation_referrer_deja_lu';

  // ===================== LE JETON EN ATTENTE =====================

  /// Le jeton de partage qui attend d'être traité, s'il y en a un.
  ///
  /// Toujours relu depuis le disque, jamais gardé en mémoire : la
  /// lecture du referrer Play tourne en parallèle et peut écrire un
  /// jeton à tout moment. Une valeur mise en cache ici resterait nulle
  /// pour toute la session, et l'invitation serait perdue une seconde
  /// fois. SharedPreferences garde déjà tout en mémoire de son côté :
  /// relire ne coûte rien.
  Future<String?> jetonEnAttente() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      return prefs.getString(_cleJeton);
    } catch (e) {
      debugPrint('[Invitation] lecture du jeton impossible : $e');
      return null;
    }
  }

  /// La provenance à annoncer lors de l'inscription.
  Future<String> sourceInscription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_cleSource) ?? SourceInscription.direct;
    } catch (_) {
      return SourceInscription.direct;
    }
  }

  /// Met un jeton en attente. Écrit sur le disque : il doit survivre à
  /// la fermeture de l'application pendant l'inscription.
  Future<void> garderJeton(String jeton, {required String source}) async {
    final propre = jeton.trim();
    if (propre.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cleJeton, propre);
      await prefs.setString(_cleSource, source);
      debugPrint('[Invitation] jeton gardé ($source)');
    } catch (e) {
      debugPrint('[Invitation] écriture du jeton impossible : $e');
    }
  }

  /// L'invitation est traitée (acceptée, refusée, ou périmée).
  Future<void> oublierJeton() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cleJeton);
      await prefs.remove(_cleSource);
    } catch (e) {
      debugPrint('[Invitation] effacement du jeton impossible : $e');
    }
  }

  // ===================== LE CODE À SIX CARACTÈRES =====================

  /// Échange un code d'invitation contre son jeton de partage.
  ///
  /// Rend `null` si le code ne correspond à rien — expiré, déjà
  /// accepté, ou inventé : l'API ne fait pas la différence, exprès.
  Future<String?> resoudreCode(String code) async {
    final propre = code.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();

    if (propre.length != 6) {
      return null;
    }

    try {
      final reponse = await _dio.get('/share/code/$propre');
      final corps = reponse.data;

      if (corps is! Map || corps['success'] != true) {
        return null;
      }

      final jeton = (corps['data'] as Map?)?['share_token'] as String?;

      if (jeton == null || jeton.isEmpty) {
        return null;
      }

      await garderJeton(jeton, source: SourceInscription.codeInvitation);

      return jeton;
    } on DioException catch (e) {
      debugPrint('[Invitation] code refusé (${e.response?.statusCode})');
      return null;
    } catch (e) {
      debugPrint('[Invitation] erreur de résolution : $e');
      return null;
    }
  }

  // ===================== LE REFERRER DE GOOGLE PLAY =====================

  /// Lit, UNE SEULE FOIS, le referrer transmis par Google Play.
  ///
  /// Le lien de partage y a glissé `share_token=...`. Google le garde
  /// et le rend à l'application à son premier lancement : c'est le seul
  /// chemin qui traverse le magasin sans rien demander à personne.
  ///
  /// Une seule fois, car le referrer ne change jamais : le relire à
  /// chaque démarrage ferait ressurgir une vieille invitation déjà
  /// acceptée ou refusée.
  ///
  /// Sans effet hors Android : iOS n'a pas d'équivalent, et c'est
  /// précisément pourquoi le code à six caractères existe.
  Future<void> lireReferrerAuPremierLancement() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('[Invitation] préférences indisponibles : $e');
      return;
    }

    if (prefs.getBool(_cleReferrerLu) == true) {
      return;
    }

    try {
      final details = await PlayInstallReferrer.installReferrer;
      final referrer = details.installReferrer;

      // Marqué comme lu quoi qu'il arrive : un referrer absent le
      // restera, et réessayer à chaque lancement ne coûterait que du
      // temps de démarrage.
      await prefs.setBool(_cleReferrerLu, true);

      if (referrer == null || referrer.isEmpty) {
        return;
      }

      final jeton = _jetonDepuisReferrer(referrer);

      if (jeton != null) {
        await garderJeton(jeton, source: SourceInscription.referrerInstallation);
        debugPrint('[Invitation] jeton retrouvé dans le referrer Play');
      }
    } catch (e) {
      // Appareil sans Play Store, service indisponible, délai dépassé :
      // ce chemin est un bonus, son échec ne doit rien bloquer.
      debugPrint('[Invitation] referrer Play indisponible : $e');
      await prefs.setBool(_cleReferrerLu, true);
    }
  }

  /// Extrait `share_token` d'un referrer de la forme
  /// `share_token=abc&utm_source=share`.
  ///
  /// Le referrer arrive parfois encodé une fois de plus que prévu selon
  /// le chemin suivi ; on décode avant de découper, et on n'accepte que
  /// ce qui ressemble à un jeton (32 caractères hexadécimaux).
  @visibleForTesting
  static String? jetonDepuisReferrer(String referrer) =>
      _jetonDepuisReferrer(referrer);

  static String? _jetonDepuisReferrer(String referrer) {
    var texte = referrer;

    // On ESSAIE de lire, puis on décode, et on réessaie.
    //
    // Tester la présence du texte « share_token » ne suffit pas : une
    // chaîne encodée le contient encore (les lettres et le souligné ne
    // changent pas), seuls « = » et « & » deviennent %3D et %26. Un
    // referrer encodé passerait donc le test et se lirait de travers.
    //
    // Deux décodages au plus : selon le chemin suivi jusqu'au magasin,
    // le referrer revient parfois encodé une fois de trop.
    for (var essai = 0; essai < 3; essai++) {
      final jeton = _extraireJeton(texte);

      if (jeton != null) {
        return jeton;
      }

      if (!texte.contains('%')) {
        return null;
      }

      try {
        texte = Uri.decodeComponent(texte);
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  /// Le `share_token` d'une chaîne de paramètres, s'il est crédible.
  ///
  /// Seul un vrai jeton passe : le referrer vient de l'extérieur, et ce
  /// qui en sort finit en base de données.
  static String? _extraireJeton(String parametres) {
    final String? brut;

    try {
      brut = Uri.splitQueryString(parametres)['share_token'];
    } catch (_) {
      return null;
    }

    if (brut == null) {
      return null;
    }

    final propre = brut.trim().toLowerCase();

    return RegExp(r'^[a-f0-9]{32}$').hasMatch(propre) ? propre : null;
  }

  // ===================== POUR LE DÉBOGAGE =====================

  @visibleForTesting
  Future<String> etat() async => jsonEncode({
    'jeton': await jetonEnAttente(),
    'source': await sourceInscription(),
  });
}
