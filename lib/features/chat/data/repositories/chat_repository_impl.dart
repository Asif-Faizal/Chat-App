import 'dart:async';
import 'package:dio/dio.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/chat_model.dart';
import '../../domain/entities/message_model.dart';
import '../../domain/entities/send_message_request.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ApiClient apiClient;
  final SocketService socketService;
  
  StreamController<MessageModel>? _messageStreamController;

  ChatRepositoryImpl({
    required this.apiClient,
    required this.socketService,
  }) {
    _initializeMessageStream();
  }

  void _initializeMessageStream() {
    _messageStreamController = StreamController<MessageModel>.broadcast();
    
    // Listen to socket message stream and convert to MessageModel
    socketService.messageStream.listen((data) {
      try {
        final message = MessageModel.fromJson(data);
        _messageStreamController?.add(message);
      } catch (e) {
        print('Error parsing socket message: $e');
      }
    });
  }

  @override
  Stream<MessageModel> get messageStream => 
      _messageStreamController?.stream ?? const Stream.empty();

  @override
  Future<Result<List<ChatModel>>> getChatList(String userId) async {
    try {
      final response = await apiClient.dio.get(
        '${Environment.userChatsEndpoint}/$userId',
      );

      if (response.statusCode == 200) {
        final List<dynamic> chatListData = response.data['chats'] ?? response.data ?? [];
        final chatList = chatListData
            .map((chatJson) => ChatModel.fromJson(chatJson))
            .toList();
        
        return Success(chatList);
      } else {
        return Error(ServerFailure(
          message: response.data['message'] ?? 'Failed to fetch chat list',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      return Error(_handleDioError(e));
    } catch (e) {
      return Error(UnknownFailure(
        message: 'An unexpected error occurred: $e',
      ));
    }
  }

  @override
  Future<Result<List<MessageModel>>> getChatMessages(String chatId) async {
    try {
      final response = await apiClient.dio.get(
        '${Environment.getChatMessagesEndpoint}/$chatId',
      );

      if (response.statusCode == 200) {
        final List<dynamic> messagesData = response.data['messages'] ?? response.data ?? [];
        final messages = messagesData
            .map((messageJson) => MessageModel.fromJson(messageJson))
            .toList();
        
        // Sort messages by created date (oldest first)
        messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        
        return Success(messages);
      } else {
        return Error(ServerFailure(
          message: response.data['message'] ?? 'Failed to fetch chat messages',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      return Error(_handleDioError(e));
    } catch (e) {
      return Error(UnknownFailure(
        message: 'An unexpected error occurred: $e',
      ));
    }
  }

  @override
  Future<Result<MessageModel>> sendMessage(SendMessageRequest request) async {
    try {
      // Send via HTTP API
      final response = await apiClient.dio.post(
        Environment.sendMessageEndpoint,
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final messageData = response.data['message'] ?? response.data;
        final message = MessageModel.fromJson(messageData);
        
        // Also send via socket for real-time delivery
        socketService.sendMessage(
          chatId: request.chatId,
          senderId: request.senderId,
          content: request.content,
          messageType: request.messageType,
          fileUrl: request.fileUrl,
        );
        
        return Success(message);
      } else {
        return Error(ServerFailure(
          message: response.data['message'] ?? 'Failed to send message',
          statusCode: response.statusCode,
        ));
      }
    } on DioException catch (e) {
      return Error(_handleDioError(e));
    } catch (e) {
      return Error(UnknownFailure(
        message: 'An unexpected error occurred: $e',
      ));
    }
  }

  @override
  void connectSocket(String userId) {
    socketService.connect(userId);
  }

  @override
  void disconnectSocket() {
    socketService.disconnect();
  }

  @override
  void joinChat(String chatId) {
    socketService.joinChat(chatId);
  }

  @override
  void leaveChat(String chatId) {
    socketService.leaveChat(chatId);
  }

  Failure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure(
          message: 'Connection timeout. Please check your internet connection.',
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data['message'] ?? 'Server error occurred';
        
        return ServerFailure(
          message: message,
          statusCode: statusCode,
        );
      case DioExceptionType.cancel:
        return const NetworkFailure(message: 'Request was cancelled');
      case DioExceptionType.connectionError:
        return const NetworkFailure(
          message: 'No internet connection. Please check your network settings.',
        );
      default:
        return UnknownFailure(
          message: 'An unexpected error occurred: ${error.message}',
        );
    }
  }

  void dispose() {
    _messageStreamController?.close();
  }
}