import '../../../../core/utils/result.dart';
import '../entities/message_model.dart';
import '../entities/send_message_request.dart';
import '../repositories/chat_repository.dart';

class SendMessageUsecase {
  final ChatRepository repository;

  SendMessageUsecase(this.repository);

  Future<Result<MessageModel>> call(SendMessageRequest request) async {
    return await repository.sendMessage(request);
  }
}