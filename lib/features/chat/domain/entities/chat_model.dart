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
      print('Parsing ChatModel from JSON: ${json.keys.toList()}');
      
      // Parse participants safely
      List<UserModel> participantsList = [];
      if (json['participants'] is List) {
        participantsList = (json['participants'] as List)
            .asMap()
            .entries
            .map((entry) {
              try {
                final index = entry.key;
                final participant = entry.value;
                if (participant is Map<String, dynamic>) {
                  return UserModel.fromJson(participant);
                } else {
                  print('Participant at index $index is not a Map: ${participant.runtimeType}');
                  return null;
                }
              } catch (e) {
                print('Error parsing participant at index ${entry.key}: $e');
                return null;
              }
            })
            .where((p) => p != null)
            .cast<UserModel>()
            .toList();
      } else {
        print('Participants field is not a List: ${json['participants']?.runtimeType}');
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
      } else if (json['lastMessage'] is String) {
        lastMessageContent = json['lastMessage'] as String;
      }

      // Parse unreadCount safely
      int unreadCount = 0;
      if (json['unreadCount'] is int) {
        unreadCount = json['unreadCount'] as int;
      } else if (json['unreadCount'] is String) {
        unreadCount = int.tryParse(json['unreadCount'] as String) ?? 0;
      }

      return ChatModel(
        id: json['_id'] as String? ?? json['id'] as String? ?? '',
        participants: participantsList,
        lastMessage: lastMessageContent,
        lastMessageTime: lastMessageTime,
        unreadCount: unreadCount,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      print('Error parsing ChatModel: $e');
      print('JSON data: $json');
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