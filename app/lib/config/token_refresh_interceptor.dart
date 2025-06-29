import 'dart:async';
import 'package:dio/dio.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:flutter/foundation.dart';

class TokenRefreshInterceptor extends Interceptor {
  final AuthService authService;
  final AuthBloc authBloc;
  final Dio dio;

  // Mutex pour éviter les refreshs multiples simultanés
  bool _isRefreshing = false;
  final List<Completer<void>> _pendingRequests = [];

  TokenRefreshInterceptor({
    required this.authService,
    required this.authBloc,
    required this.dio,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
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
    if (err.response?.statusCode == 401) {
      debugPrint('🔄 Token expiré - Tentative de refresh');

      try {
        // Vérifier si un refresh est déjà en cours
        if (_isRefreshing) {
          // Attendre que le refresh en cours se termine
          final completer = Completer<void>();
          _pendingRequests.add(completer);
          await completer.future;
        } else {
          // Démarrer le processus de refresh
          _isRefreshing = true;
          await _refreshTokenAndRetry(err, handler);

          // Notifier toutes les requêtes en attente
          for (final completer in _pendingRequests) {
            completer.complete();
          }
          _pendingRequests.clear();
          _isRefreshing = false;
          return;
        }

        // Réessayer la requête avec le nouveau token
        final response = await _retryRequest(err.requestOptions);
        return handler.resolve(response);
      } catch (e) {
        debugPrint('❌ Échec du refresh token: $e');
        _isRefreshing = false;
        _pendingRequests.clear();

        // Déconnecter l'utilisateur en cas d'échec
        authBloc.add(LogoutRequested());
        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  Future<void> _refreshTokenAndRetry(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final refreshToken = await authService.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('Aucun refresh token disponible');
    }

    // Créer une nouvelle instance Dio pour éviter l'interception
    final refreshDio = Dio(
      BaseOptions(
        baseUrl: dio.options.baseUrl,
        connectTimeout: dio.options.connectTimeout,
        receiveTimeout: dio.options.receiveTimeout,
      ),
    );

    try {
      // Appeler directement l'API de refresh
      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final newAccessToken = response.data['access_token'] as String?;
      final newRefreshToken = response.data['refresh_token'] as String?;

      if (newAccessToken == null || newRefreshToken == null) {
        throw Exception('Tokens manquants dans la réponse');
      }

      // Sauvegarder les nouveaux tokens
      await authService.saveTokens(newAccessToken, newRefreshToken);

      debugPrint('✅ Tokens rafraîchis avec succès');

      // Réessayer la requête originale
      final retryResponse = await _retryRequest(err.requestOptions);
      handler.resolve(retryResponse);
    } catch (e) {
      debugPrint('❌ Erreur lors du refresh: $e');
      throw e;
    }
  }

  Future<Response> _retryRequest(RequestOptions options) async {
    try {
      final newToken = await authService.getToken();
      if (newToken != null && newToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $newToken';
      }
      return await dio.fetch(options);
    } catch (e) {
      debugPrint('❌ Erreur lors de la nouvelle tentative: $e');
      rethrow;
    }
  }
}
