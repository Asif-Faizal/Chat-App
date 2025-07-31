import 'package:equatable/equatable.dart';
import '../../domain/entities/message_model.dart';
import '../../domain/entities/send_message_request.dart';

abstract class ChatDetailEvent extends Equatable {
  const ChatDetailEvent();

  @override
  List<Object> get props => [];
}

class LoadChatMessagesEvent extends ChatDetailEvent {
  final String chatId;

  const LoadChatMessagesEvent(this.chatId);

  @override
  List<Object> get props => [chatId];
}

class SendMessageEvent extends ChatDetailEvent {
  final SendMessageRequest request;

  const SendMessageEvent(this.request);

  @override
  List<Object> get props => [request];
}

class ReceiveMessageEvent extends ChatDetailEvent {
  final MessageModel message;

  const ReceiveMessageEvent(this.message);

  @override
  List<Object> get props => [message];
}

class JoinChatEvent extends ChatDetailEvent {
  final String chatId;

  const JoinChatEvent(this.chatId);

  @override
  List<Object> get props => [chatId];
}

class LeaveChatEvent extends ChatDetailEvent {
  final String chatId;

  const LeaveChatEvent(this.chatId);

  @override
  List<Object> get props => [chatId];
}