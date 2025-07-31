import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/message_model.dart';
import '../../domain/usecases/get_chat_messages_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import 'chat_detail_event.dart';
import 'chat_detail_state.dart';

class ChatDetailBloc extends Bloc<ChatDetailEvent, ChatDetailState> {
  final GetChatMessagesUsecase getChatMessagesUsecase;
  final SendMessageUsecase sendMessageUsecase;
  final SocketService socketService;
  
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;

  ChatDetailBloc({
    required this.getChatMessagesUsecase,
    required this.sendMessageUsecase,
    required this.socketService,
  }) : super(const ChatDetailInitial()) {
    on<LoadChatMessagesEvent>(_onLoadChatMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<ReceiveMessageEvent>(_onReceiveMessage);
    on<JoinChatEvent>(_onJoinChat);
    on<LeaveChatEvent>(_onLeaveChat);
    
    _initializeSocketListener();
  }

  void _initializeSocketListener() {
    _messageSubscription = socketService.messageStream.listen((messageData) {
      try {
        final message = MessageModel.fromJson(messageData);
        add(ReceiveMessageEvent(message));
      } catch (e) {
        print('Error parsing socket message: $e');
      }
    });
  }

  Future<void> _onLoadChatMessages(
    LoadChatMessagesEvent event,
    Emitter<ChatDetailState> emit,
  ) async {
    emit(const ChatDetailLoading());
    
    final result = await getChatMessagesUsecase(event.chatId);
    
    result.fold(
      (failure) => emit(ChatDetailError(failure.message)),
      (messages) => emit(ChatDetailLoaded(messages: messages)),
    );
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatDetailState> emit,
  ) async {
    if (state is ChatDetailLoaded) {
      final currentState = state as ChatDetailLoaded;
      emit(currentState.copyWith(isSendingMessage: true));
      
      final result = await sendMessageUsecase(event.request);
      
      result.fold(
        (failure) => emit(MessageSendError(
          message: failure.message,
          messages: currentState.messages,
        )),
        (message) {
          final updatedMessages = List<MessageModel>.from(currentState.messages)
            ..add(message);
          emit(ChatDetailLoaded(
            messages: updatedMessages,
            isSendingMessage: false,
          ));
        },
      );
    }
  }

  void _onReceiveMessage(
    ReceiveMessageEvent event,
    Emitter<ChatDetailState> emit,
  ) {
    if (state is ChatDetailLoaded) {
      final currentState = state as ChatDetailLoaded;
      
      // Check if message already exists (to avoid duplicates)
      final messageExists = currentState.messages
          .any((msg) => msg.id == event.message.id);
      
      if (!messageExists) {
        final updatedMessages = List<MessageModel>.from(currentState.messages)
          ..add(event.message);
        
        // Sort messages by created date
        updatedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        
        emit(currentState.copyWith(messages: updatedMessages));
      }
    }
  }

  void _onJoinChat(
    JoinChatEvent event,
    Emitter<ChatDetailState> emit,
  ) {
    socketService.joinChat(event.chatId);
  }

  void _onLeaveChat(
    LeaveChatEvent event,
    Emitter<ChatDetailState> emit,
  ) {
    socketService.leaveChat(event.chatId);
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    return super.close();
  }
}