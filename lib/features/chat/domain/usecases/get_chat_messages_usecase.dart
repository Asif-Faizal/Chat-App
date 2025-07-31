import '../../../../core/utils/result.dart';
import '../entities/message_model.dart';
import '../repositories/chat_repository.dart';

class GetChatMessagesUsecase {
  final ChatRepository repository;

  GetChatMessagesUsecase(this.repository);

  Future<Result<List<MessageModel>>> call(String chatId) async {
    return await repository.getChatMessages(chatId);
  }
}