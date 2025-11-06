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

  /// Vérifie si on peut réellement accéder à internet en testant plusieurs endpoints
  Future<bool> _checkInternetConnection() async {
    // Liste d'URLs à tester (du plus rapide au plus lent)
    final testUrls = [
      'https://www.google.com',
      'https://www.cloudflare.com',
      'https://httpbin.org/status/200',
    ];

    for (final url in testUrls) {
      try {
        // Utiliser HEAD request pour être plus rapide
        final response = await _dio.head(url);

        // Accepter les codes 200-299 et les redirections (300-399)
        if (response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 400) {
          return true;
        }
      } catch (e) {
        // Continuer avec l'URL suivante si celle-ci échoue
        continue;
      }
    }

    return false;
  }

  /// Vérifie manuellement la connectivité (utile pour les retry)
  Future<bool> checkConnectivity() async {
    await _updateConnectivityStatus();
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
