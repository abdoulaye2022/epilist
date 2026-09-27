// services/image_upload_service.dart - Upload des images (avatar, photos
// produits) vers l'API, qui les assainit puis les stocke sur GCS.
// Dio partagé : Bearer + refresh token automatiques.
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:epilist/models/list_item.dart';

class ImageUploadService {
  final Dio _dio;

  ImageUploadService({required Dio dio}) : _dio = dio;

  Future<FormData> _form(File file) async => FormData.fromMap({
        'image': await MultipartFile.fromFile(file.path, filename: 'image.jpg'),
      });

  /// Téléverse l'avatar de l'utilisateur ; retourne l'URL publique.
  Future<String> uploadAvatar(File file) async {
    final response = await _dio.post('/user/avatar', data: await _form(file));
    return response.data['data']['avatar_url'] as String;
  }

  Future<void> deleteAvatar() async {
    await _dio.delete('/user/avatar');
  }

  /// Téléverse la photo d'un article ; retourne l'article mis à jour.
  Future<ListItem> uploadItemImage(int listId, int itemId, File file) async {
    final response = await _dio.post(
      '/shopping-lists/$listId/items/$itemId/image',
      data: await _form(file),
    );
    return ListItem.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<ListItem> deleteItemImage(int listId, int itemId) async {
    final response =
        await _dio.delete('/shopping-lists/$listId/items/$itemId/image');
    return ListItem.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
