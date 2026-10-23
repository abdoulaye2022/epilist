// services/location_service.dart - Où est le téléphone, et à quelle
// distance sont les magasins.
//
// La position sert à UNE chose : calculer la distance jusqu'aux
// magasins et les trier du plus proche au plus loin. Elle n'est ni
// envoyée au serveur, ni enregistrée sur l'appareil — seul le CHOIX de
// la partager ou non est gardé, pour ne pas reposer la question à
// chaque ouverture.
//
// Trois décisions de conception, et elles tiennent toutes à la même
// idée : une fenêtre de permission qui tombe sans prévenir se refuse.
//
//   1. La phrase d'explication vient AVANT la fenêtre du téléphone.
//      C'est l'écran qui la montre ; ce service ne demande rien tant
//      qu'on ne l'appelle pas.
//   2. Le refus est une réponse, pas une panne : l'écran propose alors
//      le code postal, qui donne le secteur sans donner la position.
//   3. « Ne pas partager ma position » se garde, et rien ne le
//      contourne.
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ce que l'utilisatrice a répondu à la question de la position.
enum LocationChoice {
  /// Jamais posée.
  pasEncore,

  /// Position acceptée (la permission du téléphone reste maîtresse).
  position,

  /// Refusée, et un code postal donné à la place.
  codePostal,

  /// Refusée, sans rien en échange. L'écran n'y revient plus.
  refusee,
}

class LocationService {
  static const _cleChoix = 'location_choice';
  static const _cleCodePostal = 'location_postal_code';

  /// La réponse gardée, ou [LocationChoice.pasEncore].
  static Future<LocationChoice> choix() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final brut = prefs.getString(_cleChoix);
      return LocationChoice.values.firstWhere(
        (c) => c.name == brut,
        orElse: () => LocationChoice.pasEncore,
      );
    } catch (_) {
      return LocationChoice.pasEncore;
    }
  }

  static Future<void> garderLeChoix(LocationChoice choix) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cleChoix, choix.name);
    } catch (_) {}
  }

  /// Le code postal donné à la place de la position, ou `null`.
  static Future<String?> codePostal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString(_cleCodePostal);
      return v == null || v.isEmpty ? null : v;
    } catch (_) {
      return null;
    }
  }

  static Future<void> garderLeCodePostal(String? code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (code == null || code.trim().isEmpty) {
        await prefs.remove(_cleCodePostal);
      } else {
        await prefs.setString(_cleCodePostal, code.trim().toUpperCase());
      }
    } catch (_) {}
  }

  /// Les trois premiers caractères d'un code postal canadien : la
  /// « région de tri d'acheminement ». C'est le quartier, à peu près.
  ///
  /// Sans service de géocodage, c'est la seule comparaison honnête
  /// qu'on puisse faire entre deux codes postaux : dire « dans votre
  /// secteur », et jamais une distance en kilomètres qu'on ne connaît
  /// pas.
  static String? secteur(String? codePostal) {
    final c = codePostal?.replaceAll(' ', '').toUpperCase();
    if (c == null || c.length < 3) return null;
    return c.substring(0, 3);
  }

  /// Demande la position.
  ///
  /// [demanderLaPermission] ouvre la fenêtre du téléphone si elle n'a
  /// pas encore été accordée. À `false`, la position n'est lue que si
  /// la permission existe DÉJÀ — c'est le cas des rafraîchissements :
  /// une fenêtre de permission qui s'ouvre à la simple ouverture d'un
  /// écran, sans un mot d'explication, se refuse. Et une permission
  /// révoquée depuis les réglages du téléphone ne doit pas se
  /// redemander dans le dos de l'utilisatrice.
  ///
  /// Rend `null` sur un refus, un service de localisation éteint, ou
  /// une erreur : l'appelant montre alors le code postal, et ne traite
  /// jamais l'absence de position comme une panne.
  static Future<Position?> position({bool demanderLaPermission = true}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (!demanderLaPermission) return null;
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          // « Medium » suffit pour une distance jusqu'à un magasin, et
          // consomme bien moins qu'une position fine : personne ne se
          // repère au mètre dans une épicerie.
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Distance en KILOMÈTRES entre deux points, en formule de
  /// haversine.
  ///
  /// Calculée ici et jamais enregistrée : une distance en base serait
  /// une distance depuis un point qui n'a plus de sens dès qu'on bouge.
  static double distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const rayonTerre = 6371.0; // km
    double rad(double d) => d * math.pi / 180.0;

    final dLat = rad(lat2 - lat1);
    final dLon = rad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return rayonTerre * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// La distance ÉCRITE : « 850 m » en dessous du kilomètre, « 1,2 km »
  /// au-delà. Jamais « 1.2345 km » : personne ne lit quatre décimales.
  static String distanceEcrite(double km, {required bool anglais}) {
    if (km < 1) {
      final metres = (km * 1000).round();
      // Arrondi à 50 m : une position « medium » ne vaut pas mieux.
      final arrondi = (metres / 50).round() * 50;
      return '${arrondi == 0 ? 50 : arrondi} m';
    }
    final texte = km.toStringAsFixed(1);
    return '${anglais ? texte : texte.replaceAll('.', ',')} km';
  }
}
