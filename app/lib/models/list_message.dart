// models/list_message.dart
class ListMessage {
  final int id;
  final int listId;
  final int userId;
  final String message;
  final MessageType messageType;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  // User info (populated from API)
  final MessageUser? user;

  // Read status
  final int? readByCount;

  ListMessage({
    required this.id,
    required this.listId,
    required this.userId,
    required this.message,
    required this.messageType,
    this.imageUrl,
    this.isRead = false,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.readByCount,
  });

  factory ListMessage.fromJson(Map<String, dynamic> json) {
    return ListMessage(
      id: json['id'] as int,
      listId: json['list_id'] as int,
      userId: json['user_id'] as int,
      message: json['message'] as String,
      messageType: MessageType.fromString(json['message_type'] as String? ?? 'text'),
      imageUrl: json['image_url'] as String?,
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      user: json['user'] != null
          ? MessageUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      readByCount: json['read_by_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'list_id': listId,
      'user_id': userId,
      'message': message,
      'message_type': messageType.value,
      'image_url': imageUrl,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (user != null) 'user': user!.toJson(),
      if (readByCount != null) 'read_by_count': readByCount,
    };
  }

  ListMessage copyWith({
    int? id,
    int? listId,
    int? userId,
    String? message,
    MessageType? messageType,
    String? imageUrl,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
    MessageUser? user,
    int? readByCount,
  }) {
    return ListMessage(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
      readByCount: readByCount ?? this.readByCount,
    );
  }

  bool isFromCurrentUser(int currentUserId) {
    return userId == currentUserId;
  }
}

/// Message type enum
enum MessageType {
  text('text'),
  image('image'),
  system('system');

  final String value;
  const MessageType(this.value);

  static MessageType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'image':
        return MessageType.image;
      case 'system':
        return MessageType.system;
      case 'text':
      default:
        return MessageType.text;
    }
  }
}

/// User info in message
class MessageUser {
  final int id;
  final String name;
  final String email;

  MessageUser({
    required this.id,
    required this.name,
    required this.email,
  });

  factory MessageUser.fromJson(Map<String, dynamic> json) {
    return MessageUser(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? 'Unknown User',
      email: (json['email'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }

  String get displayName {
    // Extract first name or use full name
    final parts = name.split(' ');
    return parts.isNotEmpty ? parts[0] : name;
  }

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      return name.substring(0, 1).toUpperCase();
    }
    return '?';
  }
}
