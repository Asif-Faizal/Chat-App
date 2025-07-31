import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/chat_model.dart';
import '../../domain/entities/message_model.dart';
import '../../domain/entities/send_message_request.dart';
import '../bloc/chat_detail_bloc.dart';
import '../bloc/chat_detail_event.dart';
import '../bloc/chat_detail_state.dart';

class ChatDetailPage extends StatefulWidget {
  final ChatModel chat;
  final String currentUserId;

  const ChatDetailPage({
    super.key,
    required this.chat,
    required this.currentUserId,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ChatDetailBloc? _chatDetailBloc;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safely store the bloc reference when dependencies are available
    if (!_isInitialized) {
      _chatDetailBloc = context.read<ChatDetailBloc>();
      _chatDetailBloc?.add(LoadChatMessagesEvent(widget.chat.id));
      _chatDetailBloc?.add(JoinChatEvent(widget.chat.id));
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    // Use stored reference to avoid accessing deactivated widget's context
    _chatDetailBloc?.add(LeaveChatEvent(widget.chat.id));
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final otherParticipant = widget.chat.getOtherParticipant(widget.currentUserId);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryLightColor,
              child: Text(
                otherParticipant?.name.isNotEmpty == true
                    ? otherParticipant!.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDarkColor,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherParticipant?.name ?? 'Unknown User',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (otherParticipant?.role != null)
                    Text(
                      otherParticipant!.role.toUpperCase(),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: BlocConsumer<ChatDetailBloc, ChatDetailState>(
          listener: (context, state) {
            if (state is ChatDetailLoaded) {
              _scrollToBottom();
            } else if (state is MessageSendError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                Expanded(
                  child: _buildMessageList(state),
                ),
                _buildMessageInput(state),
              ],
            );
          },
        ),
    );
  }

  Widget _buildMessageList(ChatDetailState state) {
    if (state is ChatDetailLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (state is ChatDetailLoaded || state is MessageSendError) {
      final messages = state is ChatDetailLoaded 
          ? state.messages 
          : (state as MessageSendError).messages;
      
      if (messages.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: AppTheme.textLightColor,
              ),
              const SizedBox(height: 16),
              Text(
                'No messages yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start the conversation by sending a message',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textLightColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          final isMe = message.senderId == widget.currentUserId;
          final showDateSeparator = _shouldShowDateSeparator(messages, index);

          return Column(
            children: [
              if (showDateSeparator) _buildDateSeparator(message.createdAt),
              _buildMessageBubble(message, isMe),
            ],
          );
        },
      );
    } else if (state is ChatDetailError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
                      Icon(
            Icons.error_outline,
            size: 80,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading messages',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<ChatDetailBloc>().add(
                  LoadChatMessagesEvent(widget.chat.id),
                );
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: AppTheme.dateSeparatorDecoration,
          child: Text(
            DateFormat('MMMM dd, yyyy').format(date),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.textLightColor,
              child: Text(
                message.sender?.name.isNotEmpty == true
                    ? message.sender!.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: isMe 
                  ? AppTheme.sentMessageBubbleDecoration
                  : AppTheme.receivedMessageBubbleDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: AppTheme.messageTextStyle.copyWith(
                      color: isMe ? AppTheme.sentMessageTextColor : AppTheme.receivedMessageTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.createdAt),
                    style: AppTheme.messageTimeTextStyle.copyWith(
                      color: isMe ? AppTheme.textPrimaryColor.withOpacity(0.7) : AppTheme.messageTimeColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMessageInput(ChatDetailState state) {
    final isSending = state is ChatDetailLoaded && state.isSendingMessage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor, width: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: AppTheme.messageInputDecoration,
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: AppTheme.sendButtonDecoration,
            child: IconButton(
              onPressed: isSending ? null : _sendMessage,
              icon: isSending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppTheme.textPrimaryColor,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      Icons.send,
                      color: AppTheme.textPrimaryColor,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isNotEmpty && _chatDetailBloc != null) {
      final request = SendMessageRequest(
        chatId: widget.chat.id,
        senderId: widget.currentUserId,
        content: content,
        messageType: 'text',
      );

      _chatDetailBloc!.add(SendMessageEvent(request));
      _messageController.clear();
    }
  }

  bool _shouldShowDateSeparator(List<MessageModel> messages, int index) {
    if (index == 0) return true;
    
    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];
    
    final currentDate = DateTime(
      currentMessage.createdAt.year,
      currentMessage.createdAt.month,
      currentMessage.createdAt.day,
    );
    
    final previousDate = DateTime(
      previousMessage.createdAt.year,
      previousMessage.createdAt.month,
      previousMessage.createdAt.day,
    );
    
    return currentDate != previousDate;
  }
}