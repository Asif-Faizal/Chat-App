import 'package:equatable/equatable.dart';

abstract class ChatListEvent extends Equatable {
  const ChatListEvent();

  @override
  List<Object> get props => [];
}

class LoadChatListEvent extends ChatListEvent {
  final String userId;

  const LoadChatListEvent(this.userId);

  @override
  List<Object> get props => [userId];
}

class RefreshChatListEvent extends ChatListEvent {
  final String userId;

  const RefreshChatListEvent(this.userId);

  @override
  List<Object> get props => [userId];
}