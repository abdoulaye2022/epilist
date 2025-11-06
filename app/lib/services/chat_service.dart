// services/chat_service.dart
import 'package:dio/dio.dart';
import 'package:epilist/models/list_message.dart';
import 'package:epilist/config/app_config.dart';

class ChatService {
  final Dio dio;

  ChatService({required this.dio});

  /// Get messages for a list with pagination
  Future<Map<String, dynamic>> getMessages({
    required int listId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await dio.get(
        '${AppConfig.baseUrl}/api/lists/$listId/messages',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final messages = (data['messages'] as List)
            .map((json) => ListMessage.fromJson(json))
            .toList();

        return {
          'messages': messages,
          'unread_count': data['unread_count'] ?? 0,
          'total': data['total'] ?? 0,
        };
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load messages');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('You don\'t have access to this chat');
      }
      throw Exception('Failed to load messages: ${e.message}');
    }
  }

  /// Send a text message
  Future<ListMessage> sendMessage({
    required int listId,
    required String message,
  }) async {
    try {
      final response = await dio.post(
        '${AppConfig.baseUrl}/api/lists/$listId/messages',
        data: {
          'message': message,
          'message_type': 'text',
        },
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return ListMessage.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to send message');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('You don\'t have access to this chat');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Message is invalid');
      }
      throw Exception('Failed to send message: ${e.message}');
    }
  }

  /// Send an image message
  Future<ListMessage> sendImageMessage({
    required int listId,
    required String message,
    required String imageUrl,
  }) async {
    try {
      final response = await dio.post(
        '${AppConfig.baseUrl}/api/lists/$listId/messages',
        data: {
          'message': message,
          'message_type': 'image',
          'image_url': imageUrl,
        },
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return ListMessage.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to send image');
      }
    } on DioException catch (e) {
      throw Exception('Failed to send image: ${e.message}');
    }
  }

  /// Mark a message as read
  Future<void> markMessageAsRead(int messageId) async {
    try {
      final response = await dio.post(
        '${AppConfig.baseUrl}/api/messages/$messageId/read',
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to mark as read');
      }
    } on DioException catch (e) {
      // Silently fail for read receipts - not critical
      print('Failed to mark message as read: ${e.message}');
    }
  }

  /// Delete a message
  Future<void> deleteMessage(int messageId) async {
    try {
      final response = await dio.delete(
        '${AppConfig.baseUrl}/api/messages/$messageId',
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to delete message');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('You can only delete your own messages');
      }
      throw Exception('Failed to delete message: ${e.message}');
    }
  }

  /// Get unread message count for a list
  Future<int> getUnreadCount(int listId) async {
    try {
      final response = await dio.get(
        '${AppConfig.baseUrl}/api/lists/$listId/messages/unread-count',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['unread_count'] ?? 0;
      } else {
        return 0;
      }
    } on DioException catch (e) {
      print('Failed to get unread count: ${e.message}');
      return 0;
    }
  }

  /// Poll for new messages (simple polling implementation)
  /// Returns new messages since the given timestamp
  Future<List<ListMessage>> pollNewMessages({
    required int listId,
    required DateTime since,
  }) async {
    try {
      final result = await getMessages(listId: listId, limit: 20);
      final messages = result['messages'] as List<ListMessage>;

      // Filter messages newer than 'since'
      return messages.where((m) => m.createdAt.isAfter(since)).toList();
    } catch (e) {
      print('Failed to poll new messages: $e');
      return [];
    }
  }
}
