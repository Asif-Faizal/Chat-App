import 'package:equatable/equatable.dart';
import '../../domain/entities/message_model.dart';

abstract class ChatDetailState extends Equatable {
  const ChatDetailState();

  @override
  List<Object> get props => [];
}

class ChatDetailInitial extends ChatDetailState {
  const ChatDetailInitial();
}

class ChatDetailLoading extends ChatDetailState {
  const ChatDetailLoading();
}

class ChatDetailLoaded extends ChatDetailState {
  final List<MessageModel> messages;
  final bool isSendingMessage;

  const ChatDetailLoaded({
    required this.messages,
    this.isSendingMessage = false,
  });

  ChatDetailLoaded copyWith({
    List<MessageModel>? messages,
    bool? isSendingMessage,
  }) {
    return ChatDetailLoaded(
      messages: messages ?? this.messages,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
    );
  }

  @override
  List<Object> get props => [messages, isSendingMessage];
}

class ChatDetailError extends ChatDetailState {
  final String message;

  const ChatDetailError(this.message);

  @override
  List<Object> get props => [message];
}

class MessageSendError extends ChatDetailState {
  final String message;
  final List<MessageModel> messages;

  const MessageSendError({
    required this.message,
    required this.messages,
  });

  @override
  List<Object> get props => [message, messages];
}