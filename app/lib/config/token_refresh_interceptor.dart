import 'dart:async';
import 'package:dio/dio.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:flutter/foundation.dart';

/// Issue d'une tentative de rafraichissement du jeton.
enum RefreshOutcome {
  /// Nouveaux jetons obtenus et enregistres.
  success,

  /// Le serveur a refuse : le refresh token est expire ou revoque.
  /// C'est le SEUL cas qui justifie de deconnecter l'utilisateur.
  rejected,

  /// Le serveur n'a pas pu etre joint (reseau coupe, delai depasse).
  /// La session est peut-etre encore valide : on ne deconnecte pas.
  unreachable,
}

class TokenRefreshInterceptor extends Interceptor {
  final AuthService authService;
  final AuthBloc authBloc;
  final Dio dio;

  /// Rafraichissement en cours, s'il y en a un. Les requetes qui recoivent
  /// un 401 pendant ce temps attendent SON resultat au lieu d'en lancer un
  /// deuxieme.
  ///
  /// Remplace l'ancien couple (booleen + liste de Completer). Cette liste
  /// etait VIDEE sans etre completee quand le rafraichissement echouait :
  /// les requetes en attente ne recevaient alors plus jamais de reponse, ni
  /// resultat ni erreur. Les ecrans qui en dependaient tournaient
  /// indefiniment — rien n'arrivait au serveur, donc rien n'apparaissait
  /// non plus dans le journal d'erreurs de l'API.
  Completer<RefreshOutcome>? _refreshEnCours;

  /// Fabrique du client utilise pour l'appel /auth/refresh. Il doit rester
  /// SEPARE de `dio`, sinon l'appel repasse par cet intercepteur et la
  /// recursion est infinie. Remplacable par les tests, qui n'ont pas de
  /// serveur en face.
  @visibleForTesting
  Dio Function()? refreshClientFactory;

  TokenRefreshInterceptor({
    required this.authService,
    required this.authBloc,
    required this.dio,
  });

  // Endpoints d'authentification qui ne doivent JAMAIS déclencher
  // getToken() : /auth/refresh passe par ce même Dio, et getToken() sur un
  // token expiré relance un refresh → récursion infinie (app bloquée au
  // splash, constaté sur simulateur avec un token > 1 h).
  static const _noAuthPaths = [
    '/auth/refresh',
    '/auth/login',
    '/auth/register',
    '/auth/confirm-email',
    '/auth/resend-verification',
  ];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_noAuthPaths.any(options.path.contains)) {
      return handler.next(options);
    }

    // Ajouter automatiquement le token à chaque requête
    final token = await authService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final estUn401 = err.response?.statusCode == 401;
    final estUnePageDAuth = _noAuthPaths.any(err.requestOptions.path.contains);
    if (!estUn401 || estUnePageDAuth) {
      return handler.next(err);
    }

    debugPrint('🔄 Token expiré - Tentative de refresh');
    final issue = await _rafraichir();

    if (issue != RefreshOutcome.success) {
      // L'appelant recoit son 401 d'origine : une erreur, jamais le silence.
      return handler.next(err);
    }

    try {
      return handler.resolve(await _retryRequest(err.requestOptions));
    } on DioException catch (erreurDeLaSecondeTentative) {
      // Un echec de la NOUVELLE TENTATIVE n'est pas un echec
      // d'authentification : le jeton vient d'etre renouvele. L'ancienne
      // version deconnectait l'utilisateur ici, sur un simple incident
      // reseau survenu une seconde apres un rafraichissement reussi.
      return handler.next(erreurDeLaSecondeTentative);
    } catch (e) {
      debugPrint('❌ Erreur lors de la nouvelle tentative: $e');
      return handler.next(err);
    }
  }

  /// Rafraichit le jeton, ou rejoint le rafraichissement deja en cours.
  /// Ne leve jamais : toute issue est un [RefreshOutcome].
  Future<RefreshOutcome> _rafraichir() async {
    final dejaEnCours = _refreshEnCours;
    if (dejaEnCours != null) {
      return dejaEnCours.future;
    }

    final completer = Completer<RefreshOutcome>();
    _refreshEnCours = completer;

    // Initialisee des maintenant : si quoi que ce soit tourne mal avant
    // l'affectation, les requetes en attente recoivent une issue, pas rien.
    RefreshOutcome issue = RefreshOutcome.unreachable;
    try {
      issue = await _demanderDeNouveauxJetons();
    } catch (e) {
      debugPrint('❌ Erreur lors du refresh: $e');
      issue = RefreshOutcome.unreachable;
    } finally {
      // Dans un `finally` : quoi qu'il arrive, personne n'attend dans le vide.
      _refreshEnCours = null;
      if (!completer.isCompleted) {
        completer.complete(issue);
      }
    }

    if (issue == RefreshOutcome.rejected) {
      debugPrint('❌ Refresh token refusé par le serveur — déconnexion');
      authBloc.add(LogoutRequested());
    }
    return issue;
  }

  Future<RefreshOutcome> _demanderDeNouveauxJetons() async {
    final refreshToken = await authService.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return RefreshOutcome.rejected;
    }

    // Créer une nouvelle instance Dio pour éviter l'interception
    final refreshDio =
        refreshClientFactory?.call() ??
        Dio(
          BaseOptions(
            baseUrl: dio.options.baseUrl,
            connectTimeout: dio.options.connectTimeout,
            receiveTimeout: dio.options.receiveTimeout,
          ),
        );

    try {
      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final data = response.data;
      final newAccessToken = data is Map ? data['access_token'] as String? : null;
      final newRefreshToken = data is Map ? data['refresh_token'] as String? : null;

      if (newAccessToken == null || newRefreshToken == null) {
        return RefreshOutcome.rejected;
      }

      await authService.saveTokens(newAccessToken, newRefreshToken);
      debugPrint('✅ Tokens rafraîchis avec succès');
      return RefreshOutcome.success;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // Un refus explicite du serveur (401/403, ou une demande invalide)
      // signifie que la session est bel et bien terminee. Une coupure
      // reseau, un delai depasse ou un 500 passager, non.
      final refusParLeServeur =
          status == 400 || status == 401 || status == 403 || status == 422;
      return refusParLeServeur
          ? RefreshOutcome.rejected
          : RefreshOutcome.unreachable;
    }
  }

  Future<Response> _retryRequest(RequestOptions options) async {
    final newToken = await authService.getToken();
    if (newToken != null && newToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $newToken';
    }
    return dio.fetch(options);
  }
}
