import 'package:dio/dio.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:epilist/models/account_deletion_status.dart';
import 'package:flutter/foundation.dart';

class AccountDeletionService {
  final Dio _dio;
  final AuthService _authService;

  AccountDeletionService({required Dio dio, required AuthService authService})
    : _dio = dio,
      _authService = authService;

  /// Demander un code de suppression de compte
  Future<Map<String, dynamic>> requestAccountDeletion({String? reason}) async {
    try {
      // ✅ CORRECTION : Utiliser la même méthode que dans AuthService
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        debugPrint('❌ Token manquant pour la suppression de compte');
        throw Exception('Session expirée - Veuillez vous reconnecter');
      }

      debugPrint('🔄 Demande de suppression de compte...');
      debugPrint('🔑 Token utilisé: ${token.substring(0, 20)}...');

      // Préparer les données de la requête
      final Map<String, dynamic> requestData = {};
      if (reason != null && reason.isNotEmpty) {
        requestData['reason'] = reason;
      }

      debugPrint('📤 Données envoyées: $requestData');

      final response = await _dio.post(
        '/auth/request-account-deletion',
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      debugPrint('✅ Réponse reçue - Status: ${response.statusCode}');
      debugPrint('📥 Données de réponse: ${response.data}');

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] != true) {
        final message = responseData['message'] ?? 'Erreur lors de la demande';
        throw Exception(message);
      }

      return responseData['data'] ?? {};
    } on DioException catch (e) {
      debugPrint('❌ Erreur DioException lors de la demande de suppression:');
      debugPrint('   - Status Code: ${e.response?.statusCode}');
      debugPrint('   - Message: ${e.message}');
      debugPrint('   - Response Data: ${e.response?.data}');
      debugPrint('   - Request Headers: ${e.requestOptions.headers}');

      // Gestion spécifique de l'erreur 401
      if (e.response?.statusCode == 401) {
        debugPrint('🔄 Token probablement expiré, tentative de refresh...');

        try {
          final refreshToken = await _authService.getRefreshToken();
          if (refreshToken != null && refreshToken.isNotEmpty) {
            debugPrint('🔄 Tentative de rafraîchissement du token...');
            final newTokens = await _authService.refreshToken(refreshToken);
            await _authService.saveTokens(
              newTokens['access_token']!,
              newTokens['refresh_token']!,
            );

            debugPrint('✅ Token rafraîchi, nouvelle tentative...');
            // Retry avec le nouveau token
            return await requestAccountDeletion(reason: reason);
          }
        } catch (refreshError) {
          debugPrint('❌ Impossible de rafraîchir le token: $refreshError');
        }

        throw Exception('Session expirée - Veuillez vous reconnecter');
      }

      // Autres erreurs
      final responseData = e.response?.data;
      String errorMessage = 'Erreur lors de la demande de suppression';

      if (responseData is Map<String, dynamic>) {
        errorMessage = responseData['message'] ?? errorMessage;
      }

      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('❌ Erreur inattendue: $e');
      throw Exception('Erreur lors de la demande de suppression: $e');
    }
  }

  /// Confirmer la suppression avec le code
  Future<Map<String, dynamic>> confirmAccountDeletion({
    required String deletionCode,
    String? reason,
  }) async {
    try {
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Session expirée - Veuillez vous reconnecter');
      }

      debugPrint(
        '🔄 Confirmation de suppression avec code: ${deletionCode.substring(0, 2)}...',
      );

      final response = await _dio.post(
        '/auth/confirm-account-deletion',
        data: {
          'deletion_code': deletionCode,
          if (reason != null) 'reason': reason,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      debugPrint('✅ Suppression confirmée - Status: ${response.statusCode}');

      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] != true) {
        final message =
            responseData['message'] ?? 'Erreur lors de la confirmation';
        throw Exception(message);
      }

      return responseData['data'] ?? {};
    } on DioException catch (e) {
      debugPrint('❌ Erreur lors de la confirmation:');
      debugPrint('   - Status Code: ${e.response?.statusCode}');
      debugPrint('   - Message: ${e.message}');

      if (e.response?.statusCode == 401) {
        throw Exception('Session expirée - Veuillez vous reconnecter');
      }

      if (e.response?.statusCode == 400) {
        final responseData = e.response?.data;
        final errorCode =
            responseData is Map<String, dynamic> ? responseData['code'] : null;

        if (errorCode == 'INVALID_DELETION_CODE') {
          throw Exception('Code de suppression invalide ou expiré');
        }
      }

      final responseData = e.response?.data;
      final errorMessage =
          responseData is Map<String, dynamic>
              ? responseData['message'] ?? e.message
              : e.message;
      throw Exception('Erreur lors de la confirmation: $errorMessage');
    } catch (e) {
      debugPrint('❌ Erreur inattendue: $e');
      throw Exception('Erreur lors de la confirmation de suppression');
    }
  }

  /// Annuler la demande de suppression
  Future<void> cancelAccountDeletion() async {
    try {
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Session expirée - Veuillez vous reconnecter');
      }

      debugPrint('🔄 Annulation de la demande de suppression...');

      final response = await _dio.post(
        '/auth/cancel-account-deletion',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      debugPrint('✅ Suppression annulée - Status: ${response.statusCode}');

      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] != true) {
        final message =
            responseData['message'] ?? 'Erreur lors de l\'annulation';
        throw Exception(message);
      }
    } on DioException catch (e) {
      debugPrint('❌ Erreur lors de l\'annulation:');
      debugPrint('   - Status Code: ${e.response?.statusCode}');
      debugPrint('   - Message: ${e.message}');

      if (e.response?.statusCode == 401) {
        throw Exception('Session expirée - Veuillez vous reconnecter');
      }

      final responseData = e.response?.data;
      final errorMessage =
          responseData is Map<String, dynamic>
              ? responseData['message'] ?? e.message
              : e.message;
      throw Exception('Erreur lors de l\'annulation: $errorMessage');
    } catch (e) {
      debugPrint('❌ Erreur inattendue: $e');
      throw Exception('Erreur lors de l\'annulation');
    }
  }

  /// Obtenir le statut de suppression
  Future<AccountDeletionStatus> getAccountDeletionStatus() async {
    try {
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Session expirée - Veuillez vous reconnecter');
      }

      debugPrint('🔄 Récupération du statut de suppression...');

      final response = await _dio.get(
        '/auth/account-deletion-status',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      debugPrint('✅ Statut récupéré - Status: ${response.statusCode}');

      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] != true) {
        throw Exception('Erreur lors de la récupération du statut');
      }

      return AccountDeletionStatus.fromJson(responseData['data']);
    } on DioException catch (e) {
      debugPrint('❌ Erreur lors de la récupération du statut: ${e.message}');

      if (e.response?.statusCode == 401) {
        throw Exception('Session expirée - Veuillez vous reconnecter');
      }

      throw Exception('Erreur lors de la récupération du statut');
    } catch (e) {
      debugPrint('❌ Erreur inattendue: $e');
      throw Exception('Erreur lors de la récupération du statut');
    }
  }
}
