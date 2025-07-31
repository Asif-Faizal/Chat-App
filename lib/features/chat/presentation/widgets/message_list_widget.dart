import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/message_model.dart';
import '../bloc/chat_detail_bloc.dart';
import '../bloc/chat_detail_event.dart';
import '../bloc/chat_detail_state.dart';
import '../cubit/chat_detail_ui_cubit.dart';

class MessageListWidget extends StatelessWidget {
  final String currentUserId;
  final String chatId;

  const MessageListWidget({
    super.key,
    required this.currentUserId,
    required this.chatId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatDetailBloc, ChatDetailState>(
      builder: (context, state) {
        if (state is ChatDetailLoading) {
          return const Center(child: CircularProgressIndicator());
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
                  final showDateSeparator = _shouldShowDateSeparator(
                    messages,
                    index,
                  );

                  return Column(
                    children: [
                      if (showDateSeparator)
                        _buildDateSeparator(context, message.createdAt),
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
                Icon(Icons.error_outline, size: 80, color: AppTheme.errorColor),
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
                      LoadChatMessagesEvent(chatId),
                    );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
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
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: AppTheme.textPrimaryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    MessageModel message,
    bool isMe,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
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
                      color: isMe
                          ? AppTheme.sentMessageTextColor
                          : AppTheme.receivedMessageTextColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.createdAt),
                    style: AppTheme.messageTimeTextStyle.copyWith(
                      color: AppTheme.messageTimeColor,
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
