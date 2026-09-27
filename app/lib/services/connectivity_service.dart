// services/connectivity_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Instance Dio dédiée pour les tests de connectivité
  late final Dio _dio;

  // Stream controller pour notifier les changements de connectivité
  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  /// Initialise le service de connectivité
  Future<void> initialize() async {
    // Configurer Dio pour les tests de connectivité
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
        headers: {
          'Cache-Control': 'no-cache',
          'User-Agent': 'EpiList-ConnectivityCheck/1.0',
        },
        // Désactiver les redirections pour un test plus rapide
        followRedirects: false,
        maxRedirects: 0,
      ),
    );

    // Vérifier la connectivité initiale
    await _updateConnectivityStatus();

    // Écouter les changements de connectivité
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) async {
      await _updateConnectivityStatus();
    });
  }

  /// Met à jour le statut de connectivité
  Future<void> _updateConnectivityStatus() async {
    final connectivityResults = await _connectivity.checkConnectivity();

    // Vérifier si on a une connexion réseau
    bool hasNetworkConnection = connectivityResults.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn,
    );

    if (!hasNetworkConnection) {
      _isConnected = false;
      if (!_connectivityController.isClosed) {
        _connectivityController.add(false);
      }
      return;
    }

    // Vérifier si on peut réellement accéder à internet
    bool hasInternetConnection = await _checkInternetConnection();
    _isConnected = hasInternetConnection;
    if (!_connectivityController.isClosed) {
      _connectivityController.add(hasInternetConnection);
    }
  }

  /// Vérifie l'accès réel à internet.
  ///
  /// DURCI après deux incidents "bloqué en hors ligne alors que le réseau
  /// va bien" :
  ///  - endpoints de test ultra-légers, sans redirection (generate_204) ;
  ///  - RECEVOIR une réponse HTTP suffit, quel que soit le code (un 204,
  ///    un 302 ou même un 403 prouvent que le réseau fonctionne) ;
  ///  - timeout STRICT par tentative et global : ce test ne peut plus
  ///    rester suspendu (c'est ce qui figeait l'état hors ligne, les
  ///    vérifications périodiques ne se terminant jamais).
  Future<bool> _checkInternetConnection() async {
    final testUrls = [
      'https://www.gstatic.com/generate_204',
      'https://connectivitycheck.gstatic.com/generate_204',
      'https://www.cloudflare.com/cdn-cgi/trace',
    ];

    try {
      return await () async {
        for (final url in testUrls) {
          try {
            await _dio
                .get(
                  url,
                  options: Options(
                    // N'importe quel statut = le réseau répond
                    validateStatus: (_) => true,
                    responseType: ResponseType.plain,
                  ),
                )
                .timeout(const Duration(seconds: 4));
            return true;
          } catch (_) {
            continue;
          }
        }
        return false;
      }()
          .timeout(const Duration(seconds: 10), onTimeout: () => false);
    } catch (_) {
      return false;
    }
  }

  /// Vérifie manuellement la connectivité (utile pour les retry).
  /// Ne peut jamais rester suspendue : timeout global de sécurité.
  Future<bool> checkConnectivity() async {
    try {
      await _updateConnectivityStatus().timeout(const Duration(seconds: 12));
    } catch (_) {
      // en cas de blocage improbable, on garde le dernier état connu
    }
    return _isConnected;
  }

  /// Test de connectivité rapide (pour les vérifications fréquentes)
  Future<bool> quickConnectivityCheck() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();

      bool hasNetworkConnection = connectivityResults.any(
        (result) =>
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet ||
            result == ConnectivityResult.vpn,
      );

      if (!hasNetworkConnection) {
        return false;
      }

      // Test rapide avec un seul endpoint
      final response = await _dio.head('https://www.google.com');
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 400;
    } catch (e) {
      return false;
    }
  }

  /// Vérifie si l'URL de votre API est accessible
  Future<bool> checkApiConnectivity(String apiBaseUrl) async {
    try {
      // Test spécifique à votre API
      final response = await _dio
          .head('$apiBaseUrl/health')
          .timeout(const Duration(seconds: 10));

      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 400;
    } catch (e) {
      // Si l'endpoint /health n'existe pas, essayer la racine
      try {
        final response = await _dio
            .head(apiBaseUrl)
            .timeout(const Duration(seconds: 10));

        return response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 500; // Accepter même les 4xx pour l'API
      } catch (e) {
        return false;
      }
    }
  }

  /// Nettoie les ressources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
    _dio.close();
  }
}
