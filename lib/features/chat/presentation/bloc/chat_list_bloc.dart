import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/result.dart';
import '../../domain/usecases/get_chat_list_usecase.dart';
import 'chat_list_event.dart';
import 'chat_list_state.dart';

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final GetChatListUsecase getChatListUsecase;

  ChatListBloc({
    required this.getChatListUsecase,
  }) : super(const ChatListInitial()) {
    on<LoadChatListEvent>(_onLoadChatList);
    on<RefreshChatListEvent>(_onRefreshChatList);
  }

  Future<void> _onLoadChatList(
    LoadChatListEvent event,
    Emitter<ChatListState> emit,
  ) async {
    emit(const ChatListLoading());
    await _fetchChatList(event.userId, emit);
  }

  Future<void> _onRefreshChatList(
    RefreshChatListEvent event,
    Emitter<ChatListState> emit,
  ) async {
    await _fetchChatList(event.userId, emit);
  }

  Future<void> _fetchChatList(
    String userId,
    Emitter<ChatListState> emit,
  ) async {
    final result = await getChatListUsecase(userId);
    
    result.fold(
      (failure) => emit(ChatListError(failure.message)),
      (chats) => emit(ChatListLoaded(chats)),
    );
  }
}