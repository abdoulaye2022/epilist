// blocs/chat/chat_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/services/chat_service.dart';
import 'package:epilist/models/list_message.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatService chatService;
  Timer? _pollingTimer;
  DateTime? _lastMessageTime;
  int _currentOffset = 0;
  static const int _pageSize = 50;

  ChatBloc({required this.chatService}) : super(ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<SendImageMessage>(_onSendImageMessage);
    on<MarkMessageAsRead>(_onMarkMessageAsRead);
    on<DeleteMessage>(_onDeleteMessage);
    on<PollNewMessages>(_onPollNewMessages);
    on<LoadMoreMessages>(_onLoadMoreMessages);
  }

  /// Load messages for a list
  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    try {
      if (event.refresh || state is! ChatLoaded) {
        emit(ChatLoading());
        _currentOffset = 0;
      }

      final result = await chatService.getMessages(
        listId: event.listId,
        limit: _pageSize,
        offset: _currentOffset,
      );

      final messages = result['messages'] as List<ListMessage>;
      final unreadCount = result['unread_count'] as int;
      final total = result['total'] as int;

      // Update last message time for polling
      if (messages.isNotEmpty) {
        _lastMessageTime = messages.first.createdAt;
      }

      emit(ChatLoaded(
        messages: messages,
        unreadCount: unreadCount,
        total: total,
        hasMore: messages.length >= _pageSize,
      ));

      // Start polling for new messages
      _startPolling(event.listId);
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  /// Send a text message
  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is ChatLoaded) {
        emit(ChatSending(currentState.messages));
      }

      final message = await chatService.sendMessage(
        listId: event.listId,
        message: event.message,
      );

      // Update last message time
      _lastMessageTime = message.createdAt;

      // Reload messages to get the new one
      add(LoadMessages(event.listId, refresh: true));
    } catch (e) {
      emit(ChatError(e.toString()));

      // Restore previous state
      if (state is ChatSending) {
        final sendingState = state as ChatSending;
        emit(ChatLoaded(messages: sendingState.messages));
      }
    }
  }

  /// Send an image message
  Future<void> _onSendImageMessage(
    SendImageMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is ChatLoaded) {
        emit(ChatSending(currentState.messages));
      }

      final message = await chatService.sendImageMessage(
        listId: event.listId,
        message: event.message,
        imageUrl: event.imageUrl,
      );

      _lastMessageTime = message.createdAt;
      add(LoadMessages(event.listId, refresh: true));
    } catch (e) {
      emit(ChatError(e.toString()));

      if (state is ChatSending) {
        final sendingState = state as ChatSending;
        emit(ChatLoaded(messages: sendingState.messages));
      }
    }
  }

  /// Mark message as read
  Future<void> _onMarkMessageAsRead(
    MarkMessageAsRead event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await chatService.markMessageAsRead(event.messageId);
      // Don't emit a new state - this is a background operation
    } catch (e) {
      // Silently fail - not critical
    }
  }

  /// Delete a message
  Future<void> _onDeleteMessage(
    DeleteMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await chatService.deleteMessage(event.messageId);

      // Remove message from current state
      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        final updatedMessages = currentState.messages
            .where((m) => m.id != event.messageId)
            .toList();

        emit(currentState.copyWith(messages: updatedMessages));
      }
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  /// Poll for new messages
  Future<void> _onPollNewMessages(
    PollNewMessages event,
    Emitter<ChatState> emit,
  ) async {
    try {
      if (_lastMessageTime == null) return;

      final newMessages = await chatService.pollNewMessages(
        listId: event.listId,
        since: _lastMessageTime!,
      );

      if (newMessages.isNotEmpty && state is ChatLoaded) {
        final currentState = state as ChatLoaded;

        // Merge new messages with existing ones
        final allMessages = [...newMessages, ...currentState.messages];

        // Remove duplicates based on ID
        final uniqueMessages = <int, ListMessage>{};
        for (final message in allMessages) {
          uniqueMessages[message.id] = message;
        }

        final sortedMessages = uniqueMessages.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        _lastMessageTime = sortedMessages.first.createdAt;

        emit(currentState.copyWith(messages: sortedMessages));

        // Mark new messages as read
        for (final message in newMessages) {
          add(MarkMessageAsRead(message.id));
        }
      }
    } catch (e) {
      // Silently fail for polling errors
    }
  }

  /// Load more messages (pagination)
  Future<void> _onLoadMoreMessages(
    LoadMoreMessages event,
    Emitter<ChatState> emit,
  ) async {
    try {
      if (state is! ChatLoaded) return;

      final currentState = state as ChatLoaded;
      if (!currentState.hasMore) return;

      emit(ChatLoadingMore(currentState.messages));

      _currentOffset += _pageSize;

      final result = await chatService.getMessages(
        listId: event.listId,
        limit: _pageSize,
        offset: _currentOffset,
      );

      final newMessages = result['messages'] as List<ListMessage>;
      final total = result['total'] as int;

      // Merge with existing messages
      final allMessages = [...currentState.messages, ...newMessages];

      emit(ChatLoaded(
        messages: allMessages,
        unreadCount: currentState.unreadCount,
        total: total,
        hasMore: newMessages.length >= _pageSize,
      ));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  /// Start polling for new messages every 5 seconds
  void _startPolling(int listId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        add(PollNewMessages(listId));
      },
    );
  }

  /// Stop polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  Future<void> close() {
    stopPolling();
    return super.close();
  }
}
