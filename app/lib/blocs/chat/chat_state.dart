// blocs/chat/chat_state.dart
import 'package:equatable/equatable.dart';
import 'package:epilist/models/list_message.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ChatInitial extends ChatState {}

/// Loading messages
class ChatLoading extends ChatState {}

/// Messages loaded successfully
class ChatLoaded extends ChatState {
  final List<ListMessage> messages;
  final int unreadCount;
  final int total;
  final bool hasMore;

  const ChatLoaded({
    required this.messages,
    this.unreadCount = 0,
    this.total = 0,
    this.hasMore = false,
  });

  @override
  List<Object?> get props => [messages, unreadCount, total, hasMore];

  ChatLoaded copyWith({
    List<ListMessage>? messages,
    int? unreadCount,
    int? total,
    bool? hasMore,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      unreadCount: unreadCount ?? this.unreadCount,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Sending a message
class ChatSending extends ChatState {
  final List<ListMessage> messages;

  const ChatSending(this.messages);

  @override
  List<Object?> get props => [messages];
}

/// Message sent successfully
class MessageSent extends ChatState {
  final ListMessage message;

  const MessageSent(this.message);

  @override
  List<Object?> get props => [message];
}

/// Message deleted successfully
class MessageDeleted extends ChatState {
  final int messageId;

  const MessageDeleted(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

/// Error state
class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Loading more messages (pagination)
class ChatLoadingMore extends ChatState {
  final List<ListMessage> currentMessages;

  const ChatLoadingMore(this.currentMessages);

  @override
  List<Object?> get props => [currentMessages];
}
