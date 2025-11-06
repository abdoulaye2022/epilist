// blocs/chat/chat_event.dart
import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Load messages for a list
class LoadMessages extends ChatEvent {
  final int listId;
  final bool refresh;

  const LoadMessages(this.listId, {this.refresh = false});

  @override
  List<Object?> get props => [listId, refresh];
}

/// Send a text message
class SendMessage extends ChatEvent {
  final int listId;
  final String message;

  const SendMessage(this.listId, this.message);

  @override
  List<Object?> get props => [listId, message];
}

/// Send an image message
class SendImageMessage extends ChatEvent {
  final int listId;
  final String message;
  final String imageUrl;

  const SendImageMessage(this.listId, this.message, this.imageUrl);

  @override
  List<Object?> get props => [listId, message, imageUrl];
}

/// Mark message as read
class MarkMessageAsRead extends ChatEvent {
  final int messageId;

  const MarkMessageAsRead(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

/// Delete a message
class DeleteMessage extends ChatEvent {
  final int messageId;

  const DeleteMessage(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

/// Poll for new messages
class PollNewMessages extends ChatEvent {
  final int listId;

  const PollNewMessages(this.listId);

  @override
  List<Object?> get props => [listId];
}

/// Load more messages (pagination)
class LoadMoreMessages extends ChatEvent {
  final int listId;

  const LoadMoreMessages(this.listId);

  @override
  List<Object?> get props => [listId];
}
