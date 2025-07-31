import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

class ChatDetailUICubit extends Cubit<ChatDetailUIState> {
  ChatDetailUICubit() : super(const ChatDetailUIState());

  void updateMessageText(String text) {
    emit(state.copyWith(messageText: text));
  }

  void clearMessageText() {
    emit(state.copyWith(messageText: ''));
  }

  void setScrollController(ScrollController controller) {
    emit(state.copyWith(scrollController: controller));
  }

  void scrollToBottom() {
    final controller = state.scrollController;
    if (controller != null && controller.hasClients) {
      controller.animateTo(
        controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void reset() {
    emit(const ChatDetailUIState());
  }
}

class ChatDetailUIState extends Equatable {
  final String messageText;
  final ScrollController? scrollController;

  const ChatDetailUIState({
    this.messageText = '',
    this.scrollController,
  });

  ChatDetailUIState copyWith({
    String? messageText,
    ScrollController? scrollController,
  }) {
    return ChatDetailUIState(
      messageText: messageText ?? this.messageText,
      scrollController: scrollController ?? this.scrollController,
    );
  }

  @override
  List<Object?> get props => [messageText, scrollController];
} 