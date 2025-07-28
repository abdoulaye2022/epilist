// services/receipt_service.dart - MÉTHODE UPDATE CORRIGÉE
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:epilist/models/receipt.dart';
import 'package:epilist/services/auth_service.dart';
import 'package:flutter/foundation.dart';

class ReceiptService {
  final Dio _dio;
  final AuthService _authService;

  ReceiptService({required Dio dio, required AuthService authService})
    : _dio = dio,
      _authService = authService;

  /// ✅ PARSE RESPONSE HELPER - Adapté à votre structure API
  Map<String, dynamic> _parseApiResponse(dynamic responseData) {
    if (responseData is String) {
      try {
        responseData = jsonDecode(responseData);
      } catch (e) {
        throw Exception('Réponse du serveur invalide (format JSON incorrect)');
      }
    }

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Format de réponse du serveur inattendu');
    }

    return responseData;
  }

  /// ✅ HANDLE API ERROR - Adapté à votre structure d'erreur
  Exception _handleApiError(Map<String, dynamic> errorData) {
    if (errorData.containsKey('error')) {
      final error = errorData['error'];
      if (error is Map<String, dynamic>) {
        final message = error['message'] ?? 'Erreur inconnue';
        final code = error['code'] ?? 'UNKNOWN_ERROR';

        // Messages d'erreur traduits selon le code
        final translatedMessage = switch (code) {
          'ACCESS_DENIED' => 'Vous n\'avez pas accès à cette liste',
          'PERMISSION_DENIED' => 'Permission insuffisante',
          'NOT_FOUND' => 'Facture non trouvée',
          'VALIDATION_ERROR' => 'Données invalides',
          'INTERNAL_ERROR' => 'Erreur du serveur',
          _ => message,
        };

        return Exception(translatedMessage);
      }
      return Exception(error.toString());
    }

    return Exception('Erreur inconnue du serveur');
  }

  /// Récupérer toutes les factures d'une liste
  Future<List<Receipt>> getListReceipts(int listId) async {
    try {
      final token = await _authService.getToken();

      debugPrint('🔄 Récupération des factures pour la liste: $listId');

      final response = await _dio.get(
        '/shopping-lists/$listId/receipts',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('✅ Factures récupérées - Status: ${response.statusCode}');

      final responseData = _parseApiResponse(response.data);

      if (responseData['success'] == true) {
        final receiptsData = responseData['data'];

        if (receiptsData is! List) {
          debugPrint('📝 Aucune facture trouvée ou format invalide');
          return <Receipt>[];
        }

        final receiptsList = receiptsData as List;
        debugPrint('📊 Nombre de factures trouvées: ${receiptsList.length}');

        // Parser chaque facture avec gestion d'erreur individuelle
        final List<Receipt> receipts = [];
        for (int i = 0; i < receiptsList.length; i++) {
          try {
            final receiptData = receiptsList[i];
            if (receiptData is Map<String, dynamic>) {
              receipts.add(Receipt.fromJson(receiptData));
            } else {
              debugPrint(
                '❌ Facture $i: format invalide - ${receiptData.runtimeType}',
              );
            }
          } catch (e) {
            debugPrint('❌ Erreur parsing facture $i: $e');
          }
        }

        debugPrint('✅ ${receipts.length} factures parsées avec succès');
        return receipts;
      } else {
        throw _handleApiError(responseData);
      }
    } on DioException catch (e) {
      debugPrint('❌ Erreur Dio: ${e.response?.statusCode} - ${e.message}');

      if (e.response?.statusCode == 403) {
        throw Exception('Vous n\'avez pas accès à cette liste');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Liste non trouvée');
      } else if (e.response?.data != null) {
        try {
          final errorData = _parseApiResponse(e.response!.data);
          throw _handleApiError(errorData);
        } catch (_) {
          throw Exception('Erreur de connexion: ${e.message}');
        }
      }

      throw Exception('Erreur de connexion: ${e.message}');
    } catch (e) {
      debugPrint('❌ Erreur inattendue: $e');
      throw Exception('Erreur lors de la récupération des factures');
    }
  }

  /// Créer une nouvelle facture
  Future<Receipt> createReceipt({
    required int listId,
    required String storeName,
    required double totalAmount,
    required DateTime purchaseDate,
    String? notes,
  }) async {
    try {
      final token = await _authService.getToken();

      debugPrint('🔄 Création facture: $storeName - $totalAmount');

      final response = await _dio.post(
        '/shopping-lists/$listId/receipts',
        data: {
          'store_name': storeName,
          'total_amount': totalAmount,
          'purchase_date': purchaseDate.toIso8601String().split('T')[0],
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('✅ Facture créée - Status: ${response.statusCode}');

      final responseData = _parseApiResponse(response.data);

      if (responseData['success'] == true) {
        final receiptData = responseData['data'];
        if (receiptData is Map<String, dynamic>) {
          return Receipt.fromJson(receiptData);
        } else {
          throw Exception('Données de facture invalides dans la réponse');
        }
      } else {
        throw _handleApiError(responseData);
      }
    } on DioException catch (e) {
      debugPrint('❌ Erreur création: ${e.response?.statusCode}');

      if (e.response?.statusCode == 422) {
        try {
          final errorData = _parseApiResponse(e.response!.data);
          if (errorData['error']?['validation_errors'] != null) {
            final errors =
                errorData['error']['validation_errors'] as Map<String, dynamic>;
            final messages = <String>[];
            errors.forEach((field, fieldErrors) {
              if (fieldErrors is List) {
                messages.addAll(fieldErrors.map((e) => e.toString()));
              }
            });
            throw Exception(messages.join(', '));
          }
          throw _handleApiError(errorData);
        } catch (_) {
          throw Exception('Données invalides');
        }
      } else if (e.response?.statusCode == 403) {
        throw Exception('Permission insuffisante pour ajouter des factures');
      } else if (e.response?.data != null) {
        try {
          final errorData = _parseApiResponse(e.response!.data);
          throw _handleApiError(errorData);
        } catch (_) {
          throw Exception('Erreur de connexion: ${e.message}');
        }
      }

      throw Exception('Erreur de connexion: ${e.message}');
    } catch (e) {
      debugPrint('❌ Erreur inattendue: $e');
      throw Exception('Erreur lors de la création de la facture');
    }
  }

  /// ✅ CORRECTION MAJEURE: Mettre à jour une facture
  Future<Receipt> updateReceipt({
    required int listId,
    required int receiptId,
    String? storeName,
    double? totalAmount,
    DateTime? purchaseDate,
    String? notes,
  }) async {
    try {
      final token = await _authService.getToken();

      debugPrint('🔄 Mise à jour facture: $receiptId');

      // ✅ CORRECTION: Construire correctement les données
      final Map<String, dynamic> data = {};

      if (storeName != null) {
        data['store_name'] = storeName;
        debugPrint('📝 Store name: $storeName');
      }

      if (totalAmount != null) {
        data['total_amount'] = totalAmount;
        debugPrint('💰 Total amount: $totalAmount');
      }

      if (purchaseDate != null) {
        data['purchase_date'] = purchaseDate.toIso8601String().split('T')[0];
        debugPrint('📅 Purchase date: ${data['purchase_date']}');
      }

      if (notes != null) {
        data['notes'] = notes.isEmpty ? null : notes;
        debugPrint('📝 Notes: ${data['notes']}');
      }

      debugPrint('📤 Données envoyées: $data');

      final response = await _dio.put(
        '/shopping-lists/$listId/receipts/$receiptId',
        data: data,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: Headers.jsonContentType,
        ),
      );

      debugPrint('✅ Facture mise à jour - Status: ${response.statusCode}');
      debugPrint('📥 Response data: ${response.data}');

      final responseData = _parseApiResponse(response.data);

      if (responseData['success'] == true) {
        final receiptData = responseData['data'];
        if (receiptData is Map<String, dynamic>) {
          final updatedReceipt = Receipt.fromJson(receiptData);
          debugPrint('✅ Facture parsée avec succès: ${updatedReceipt.id}');
          return updatedReceipt;
        } else {
          throw Exception('Données de facture invalides dans la réponse');
        }
      } else {
        debugPrint('❌ Échec de la mise à jour: ${responseData['error']}');
        throw _handleApiError(responseData);
      }
    } on DioException catch (e) {
      debugPrint('❌ Erreur Dio mise à jour: ${e.response?.statusCode}');
      debugPrint('❌ Response data: ${e.response?.data}');
      debugPrint('❌ Error message: ${e.message}');

      if (e.response?.statusCode == 404) {
        throw Exception('Facture non trouvée');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Permission insuffisante pour modifier cette facture');
      } else if (e.response?.statusCode == 422) {
        try {
          final errorData = _parseApiResponse(e.response!.data);
          if (errorData['error']?['validation_errors'] != null) {
            final errors =
                errorData['error']['validation_errors'] as Map<String, dynamic>;
            final messages = <String>[];
            errors.forEach((field, fieldErrors) {
              if (fieldErrors is List) {
                messages.addAll(fieldErrors.map((e) => e.toString()));
              }
            });
            throw Exception(messages.join(', '));
          }
          throw _handleApiError(errorData);
        } catch (_) {
          throw Exception('Données invalides');
        }
      } else if (e.response?.data != null) {
        try {
          final errorData = _parseApiResponse(e.response!.data);
          throw _handleApiError(errorData);
        } catch (_) {
          throw Exception('Erreur de connexion: ${e.message}');
        }
      }

      throw Exception('Erreur de connexion: ${e.message}');
    } catch (e) {
      debugPrint('❌ Erreur inattendue mise à jour: $e');
      throw Exception('Erreur lors de la mise à jour de la facture');
    }
  }

  /// Supprimer une facture
  Future<void> deleteReceipt(int listId, int receiptId) async {
    try {
      final token = await _authService.getToken();

      debugPrint('🔄 Suppression facture: $receiptId');

      final response = await _dio.delete(
        '/shopping-lists/$listId/receipts/$receiptId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('✅ Facture supprimée - Status: ${response.statusCode}');

      // Votre API renvoie {"success": true, "message": "..."} pour la suppression
      final responseData = _parseApiResponse(response.data);

      if (responseData['success'] != true) {
        throw _handleApiError(responseData);
      }
    } on DioException catch (e) {
      debugPrint('❌ Erreur suppression: ${e.response?.statusCode}');

      if (e.response?.statusCode == 404) {
        throw Exception('Facture non trouvée');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Permission insuffisante pour supprimer cette facture');
      } else if (e.response?.data != null) {
        try {
          final errorData = _parseApiResponse(e.response!.data);
          throw _handleApiError(errorData);
        } catch (_) {
          throw Exception('Erreur de connexion: ${e.message}');
        }
      }

      throw Exception('Erreur de connexion: ${e.message}');
    } catch (e) {
      debugPrint('❌ Erreur inattendue: $e');
      throw Exception('Erreur lors de la suppression de la facture');
    }
  }

  /// Récupérer les factures groupées par magasin
  Future<List<StoreReceiptGroup>> getReceiptsByStore(int listId) async {
    try {
      final token = await _authService.getToken();

      debugPrint('🔄 Récupération factures par magasin: $listId');

      final response = await _dio.get(
        '/shopping-lists/$listId/receipts/by-store',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final responseData = _parseApiResponse(response.data);

      if (responseData['success'] == true) {
        final storesData = responseData['data'];
        if (storesData is List) {
          return storesData
              .map((json) => StoreReceiptGroup.fromJson(json))
              .toList();
        } else {
          return <StoreReceiptGroup>[];
        }
      } else {
        throw _handleApiError(responseData);
      }
    } on DioException catch (e) {
      debugPrint(
        '❌ Erreur récupération par magasin: ${e.response?.statusCode}',
      );

      if (e.response?.data != null) {
        try {
          final errorData = _parseApiResponse(e.response!.data);
          throw _handleApiError(errorData);
        } catch (_) {
          throw Exception('Erreur de connexion');
        }
      }

      throw Exception(
        'Erreur lors de la récupération des factures par magasin',
      );
    } catch (e) {
      debugPrint('❌ Erreur inattendue: $e');
      throw Exception(
        'Erreur lors de la récupération des factures par magasin',
      );
    }
  }

  /// Récupérer les statistiques des factures
  Future<ReceiptStats> getReceiptStats(int listId) async {
    try {
      final token = await _authService.getToken();

      debugPrint('🔄 Récupération statistiques: $listId');

      final response = await _dio.get(
        '/shopping-lists/$listId/receipts/stats',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final responseData = _parseApiResponse(response.data);

      if (responseData['success'] == true) {
        final statsData = responseData['data'];
        if (statsData is Map<String, dynamic>) {
          return ReceiptStats.fromJson(statsData);
        } else {
          throw Exception('Données de statistiques invalides dans la réponse');
        }
      } else {
        throw _handleApiError(responseData);
      }
    } on DioException catch (e) {
      debugPrint('❌ Erreur récupération stats: ${e.response?.statusCode}');

      if (e.response?.data != null) {
        try {
          final errorData = _parseApiResponse(e.response!.data);
          throw _handleApiError(errorData);
        } catch (_) {
          throw Exception('Erreur de connexion');
        }
      }

      throw Exception('Erreur lors de la récupération des statistiques');
    } catch (e) {
      debugPrint('❌ Erreur inattendue: $e');
      throw Exception('Erreur lors de la récupération des statistiques');
    }
  }
}
