import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/environment.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;

  // Stream controllers for different events
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  // Getters for streams
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _isConnected;

  void connect(String userId) {
    try {
      _socket = io.io(
        Environment.socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .setExtraHeaders({'userId': userId})
            .build(),
      );

      _socket!.onConnect((_) {
        if (kDebugMode) {
          print('Socket connected');
        }
        _isConnected = true;
        _connectionController.add(true);
        
        // Join user to their room
        _socket!.emit('join', {'userId': userId});
      });

      _socket!.onDisconnect((_) {
        if (kDebugMode) {
          print('Socket disconnected');
        }
        _isConnected = false;
        _connectionController.add(false);
      });

      _socket!.on('newMessage', (data) {
        if (kDebugMode) {
          print('New message received: $data');
        }
        _messageController.add(Map<String, dynamic>.from(data));
      });

      _socket!.onConnectError((error) {
        if (kDebugMode) {
          print('Socket connection error: $error');
        }
        _isConnected = false;
        _connectionController.add(false);
      });

      _socket!.onError((error) {
        if (kDebugMode) {
          print('Socket error: $error');
        }
      });

      _socket!.connect();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing socket: $e');
      }
    }
  }

  void sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    required String messageType,
    String? fileUrl,
  }) {
    if (_socket != null && _isConnected) {
      final messageData = {
        'chatId': chatId,
        'senderId': senderId,
        'content': content,
        'messageType': messageType,
        'fileUrl': fileUrl ?? '',
        'timestamp': DateTime.now().toIso8601String(),
      };

      _socket!.emit('sendMessage', messageData);
      
      if (kDebugMode) {
        print('Message sent: $messageData');
      }
    } else {
      if (kDebugMode) {
        print('Socket not connected. Cannot send message.');
      }
    }
  }

  void joinChat(String chatId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('joinChat', {'chatId': chatId});
      if (kDebugMode) {
        print('Joined chat: $chatId');
      }
    }
  }

  void leaveChat(String chatId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('leaveChat', {'chatId': chatId});
      if (kDebugMode) {
        print('Left chat: $chatId');
      }
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      _connectionController.add(false);
      
      if (kDebugMode) {
        print('Socket disconnected and disposed');
      }
    }
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
  }
}