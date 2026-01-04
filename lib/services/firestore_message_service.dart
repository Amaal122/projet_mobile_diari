/// Firestore Message Service
/// ==========================
/// Real-time messaging using Firestore directly

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreMessageService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get currentUserId => _auth.currentUser?.uid;

  /// Get or create a conversation between current user and another user
  static Future<String> getOrCreateConversation(String otherUserId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // Check if conversation already exists
    final existing = await _db.collection('conversations')
        .where('participants', arrayContains: userId)
        .get();

    for (var doc in existing.docs) {
      final participants = List<String>.from(doc.data()['participants'] ?? []);
      if (participants.contains(otherUserId)) {
        return doc.id;
      }
    }

    // Create new conversation
    final docRef = await _db.collection('conversations').add({
      'participants': [userId, otherUserId],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'unreadCount_$userId': 0,
      'unreadCount_$otherUserId': 0,
    });

    return docRef.id;
  }

  /// Stream of conversations for current user
  static Stream<List<ConversationModel>> getConversationsStream() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _db.collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      List<ConversationModel> conversations = [];
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final participants = List<String>.from(data['participants'] ?? []);
          final otherUserId = participants.firstWhere((p) => p != userId, orElse: () => '');
          
          if (otherUserId.isEmpty) continue;

          // Get other user info - check cookers first, then users
          String otherUserName = 'مستخدم';
          String otherUserImage = '';
          
          try {
            final cookerDoc = await _db.collection('cookers').doc(otherUserId).get();
            if (cookerDoc.exists) {
              final cookerData = cookerDoc.data()!;
              otherUserName = cookerData['name'] ?? 'طباخ';
              otherUserImage = cookerData['profileImage'] ?? cookerData['image'] ?? '';
            } else {
              final userDoc = await _db.collection('users').doc(otherUserId).get();
              if (userDoc.exists) {
                final userData = userDoc.data()!;
                otherUserName = userData['name'] ?? 'مستخدم';
                otherUserImage = userData['profileImage'] ?? '';
              }
            }
          } catch (e) {
            print('Error fetching user data: $e');
          }

          conversations.add(ConversationModel(
            id: doc.id,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
            otherUserImage: otherUserImage,
            lastMessage: data['lastMessage'] ?? '',
            lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
            unreadCount: data['unreadCount_$userId'] ?? 0,
          ));
        } catch (e) {
          print('Error processing conversation: $e');
          continue;
        }
      }
      
      // Sort by last message time (most recent first)
      conversations.sort((a, b) {
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });
      
      return conversations;
    }).handleError((error) {
      print('Error in conversations stream: $error');
      return <ConversationModel>[];
    });
  }

  /// Stream of messages in a conversation
  static Stream<List<MessageModel>> getMessagesStream(String conversationId) {
    return _db.collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return MessageModel(
            id: doc.id,
            senderId: data['senderId'] ?? '',
            text: data['text'] ?? '',
            timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
            read: data['read'] ?? false,
          );
        }).toList());
  }

  /// Send a message
  static Future<void> sendMessage(String conversationId, String text) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');
    if (text.trim().isEmpty) return;

    final conversationRef = _db.collection('conversations').doc(conversationId);
    
    // Add message
    await conversationRef.collection('messages').add({
      'senderId': userId,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });

    // Get other participant to update their unread count
    final convDoc = await conversationRef.get();
    final participants = List<String>.from(convDoc.data()?['participants'] ?? []);
    final otherUserId = participants.firstWhere((p) => p != userId, orElse: () => '');

    // Update conversation
    await conversationRef.update({
      'lastMessage': text.trim(),
      'lastMessageTime': FieldValue.serverTimestamp(),
      if (otherUserId.isNotEmpty) 'unreadCount_$otherUserId': FieldValue.increment(1),
    });
  }

  /// Mark messages as read
  static Future<void> markAsRead(String conversationId) async {
    final userId = currentUserId;
    if (userId == null) return;

    // Reset unread count for current user
    await _db.collection('conversations').doc(conversationId).update({
      'unreadCount_$userId': 0,
    });

    // Mark individual messages as read
    final unreadMessages = await _db.collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('read', isEqualTo: false)
        .where('senderId', isNotEqualTo: userId)
        .get();

    final batch = _db.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}

/// Conversation Model
class ConversationModel {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String otherUserImage;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  ConversationModel({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserImage,
    required this.lastMessage,
    this.lastMessageTime,
    required this.unreadCount,
  });
}

/// Message Model
class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime? timestamp;
  final bool read;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.timestamp,
    required this.read,
  });

  bool isMe(String? currentUserId) => senderId == currentUserId;
}
