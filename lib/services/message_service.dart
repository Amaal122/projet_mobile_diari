/// Message Service
/// ===============
/// Handles messaging between users and cookers

import 'api_service.dart';
import 'api_config.dart';

class MessageService {
  static String get _base => ApiConfig.baseUrl;

  /// Get all conversations for current user
  static Future<ApiResponse> getConversations() async {
    return await ApiService.get('$_base/messages/conversations');
  }

  /// Get messages in a conversation
  static Future<ApiResponse> getMessages(String conversationId, {int page = 1, int perPage = 50}) async {
    return await ApiService.get(
      '$_base/messages/conversations/$conversationId/messages?page=$page&per_page=$perPage',
    );
  }

  /// Send a message
  static Future<ApiResponse> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    return await ApiService.post(
      '$_base/messages/conversations/$conversationId/messages',
      body: {'text': text},
    );
  }

  /// Create a new conversation
  static Future<ApiResponse> createConversation({
    required String otherUserId,
  }) async {
    return await ApiService.post(
      '$_base/messages/conversations',
      body: {'userId2': otherUserId},
    );
  }

  /// Mark messages as read
  static Future<ApiResponse> markMessagesRead(String conversationId) async {
    return await ApiService.post(
      '$_base/messages/conversations/$conversationId/mark-read',
      body: {},
    );
  }
}

/// Conversation model
class Conversation {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String otherUserImage;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserImage,
    required this.lastMessage,
    this.lastMessageTime,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? '',
      otherUserId: json['otherUserId'] ?? '',
      otherUserName: json['otherUserName'] ?? 'مستخدم',
      otherUserImage: json['otherUserImage'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.tryParse(json['lastMessageTime'].toString())
          : null,
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}

/// Message model
class Message {
  final String id;
  final String senderId;
  final String text;
  final DateTime? timestamp;
  final bool read;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    this.timestamp,
    required this.read,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      text: json['text'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())
          : null,
      read: json['read'] ?? false,
    );
  }
}
