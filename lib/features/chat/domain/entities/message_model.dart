import 'package:equatable/equatable.dart';
import '../../../../core/models/user_model.dart';

class MessageModel extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final UserModel? sender;
  final String content;
  final String messageType;
  final String? fileUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.sender,
    required this.content,
    required this.messageType,
    this.fileUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isRead = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    try {
      print('Parsing MessageModel from JSON: ${json.keys.toList()}');
      
      // Parse sender safely
      UserModel? senderModel;
      if (json['sender'] != null) {
        try {
          if (json['sender'] is Map<String, dynamic>) {
            senderModel = UserModel.fromJson(json['sender'] as Map<String, dynamic>);
          } else {
            print('Sender field is not a Map: ${json['sender'].runtimeType}');
          }
        } catch (e) {
          print('Error parsing sender: $e');
        }
      }
      
      return MessageModel(
        id: json['_id'] as String? ?? json['id'] as String? ?? '',
        chatId: json['chatId'] as String? ?? '',
        senderId: json['senderId'] as String? ?? '',
        sender: senderModel,
        content: json['content'] as String? ?? '',
        messageType: json['messageType'] as String? ?? 'text',
        fileUrl: json['fileUrl'] as String?,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
        isRead: json['isRead'] as bool? ?? false,
      );
    } catch (e) {
      print('Error parsing MessageModel: $e');
      print('JSON data: $json');
      // Return a default message model to prevent crashes
      return MessageModel(
        id: json['_id'] as String? ?? json['id'] as String? ?? '',
        chatId: json['chatId'] as String? ?? '',
        senderId: json['senderId'] as String? ?? '',
        content: json['content'] as String? ?? 'Error loading message',
        messageType: 'text',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'sender': sender?.toJson(),
      'content': content,
      'messageType': messageType,
      'fileUrl': fileUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    UserModel? sender,
    String? content,
    String? messageType,
    String? fileUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRead,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      fileUrl: fileUrl ?? this.fileUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [
        id,
        chatId,
        senderId,
        sender,
        content,
        messageType,
        fileUrl,
        createdAt,
        updatedAt,
        isRead,
      ];
}