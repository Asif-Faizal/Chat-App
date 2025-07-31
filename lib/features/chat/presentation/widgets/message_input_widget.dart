import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/send_message_request.dart';
import '../bloc/chat_detail_bloc.dart';
import '../bloc/chat_detail_event.dart';
import '../bloc/chat_detail_state.dart';
import '../cubit/chat_detail_ui_cubit.dart';

class MessageInputWidget extends StatelessWidget {
  final String chatId;
  final String currentUserId;

  const MessageInputWidget({
    super.key,
    required this.chatId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatDetailBloc, ChatDetailState>(
      builder: (context, state) {
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
      },
    );
  }

  void _sendMessage(BuildContext context) {
    final content = context.read<ChatDetailUICubit>().state.messageText.trim();
    if (content.isNotEmpty) {
      final request = SendMessageRequest(
        chatId: chatId,
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
} 