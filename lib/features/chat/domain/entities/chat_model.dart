import 'package:equatable/equatable.dart';
import '../../../../core/models/user_model.dart';

class ChatModel extends Equatable {
  final String id;
  final List<UserModel> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    try {
      // Parse participants safely
      List<UserModel> participantsList = [];
      if (json['participants'] is List) {
        participantsList = (json['participants'] as List)
            .map((p) {
              try {
                return UserModel.fromJson(p as Map<String, dynamic>);
              } catch (e) {
                print('Error parsing participant: $e');
                return null;
              }
            })
            .where((p) => p != null)
            .cast<UserModel>()
            .toList();
      }

      // Parse lastMessage safely
      String? lastMessageContent;
      DateTime? lastMessageTime;
      
      if (json['lastMessage'] is Map<String, dynamic>) {
        final lastMessageData = json['lastMessage'] as Map<String, dynamic>;
        lastMessageContent = lastMessageData['content'] as String?;
        if (lastMessageData['createdAt'] is String) {
          lastMessageTime = DateTime.tryParse(lastMessageData['createdAt'] as String);
        }
      }

      return ChatModel(
        id: json['_id'] as String? ?? json['id'] as String? ?? '',
        participants: participantsList,
        lastMessage: lastMessageContent,
        lastMessageTime: lastMessageTime,
        unreadCount: json['unreadCount'] as int? ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      print('Error parsing ChatModel: $e');
      // Return a default chat model to prevent crashes
      return ChatModel(
        id: json['_id'] as String? ?? json['id'] as String? ?? '',
        participants: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants.map((p) => p.toJson()).toList(),
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ChatModel copyWith({
    String? id,
    List<UserModel>? participants,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to get the other participant (for 1-on-1 chats)
  UserModel? getOtherParticipant(String currentUserId) {
    try {
      return participants.firstWhere((p) => p.id != currentUserId);
    } catch (e) {
      return null;
    }
  }

  @override
  List<Object?> get props => [
        id,
        participants,
        lastMessage,
        lastMessageTime,
        unreadCount,
        createdAt,
        updatedAt,
      ];
}