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

  // Dio paresseux et RECRÉABLE : même si quelqu'un appelle dispose(),
  // le prochain test réseau repart sur une instance saine (un Dio fermé
  // ferait échouer tous les checks -> faux « hors ligne » permanent).
  Dio? _dioInstance;
  Dio get _dio => _dioInstance ??= Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
          headers: {
            'Cache-Control': 'no-cache',
            'User-Agent': 'EpiList-ConnectivityCheck/1.0',
          },
          followRedirects: false,
          maxRedirects: 0,
        ),
      );

  // Stream controller pour notifier les changements de connectivité
  StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream {
    if (_connectivityController.isClosed) {
      _connectivityController = StreamController<bool>.broadcast();
    }
    return _connectivityController.stream;
  }

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  /// Initialise le service de connectivité
  Future<void> initialize() async {
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
                // 3 s par tentative : hors ligne, l'échec est quasi
                // immédiat (pas de route) ; ce plafond ne joue que sur
                // les réseaux zombies et raccourcit le démarrage à froid.
                .timeout(const Duration(seconds: 3));
            return true;
          } catch (_) {
            continue;
          }
        }
        return false;
      }()
          .timeout(const Duration(seconds: 8), onTimeout: () => false);
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

  /// « Dispose » sans danger : ce singleton vit toute la vie du
  /// processus. On coupe seulement l'abonnement système ; le stream et
  /// le Dio restent utilisables (ou se recréent) pour que les tests
  /// réseau ne tombent jamais en panne définitive.
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
}
