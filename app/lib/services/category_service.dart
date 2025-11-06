// services/category_service.dart - Service pour gérer les catégories
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../config/app_config.dart';
import 'auth_service.dart';

class CategoryService {
  final AuthService _authService;

  CategoryService(this._authService);

  // Récupérer toutes les catégories de l'utilisateur
  Future<List<Category>> getCategories() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/categories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['categories'] != null) {
          return (data['categories'] as List)
              .map((json) => Category.fromJson(json))
              .toList();
        }
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée');
      } else {
        throw Exception('Erreur lors du chargement des catégories');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // Créer une nouvelle catégorie
  Future<Category> createCategory({
    required String name,
    required String iconCode,
    required String colorHex,
    int orderIndex = 0,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/categories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'icon_code': iconCode,
          'color_hex': colorHex,
          'order_index': orderIndex,
        }),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Category.fromJson(data['category']);
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée');
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la création de la catégorie');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // Mettre à jour une catégorie
  Future<Category> updateCategory({
    required int categoryId,
    String? name,
    String? iconCode,
    String? colorHex,
    int? orderIndex,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final Map<String, dynamic> body = {};
      if (name != null) body['name'] = name;
      if (iconCode != null) body['icon_code'] = iconCode;
      if (colorHex != null) body['color_hex'] = colorHex;
      if (orderIndex != null) body['order_index'] = orderIndex;

      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/categories/$categoryId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Category.fromJson(data['category']);
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée');
      } else if (response.statusCode == 404) {
        throw Exception('Catégorie non trouvée');
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la mise à jour de la catégorie');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // Supprimer une catégorie (soft delete)
  Future<void> deleteCategory(int categoryId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/categories/$categoryId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée');
      } else if (response.statusCode == 404) {
        throw Exception('Catégorie non trouvée');
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la suppression de la catégorie');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // Réorganiser les catégories
  Future<void> reorderCategories(List<int> categoryIds) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/categories/reorder'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'category_ids': categoryIds,
        }),
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée');
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de la réorganisation des catégories');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // Initialiser les catégories par défaut pour un nouvel utilisateur
  Future<List<Category>> initializeDefaultCategories() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/categories/initialize-defaults'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['categories'] != null) {
          return (data['categories'] as List)
              .map((json) => Category.fromJson(json))
              .toList();
        }
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée');
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Erreur lors de l\'initialisation des catégories');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // Récupérer une catégorie spécifique
  Future<Category> getCategory(int categoryId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Non authentifié');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/categories/$categoryId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Category.fromJson(data['category']);
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée');
      } else if (response.statusCode == 404) {
        throw Exception('Catégorie non trouvée');
      } else {
        throw Exception('Erreur lors du chargement de la catégorie');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }
}
