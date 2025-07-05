// services/account_deletion_service.dart
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
      final token = await _authService.getToken();

      debugPrint('🔄 Demande de suppression de compte...');

      final response = await _dio.post(
        '/auth/request-account-deletion',
        data: {if (reason != null) 'reason': reason},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint(
        '✅ Code de suppression demandé - Status: ${response.statusCode}',
      );

      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] != true) {
        final message = responseData['message'] ?? 'Erreur lors de la demande';
        throw Exception(message);
      }

      return responseData['data'] ?? {};
    } on DioException catch (e) {
      debugPrint('❌ Erreur lors de la demande de suppression:');
      debugPrint('   - Status Code: ${e.response?.statusCode}');
      debugPrint('   - Message: ${e.message}');
      debugPrint('   - Response Data: ${e.response?.data}');

      final responseData = e.response?.data;
      final errorMessage =
          responseData is Map<String, dynamic>
              ? responseData['message'] ?? e.message
              : e.message;
      throw Exception('Erreur lors de la demande: $errorMessage');
    } catch (e) {
      debugPrint('❌ Erreur inattendue: $e');
      throw Exception('Erreur lors de la demande de suppression');
    }
  }

  /// Confirmer la suppression avec le code
  Future<Map<String, dynamic>> confirmAccountDeletion({
    required String deletionCode,
    String? reason,
  }) async {
    try {
      final token = await _authService.getToken();

      debugPrint('🔄 Confirmation de suppression avec code: $deletionCode');

      final response = await _dio.post(
        '/auth/confirm-account-deletion',
        data: {
          'deletion_code': deletionCode,
          if (reason != null) 'reason': reason,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
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

      debugPrint('🔄 Annulation de la demande de suppression...');

      final response = await _dio.post(
        '/auth/cancel-account-deletion',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
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

      final response = await _dio.get(
        '/auth/account-deletion-status',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] != true) {
        throw Exception('Erreur lors de la récupération du statut');
      }

      return AccountDeletionStatus.fromJson(responseData['data']);
    } on DioException catch (e) {
      debugPrint('❌ Erreur lors de la récupération du statut: ${e.message}');
      throw Exception('Erreur lors de la récupération du statut');
    } catch (e) {
      debugPrint('❌ Erreur inattendue: $e');
      throw Exception('Erreur lors de la récupération du statut');
    }
  }
}
