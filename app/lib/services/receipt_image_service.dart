// services/receipt_image_service.dart — l'URL pour regarder un reçu.
//
// Un reçu n'est plus une image publique. Il porte le magasin, la date et
// les montants, et il était rangé en lecture publique : l'URL suffisait
// à le lire, sans compte et sans jeton. Elle n'était pas devinable, mais
// « non devinable » n'est pas « privé » — une URL fuit par un partage
// d'écran, un presse-papier, un journal de serveur mandataire.
//
// Depuis, le serveur garde la clé de l'objet et ne délivre qu'une URL
// SIGNÉE, valable quinze minutes, à qui a le droit de voir la liste.
// Ce service demande cette URL, la garde en mémoire le temps qu'elle
// vaut, et en redemande une quand elle approche de son terme.
//
// En mémoire seulement : rien sur le disque. Une URL signée écrite dans
// un cache de fichiers survivrait à l'application et redeviendrait ce
// qu'on vient de supprimer — un lien qui ouvre un reçu sans rien
// demander.
import 'package:dio/dio.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:flutter/foundation.dart';

/// Une URL signée et la date à laquelle elle cesse de valoir.
@immutable
class UrlSignee {
  final String url;
  final DateTime expireA;

  const UrlSignee({required this.url, required this.expireA});

  /// Vraie quand l'URL vaut encore, avec une marge.
  ///
  /// La marge compte : une image qui commence à se charger à la
  /// quatorzième minute ne doit pas se faire couper en route, et
  /// l'horloge du téléphone n'est pas celle du serveur.
  bool valideAvecMarge(Duration marge) =>
      DateTime.now().add(marge).isBefore(expireA);
}

class ReceiptImageService {
  final Dio _dio;
  final AuthService _authService;

  /// Marge avant expiration : on redemande une URL plutôt que d'en
  /// servir une qui mourra pendant le chargement.
  static const Duration marge = Duration(minutes: 2);

  /// Les URL déjà obtenues, par identifiant de reçu. Jamais persistées.
  final Map<int, UrlSignee> _cache = {};

  ReceiptImageService({required Dio dio, required AuthService authService})
    : _dio = dio,
      _authService = authService;

  /// L'URL pour regarder la photo du reçu, ou null s'il n'en a pas.
  ///
  /// [forcer] ignore le cache : à utiliser quand le chargement vient
  /// d'échouer, le temps ayant pu passer entre l'obtention de l'URL et
  /// son usage.
  Future<String?> urlPour(
    int listId,
    int receiptId, {
    bool forcer = false,
  }) async {
    if (!forcer) {
      final enCache = _cache[receiptId];
      if (enCache != null && enCache.valideAvecMarge(marge)) {
        return enCache.url;
      }
    }

    try {
      final token = await _authService.getToken();
      final reponse = await _dio.get(
        '/shopping-lists/$listId/receipts/$receiptId/image-url',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final corps = reponse.data;
      if (corps is! Map || corps['success'] != true) {
        return null;
      }
      final donnees = corps['data'];
      if (donnees is! Map) {
        return null;
      }

      final url = donnees['url'] as String?;
      if (url == null || url.isEmpty) {
        return null;
      }

      // Sans date lisible, on considère l'URL bonne pour un quart
      // d'heure moins la marge : c'est le contrat du serveur.
      final expire =
          DateTime.tryParse('${donnees['expires_at']}') ??
          DateTime.now().add(const Duration(minutes: 15));

      final signee = UrlSignee(url: url, expireA: expire);
      _cache[receiptId] = signee;
      return url;
    } on DioException catch (e) {
      // 403 : la liste n'est plus partagée avec cette personne.
      // 404 : le reçu n'a pas (ou plus) de photo.
      // Dans les deux cas il n'y a rien à montrer, et rien à réessayer.
      final code = e.response?.statusCode;
      if (code == 403 || code == 404) {
        _cache.remove(receiptId);
        return null;
      }
      if (kDebugMode) {
        debugPrint('[ReceiptImage] URL indisponible (#$receiptId) : $e');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ReceiptImage] erreur (#$receiptId) : $e');
      }
      return null;
    }
  }

  /// Oublie l'URL d'un reçu : après remplacement ou suppression de sa
  /// photo, l'ancienne ne désigne plus rien.
  void oublier(int receiptId) => _cache.remove(receiptId);

  /// Vide tout. Appelé à la déconnexion : les URL d'une personne ne
  /// doivent pas survivre à sa session.
  void vider() => _cache.clear();
}
