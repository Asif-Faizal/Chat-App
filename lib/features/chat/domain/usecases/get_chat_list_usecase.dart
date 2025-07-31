import '../../../../core/utils/result.dart';
import '../entities/chat_model.dart';
import '../repositories/chat_repository.dart';

class GetChatListUsecase {
  final ChatRepository repository;

  GetChatListUsecase(this.repository);

  Future<Result<List<ChatModel>>> call(String userId) async {
    return await repository.getChatList(userId);
  }
}