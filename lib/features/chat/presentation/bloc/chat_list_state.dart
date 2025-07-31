import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_model.dart';

abstract class ChatListState extends Equatable {
  const ChatListState();

  @override
  List<Object> get props => [];
}

class ChatListInitial extends ChatListState {
  const ChatListInitial();
}

class ChatListLoading extends ChatListState {
  const ChatListLoading();
}

class ChatListLoaded extends ChatListState {
  final List<ChatModel> chats;

  const ChatListLoaded(this.chats);

  @override
  List<Object> get props => [chats];
}

class ChatListError extends ChatListState {
  final String message;

  const ChatListError(this.message);

  @override
  List<Object> get props => [message];
}