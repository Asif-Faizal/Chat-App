import '../../../../core/utils/result.dart';
import '../entities/chat_model.dart';
import '../entities/message_model.dart';
import '../entities/send_message_request.dart';

abstract class ChatRepository {
  Future<Result<List<ChatModel>>> getChatList(String userId);
  Future<Result<List<MessageModel>>> getChatMessages(String chatId);
  Future<Result<MessageModel>> sendMessage(SendMessageRequest request);
  Stream<MessageModel> get messageStream;
  void connectSocket(String userId);
  void disconnectSocket();
  void joinChat(String chatId);
  void leaveChat(String chatId);
}