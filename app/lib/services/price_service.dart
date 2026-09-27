// services/price_service.dart - Client API de l'intelligence prix :
// import de reçus, résolution de libellés, historique, comparateur,
// optimiseur. Utilise le Dio partagé (jeton + refresh déjà gérés).
import 'package:dio/dio.dart';
import 'package:epilist/models/parsed_receipt.dart';
import 'package:epilist/models/price_intelligence.dart';

/// Levée quand le serveur détecte un reçu déjà importé (HTTP 409).
class DuplicateReceiptException implements Exception {
  final int? existingReceiptId;
  DuplicateReceiptException(this.existingReceiptId);
}

class PriceService {
  final Dio _dio;

  PriceService({required Dio dio}) : _dio = dio;

  /// Importe un reçu validé par l'utilisateur. [force] outrepasse la
  /// détection de doublon après confirmation explicite.
  Future<void> importReceipt({
    required int listId,
    required String storeName,
    int? storeId,
    required DateTime purchaseDate,
    required double totalAmount,
    double? subtotal,
    double? taxes,
    String? receiptNumber,
    String? currency,
    required List<ParsedReceiptItem> items,
    String source = 'receipt_ocr',
    bool force = false,
  }) async {
    try {
      await _dio.post(
        '/shopping-lists/$listId/receipts/import',
        data: {
          'store_name': storeName,
          if (storeId != null) 'store_id': storeId,
          'purchase_date':
              purchaseDate.toIso8601String().split('T').first,
          'total_amount': totalAmount,
          if (subtotal != null) 'subtotal': subtotal,
          if (taxes != null) 'taxes': taxes,
          if (receiptNumber != null && receiptNumber.isNotEmpty)
            'receipt_number': receiptNumber,
          if (currency != null) 'currency': currency,
          'source': source,
          if (force) 'force': true,
          'items': items
              .where((i) => !i.isDiscount)
              .map((i) => i.toImportJson())
              .toList(),
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final data = e.response?.data;
        final id = data is Map
            ? (data['data']?['existing_receipt_id'] as num?)?.toInt()
            : null;
        throw DuplicateReceiptException(id);
      }
      rethrow;
    }
  }

  /// Propose des correspondances produit pour des libellés bruts de reçu.
  Future<List<LabelResolution>> resolveLabels(
    List<String> labels, {
    int? storeId,
  }) async {
    final response = await _dio.post(
      '/receipts/resolve-labels',
      data: {
        if (storeId != null) 'store_id': storeId,
        'labels': labels,
      },
    );
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => LabelResolution.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProductPriceHistory> getPriceHistory(
    String product, {
    int days = 180,
  }) async {
    final response = await _dio.get(
      '/price-history',
      queryParameters: {'product': product, 'days': days},
    );
    return ProductPriceHistory.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<ComparisonResult> getStoreComparison(
    int listId, {
    int days = 90,
  }) async {
    final response = await _dio.get(
      '/shopping-lists/$listId/store-comparison',
      queryParameters: {'days': days},
    );
    return ComparisonResult.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<OptimizationResult> getOptimization(
    int listId, {
    int maxStores = 2,
    double minSaving = 5,
    int days = 90,
  }) async {
    final response = await _dio.get(
      '/shopping-lists/$listId/optimization',
      queryParameters: {
        'max_stores': maxStores,
        'min_saving': minSaving,
        'days': days,
      },
    );
    return OptimizationResult.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
}
