import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_info.dart';

class ProductApiService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2';

  final http.Client _client;

  ProductApiService({http.Client? client})
      : _client = client ?? http.Client();

  /// Recherche un produit par son code-barres
  Future<ProductInfo?> getProductByBarcode(String barcode) async {
    try {
      final uri = Uri.parse('$_baseUrl/product/$barcode');

      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'EpiList - Shopping List App - Version 1.1.4',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: La recherche a pris trop de temps');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Vérifier si le produit existe
        if (data['status'] == 1 && data['product'] != null) {
          return ProductInfo.fromOpenFoodFacts(data['product']);
        } else {
          return null; // Produit non trouvé
        }
      } else if (response.statusCode == 404) {
        return null; // Produit non trouvé
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        throw Exception('Erreur de connexion. Vérifiez votre connexion Internet.');
      }
      rethrow;
    }
  }

  /// Recherche des produits par nom (pour l'auto-complétion)
  Future<List<ProductInfo>> searchProducts(String query, {int page = 1}) async {
    if (query.isEmpty) return [];

    try {
      final uri = Uri.parse('$_baseUrl/search').replace(
        queryParameters: {
          'search_terms': query,
          'page': page.toString(),
          'page_size': '10',
          'fields': 'code,product_name,brands,quantity,image_url,nutriments',
        },
      );

      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'EpiList - Shopping List App - Version 1.1.4',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> products = data['products'] ?? [];

        return products
            .map((json) => ProductInfo.fromOpenFoodFacts(json))
            .where((product) => product.name.isNotEmpty)
            .toList();
      } else {
        throw Exception('Erreur de recherche: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        throw Exception('Erreur de connexion. Vérifiez votre connexion Internet.');
      }
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}
