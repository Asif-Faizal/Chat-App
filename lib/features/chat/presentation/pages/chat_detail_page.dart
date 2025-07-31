import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/chat_model.dart';
import '../../domain/entities/message_model.dart';
import '../../domain/entities/send_message_request.dart';
import '../bloc/chat_detail_bloc.dart';
import '../bloc/chat_detail_event.dart';
import '../bloc/chat_detail_state.dart';
import '../cubit/chat_detail_ui_cubit.dart';

class ChatDetailPage extends StatelessWidget {
  final ChatModel chat;
  final String currentUserId;

  const ChatDetailPage({
    super.key,
    required this.chat,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final otherParticipant = chat.getOtherParticipant(currentUserId);

    return MultiBlocProvider(
      providers: [
        BlocProvider<ChatDetailBloc>(
          create: (context) {
            final bloc = getIt<ChatDetailBloc>();
            bloc.add(LoadChatMessagesEvent(chat.id));
            bloc.add(JoinChatEvent(chat.id));
            return bloc;
          },
        ),
        BlocProvider<ChatDetailUICubit>(
          create: (context) {
            final cubit = getIt<ChatDetailUICubit>();
            // Initialize scroll controller immediately
            final scrollController = ScrollController();
            cubit.setScrollController(scrollController);
            return cubit;
          },
        ),
      ],
      child: BlocListener<ChatDetailBloc, ChatDetailState>(
        listener: (context, state) {
          if (state is ChatDetailLoaded) {
            // Scroll to bottom when messages are loaded
            WidgetsBinding.instance.addPostFrameCallback((_) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<ChatDetailUICubit>().scrollToBottomImmediate();
              });
            });
          } else if (state is MessageSendError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        child: BlocBuilder<ChatDetailBloc, ChatDetailState>(
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(
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
                          color: AppTheme.textOnPrimaryColor,
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
              body: Column(
                children: [
                  Expanded(
                    child: _buildMessageList(context, state),
                  ),
                  _buildMessageInput(context, state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessageList(BuildContext context, ChatDetailState state) {
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

      return BlocBuilder<ChatDetailUICubit, ChatDetailUIState>(
        builder: (context, uiState) {
          return ListView.builder(
            controller: uiState.scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final isMe = message.senderId == currentUserId;
              final showDateSeparator = _shouldShowDateSeparator(messages, index);

              return Column(
                children: [
                  if (showDateSeparator) _buildDateSeparator(context, message.createdAt),
                  _buildMessageBubble(context, message, isMe),
                ],
              );
            },
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
                  LoadChatMessagesEvent(chat.id),
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

  Widget _buildDateSeparator(BuildContext context, DateTime date) {
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

  Widget _buildMessageBubble(BuildContext context, MessageModel message, bool isMe) {
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
                      color:  AppTheme.messageTimeColor,
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

  Widget _buildMessageInput(BuildContext context, ChatDetailState state) {
    final isSending = state is ChatDetailLoaded && state.isSendingMessage;

    return BlocBuilder<ChatDetailUICubit, ChatDetailUIState>(
      builder: (context, uiState) {
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
                    controller: context.read<ChatDetailUICubit>().messageController,
                    onChanged: (value) {
                      context.read<ChatDetailUICubit>().updateMessageText(value);
                    },
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
                  onPressed: isSending ? null : () => _sendMessage(context),
                  icon: isSending
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppTheme.textOnPrimaryColor,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          Icons.send,
                          color: AppTheme.textOnPrimaryColor,
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendMessage(BuildContext context) {
    final content = context.read<ChatDetailUICubit>().state.messageText.trim();
    if (content.isNotEmpty) {
      final request = SendMessageRequest(
        chatId: chat.id,
        senderId: currentUserId,
        content: content,
        messageType: 'text',
      );

      context.read<ChatDetailBloc>().add(SendMessageEvent(request));
      context.read<ChatDetailUICubit>().clearMessageText();
      
      // Scroll to bottom after sending message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ChatDetailUICubit>().scrollToBottom();
      });
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