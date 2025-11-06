// screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/chat/chat_bloc.dart';
import 'package:epilist/blocs/chat/chat_event.dart';
import 'package:epilist/blocs/chat/chat_state.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/models/list_message.dart';
import 'package:epilist/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final int listId;
  final String listName;

  const ChatScreen({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupScrollListener();
  }

  void _loadMessages() {
    context.read<ChatBloc>().add(LoadMessages(widget.listId));
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        // Load more when scrolled to bottom
        context.read<ChatBloc>().add(LoadMoreMessages(widget.listId));
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    context.read<ChatBloc>().stopPolling();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    context.read<ChatBloc>().add(SendMessage(widget.listId, message));
    _messageController.clear();

    // Scroll to top after sending
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is AuthSuccess) {
          _currentUserId = authState.user.id;
        }

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.listName),
                Text(
                  l10n.chatTitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Column(
            children: [
              // Messages list
              Expanded(
                child: BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, state) {
                    if (state is ChatLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is ChatError) {
                      return _buildErrorView(l10n, state.message);
                    }

                    if (state is ChatLoaded || state is ChatSending) {
                      final messages = state is ChatLoaded
                          ? state.messages
                          : (state as ChatSending).messages;

                      if (messages.isEmpty) {
                        return _buildEmptyView(l10n);
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          context
                              .read<ChatBloc>()
                              .add(LoadMessages(widget.listId, refresh: true));
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length +
                              (state is ChatLoaded && state.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == messages.length) {
                              // Loading indicator for pagination
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final message = messages[index];
                            final isCurrentUser = message.userId == _currentUserId;

                            return _MessageBubble(
                              message: message,
                              isCurrentUser: isCurrentUser,
                              onDelete: () {
                                _confirmDelete(message);
                              },
                            );
                          },
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),

              // Message input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: 12 + MediaQuery.of(context).padding.bottom,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: l10n.typeMessage,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: theme.primaryColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyView(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noMessagesYet,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.startConversation,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(AppLocalizations l10n, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              l10n.errorLoadingMessages,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadMessages,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(ListMessage message) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteMessage),
        content: Text(l10n.deleteMessageConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ChatBloc>().add(DeleteMessage(message.id));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

// Message bubble widget
class _MessageBubble extends StatelessWidget {
  final ListMessage message;
  final bool isCurrentUser;
  final VoidCallback onDelete;

  const _MessageBubble({
    required this.message,
    required this.isCurrentUser,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: isCurrentUser ? onDelete : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? theme.primaryColor
                      : Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isCurrentUser ? 20 : 4),
                    bottomRight: Radius.circular(isCurrentUser ? 4 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isCurrentUser && message.user != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          message.user!.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                    Text(
                      message.message,
                      style: TextStyle(
                        color: isCurrentUser ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(message.createdAt, context),
                      style: TextStyle(
                        fontSize: 11,
                        color: isCurrentUser
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final initials = message.user?.initials ?? '?';
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    final color = colors[message.userId % colors.length];

    return CircleAvatar(
      radius: 16,
      backgroundColor: color,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Today - show time only
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      // Yesterday
      return '${l10n.yesterday} ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays < 7) {
      // This week - show day and time
      return DateFormat('EEE HH:mm').format(dateTime);
    } else {
      // Older - show date and time
      return DateFormat('MMM d, HH:mm').format(dateTime);
    }
  }
}
