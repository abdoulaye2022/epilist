// Un 401 ne doit JAMAIS laisser une requete sans reponse.
//
// L'ancienne version gardait une liste de Completer pour les requetes
// arrivees pendant un rafraichissement. Quand le rafraichissement echouait,
// cette liste etait VIDEE sans etre completee : les requetes en attente ne
// recevaient plus jamais rien, ni resultat ni erreur. Les ecrans qui en
// dependaient tournaient indefiniment. Rien n'atteignait le serveur, donc
// rien n'apparaissait non plus dans le journal d'erreurs de l'API : une
// application « qui ne marche pas » avec des journaux serveur vides.
//
// Elle deconnectait aussi l'utilisateur quand la SECONDE TENTATIVE echouait,
// alors que le jeton venait d'etre renouvele avec succes.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/blocs/localization/localization_bloc.dart';
import 'package:epilist/config/token_refresh_interceptor.dart';
import 'package:epilist/services/account_deletion_service.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Adaptateur HTTP de facade : repond ce que le test lui dicte.
class _AdaptateurSimule implements HttpClientAdapter {
  _AdaptateurSimule(this.repondre);
  final Future<ResponseBody> Function(RequestOptions options) repondre;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => repondre(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Map<String, dynamic> corps, int statut) => ResponseBody.fromString(
  jsonEncode(corps),
  statut,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

/// Jetons en memoire : pas de trousseau, pas de plugin.
class _AuthServiceSimule extends AuthService {
  _AuthServiceSimule({required super.dio, required super.sharedPreferences});

  String? acces = 'jeton-perime';
  String? rafraichissement = 'refresh-valide';

  @override
  Future<String?> getToken() async => acces;

  @override
  Future<String?> getRefreshToken() async => rafraichissement;

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    acces = accessToken;
    rafraichissement = refreshToken;
  }
}

/// Note les evenements au lieu de les traiter : le vrai traitement de
/// LogoutRequested touche aux notifications et au SSO, hors de portee d'un
/// test unitaire.
class _AuthBlocEspion extends AuthBloc {
  _AuthBlocEspion({
    required super.authService,
    required super.accountDeletionService,
    required super.localizationBloc,
  });

  final evenements = <AuthEvent>[];

  @override
  void add(AuthEvent event) => evenements.add(event);
}

void main() {
  late Dio dio;
  late _AuthServiceSimule authService;
  late _AuthBlocEspion authBloc;
  late TokenRefreshInterceptor intercepteur;

  /// Nombre d'appels recus par le serveur simule, par chemin.
  late Map<String, int> appels;

  Future<void> preparer({
    required Future<ResponseBody> Function(RequestOptions) serveur,
    required Future<ResponseBody> Function(RequestOptions) serveurDeRefresh,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    dio = Dio(BaseOptions(baseUrl: 'http://serveur.test'));
    dio.httpClientAdapter = _AdaptateurSimule((options) {
      appels[options.path] = (appels[options.path] ?? 0) + 1;
      return serveur(options);
    });

    authService = _AuthServiceSimule(dio: dio, sharedPreferences: prefs);
    authBloc = _AuthBlocEspion(
      authService: authService,
      accountDeletionService: AccountDeletionService(
        dio: dio,
        authService: authService,
      ),
      localizationBloc: LocalizationBloc(sharedPreferences: prefs),
    );

    intercepteur = TokenRefreshInterceptor(
      authService: authService,
      authBloc: authBloc,
      dio: dio,
    );
    intercepteur.refreshClientFactory = () {
      final client = Dio(BaseOptions(baseUrl: 'http://serveur.test'));
      client.httpClientAdapter = _AdaptateurSimule((options) {
        appels[options.path] = (appels[options.path] ?? 0) + 1;
        return serveurDeRefresh(options);
      });
      return client;
    };
    dio.interceptors.add(intercepteur);
  }

  setUp(() => appels = {});
  tearDown(() => authBloc.close());

  test('serveur de rafraichissement injoignable : les requetes en attente ne restent pas suspendues', () async {
    await preparer(
      serveur: (_) async => _json({'message': 'jeton expire'}, 401),
      serveurDeRefresh: (options) async => throw DioException.connectionError(
        requestOptions: options,
        reason: 'reseau coupe',
      ),
    );

    // Trois appels en parallele, comme un ecran qui charge ses donnees.
    final resultats = await Future.wait([
      dio.get('/budgets').then((_) => 'ok').catchError((e) => 'erreur'),
      dio.get('/shopping-lists').then((_) => 'ok').catchError((e) => 'erreur'),
      dio.get('/inventory').then((_) => 'ok').catchError((e) => 'erreur'),
    ]).timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw StateError('des requetes sont restees suspendues'),
    );

    // Avant : deux de ces trois futures ne se terminaient jamais.
    expect(resultats, ['erreur', 'erreur', 'erreur']);
    // Un seul rafraichissement pour les trois : le mutex tient toujours.
    expect(appels['/auth/refresh'], 1);
    // Reseau coupe n'est pas une session finie : on ne deconnecte pas.
    expect(authBloc.evenements, isEmpty);
  });

  test('refresh token refuse par le serveur : deconnexion, une seule fois', () async {
    await preparer(
      serveur: (_) async => _json({'message': 'jeton expire'}, 401),
      serveurDeRefresh: (_) async => _json({'message': 'refresh invalide'}, 401),
    );

    final resultats = await Future.wait([
      dio.get('/budgets').then((_) => 'ok').catchError((e) => 'erreur'),
      dio.get('/shopping-lists').then((_) => 'ok').catchError((e) => 'erreur'),
    ]).timeout(const Duration(seconds: 5));

    expect(resultats, ['erreur', 'erreur']);
    expect(appels['/auth/refresh'], 1);
    expect(authBloc.evenements.whereType<LogoutRequested>().length, 1);
  });

  test('rafraichissement reussi : la requete initiale repart avec le nouveau jeton', () async {
    final entetesVus = <String?>[];
    await preparer(
      serveur: (options) async {
        entetesVus.add(options.headers['Authorization'] as String?);
        // Le premier appel echoue en 401, le second (apres refresh) passe.
        if (appels['/budgets'] == 1) {
          return _json({'message': 'jeton expire'}, 401);
        }
        return _json({'success': true}, 200);
      },
      serveurDeRefresh: (_) async => _json({
        'access_token': 'jeton-neuf',
        'refresh_token': 'refresh-neuf',
      }, 200),
    );

    final reponse = await dio.get('/budgets').timeout(const Duration(seconds: 5));

    expect(reponse.statusCode, 200);
    expect(entetesVus, ['Bearer jeton-perime', 'Bearer jeton-neuf']);
    expect(authService.acces, 'jeton-neuf');
    expect(authBloc.evenements, isEmpty);
  });

  test('echec de la SECONDE tentative : pas de deconnexion, le jeton vient d etre renouvele', () async {
    await preparer(
      serveur: (options) async {
        if (appels['/budgets'] == 1) {
          return _json({'message': 'jeton expire'}, 401);
        }
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'coupure juste apres le refresh',
        );
      },
      serveurDeRefresh: (_) async => _json({
        'access_token': 'jeton-neuf',
        'refresh_token': 'refresh-neuf',
      }, 200),
    );

    await expectLater(
      dio.get('/budgets').timeout(const Duration(seconds: 5)),
      throwsA(isA<DioException>()),
    );
    // Avant : cet incident reseau deconnectait l'utilisateur.
    expect(authBloc.evenements, isEmpty);
  });
}
