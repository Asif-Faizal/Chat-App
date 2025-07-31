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
      if (userId.isEmpty) {
        return const Error(ValidationFailure(
          message: 'User ID is required to fetch chats',
        ));
      }

      print('Fetching chats for userId: $userId'); // Debug log
      
      final response = await apiClient.dio.get(
        '${Environment.userChatsEndpoint}/$userId',
      );

      if (response.statusCode == 200) {
        // Handle different possible response structures
        List<dynamic> chatListData = [];
        
        if (response.data is List) {
          // Direct array response
          chatListData = response.data as List<dynamic>;
        } else if (response.data is Map<String, dynamic>) {
          // Object with chats property
          final responseMap = response.data as Map<String, dynamic>;
          if (responseMap.containsKey('chats')) {
            chatListData = responseMap['chats'] as List<dynamic>? ?? [];
          } else if (responseMap.containsKey('data')) {
            final dataField = responseMap['data'];
            if (dataField is List) {
              chatListData = dataField;
            } else if (dataField is Map<String, dynamic> && dataField.containsKey('chats')) {
              chatListData = dataField['chats'] as List<dynamic>? ?? [];
            }
          }
        }
        
        print('Raw chat list data length: ${chatListData.length}');
        if (chatListData.isNotEmpty) {
          print('First item structure: ${chatListData.first}');
        }
            
        final chatList = <ChatModel>[];
        
        for (int i = 0; i < chatListData.length; i++) {
          try {
            final chatItem = chatListData[i];
            if (chatItem is Map<String, dynamic>) {
              final chat = ChatModel.fromJson(chatItem);
              chatList.add(chat);
            } else {
              print('Chat item at index $i is not a Map: ${chatItem.runtimeType}');
            }
          } catch (e) {
            print('Error parsing chat at index $i: $e');
            print('Chat data: ${chatListData[i]}');
            // Continue processing other chats instead of failing completely
          }
        }
        
        print('Successfully parsed ${chatList.length} chats');
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
      print('Unexpected error in getChatList: $e');
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
        
        // Extract error message from API response
        String message = 'Server error occurred';
        if (error.response?.data != null) {
          final responseData = error.response!.data;
          if (responseData is Map<String, dynamic>) {
            // Try different common error message fields
            message = responseData['msg'] ?? 
                     responseData['message'] ?? 
                     responseData['error'] ?? 
                     message;
          } else if (responseData is String) {
            message = responseData;
          }
        }
        
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