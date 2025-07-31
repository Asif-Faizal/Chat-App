import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/chat_model.dart';
import '../bloc/chat_detail_bloc.dart';
import '../bloc/chat_detail_event.dart';
import '../bloc/chat_detail_state.dart';
import '../cubit/chat_detail_ui_cubit.dart';
import '../widgets/message_list_widget.dart';
import '../widgets/message_input_widget.dart';

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
            return WillPopScope(
              onWillPop: () async {
                // Trigger chat list refresh when popping
                Navigator.of(context).pop(true);
                return false; // Prevent default pop behavior since we're handling it
              },
              child: Scaffold(
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
                      child: MessageListWidget(
                        currentUserId: currentUserId,
                        chatId: chat.id,
                      ),
                    ),
                    MessageInputWidget(
                      chatId: chat.id,
                      currentUserId: currentUserId,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}