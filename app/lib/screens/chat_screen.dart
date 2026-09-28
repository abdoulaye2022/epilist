// screens/chat_screen.dart
import 'package:epilist/theme/app_theme.dart';
import 'package:epilist/widgets/common/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:epilist/blocs/chat/chat_bloc.dart';
import 'package:epilist/blocs/chat/chat_event.dart';
import 'package:epilist/blocs/chat/chat_state.dart';
import 'package:epilist/blocs/auth/auth_bloc.dart';
import 'package:epilist/models/list_message.dart';
import 'package:epilist/services/connectivity_service.dart';
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


    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is AuthSuccess) {
          _currentUserId = authState.user.id;
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          // Barre blanche plate, comme partout ailleurs dans l'app.
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.listName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  l10n.chatTitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
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
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.border)),
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
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
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
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 36,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.noMessagesYet,
            style: const TextStyle(
              fontSize: 17,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.startConversation,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(AppLocalizations l10n, String error) {
    // Hors ligne : un état explicite, jamais l'exception brute (la
    // discussion vit sur le serveur, il n'y a pas de cache local).
    final offline = !ConnectivityService().isConnected;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              offline ? Icons.cloud_off_rounded : Icons.error_outline,
              size: 64,
              color: offline ? Colors.grey[400] : Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              offline ? l10n.offlineMode : l10n.errorLoadingMessages,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (offline) ...[
              const SizedBox(height: 8),
              Text(
                l10n.offlineUnavailableHint,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
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
    final chatBloc = context.read<ChatBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppDialogHeader(
                icon: Icons.delete_outline,
                title: l10n.deleteMessage,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.deleteMessageConfirmation,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppDialogActions(
                cancelLabel: l10n.cancel,
                submitLabel: l10n.delete,
                destructive: true,
                onCancel: () => Navigator.pop(dialogContext),
                onSubmit: () {
                  Navigator.pop(dialogContext);
                  chatBloc.add(DeleteMessage(message.id));
                },
              ),
            ],
          ),
        ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            _buildAvatar(),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: isCurrentUser ? onDelete : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                // Ma bulle : vert plein. Les autres : carte blanche
                // bordée, comme les cartes du reste de l'app.
                decoration: BoxDecoration(
                  color: isCurrentUser ? AppColors.primary : Colors.white,
                  border: isCurrentUser
                      ? null
                      : Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                    bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isCurrentUser && message.user != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          message.user!.displayName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    Text(
                      message.message,
                      style: TextStyle(
                        color: isCurrentUser
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatTime(message.createdAt, context),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isCurrentUser
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppColors.textDisabled,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: AppSpacing.sm),
            _buildAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final initials = message.user?.initials ?? '?';

    // Même langage que UserAvatar : initiales sombres sur vert doux.
    return CircleAvatar(
      radius: 15,
      backgroundColor: AppColors.primaryLight,
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
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
