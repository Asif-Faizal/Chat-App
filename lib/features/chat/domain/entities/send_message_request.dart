import 'package:equatable/equatable.dart';

class SendMessageRequest extends Equatable {
  final String chatId;
  final String senderId;
  final String content;
  final String messageType;
  final String? fileUrl;

  const SendMessageRequest({
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.messageType,
    this.fileUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'messageType': messageType,
      'fileUrl': fileUrl ?? '',
    };
  }

  @override
  List<Object?> get props => [
        chatId,
        senderId,
        content,
        messageType,
        fileUrl,
      ];
}