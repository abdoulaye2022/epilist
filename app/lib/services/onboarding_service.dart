// services/onboarding_service.dart — le parcours de départ a-t-il déjà
// été vu ?
//
// La réponse vit SUR LE SERVEUR (`users.onboarding_done_at`), pas dans
// les préférences du téléphone. Quelqu'un qui change d'appareil,
// réinstalle, ou ouvre l'application sur une tablette a déjà fait ce
// parcours : le lui remontrer donnerait l'impression d'un compte neuf,
// et « Créez votre première liste » à quelqu'un qui en a douze ressemble
// à une perte de données.
//
// Une copie locale sert de garde-fou le temps d'un démarrage : si
// l'appel réseau échoue, mieux vaut ne RIEN montrer que de montrer le
// parcours deux fois.
import 'package:dio/dio.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  OnboardingService({required Dio dio, required AuthService authService})
    : _dio = dio,
      _authService = authService;

  final Dio _dio;
  final AuthService _authService;

  static const _cleLocale = 'onboarding_termine_localement';

  /// Dit au serveur que le parcours est vu — termine OU passé.
  ///
  /// Les deux cas valent la même chose : dans un comme dans l'autre, la
  /// personne a décidé, et redemander serait insistant.
  Future<void> marquerTermine() async {
    // Le drapeau local D'ABORD : si le réseau tombe au mauvais moment,
    // le parcours ne doit pas réapparaître au prochain démarrage.
    await _marquerLocalement();

    try {
      final jeton = await _authService.getToken();

      await _dio.post(
        '/user/onboarding-complete',
        options: Options(headers: {'Authorization': 'Bearer $jeton'}),
      );
    } catch (e) {
      // Le serveur le réapprendra au prochain passage réussi ; le
      // drapeau local tient en attendant.
      debugPrint('[Onboarding] marquage serveur impossible : $e');
    }
  }

  /// Faut-il montrer le parcours ?
  ///
  /// [dejaFaitSelonServeur] vient de la charge utile du compte
  /// (`onboarding_done`). En cas de doute — champ absent d'un serveur
  /// plus ancien — on ne montre RIEN : un parcours manqué ne coûte
  /// qu'une occasion, un parcours montré en boucle coûte un compte.
  Future<bool> doitMontrer({required bool? dejaFaitSelonServeur}) async {
    if (dejaFaitSelonServeur == null || dejaFaitSelonServeur) {
      return false;
    }

    return !await _faitLocalement();
  }

  Future<void> _marquerLocalement() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cleLocale, true);
    } catch (e) {
      debugPrint('[Onboarding] drapeau local non écrit : $e');
    }
  }

  Future<bool> _faitLocalement() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      return prefs.getBool(_cleLocale) ?? false;
    } catch (e) {
      debugPrint('[Onboarding] drapeau local illisible : $e');
      return true; // dans le doute, on ne montre pas
    }
  }

  /// À la déconnexion : le compte suivant sur ce téléphone a droit à
  /// son propre parcours.
  Future<void> oublier() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cleLocale);
    } catch (e) {
      debugPrint('[Onboarding] drapeau local non effacé : $e');
    }
  }
}
